import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:service/feather.dart';

/// The buckets: their folder on disk under `STORAGE_VOLUME_PATH`, their
/// metadata in the database, and what goes away with them (rules, grants,
/// pending uploads).
class BucketService {
  final BucketTableRepo bucketRepo;
  final ObjectService objectService;

  final AccessRuleTableRepo accessRuleRepo;
  final AccessKeyTableRepo accessKeyRepo;

  BucketService()
    : bucketRepo = BucketTableRepo(di.find()),
      accessRuleRepo = AccessRuleTableRepo(di.find()),
      accessKeyRepo = AccessKeyTableRepo(di.find()),
      objectService = di.find();

  Future<bool> createBucket({
    required String bucketName,
    String? description,
    int? color,
  }) async {
    // 1. Its folder
    await _createFolder(bucketName);

    // 2. Persistence via Repo
    await bucketRepo.save(
      name: bucketName,
      description: description,
      color: color,
    );
    logger.info('Bucket created', fields: {'bucket': bucketName});

    return true;
  }

  Future<void> deleteBucket({required String bucketName}) async {
    // 1. Its folder (only if it is empty)
    await _deleteFolder(bucketName);

    // 2. Its pending multipart uploads
    await MultipartService().abortAll(bucketName);

    // 3. Database delete (its anonymous access rules and the access keys'
    // grants first)
    await accessRuleRepo.deleteByBucket(bucketName);
    await accessKeyRepo.deleteGrantsByBucket(bucketName);
    await bucketRepo.delete(bucketName);
    logger.info('Bucket deleted', fields: {'bucket': bucketName});
  }

  Future<BucketModel> getBucket({required String bucketName}) async {
    final dir = await _existingBucketDir(bucketName);
    return _toModel(dir, await bucketRepo.findByName(bucketName));
  }

  /// Deletes every object; the bucket, its metadata and its rules stay.
  Future<void> emptyBucket({required String bucketName}) async {
    await _existingBucketDir(bucketName);
    await objectService.deleteAll(bucketName);
    logger.info('Bucket emptied', fields: {'bucket': bucketName});
  }

  /// Replaces the description and color of an existing bucket.
  Future<BucketModel> updateBucket({
    required String bucketName,
    String? description,
    int? color,
  }) async {
    final dir = await _existingBucketDir(bucketName);

    await bucketRepo.save(
      name: bucketName,
      description: description,
      color: color,
    );

    return _toModel(dir, await bucketRepo.findByName(bucketName));
  }

  Future<List<BucketModel>> listBuckets() async {
    final storageDir = Directory(env.storageVolumePath);
    if (!await storageDir.exists()) {
      return [];
    }

    // Metadata from DB
    final dbBuckets = await bucketRepo.findAll();
    final dbBucketsMap = {for (var b in dbBuckets) b.name: b};

    final List<BucketModel> buckets = [];
    final List<FileSystemEntity> entities = await storageDir.list().toList();

    for (var entity in entities) {
      if (entity is Directory) {
        final bucketName = p.basename(entity.path);
        if (!S3Validator.isValidBucketName(bucketName)) continue;

        buckets.add(await _toModel(entity, dbBucketsMap[bucketName]));
      }
    }

    return buckets;
  }

  Future<bool> bucketExists(String bucketName) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    return Directory(_bucketPath(bucketName)).exists();
  }

  Future<void> _createFolder(String bucketName) async {
    // Bucket name with the S3 rules
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception(
        S3ErrorCode.invalidBucketName,
        message: intl.errors.s3.invalidBucketNameRules(bucket: bucketName),
        resource: bucketName,
      );
    }

    // As in S3, creating a bucket that already exists is a 409
    final bucketDir = Directory(_bucketPath(bucketName));
    if (await bucketDir.exists()) {
      throw S3Exception(
        S3ErrorCode.bucketAlreadyOwnedByYou,
        message: intl.errors.s3.bucketAlreadyExists(bucket: bucketName),
        resource: bucketName,
      );
    }
    await bucketDir.create(recursive: true);
  }

  Future<void> _deleteFolder(String bucketName) async {
    final dir = await _existingBucketDir(bucketName);

    // S3 requires the bucket to be empty. Empty folders (with only their
    // marker) are not objects and don't prevent it
    final hasObjects = await dir
        .list(recursive: true)
        .any(
          (entity) =>
              entity is File &&
              p.basename(entity.path) != S3Validator.folderMarker,
        );
    if (hasObjects) {
      throw S3Exception(
        S3ErrorCode.bucketNotEmpty,
        message: intl.errors.s3.bucketNotEmpty(bucket: bucketName),
        resource: bucketName,
      );
    }

    await dir.delete(recursive: true);
    await objectService.objectMeta.forgetBucket(bucketName);
  }

  String _bucketPath(String bucketName) =>
      p.join(env.storageVolumePath, bucketName);

  Future<Directory> _existingBucketDir(String bucketName) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    final dir = Directory(_bucketPath(bucketName));
    if (!await dir.exists()) {
      throw S3Exception.noSuchBucket(bucketName);
    }
    return dir;
  }

  /// Joins the disk statistics with the database metadata.
  Future<BucketModel> _toModel(Directory dir, BucketTableData? dbBucket) async {
    final stat = await dir.stat();

    int totalSize = 0;
    int objectCount = 0;
    DateTime? lastModified;

    final bucketEntities = await dir.list(recursive: true).toList();
    for (var bucketEntity in bucketEntities) {
      if (bucketEntity is File &&
          p.basename(bucketEntity.path) != S3Validator.folderMarker) {
        final fileStat = await bucketEntity.stat();
        objectCount++;
        totalSize += fileStat.size;
        if (lastModified == null || fileStat.modified.isAfter(lastModified)) {
          lastModified = fileStat.modified;
        }
      }
    }

    return BucketModel(
      name: p.basename(dir.path),
      objectCount: objectCount,
      size: totalSize,
      creationDate: dbBucket?.createdAt ?? stat.changed,
      lastModified: lastModified,
      description: dbBucket?.description,
      color: dbBucket?.color,
    );
  }
}

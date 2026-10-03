import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:service/feather.dart';

class BucketService {
  final BucketTableRepo bucketRepo;
  final FileManagementService fileManagement;

  final AccessRuleTableRepo accessRuleRepo;

  BucketService()
    : bucketRepo = BucketTableRepo(di.find()),
      accessRuleRepo = AccessRuleTableRepo(di.find()),
      fileManagement = di.find();

  Future<bool> createBucket({
    required String bucketName,
    String? description,
    int? color,
  }) async {
    // 1. Physical creation via FileManagementService
    await fileManagement.createBucket(bucketName: bucketName);

    // 2. Persistence via Repo
    await bucketRepo.save(
      name: bucketName,
      description: description,
      color: color,
    );

    return true;
  }

  Future<void> deleteBucket({required String bucketName}) async {
    // 1. Physical delete (checks if empty)
    await fileManagement.deleteBucketPhysical(bucketName);

    // 2. Its pending multipart uploads
    await MultipartService().abortAll(bucketName);

    // 3. Database delete (its anonymous access rules first)
    await accessRuleRepo.deleteByBucket(bucketName);
    await bucketRepo.delete(bucketName);
  }

  Future<BucketModel> getBucket({required String bucketName}) async {
    final dir = await _existingBucketDir(bucketName);
    return _toModel(dir, await bucketRepo.findByName(bucketName));
  }

  /// Deletes every object; the bucket, its metadata and its rules stay.
  Future<void> emptyBucket({required String bucketName}) async {
    await fileManagement.emptyBucket(bucketName);
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

  Future<Directory> _existingBucketDir(String bucketName) async {
    if (!S3Validator.isValidBucketName(bucketName)) {
      throw S3Exception.invalidBucketName(bucketName);
    }
    final dir = Directory(p.join(env.storageVolumePath, bucketName));
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

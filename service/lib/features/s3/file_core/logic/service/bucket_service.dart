import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:service/feather.dart';

class BucketService {
  final BucketTableRepo bucketRepo;
  final FileManagementService fileManagement;

  BucketService()
    : bucketRepo = BucketTableRepo(di.find()),
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

    // 2. Database delete
    await bucketRepo.delete(bucketName);
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

        final stat = await entity.stat();
        final dbBucket = dbBucketsMap[bucketName];

        // Physical stats
        int totalSize = 0;
        int objectCount = 0;

        final bucketEntities = await entity.list(recursive: true).toList();
        for (var bucketEntity in bucketEntities) {
          if (bucketEntity is File) {
            objectCount++;
            totalSize += await bucketEntity.length();
          }
        }

        buckets.add(
          BucketModel(
            name: bucketName,
            objectCount: objectCount,
            size: totalSize,
            creationDate: dbBucket?.createdAt ?? stat.changed,
            description: dbBucket?.description,
            color: dbBucket?.color,
          ),
        );
      }
    }

    return buckets;
  }
}

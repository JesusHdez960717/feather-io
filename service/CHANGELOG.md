# Changelog

## 1.0.0-rc.2 (2026-10-11)

- The Docker image no longer declares a `VOLUME`: platforms that mount their own (Railway)
  reject it. Mount one at `/data` (`STORAGE_VOLUME_PATH`) as before.

## 1.0.0-rc.1 (2026-10-10)

First release candidate of the S3-compatible service.

- **S3 API**: buckets (create, list, delete, location), objects (upload streamed to disk, download
  with `Range`, `HEAD`, copy with conditions, delete one or up to 1000, folders, stored headers and
  storage class, real ETags), ListObjects V1 and V2 (prefix, delimiter, paging,
  `encoding-type=url`) and multipart (create, parts, copy of parts, complete, abort, list parts and
  uploads). XML like S3 by default, JSON with `Accept: application/json`; unimplemented
  subresources answer `501 NotImplemented`.
- **Authentication**: AWS SigV4 in the header and in presigned URLs (up to 7 days), `aws-chunked`
  bodies, clock skew and body sha256 checks; JWT for the console.
- **Access**: managed access keys (read, write or both, per bucket or on every bucket, expiry,
  secrets encrypted with AES-256-GCM) and anonymous access rules per prefix or pattern.
- **Admin API** for the console: bucket details and statistics, empty a bucket, delete a folder,
  presigned links, zip downloads, anonymous rules and access keys; documented with OpenAPI and
  Swagger UI.
- **Operations**: health check at `/{admin}/health`, structured logs (`LOG_FORMAT=json`), a rate
  limit per IP and login throttling, error messages in English and Spanish, metadata in SQLite (WAL)
  inside the storage volume, and a 24 MB Docker image.
- Tested against the AWS CLI v2, rclone and the 15 suites of MinIO Mint.

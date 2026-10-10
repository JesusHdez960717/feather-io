# Roadmap

Proposed order of the remaining work in `service/` and `console/`. Mark each task with `[x]` when it
is done.

## Current status

| Area             | Service                                                                                                                       | Console                                                          |
|------------------|-------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------|
| Buckets          | List, create, edit, delete, empty, details with statistics (description and color in SQLite)                                  | All of the above, in the *Buckets* section                       |
| Objects          | List (prefix/delimiter, paging), upload, multipart, download, copy, delete one or many, zip download, folders, presigned URLs | All of the above, with preview, drag & drop and a transfer queue |
| Anonymous access | Rules per prefix or pattern (`readOnly`, `writeOnly`, `readWrite`), applied by `AnonymousAccessFilter`                        | Create and delete rules per bucket                               |
| Auth             | JWT + SigV4, the root key from the env plus access keys per bucket, login and general rate limits                             | Login, *Access keys* section                                     |

## Phase 0: Foundation

- [x] Move `service/test/*` to JWT (`JWT_SECRET`, `STORAGE_VOLUME_PATH`).
- [x] `S3Exception` mapped to AWS error codes (`NoSuchBucket`, `BucketNotEmpty`, `EntityTooLarge`…),
  honoring content negotiation.
- [x] Apply `ReservedBucketFilter` when creating and deleting buckets (a bucket could be created
  with a name from `RESERVED_BUCKET_NAMES`).

## Phase 1: Quick wins in the console

- [x] **Browser filters** (console): by type, size, date and text, client-side over the list
  already loaded.
- [x] **Edit bucket**
    - [x] Service: `PUT /{admin}/bucket/{bucket}` for description and color.
    - [x] Console: edit form reusing `bucket_create_form`.

## Phase 2: Bucket details

- [x] Service: `GET /{admin}/bucket/{bucket}` with metadata and statistics (`last_modified`
  included). The rules are requested separately, with their own endpoint.
- [x] Service: `DELETE /{admin}/bucket/{bucket}/objects` to empty the bucket; deleting a bucket also
  deletes its rules.
- [x] Service: register `AnonymousAccessFilter` on the S3 routes, with anonymous access tests.
- [x] Console: *Buckets* section with the list and the details (feature `bucket_admin`)
    - [x] General: name, description, color, dates, size and object count.
    - [x] Access rules: create and delete (feature `anonymous_access`).
    - [x] Danger zone: empty and delete the bucket.
- [x] Console: *Settings* entry from the browser (bucket menu and header), by route with
  `RouteNames.openBucketSettings`.
- [x] Console: keep the *Buckets* section and the browser in sync (each has its own cubits; they
  notify each other with `BucketChangedEvent` when a bucket is created, edited, emptied or deleted
  and when objects are uploaded or deleted).

## Phase 3: Full browser

- [x] The browser URL keeps the bucket, the folder and the view
  (`/browser?bucket=&folder=&view_type=`), with a notice if the bucket or the folder doesn't exist.
- [x] Create folder
    - [x] Service: `PUT /{bucket}/{folder}/` creates an empty folder (a directory with the
      `.feather-folder` marker), listed as the key `folder/`.
    - [x] Console: *New folder* button with a dialog.
- [x] Rename or move objects
    - [x] Service: `CopyObject` (`x-amz-copy-source`).
    - [x] Console: rename and move (one or many) with copy and delete.
- [x] Object details
    - [x] Service: `HEAD` object (served by the `GET` route) with `Last-Modified`.
    - [x] Console: details drawer with thumbnail, key, type, size, date and URL.
- [x] Paging in list-objects
    - [x] Service: `max-keys` (max. 1000) and `continuation-token`, with `IsTruncated`,
      `NextContinuationToken` and `KeyCount`.
    - [x] Console: paginator (25, 50, 75 or 100 per page; *Page X of N* with `total_keys`). Search
      and filters look at the pages already loaded.

## Phase 4: S3 compatibility

- [x] Presigned URLs, with a "share link" button in the console (the service signs in
  `POST /{admin}/bucket/{bucket}/presign`; expiry of 1 hour, 1 day or 7 days).
- [x] Background uploads and downloads (console): they no longer block the screen with the loading
  overlay. They go to an app-wide transfer queue (`TransferCubit`, feature `transfers`) that keeps
  going across folders, buckets and sections, with an always-visible indicator in the rail (above
  the language) and a panel with the progress of each file or zip, cancel and retry. Uploads fire
  `BucketChangedEvent` so the browser reloads by itself.
- [x] Multipart upload: create, upload parts, complete and abort. The console uploads files over
  16 MiB in 8 MiB parts.
- [x] Tests against real clients: AWS CLI v2 and rclone pass entirely, and in Mint the AWS and MinIO
  SDKs, s3cmd and mc reach what is out of scope (see *Parked*). The batteries live in
  `service/tool/s3_compat/`. Fixes that came out of it: SigV4 (bucket permissions, header without
  spaces, query encoding), `aws-chunked`, `Range`, real ETags and metadata, DeleteObjects in XML,
  ListObjects V1 and `encoding-type=url`, GetBucketLocation, ListMultipartUploads, ListParts,
  UploadPartCopy, copy conditions, storage class, `501` for the unimplemented subresources and
  folder deletes like S3.

## Phase 5: Operations and production

- [x] Access key management with permissions, with its admin screen in the console (*Access
  keys* section: per-bucket levels or every bucket, expiration, enable/disable, regenerate the
  secret; secrets encrypted with `KEYS_ENCRYPTION_SECRET`).
- [x] SQLite path based on `STORAGE_VOLUME_PATH` (`STORAGE_VOLUME_PATH/.db/feather-io.sqlite`).
- [x] i18n of the service error messages (English and Spanish, from `Accept-Language`).
- [x] Dockerfile: Dart version `^3.13` and `libsqlite3` in the final image.
- [x] Console tests (cubits and repos), on the VM with `fvm flutter test`.
- [x] Winter `1.0.0-rc.1`: errors as Problem Details (the console reads `detail` and the 422's
  `violations`), request bodies read with `json.field` (a 400 names the field), Winter's rate
  limiter, logs through `logger` (`LOG_FORMAT`, `LOG_LEVEL`, `LoggingFilter`) and the OpenAPI
  document of the admin API with Swagger UI (`/{admin}/docs`).

## Phase 6: Makeup for version 1.0.0

- [x] An object mapper for XML, so the service has no `parseToXML` helpers: each object implements
  `toJson` and `toXml` its own way (`lib/xml/`: `XmlElement` writes and parses, `S3Response`
  picks the format).
- [x] Shrink `S3Controller`, which had more than 1000 lines: it only holds the routes, and the
  operations live in `BucketController`, `ObjectController` and `MultipartController`.
- [ ] Performance tests/benchmarks (e.g. `minio/warp`) with the service on Linux: confirm the
  suspected bottlenecks (every listing page walks the whole bucket, `ListBuckets` walks every
  object, md5 and SQLite on every upload) and review with that data the general limit of 2000
  requests/min per IP (see `DECISIONS.md`).
- [ ] A visual identity/icon like Brag's, and a promo video with real screenshots of the design.

## Open source release

A session of its own, before publishing the repo.

- [ ] Publish Winter and depend on its released version instead of the local path
  (`../../winter`): until then nobody else can build the service.
- [ ] Root `README.md`: what it is, what is supported (and what isn't, see *Parked*), how to run
  the service and the console (local and Docker), how to configure S3 clients, screenshots, and
  what comes next.
- [ ] `LICENSE` at the root (each package has its own Apache 2.0 `LICENSE.md`; decide whether one
  at the root covers both and fill in its copyright notice).
- [ ] `CONTRIBUTING.md`: setup with FVM, code rules (from `CLAUDE.md`), tests and which batteries
  to run, commit format.
- [ ] `SECURITY.md`: how to report a vulnerability, plus the security decisions of
  `DECISIONS.md`.
- [ ] Review `CHANGELOG.md` in both packages (they still say *POC*) and the versions in
  `pubspec.yaml`.

## After 1.0 (future improvements)

Not part of 1.0; they will be done later.

- [ ] Rename and move folders (all their content has to be copied and deleted, and it must be
  decided what happens if it fails halfway).
- [ ] Move object search and filters to the service, to search the whole folder and not only the
  pages already loaded.

## Parked

- Console light theme.
- Bucket policies, MD5/checksum validation and advanced multipart cases.
- S3 compatibility that is out of scope (it shows up in Mint): SigV2 signatures (including
  `s3 presign` from CLI v1), validating `x-amz-content-sha256` and the `aws-chunked` checksums,
  POST policy uploads, versioning and tags (only answered as none), notifications, S3 Select,
  retention/object lock and MinIO's own APIs (admin, snowball, force-delete).
- Keys with characters the filesystem doesn't support (`<>:"|?*` on Windows): keys would have to be
  encoded on disk.

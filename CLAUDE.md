# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository. It is the single source of truth for project rules.

## Overview

Monorepo for a lightweight S3-compatible storage system:

- `service/` — Dart backend built on **Winter** `1.0.0-rc.1` (from pub.dev; its source is also at
  `../winter`, a sibling of this repo). Its guides (`doc/`), examples (`example/`, the apps
  `auth_jwt` and `production` are the closest to this service) and `DECISIONS.md` are the
  reference; read its source when an API is unclear.
- `console/` — Flutter Web admin console. Talks to the service over REST.

The two packages are strictly decoupled: they share nothing but the HTTP contract.

Scope relaxations still in force: focus on core S3 CRUD. Ignore bucket policies, MD5/checksum
validation and advanced multipart edge cases for now.

`DECISIONS.md` explains the non-obvious design decisions (rate limits and their numbers, SigV4,
anonymous access…) with the data behind them; update it when one of them changes.

`ROADMAP.md` lists the pending work in order, as checkboxes. When a change completes a roadmap task,
mark it `[x]` in the same change; add new pending work to the right phase.

## Commands

The project pins Flutter via FVM (`.fvmrc` in both packages, Flutter 3.47.1 / Dart 3.13). Both
packages need Dart SDK ^3.13.0. The system `dart` on PATH may be older, so prefix commands with
`fvm` (`fvm dart …`, `fvm flutter …`).

### Service (run from `service/`)

Relative paths in the env (`STORAGE_VOLUME_PATH=./uploads_local`) resolve against the working
directory, so always run from `service/`.

```bash
fvm dart pub get
fvm dart run build_runner build          # only for Drift (lib/features/db/database.g.dart)
fvm dart run slang                       # after editing lib/i18n/*.i18n.yaml (error messages)
fvm dart analyze
fvm dart test                            # all tests
fvm dart test test/features/s3/objects/put_object_test.dart  # one file
fvm dart test test/features/s3/objects/put_object_test.dart --plain-name "Should upload successfully in root"
```

Run the server (port 8080) with the env from `.vscode/launch.json`:

```bash
FEATHER_ACCESS=access FEATHER_SECRET=secret JWT_SECRET=some-jwt-secret \
KEYS_ENCRYPTION_SECRET=some-keys-secret STORAGE_VOLUME_PATH=./uploads_local ADMIN_PREFIX=_admin \
fvm dart run lib/main.dart
```

Required env (`requiredEnvVariables`, checked at once with `env.requireAll` before anything
starts): `FEATHER_ACCESS`, `FEATHER_SECRET`, `JWT_SECRET`, `KEYS_ENCRYPTION_SECRET`,
`STORAGE_VOLUME_PATH`. Optional: `ADMIN_PREFIX` (default `_admin`), `RESERVED_BUCKET_NAMES`,
`MAX_OBJECT_SIZE` (bytes, default 5 GiB), `LOG_FORMAT` (`json` for one JSON object per line,
otherwise readable lines) and `LOG_LEVEL` (`debug`, `info` (default), `warning`, `error`).
`main()` reads `.env`/`.env.<WINTER_PROFILE>` under the process variables (`Env.load()`), so a
local `.env` works too. See `service/README.md` (its endpoint table lists only some routes, so treat the
controllers as the source of truth).

`service/Dockerfile` builds with `docker build -t feather-io .` from `service/`. It compiles AOT on `dart:3.13.1` and runs on `scratch` with the Dart runtime,
`libsqlite3.so` copied next to its libc (the `sqlite3` package opens it through FFI) and a `/tmp`
(zip downloads); `STORAGE_VOLUME_PATH=/data` is a volume. Bump the image tag with `.fvmrc`.

### Console (run from `console/`)

```bash
fvm flutter pub get
fvm flutter gen-l10n                                            # after editing lib/l10n/arb/*.arb
fvm flutter run -d chrome --web-port=8081
fvm flutter analyze
fvm flutter test                                                # on the VM, no browser
```

- Runtime config comes from `web/env.js` (`window.env`: `SERVICE_URL`, `ADMIN_PREFIX`), which is
  gitignored. `ADMIN_PREFIX` must match the service.
- Tests (`test/`, `bloc_test` + `mocktail`) run on the VM. Code that needs the browser
  (`dart:js_interop`, `package:web`, Dio's browser adapter, `window.env`) lives only in the
  `*_web.dart` adapters (`adapter/`, `config/env_web.dart`), exported with
  `if (dart.library.js_interop)` next to a `*_vm.dart` that does nothing; never import it
  elsewhere, or the tests stop compiling.
- On web, Dio sets the XHR timeout to `connectTimeout + receiveTimeout` (20 s) for the **whole**
  request, upload included. Requests that can take longer (uploads, downloads) pass
  `connectTimeout`/`receiveTimeout` = `Duration.zero` (no limit) and rely on a `CancelToken`.
- On web, Dio reports 401/403 as `connectionError` rather than `badResponse`.
  `ApiExceptionConverter` therefore maps web connection errors to `GlobalExceptionType.auth`.
- Errors of the service are Problem Details: `ApiExceptionConverter` shows their `detail`, and a
  422 becomes `ValidationError`s from its `violations` (`fieldName` = the form field).

## HTTP contract (both sides)

- JSON keys are `snake_case`; Dart properties are `camelCase` (e.g. `size_bytes` ↔ `sizeBytes`,
  `access_token` ↔ `accessToken`).
- Auth is JWT (`Authorization: Bearer …`) for the console and AWS SigV4 for native S3 clients. The
  old `x-feather-access`/`x-feather-secret` header auth no longer exists.
- When a field is renamed, change the service model's `toJson`/`fromJson` **and** the console DTO in
  the same change.

## Service architecture

**Bootstrap.** `FeatherIO.start()` in `lib/main.dart` registers deserializers on the ObjectMapper (
`om`), puts `AppDatabase`, `ObjectService`, `BucketService` and `JwtService` into Winter's `di`, then builds
`S3Controller` and `AdminController` and passes their `.routing` to `Winter.start`. `S3Controller`
only holds the S3 routes: S3 multiplexes several operations on one method and path (by query and
headers), so each route hands the request to its operation in `BucketController`,
`ObjectController` or `MultipartController`. What those read from a request (bucket, key, stored
headers, storage class, copy conditions, the multipart permission) is the `S3Request` extension.
`lib/feather.dart` is the barrel file that re-exports Winter and every feature. Source files import
`package:service/feather.dart`, never `package:winter/winter.dart` or individual files. Each folder
has a barrel (`admin.dart`, `anonymous_access.dart`, `s3.dart`, `buckets.dart`, …) that must export every new
file.

**Two APIs share one router.**

- S3 API is mounted at `/`, with path-style `/{bucket}/{key|.*}`.
- Admin API is mounted at `/{ADMIN_PREFIX}` and always returns JSON.
- Admin paths start with `_` so they cannot collide with valid bucket names. `S3BucketNameFilter`
  validates bucket names on both parents. `ReservedBucketFilter` blocks `RESERVED_BUCKET_NAMES` plus
  the admin prefix, and is attached per route rather than to the parent.
- Filters on a parent route are inherited by its children. To stop a parent's `AuthFilter` from
  applying to child routes, gate it with
  `shouldFilter: (r) => r.route?.key == '<own key>'`, as `s3.list-objects` does.

**Auth and authorization.**

- The global filter is `JwtFilter`. It populates the `securityContext` from a `Bearer` token issued
  by `POST /{admin}/login`; `JwtService.verifyToken` also requires an `exp` claim, so no token can
  live forever. Login is rate limited per client IP by `LoginRateLimiter` (in DI): every failure
  waits `LOGIN_FAILURE_DELAY_MS` (1 s) and `LOGIN_MAX_FAILURES` (10) failures in a row lock the IP
  for `LOGIN_LOCK_SECONDS` (15 min, `429` + `Retry-After`, even with good credentials); a success
  clears it. The IP is `request.clientIp(trustedProxies: TRUSTED_PROXIES)`, so `X-Forwarded-For`
  is ignored unless proxies are declared. Credentials are compared in constant time. That endpoint
  checks `FEATHER_ACCESS`/`FEATHER_SECRET` and issues a
  token with a fixed permission list.
- A general `RateLimiterFilter` (Winter's) is the first global filter: `RATE_LIMIT_REQUESTS` (2000)
  requests per IP every `RATE_LIMIT_WINDOW_SECONDS` (60), 0 disables it; the number comes from
  measured client bursts (see `DECISIONS.md`). It throws Winter's 429, which `S3ExceptionHandler`
  turns into `503 SlowDown` on the S3 API (what S3 clients retry) and a translated 429 on the admin
  API, both with `Retry-After` and `X-RateLimit-*`.
- `S3SigV4Filter` handles native S3 clients and is registered only on the S3 parent route, so the
  admin API accepts JWT only. `JwtFilter` is registered globally and again on both parents.
  `JwtFilter` and `S3SigV4Filter` both skip themselves (`shouldFilter`) once the request is
  authenticated. `S3SigV4Filter` accepts the signature in the `Authorization` header or in the
  query (presigned URL: `X-Amz-Signature`, `X-Amz-Date`, `X-Amz-Expires` up to 7 days), and passes
  through requests with neither, so an unauthenticated request gets a 401 from the route's
  `AuthFilter`. Like S3, a signature more than 15 minutes away from the server clock is
  `RequestTimeTooSkewed` (`S3SigV4Filter.maxClockSkew`; it stops replaying captured requests), the
  credential scope must be the signature's day, and a presigned URL can't be dated in the future
  (that would stretch it past the 7-day maximum). When the client signs the body's sha256 (a hex
  `x-amz-content-sha256`), the filter wraps the body and fails with `XAmzContentSHA256Mismatch`
  after reading it if it doesn't match, so a captured request can't be replayed with another body
  (`UNSIGNED-PAYLOAD` and `STREAMING-…` bodies are not checked). Authentication errors never
  include internal details. The `Authorization` fields may be separated by `,` with or without a space (s3cmd
  sends none). Canonical query names and values, and the paths `PresignService` builds, are encoded
with `SigV4Signer.uriEncode` (everything but `A-Za-z0-9-_.~`, like AWS; `Uri.encodeComponent`
leaves `!'()*` alone and the signature would not match); `test/security/sig_v4_signer_test.dart` checks it
against the AWS docs example. The SigV4 maths live in `security/logic/sig_v4_signer.dart` (`SigV4Signer`), shared
  with `PresignService`, which signs `GET` URLs with the service keys for
  `POST /{admin}/bucket/{bucket}/presign` (the console has no secret key, so it asks the service).
  The URL uses `PUBLIC_URL` (scheme, host and port, validated at start-up) or, without it, the
  scheme and `Host` of that request; a proxy in front must keep the original `Host`, because the
  host is part of the signature.
- **Access keys** (`admin/access_keys/`, tables `access_key` + `access_key_grant`): besides the
  root key of the env, S3 clients sign with managed keys (`FIOK` + 16 chars, 40-char secret).
  The secret is stored encrypted by `SecretCipher` (AES-256-GCM, key = sha256 of
  `KEYS_ENCRYPTION_SECRET`, the key id as associated data; `security/logic/secret_cipher.dart`)
  because SigV4 needs it back, and the API only returns it on create and on
  `POST /{admin}/access-keys/{id}/secret`. `S3SigV4Filter` looks the key up
  (`AccessKeyService.findForSignature`), answers `InvalidAccessKeyId` when it is unknown, disabled
  or expired, and authenticates with the `AccessKeyModel` as the principal and the permissions of
  its level on the request's bucket (`S3SigV4Filter.keyPermissions`: `readOnly` = list/get,
  `writeOnly` = put/delete/multi-delete, plus `s3.list-buckets`; create/delete bucket only with
  write access to every bucket). The controller reads the principal for what the route can't see:
  ListBuckets only lists the key's buckets and a copy needs `canRead` on the source bucket (or a
  public read rule on the source key). Only
  the root key logs in to the console, so the admin API never sees a managed key. `last_used_at`
  is written at most once a minute per key (`AccessKeyService.touch`). Deleting a bucket deletes
  its grants. See `DECISIONS.md`.
- Each route declares its own permission with
  `AuthFilter(rules: hasPermission('s3.put-object') | hasPermission('s3.anonymous.put-object'))`.
  Route keys and permission names match (`s3.*`, `admin.*`).
- New endpoints need the route key, an `AuthFilter`, **and** the permission added to the list in
  `admin/auth/controller/auth_controller.dart` (and to `S3SigV4Filter` if native S3 clients should reach
  it). An admin endpoint also needs its `docs:` (see *OpenAPI*).
- `AnonymousAccessFilter` runs on the S3 parent after the SigV4 filter, for unauthenticated
  requests and, as in AWS, for requests signed with an access key that lacks the route's permission
  (it adds the rule's `s3.anonymous.*` permissions to the key's, which stays the principal; a copy
  from a public read prefix is allowed through `ObjectController.copySource`). It looks up the bucket's prefix rules (`anonymous_rule` table, via
  `AnonymousAccessService.findMatchingRule`) and grants the `s3.anonymous.*` permissions of the
  first matching rule. A rule without `*` is a prefix; with `*` (any characters, `/` included) the
  whole key must match, so `fotos/*.jpg` doesn't open `fotos/a.jpg.zip`; everything else matches
  literally (`AnonymousAccessService.matches`). It covers
  list/get/put/delete object; multi-delete is never anonymous, because its keys come in the body.
  Deleting a bucket deletes its rules.

**Folder layout.** Every feature (or sub-feature) under `lib/features/` uses the same folders:

| Folder           | Layer      | Contents                                                            |
|------------------|------------|---------------------------------------------------------------------|
| `controller/`    | Controller | Routes, request parsing, content negotiation (`S3Response`).        |
| `filter/`        | Controller | Winter `Filter`s specific to the feature.                           |
| `logic/model/`   | Model      | Typed models and request/response classes.                          |
| `logic/service/` | Service    | Business logic, validation, file I/O.                               |
| `repo/`          | Repository | Drift table access only.                                            |

A parent feature keeps what its sub-features share, and each sub-feature has its own folders:

- `admin/` (`admin_controller.dart` with the admin routes) with `auth/`, `anonymous_access/` and
  `access_keys/`.
- `s3/` (`s3_controller.dart` with the S3 routes, `s3_request.dart`, `s3_response.dart`;
  `filter/`; `utils/` with `AwsChunkedDecoder`, `S3Validator` and `S3Xml`) with `buckets/`
  (`BucketService`: their folder, metadata and what goes away with them), `objects/`
  (`ObjectService`: objects on disk, `ObjectMetaService`, `PresignService`) and `multipart/`.
- `db/` (Drift).

Outside `features/`: `config/`, `exceptions/` (`S3Exception`, `S3ErrorCode` and
`S3ExceptionHandler`), `i18n/`, `security/` (JWT, SigV4, secrets) and `xml/` (the XML mapper).

**Layer rules.**

- Controller is the **only** layer that touches HTTP formats: `Content-Type`, `Accept`, and
  choosing between the `toJson()` and the `toXml()` of a model. Use Winter abstractions (`RequestEntity`, `ResponseEntity`, `Route`,
  `ObjectMapper`), never `dart:io`'s `HttpRequest`. A body is read with `body<T>()`, `bytes()`,
  `readAsString()` (text, 400 if it isn't UTF-8) or `read()` (a stream); a filter passes a changed
  request with `request.copyWith(...)`.
- Services and repos return typed models (`BucketModel`, `ListObjectsResponse`…), `File`s or
  `Stream<List<int>>`. They never build raw JSON maps or XML for responses, nor inspect headers.
- Repos never know about `Content-Type` or HTTP.
- Avoid `dynamic`; use `Map<String, dynamic>` only for raw JSON input, otherwise strict models.
- Don't add dependencies for things Dart core or Winter already cover.

**Models / serialization.** JSON is hand-written, without interfaces: a model has a
`Map<String, Object?> toJson()` (Winter finds it by itself) with the `snake_case` names. Request
models have a `fromJson` factory that reads each field with `json.field<T>('json_name')` (never
casts: a wrong body is then a 400 that names the field, `$.buckets[0]: expected an object, got a
string`), **and** a `Deserializer<T>.json(T.fromJson)` in `main.dart`; a list of objects
(`json.field<List<CompletedPart>>`) needs its element registered too. They are read with
`request.body<T>()`, which also validates a `Validatable` (422): never call `validate()` again
in the controller, except after `body<T>(validate: false)` (CreateBucket, whose optional body may
be XML). Validation is `ConstraintValidatorContext()..field('name', value).notNull().size(...)`,
a nested list with `validEach()` (`buckets[0].access`) and a rule of the service with
`.custom((value) => message or null)`. Admin request and response models have a
`static final example` for the OpenAPI document. No `build_runner` except Drift.

**Content negotiation (S3 only).** XML is S3-compliant and the default; the console always asks
for JSON. A model answered by the S3 API implements `XmlSerializable` (`XmlElement toXml()`, next
to its `toJson()`), and the controller returns `S3Response.ok(request, model)`, which picks the
JSON when `Accept` has `application/json` and the XML otherwise. When the two forms differ (the
JSON of ListBuckets is the list, the XML a `ListAllMyBucketsResult`), a small model holds what
the XML needs (`BucketListModel`, `PartListModel`…) and its `toJson()` returns the list.

The XML mapper (`lib/xml/`, no package) is `XmlElement`: built with `XmlElement(name, elements:)`
and `XmlElement.leaf(name, value)`, written with `toXmlString()` (declaration, indentation, every
text and attribute escaped), and read with `XmlElement.parse(body)` (`child`, `children`,
`childText`; prefixes dropped, entities and CDATA decoded, anything malformed is a
`FormatException`). Request bodies have a `fromXml` factory (`DeleteObjectsRequest`,
`CompleteMultipartRequest`) and the controller turns a `FormatException` into `MalformedXML`.
`S3Xml` has what the S3 documents share: the root with the S3 namespace, `<Owner>` (`feather-io`,
which some clients require), the ETag between quotes and the dates in UTC with milliseconds
(`2026-10-02T14:22:35.000Z`). `S3Exception.toXml()` is the `<Error>`, with the `RequestId`.

`multiDelete` reads the S3 `<Delete>` XML or, with a JSON `Content-Type` or body, the console's
JSON (at most 1000 keys). CreateBucket and PutObject answer like S3, with no body: CreateBucket
with a `Location` header, PutObject with its `ETag`. GetBucketLocation (`GET /{bucket}?location`,
served by the list-objects route) always answers an empty XML `LocationConstraint`
(`us-east-1`).

`UnsupportedSubresourceFilter` (S3 parent) answers `501 NotImplemented` to the subresources the
service does not implement (`?versioning`, `?policy`, `?tagging`, `?acl`, `?legal-hold`…). Without it they would fall into
the normal routes (`PUT /{bucket}?versioning` would create the bucket). A newly implemented
subresource must be removed from its list. Two reads are answered anyway, because clients ask for
them before other operations: GetObjectTagging (`GET /{bucket}/{key}?tagging`, an empty `TagSet`;
the AWS CLI asks before a multipart copy) and GetBucketVersioning (`GET /{bucket}?versioning`,
never enabled; rclone asks before a purge).

**Errors.** Every JSON error is a Problem Details (RFC 9457, `application/problem+json`:
`type`, `title`, `status`, `detail`), as Winter answers them.

- S3 errors (from services and S3 filters) throw
  `S3Exception(S3ErrorCode.x, message: …, resource: …)` (`exceptions/`), or
  one of its named constructors (`invalidBucketName`, `invalidKey`, `noSuchBucket`, `noSuchKey`).
  It is an `ApiException`: `detail` is the message and the extensions `code` and `resource`. Each
  `S3ErrorCode` carries the AWS code and its HTTP status; add new codes there.
- `S3ExceptionHandler` (registered in `main.dart` with `Winter.context.setUp`) overrides
  `SimpleExceptionHandler.handle`: on the S3 API an `S3Exception` is the S3 `<Error>` XML (with
  its `RequestId`) unless the client accepts JSON, a 413 is `EntityTooLarge` and a 429 is
  `SlowDown`; everything else follows Winter's rules (a 400 of the object mapper with the path of
  the field, a 422 with `violations` (`fieldName`, `message`, `code`, `params`), a 500 that only
  shows the `requestId`).
- The admin API throws `S3Exception` too (`InvalidCredentials`, `NoSuchAccessKey`,
  `InvalidRequest`…), so its errors are Problem Details with `code` and `resource` as well.
- Messages are translated, codes never (`DECISIONS.md` §7). The texts live in
  `lib/i18n/en.i18n.yaml` (base, with the parameter types) and `es.i18n.yaml`, generated by slang
  (`fvm dart run slang`, generated code versioned). Any code reads them with the `intl` getter
  (`lib/i18n/i18n.dart`), in the language of the request in progress (Winter's `requestLocale`,
  from `Accept-Language`, English by default), without receiving the request:
  `S3Exception(…, message: intl.errors.s3.noSuchBucket(bucket: name))`,
  `.custom((v) => … ? null : intl.errors.validations.x)`, `.notNull(message: intl.…)`. `intl` is a
  getter: never keep it in a `final` or a `static`, and build validators inside `validate()`.
  Winter adds `Vary: Accept-Language` by itself. A new message goes into both YAML files.
- A controller that wraps a block in `try/catch` must
  `if (e is ApiException || e is DeserializationException) rethrow;` before converting unknown
  errors (a malformed body keeps its 400 with the field).
- Never put the text of an unexpected error in a response (it may hold paths of the server): log
  it with `logger.error(…, error: e, stackTrace: s)` and answer a generic message.

**Logging.** Everything goes through Winter's `logger` (never `print`/`stdout`):
`env.serviceLogger` (`LOG_FORMAT`, `LOG_LEVEL`) is set in `FeatherIO.start`, and every line
carries the request id (also in the `X-Request-Id` header). `LoggingFilter` (global) writes the
method, path, status and time of each request; it never logs the query (a presigned URL carries
its signature there) nor bodies. Services log changes of state at `info` and what needs attention
at `warning`, with ids in `fields`, never a secret, token or key typed at login.

**OpenAPI.** `AdminController.routing` serves the OpenAPI 3.1 document of the admin API at
`/{admin}/openapi.json` and Swagger UI at `/{admin}/docs` (both public; the S3 API is left out,
it is the one AWS documents). Each admin route has `docs: RouteDocs(summary:, tags:, request:,
response:, status:, query:)`: the bodies come from the `example` of the models, and the schema
constraints from their `validate()`; security, the 401/403/429 and the error responses are found
by Winter. `test/features/admin/openapi_test.dart` checks it.

**Storage & performance.** Buckets are directories under `STORAGE_VOLUME_PATH`. Bucket metadata (
description, color, timestamps), anonymous rules and object ETags live in SQLite via Drift, in
`STORAGE_VOLUME_PATH/.db/feather-io.sqlite` (`AppDatabase.defaultPath`; a dot folder, never listed
as a bucket), so the metadata lives in the same volume as the objects. It is opened in WAL mode with
`synchronous=NORMAL` (`AppDatabase._setUp`, see `DECISIONS.md` §11). The
schema has no migrations while in development: when it changes, delete the SQLite file and let it be
recreated. PutObject, CopyObject and CreateMultipartUpload need an existing bucket (`NoSuchBucket`
otherwise); only the subfolders of the key are created on the fly. PutObject writes into
`STORAGE_VOLUME_PATH/.tmp/` (a dot folder, never listed) and renames the file into place when the
upload ends, so a failed upload keeps the previous object (CopyObject and
CompleteMultipartUpload also end with `ObjectService.replaceFile`; on Windows an open
target can't be replaced, so it retries for `replaceTimeout` (5 s) and then answers
`503 ServiceUnavailable`, which S3 clients retry); `Md5Tap.write` closes and deletes the file
when the stream fails (`pipe` does not close the sink). Deletes go through
`ObjectService._delete`, which on Windows retries for a few seconds while the file is open
(a download not yet closed, the antivirus scanning a new file). Removing the empty parents of a
deleted object is best-effort and never recursive (`_deleteEmptyParents`): parallel deletes race
for the same folder, and an upload may land in it meanwhile; a leftover empty folder without marker
is not listed. Clients that sign by chunks
(`x-amz-content-sha256: STREAMING-…` or `Content-Encoding: aws-chunked`: mc and recent AWS SDKs/CLI)
send `aws-chunked` bodies; `AwsChunkedDecoder` (controller layer) strips the framing in streaming
for PutObject and UploadPart, without checking chunk signatures or trailing checksums, and answers
`IncompleteBody` for a malformed body only after reading it all (if the request body is not read to
the end, dart:io drops the connection without sending the error). `aws-chunked` is never stored as
the object's `Content-Encoding`. Object payloads must
always flow as `Stream<List<int>>` (`request.read()`, `file.openRead()`): **never** `readAsBytes()`
or `Uint8List` for object data. Multi-object downloads build the zip in a temp file (
`ObjectService.zipObjects`) and stream it with `openAndDeleteTemp`. Winter's
`ServerConfig.maxBodySize` (10 MB by default) is set to `MAX_OBJECT_SIZE`, and `BodySizeFilter` (
global) narrows it by route from the `Content-Length`: `s3.put-object` over `MAX_OBJECT_SIZE` →
`EntityTooLarge`; every other body (read into memory) is capped at 2 MB (413). A `POST`/`PUT`/
`PATCH` without `Content-Length` (empty, as aws-sdk-java-v2's CreateBucket, or chunked) gets its
body wrapped by the filter, which fails with 413 while reading; Winter reads the rest and
discards it, so the client gets the answer (`EntityTooLarge` on the S3 API). Every bucket name goes through
`S3Validator.isValidBucketName` and every key through `S3Validator.isValidKey` (path traversal
protection) before touching the filesystem. Keys can't contain `\`: on Windows it is a folder
separator, so `a\b` would alias `a/b` and could write a folder marker.

**Folders and listing.** A key ending in `/` is a folder: `PUT /{bucket}/fotos/` creates the
directory with a hidden `S3Validator.folderMarker` file (`.feather-folder`), so empty folders
survive the cleanup of empty parents. Listings show the marker as the key `fotos/` (size 0), stats
and zips skip it, no key may use that name, and a bucket holding only empty folders counts as empty.
Deleting works like S3: `DELETE /{bucket}/fotos/` (or `fotos/` in a multi-delete) removes only the
marker, never the content, and a key without `/` that is a directory deletes nothing. To delete a
folder with its content the console calls the admin endpoint
`DELETE /{admin}/bucket/{bucket}/folder?prefix=fotos/` (`ObjectService.deleteFolder`,
permission `admin.bucket.delete-folder`); `BrowserRepo.deleteObjects` sends the folder keys there and
the rest to the multi-delete. Winter drops the trailing `/` from the `{key}` path param; `S3Request.objectKey` restores it
from the URL. `listFiles` walks only the folder of the prefix (`photos/2026/` for `photos/2026/a`,
only its own level with the delimiter `/`, a subfolder with any file being a common prefix; a
prefix that is not a valid key walks from the root) and reads the `stat` of the keys of the page
only, so a page costs what its folder holds. It sorts objects and common prefixes together and
pages over them
(`max-keys` up to 1000). With `list-type=2` the controller answers ListObjectsV2
(`continuation-token` = base64url of the last key returned, or `start-after`); otherwise
ListObjects V1 (`marker` and `NextMarker`). With `encoding-type=url` keys, prefixes and markers go
URL-encoded (`SigV4Signer.uriEncode` per segment, keeping `/`) with `<EncodingType>url`, because
clients decode them.
`PUT` with `x-amz-copy-source` is CopyObject and needs the plain `s3.get-object` permission, so an
anonymous rule can never copy. Copying an object onto itself is only allowed to change its metadata
(`REPLACE`) or storage class, and then only the metadata is rewritten. `HEAD` object is served by the `GET` route (Winter sends the headers
only), which includes `Last-Modified`, `ETag` and `Accept-Ranges`. A file without a known extension
is `application/octet-stream`. `GET`/`HEAD` honour a single `Range` (`bytes=a-b`, `bytes=a-`,
`bytes=-n`) with `206` + `Content-Range`, read with `file.openRead(start, end)`; a range starting
past the end is `416 InvalidRange`, and a malformed or multiple range is ignored (`200` with the whole
object), as in S3.

**Object metadata.** `ObjectMetaService` keeps each object's ETag and headers in the `object_meta`
table, with the file's size and mtime. The headers are the ones S3 stores (`Content-Type`,
`Content-Encoding`, `Content-Disposition`, `Content-Language`, `Cache-Control`, `Expires` and
`x-amz-meta-*`, lowercased): the controller picks them from the request (`_objectHeaders`) on
PutObject, CreateMultipartUpload (kept in `upload.json` until Complete) and CopyObject with
`x-amz-metadata-directive: REPLACE` (otherwise the copy keeps the source's), and GET/HEAD send them
back. Without a stored `Content-Type` it comes from the extension. `x-amz-storage-class` is
validated (`InvalidStorageClass`) and stored like those headers, except `STANDARD`, which S3 never
sends back; a copy takes it from the request, not from the source. A signed `GET` may override the
response headers with `?response-content-type=…` (and `-disposition`, `-cache-control`, …); anonymous
requests can't. CopyObject and UploadPartCopy check the `x-amz-copy-source-if-*` conditions
(`CopyConditions`, `412 PreconditionFailed`). Uploads compute the md5 while streaming (`Md5Tap`, also used by UploadPart), copies
reuse the source's ETag and multipart stores `md5(part md5s)-N`. On read (GET/HEAD, listings), a
missing row or one whose size/mtime no longer match (the file changed outside the service) gets its
ETag recomputed by reading the file and saved, keeping its headers; listings only compute it for the objects of the returned
page. Deleting an object, a folder or a bucket, or emptying a bucket, deletes its rows.

**Multipart upload.** `MultipartService` implements CreateMultipartUpload (
`POST /{bucket}/{key}?uploads`, route `s3.post-object`), UploadPart (`PUT ?partNumber=&uploadId=`,
on `s3.put-object`, `ETag` header = md5 of the part), CompleteMultipartUpload (`POST ?uploadId=`, S3
XML or JSON `{"parts": [{"part_number", "etag"}]}`) and AbortMultipartUpload (`DELETE ?uploadId=`).
All need `s3.put-object` (no anonymous multipart): Create and Complete get it from the POST route,
but UploadPart, Abort, ListParts and ListMultipartUploads go through PUT/DELETE/GET routes that
accept anonymous rules, so their handlers call `_requireUploadPermission` (an anonymous writer
could otherwise list, overwrite parts of or abort other users' uploads). Pending uploads live in
`STORAGE_VOLUME_PATH/.multipart/<uploadId>/` (`upload.json` + `<n>.part`/`<n>.etag`); a dot folder
is not a valid bucket, so it isn't listed. Complete checks ascending order, ETags and the 5 MiB
minimum of every part but the last, joins the parts inside the upload folder and moves the result,
so the object never shows half-written; the final ETag is S3's `md5(part md5s)-N`. Deleting a bucket
aborts its uploads. The upload id is validated as 32 hex chars before it touches a path. ListParts
(`GET /{bucket}/{key}?uploadId=`, served by the get-object route) lists the uploaded parts with
`part-number-marker`/`max-parts`, and requires `s3.put-object` like the rest of multipart. ListMultipartUploads (`GET /{bucket}?uploads`, list-objects route) lists the
pending uploads of the bucket, sorted and without paging. UploadPartCopy (`PUT ?partNumber&uploadId`
with `x-amz-copy-source` and optionally `x-amz-copy-source-range: bytes=a-b`) feeds UploadPart with
`ObjectService.readForCopy`. CORS exposes `ETag` so the console can read it.

**S3 compatibility.** `service/tool/s3_compat/` runs real S3 clients in Docker against a running
service: `run.sh` (AWS CLI v2 and rclone batteries, `awscli.sh`/`rclone.sh`) and `run.sh mint`
(MinIO Mint, 15 suites of AWS/MinIO SDKs, s3cmd and mc, ~5 min). Check the service log too:
clients retry, so a 500 may only show up there.

**Performance.** `service/tool/benchmark/` runs MinIO's warp against the service in Docker
(throughput by object size and clients, listings by bucket size, ListBuckets, memory, the rate
limit) and MinIO as a reference; `report.py` writes `RESULTS.md` (see its README). Run it after a
change meant to make the service faster, and update the reading of the numbers in `report.py`.

**Which tests to run.** `dart test` catches regressions in what already works (every endpoint,
its edge cases and every bug found so far), but it checks responses against our reading of the S3
spec. Real clients parse the XML strictly, sign in their own way and chain calls nobody expects,
and almost every incompatibility so far was found by them, not by `dart test`:

| When | Run | Time |
|---|---|---|
| Every change | `fvm dart test` (from `service/`) | ~11 s |
| Touching the S3 API (controller, filters, signatures, XML, headers) | also `service/tool/s3_compat/run.sh` (AWS CLI and rclone) | ~1–2 min |
| Before a release or after big protocol changes | also `run.sh mint`, i.e. the *Full test run* below | ~5 min |

**Full test run.** When asked to run every test (or to refresh the results summary), do all of it
from scratch and regenerate `service/tool/s3_compat/RESULTS.md`. Outputs go to
`service/tool/s3_compat/out/` (gitignored), which is what `report.py` reads:

1. Static analysis: `fvm dart analyze > tool/s3_compat/out/service_analyze.txt` from `service/`,
   and `fvm flutter analyze > ../service/tool/s3_compat/out/console_analyze.txt 2>&1` from `console/`
   (it prints its summary to stderr).
2. Tests: from `service/`, `rm -rf uploads_test` and
   `fvm dart test --reporter json > tool/s3_compat/out/service_tests.jsonl`; from `console/`,
   `fvm flutter test --reporter json > ../service/tool/s3_compat/out/console_tests.jsonl`.
3. A clean service: start it from an **empty scratch folder** with
   `STORAGE_VOLUME_PATH=./uploads_local` (relative, so it doesn't touch `service/uploads_local`),
   `FEATHER_ACCESS=feather-access FEATHER_SECRET=feather-secret-key` (the defaults of `run.sh`; `mc`
   rejects a secret shorter than 8 characters), and its output in a log file. Outside `service/` `fvm` falls back to
   the global SDK, so call the pinned one: `<repo>/service/.fvm/flutter_sdk/bin/dart run
   <repo>/service/lib/main.dart`. Docker Desktop must be running.
4. Clients: `service/tool/s3_compat/run.sh awscli rclone mint` from the repo root.
5. Report: `python service/tool/s3_compat/report.py --server-log <service log>` rewrites
   `RESULTS.md` (date, commit, versions, totals per test file, client and Mint suite, only the
   failures, each Mint failure with its cause, what doesn't work and what isn't tested).
6. Review before committing:
   - Mint failures marked **Unclassified** and any unhandled error in the service log are new:
     investigate them; a real bug is fixed (with its test), a new out-of-scope one goes into
     `REASONS` in `report.py` and *Parked* in `ROADMAP.md`.
   - A new test file needs its line in `TEST_DESC` (`CONSOLE_TEST_DESC` for the console), and a suite whose outcome changed its text in
     `SUITE_STATUS` (both in `report.py`); `NOT_WORKING`/`NOT_TESTED` are kept by hand there too.
   - Stop the scratch service when done.

**Tests.** Rules for new tests:

- Every new feature gets tests. `test/` mirrors `lib/`: a test goes in the folder of what it
  tests (`features/s3/objects/put_object_test.dart`, `features/admin/auth/login_test.dart`,
  `security/`, `xml/`, `i18n/`), and `support/` holds the helpers. `s3_controller_test.dart`
  (in `features/s3/`) holds the happy path (upload → list → get → delete); each endpoint gets its
  own file (`put_object_test.dart`, `list_buckets_test.dart`…).
- Use `TestServer` (`test/support/test_server.dart`): `TestServer(port: …, name: …)`, then
  `setUpAll(server.start)` / `tearDownAll(server.stop)`. It sets the env, starts the real server
  with an in-memory SQLite (`FeatherIO.start(database: …)`), logs in to get `server.token`, and
  creates and deletes `./uploads_test/<name>` (gitignored); `fileDatabase: true` uses the real
  SQLite file inside that folder instead. It sets `LOG_LEVEL=warning`, so only problems are
  printed. Helpers: `server.url(path)`,
  `server.auth(json: …)`, `server.createBucket(…)` (tolerates an existing one),
  `server.putObject(…, headers: …)` (creates the bucket first and sends bytes without
  `Content-Type`, so reads fall back to the extension) and `server.sigV4(method, path, query: …)`, the
  headers of a native client signed with SigV4 (`access:`/`secret:` sign with an access key created
  in the test). Uploading with `http.put` needs the bucket created.
- Use one distinct port per file so files run in parallel. Ports in use: 8082–8114.
- Cover auth (missing or invalid token → 401, wrong login credentials → 403), validation (bad bucket
  names, path traversal, forbidden chars → 400; a 422 reads `body['violations']`, a JSON error
  `body['detail']` and `body['code']`), content negotiation (JSON vs XML, including the S3 error
  code) and edge cases (404, empty lists).
- To send a path traversal that reaches the server, encode the slashes (`..%2F..%2Ffile`). The HTTP
  client normalizes `%2e%2e` segments away.

## Console architecture

**Feature layout.** Each feature is self-contained in `lib/features/<name>/`:

| Path                                     | Contents                                                                                                                                                                                                                                       |
|------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `data/rest/<feature>_client.dart`        | Client extending `BaseClient`; every call passes `options(token: …)`. All DTOs live at the end of the file, each under a `//---------- {NAME} REQUEST/RESPONSE ----------` header. Requests have `toJson()`, responses a `fromJson()` factory. |
| `data/repo/<feature>_repo.dart`          | Receives the client by constructor, maps DTOs to models with extensions (`extension XResponseMapping on XResponse`), wraps every call in `try/catch` → `throw ExceptionConverter.parse(e)`.                                                    |
| `logic/cubit/`                           | Cubit and its states in the same file.                                                                                                                                                                                                         |
| `logic/model/`                           | Domain models, view models (e.g. `BrowserObjectWrapper`) and form models. No models inside `view/`.                                                                                                                                            |
| `view/`                                  | `<feature>_screen.dart` entry point, sub-screens, `form/` for dialogs/drawers with data entry.                                                                                                                                                 |
| `<feature>.dart` / `<feature>_init.dart` | Barrel, and the init that builds client + repo (+ cubit) and registers them in DI.                                                                                                                                                             |

**Cross-feature dependencies.** Each concept has one owning feature: `buckets` owns everything about
buckets (`BucketModel`, list/create/delete in `BucketClient`/`BucketRepo`/`BucketCubit`, the list
view `BucketsSubScreen` and the create/edit form `BucketForm`); `browser` owns object navigation (
`BrowserCubit`: list/upload/download/preview/delete objects of the selected bucket);
`anonymous_access` owns a bucket's anonymous rules (it takes the bucket name as a string, so it
depends on nothing); `transfers` owns the background transfer queue, uploads and zip downloads (
`TransferCubit`, app-wide in DI: transfers keep going across folders, buckets and sections, 2
uploads and 2 downloads at a time, with progress, cancel and retry; files over 16 MiB go multipart
in 8 MiB parts, one after another, so on web only one part is in memory, and a failed or cancelled
upload is aborted; the browser only calls `upload`/`download`, the rail shows `TransfersIndicator`
above the language selector and it opens `TransfersPanel`; finished downloads are handed to the
browser to save, finished uploads fire `BucketChangedEvent`, at most every 2 s per bucket while more
are pending, and it asks before closing the tab while transfers are running); `access_keys` owns the *Access keys* section (`AccessKeysScreen` at `/keys`: the
root key plus the managed keys, `AccessKeyForm` drawer, `AccessKeySecretDialog`, which shows the
secret once and can't be dismissed until the user confirms it was saved; it reads the buckets
through `BucketCubit`); `bucket_admin` is the
*Buckets* section (`BucketAdminScreen`, list + detail tabs) and composes `buckets`,
`anonymous_access` and `browser` ("Open in browser" uses `BrowserScreen.navigator.openBucket`). A
feature may consume another feature's models, cubits and views, but never its client or repo, and
dependencies go one way only (`browser` → `buckets`/`transfers`, `transfers` → `buckets`,
`access_keys` → `buckets`, `bucket_admin` → everything else, never the reverse). A screen that composes several features
provides their cubits (e.g. `BrowserScreen.navigator.builder` provides `BrowserCubit` and
`BucketCubit`); dialogs opened from it reuse the instance with `BlocProvider.value`.

`FeaturesInit.init()` (`features/features_init.dart`) wires all inits. Add the cubit to
`blocProviders` only if it is needed at the root; screen-scoped cubits are created in the screen's
navigator `builder`. Everything is imported through `package:console/app_exporter.dart`.

**State naming.** States are prefixed with the feature and follow:

- `{F}InitialState`
- `{F}LoadingInProgressState`, `{F}LoadingSuccessState`, `{F}LoadingErrorState` (fetching data)
- `{F}ProcessInProgressState`, `{F}ProcessingOKState`, `{F}ProcessingErrorState` (actions)

The browser pages objects: `BrowserSearchState` keeps the loaded `pages` of the folder (contiguous
from the first, each with its `nextContinuationToken`), the `pageIndex` shown and the `pageSize` (
`BrowserPagination`). `objects` is the current page; search and filters run over all loaded pages (
`loadedObjects`). Dialogs and drawers that act on objects (`ObjectNameDialog`, `MoveObjectsDialog`,
`ObjectDetailsDrawer`) own their cubit (`ObjectActionCubit`, `MoveTargetCubit`,
`ObjectDetailsCubit`) and announce changes with `BucketChangedEvent`, so the browser reloads by
itself.

Views only call cubit methods to run actions; everything a view needs to know comes in the state. A
cubit never exposes public getters for views (e.g. `canGoForward` is a field of
`BrowserSearchState`, filled on every emit, not `cubit.canGoForward`).

Error states carry the `GlobalException` or its `message`; cubits get it via
`ExceptionConverter.parse(e)`, never `e.toString()`. Cubits read the token from `AuthCubit` (
`auth.auth?.accessToken`) and pass it as `token:` to the repo.

**Globals.** The `app` singleton in `main.dart` exposes DI (`app.di.find<T>()`, backed by GetX —
only `adapter/di.dart` may import `get`), `app.navigator`, `app.dialog`, `app.snack`, `app.loading`,
`app.dateFormatter`, `app.storageFormatter`, `app.colors`, `app.dimensions`, `app.assets` and
`app.intl`. Routing is `go_router` in `config/route_config.dart`, and it redirects to login when
`AuthCubit.auth` is null, keeping the location asked for in `/login?from=…`; after logging in the
router itself goes there (only internal paths, otherwise the browser). The session survives
reloads: `AuthRepo` saves only the JWT and its expiry in `FlutterSecureStorage`,
`AuthInit` restores it (`AuthCubit.restore`) before the router is built, and logout deletes it.
The keys typed at login are never stored by the console: the login fields carry `AutofillHints`
inside an `AutofillGroup` (and `TextInput.finishAutofillContext()` on success), so the browser's
password manager offers to save and fill them. Dates follow the app's language because
`MaterialApp.builder` sets `Intl.defaultLocale`. Route names and their query params live in `config/route_names.dart` (
`RouteNames`); every screen navigator's `name` uses them, and a feature opens another feature's
screen through them (e.g. `RouteNames.openBucketSettings(bucket)`), never by importing that screen.

Screens whose state is worth linking keep it in the URL, which is the source of truth: the browser (
`/browser?bucket=&folder=&view_type=`) and the *Buckets* section (`/buckets?bucket=&tab=`).
Selecting something navigates to the new URL (the screen's navigator has a `show(...)` method), and
the screen reacts to its new params in `didUpdateWidget`; it never keeps its own copy of the
selection. A bucket or folder in the URL that doesn't exist shows a not-found page with a way back.

Cross-cubit events go through `GlobalEventBusCommunication` (`onBus<State>`) and
`GlobalEventBus().fire(…)`. The bus only announces changes that other cubits may or may not be
listening to (e.g. `BucketChangedEvent` keeps the browser and the *Buckets* section in sync). Never
use it for navigation or any action a user triggers and expects to happen: if nobody listens,
nothing happens.

**View rules.**

- Each screen exposes a static navigator object (`static final XScreenNavigator navigator`) with
  `name`, `path` and `builder`; routes in `route_config.dart` use it.
- Use the design system (`design_system/`): `CustomAppBar.build(title: …)`, `PrimaryButton.*`,
  `AppFormInput`, `AppTextSearchField`, `ConfirmDialog`, `FormDrawerTemplate`, colors/dimensions
  from `app.*`. Spacing with `.gap()`.
- Shared states: `LoadingPage()`, `ErrorPage(message: …, onRetry: …)`, `NoDataPage(title: …)`.
- All text is mouse-selectable through one `AppSelectionArea` in `MaterialApp.builder` (
  `main.dart`), which covers screens, dialogs and drawers. Don't add `SelectionArea` or
  `SelectableText` in widgets.
- Access cubits with `context.read<T>()` or `app.di.find<T>()`. Keep widgets small.
- Write `BlocListener`/`BlocConsumer` listeners inline in `build` (
  `listener: (context, state) { … }`), never extracted to a separate method such as `_onState`.

**Localization (mandatory).** No user-visible string is hardcoded: every label, hint, tooltip,
dialog text, error message and validation message comes from `app.intl.<key>` (or
`context.intl.<key>` inside a `MaterialApp` builder before the navigator exists, e.g. splash).
Rules:

- Add each key to **both** `lib/l10n/arb/app_en.arb` (template) and `app_es.arb`, use
  placeholders/plurals instead of concatenation, then run `fvm flutter gen-l10n`. `l10n_errors.txt`
  must stay `{}`.
- Delete keys that are no longer referenced. Don't add "section" pseudo-keys.
- `MaterialApp` gets `AppLocalizations.delegate` plus `material_ui`'s
  `GlobalMaterialLocalizations.delegates` (`appLocalizationsDelegates` in `main.dart`, also used by
  the splash), never the
  generated `AppLocalizations.localizationsDelegates`: those register `flutter_localizations`'
  Material strings, which `material_ui` widgets can't see, so any locale but English fails with "No
  MaterialLocalizations found".
- Exempt: brand-neutral technical tokens (`PDF`, `JSON`, units like `KB`), JSON/header keys, file
  names, log/`toString` output.

**Assets.** SVG icons live in `assets/icons/<group>/` and are only reached through getters in
`design_system/assets/app_icons.dart` (`app.assets.icons.actions.delete.build(...)`). Adding an
icon = file + getter + folder in `pubspec.yaml`; when a getter loses its last use, delete the getter
and the file. `assets/app/app_icon.png` is only used by `flutter_launcher_icons`.

**Claude Design.** The console has two Claude Design artifacts, both named "Feather IO Console" (
content in Spanish):

- Design system: https://claude.ai/artifact/1dJk7nhzEP7Y2CcgnTMyuB. Tokens, components and icons
  from `design_system/`.
- Canvas: https://claude.ai/artifact/XJpCx88PuduoWDgbdcBowC. A faithful replica of the current
  screens at 1536×720 (125% Windows scaling), used as the base for the redesign.

In canvas artboards, draw coloured icons as inline `<svg>` with `currentColor`. CSS
`mask-image: url(/_blob/…)` renders blank because the artboard iframe is sandboxed; `<img>` works.

**Other.** `s3_sig_v4_signer.dart` exists in `features/` but the console uses JWT today.

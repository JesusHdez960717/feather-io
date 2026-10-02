# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository. It is the single source of truth for project rules.

## Overview

Monorepo for a lightweight S3-compatible storage system:

- `service/` — Dart backend built on **Winter**, an internal framework at `../winter` (path
  dependency `../../winter` from `service/`, i.e. a sibling of this repo). Read its source there
  when a Winter API is unclear.
- `console/` — Flutter Web admin console. Talks to the service over REST.

The two packages are strictly decoupled: they share nothing but the HTTP contract.

Scope relaxations still in force: focus on core S3 CRUD. Ignore bucket policies, MD5/checksum
validation and advanced multipart edge cases for now.

`ROADMAP.md` lists the pending work in order, as checkboxes. When a change completes a roadmap task,
mark it `[x]` in the same change; add new pending work to the right phase.

## Commands

The project pins Flutter via FVM (`.fvmrc` in both packages, Flutter 3.47.1 / Dart 3.13). Both
packages need Dart SDK ^3.13.0. The system `dart` on PATH may be older, so prefix commands with
`fvm` (`fvm dart …`, `fvm flutter …`).

### Service (run from `service/`)

The SQLite path is relative to the working directory (`./uploads_local/feather-io.sqlite`), so
always run from `service/`.

```bash
fvm dart pub get
fvm dart run build_runner build          # only for Drift (lib/features/db/database.g.dart)
fvm dart analyze
fvm dart test                            # all tests
fvm dart test test/put_object_test.dart  # one file
fvm dart test test/put_object_test.dart --plain-name "Should upload successfully in root"
```

Run the server (port 8080) with the env from `.vscode/launch.json`:

```bash
FEATHER_ACCESS=access FEATHER_SECRET=secret JWT_SECRET=some-jwt-secret \
STORAGE_VOLUME_PATH=./uploads_local ADMIN_PREFIX=_admin fvm dart run lib/main.dart
```

Required env: `FEATHER_ACCESS`, `FEATHER_SECRET`, `JWT_SECRET`, `STORAGE_VOLUME_PATH`. Optional:
`ADMIN_PREFIX` (default `_admin`), `RESERVED_BUCKET_NAMES` and `MAX_OBJECT_SIZE` (bytes, default 5
GiB). See `service/README.md` (in Spanish; its endpoint table lists only some routes, so treat the
controllers as the source of truth).

The SQLite path is hardcoded in `database.dart` and does **not** follow `STORAGE_VOLUME_PATH`.

`service/Dockerfile` builds from `dart:3.12.2`, which is older than the `^3.13.0` SDK constraint. It
also runs on a `scratch` image that has no `libsqlite3`.

### Console (run from `console/`)

```bash
fvm flutter pub get
fvm flutter gen-l10n                                            # after editing lib/l10n/arb/*.arb
fvm flutter run -d chrome --web-port=8081
fvm flutter analyze
```

- Runtime config comes from `web/env.js` (`window.env`: `SERVICE_URL`, `ADMIN_PREFIX`), which is
  gitignored. `ADMIN_PREFIX` must match the service.
- The console has no test directory.
- On web, Dio sets the XHR timeout to `connectTimeout + receiveTimeout` (20 s) for the **whole**
  request, upload included. Requests that can take longer (uploads, downloads) pass
  `connectTimeout`/`receiveTimeout` = `Duration.zero` (no limit) and rely on a `CancelToken`.
- On web, Dio reports 401/403 as `connectionError` rather than `badResponse`.
  `ApiExceptionConverter` therefore maps web connection errors to `GlobalExceptionType.auth`.

## HTTP contract (both sides)

- JSON keys are `snake_case`; Dart properties are `camelCase` (e.g. `size_bytes` ↔ `sizeBytes`,
  `access_token` ↔ `accessToken`).
- Auth is JWT (`Authorization: Bearer …`) for the console and AWS SigV4 for native S3 clients. The
  old `x-feather-access`/`x-feather-secret` header auth no longer exists.
- When a field is renamed, change the service model's `toJson`/`fromJson` **and** the console DTO in
  the same change.

## Service architecture

**Bootstrap.** `FeatherIO.start()` in `lib/main.dart` registers deserializers on the ObjectMapper (
`om`), puts `AppDatabase`, `FileManagementService` and `JwtService` into Winter's `di`, then builds
`S3Controller` and `AdminController` and passes their `.routing` to `Winter.start`.
`lib/feather.dart` is the barrel file that re-exports Winter and every feature. Source files import
`package:service/feather.dart`, never `package:winter/winter.dart` or individual files. Each folder
has a barrel (`admin.dart`, `anonymous_access.dart`, `file_core.dart`, …) that must export every new
file.

**Two APIs share one router.**

- S3 API is mounted at `/`, with path-style `/{bucket}/{key|.*}`.
- Admin API is mounted at `/{ADMIN_PREFIX}` and always returns JSON.
- Admin paths start with `_` so they cannot collide with valid bucket names. `S3BucketNameFilter`
  validates bucket names on both parents. `ReservedBucketFilter` blocks `RESERVED_BUCKET_NAMES` plus
  the admin prefix, and is attached per route rather than to the parent.
- Filters on a parent route are inherited by its children. To stop a parent's `AuthFilter` from
  applying to child routes, gate it with
  `shouldFilter: (r) => r.routingContext?.key == '<own key>'`, as `s3.list-objects` does.

**Auth and authorization.**

- The global filter is `JwtFilter`. It populates the `securityContext` from a `Bearer` token issued
  by `POST /{admin}/login`. That endpoint checks `FEATHER_ACCESS`/`FEATHER_SECRET` and issues a
  token with a fixed permission list.
- `S3SigV4Filter` handles native S3 clients and is registered only on the S3 parent route, so the
  admin API accepts JWT only. `JwtFilter` is registered globally and again on both parents.
  `JwtFilter` and `S3SigV4Filter` both skip themselves (`shouldFilter`) once the request is
  authenticated. `S3SigV4Filter` accepts the signature in the `Authorization` header or in the
  query (presigned URL: `X-Amz-Signature`, `X-Amz-Date`, `X-Amz-Expires` up to 7 days), and passes
  through requests with neither, so an unauthenticated request gets a 401 from the route's
  `AuthFilter`. The `Authorization` fields may be separated by `,` with or without a space (s3cmd
  sends none). The SigV4 maths live in `security/logic/sig_v4_signer.dart` (`SigV4Signer`), shared
  with `PresignService`, which signs `GET` URLs with the service keys for
  `POST /{admin}/bucket/{bucket}/presign` (the console has no secret key, so it asks the service).
  The URL uses the scheme and `Host` of that request, because the host is part of the signature.
- Each route declares its own permission with
  `AuthFilter(rules: hasPermission('s3.put-object') | hasPermission('s3.anonymous.put-object'))`.
  Route keys and permission names match (`s3.*`, `admin.*`).
- New endpoints need the route key, an `AuthFilter`, **and** the permission added to the list in
  `admin/auth/rest/auth_controller.dart` (and to `S3SigV4Filter` if native S3 clients should reach
  it).
- `AnonymousAccessFilter` runs on the S3 parent after the SigV4 filter, only for unauthenticated
  requests. It looks up the bucket's prefix rules (`anonymous_rule` table, via
  `AnonymousAccessService.findMatchingRule`) and grants the `s3.anonymous.*` permissions of the
  first matching rule. `*` in a rule is a wildcard; everything else matches literally. It covers
  list/get/put/delete object; multi-delete is never anonymous, because its keys come in the body.
  Deleting a bucket deletes its rules.

**Folder layout.** Every feature (or sub-feature) under `lib/features/` uses the same folders:

| Folder           | Layer      | Contents                                                            |
|------------------|------------|---------------------------------------------------------------------|
| `rest/`          | Controller | Routes, filters, request parsing, content negotiation, XML mapping. |
| `filter/`        | Controller | Winter `Filter`s specific to the feature.                           |
| `logic/model/`   | Model      | Typed models and request/response classes.                          |
| `logic/service/` | Service    | Business logic, validation, file I/O.                               |
| `repo/`          | Repository | Drift table access only.                                            |

Current features: `s3/api/{rest,filter}` + `s3/file_core/{logic,repo}`, `admin/rest`,
`admin/auth/{rest,logic}`, `admin/anonymous_access/{rest,logic,repo}`, plus `db/` (Drift) and
`security/filter/` (JWT, SigV4).

**Layer rules.**

- Controller is the **only** layer that touches HTTP formats: `package:xml`, `Content-Type`,
  `Accept`, `toJson` output. Use Winter abstractions (`RequestEntity`, `ResponseEntity`, `Route`,
  `ObjectMapper`); never use `shelf` directly.
- Services and repos return typed models (`BucketModel`, `ListObjectsResponse`…), `File`s or
  `Stream<List<int>>`. They never import `package:xml`, build raw JSON maps for responses, or
  inspect headers.
- Repos never know about `Content-Type` or HTTP.
- Avoid `dynamic`; use `Map<String, dynamic>` only for raw JSON input, otherwise strict models.
- Don't add dependencies for things Dart core or Winter already cover.

**Models / serialization.** JSON is hand-written: implement `Serializable` (from Winter) with
`toJson()`. Request models have a `fromJson` factory **and** a matching `om.addDeserializer` in
`main.dart`, then are read with `request.body<T>()`. Request models that need validation implement
`Validatable` and the controller calls `.validate().throwOnFailure()`. No `build_runner` except
Drift.

**Content negotiation (S3 only).** Controllers call `_acceptsJson(request)` (checks `Accept` for
`application/json`):

```dart
if (_acceptsJson(request)) {
return ResponseEntity.ok(body: model); // Winter serializes Serializable to JSON
}
return ResponseEntity.ok(
body: _mapModelToXml(model), // private helper in the controller
headers: {'content-type': 'application/xml'},
);
```

XML is S3-compliant and the default. The console always asks for JSON. `multiDelete` reads the S3
`<Delete>` XML or, with a JSON `Content-Type` or body, the console's JSON (at most 1000 keys), and
answers `<DeleteResult>` or JSON. XML bodies are parsed with the controller's `_xmlTag`/`_xmlTags`
(regex, no XML package) and `_unescapeXml`. ListBuckets includes a fixed `<Owner>` (`feather-io`),
which some clients require. CreateBucket and PutObject answer like S3, with no body: CreateBucket with a `Location`
header, PutObject with its `ETag`. GetBucketLocation (`GET /{bucket}?location`, served by the
list-objects route) always answers an empty XML `LocationConstraint` (`us-east-1`). XML dates are
UTC with milliseconds (`_s3Date`: `2026-10-02T14:22:35.000Z`) and every key, prefix and description
goes through `_escapeXml`.

`UnsupportedSubresourceFilter` (S3 parent) answers `501 NotImplemented` to the subresources the
service does not implement (`?versioning`, `?policy`, `?tagging`, `?acl`, `?legal-hold`…, plus
`GET ?uploads`/`?uploadId`, i.e. ListMultipartUploads and ListParts). Without it they would fall into
the normal routes (`PUT /{bucket}?versioning` would create the bucket). A newly implemented
subresource must be removed from its list.

**Errors.**

- S3 errors (from services and S3 filters) throw
  `S3Exception(S3ErrorCode.x, message: …, resource: …)` (`s3/file_core/logic/s3_exception.dart`), or
  one of its named constructors (`invalidBucketName`, `invalidKey`, `noSuchBucket`, `noSuchKey`).
  Each `S3ErrorCode` carries the AWS code and its HTTP status; add new codes there.
- `S3ExceptionHandler` (registered in `main.dart` with `Winter.context.setUp`) renders them as the
  S3 `<Error>` XML by default, or as JSON `{code, message, resource}` when the client accepts JSON
  or the path is under the admin prefix. Winter sends JSON error bodies as
  `application/problem+json`.
- Other errors (login, admin request parsing) still throw Winter `ApiException` subclasses with
  plain-string bodies. Messages are currently a mix of Spanish and English.
- A controller that wraps a block in `try/catch` must `if (e is ApiException) rethrow;` before
  converting unknown errors.

**Storage & performance.** Buckets are directories under `STORAGE_VOLUME_PATH`. Bucket metadata (
description, color, timestamps), anonymous rules and object ETags live in SQLite via Drift. The
schema has no migrations while in development: when it changes, delete the SQLite file and let it be
recreated. PutObject, CopyObject and CreateMultipartUpload need an existing bucket (`NoSuchBucket`
otherwise); only the subfolders of the key are created on the fly. Object payloads must
always flow as `Stream<List<int>>` (`request.read()`, `file.openRead()`): **never** `readAsBytes()`
or `Uint8List` for object data. Multi-object downloads build the zip in a temp file (
`FileManagementService.zipObjects`) and stream it with `openAndDeleteTemp`. Winter's
`ServerConfig.maxBodySize` (10 MB by default) is set to `MAX_OBJECT_SIZE`, and `BodySizeFilter` (
global) narrows it by route from the `Content-Length`: `s3.put-object` over `MAX_OBJECT_SIZE` →
`EntityTooLarge`; every other body (read into memory) is capped at 2 MB (413). A `POST`/`PUT`/
`PATCH` without `Content-Length` (empty, as aws-sdk-java-v2's CreateBucket, or chunked: shelf drops
`Transfer-Encoding`, so they look the same) gets its body wrapped in Winter's `limitBodySize`, which
fails with 413 while reading. Every bucket name goes through
`S3Validator.isValidBucketName` and every key through `S3Validator.isValidKey` (path traversal
protection) before touching the filesystem.

**Folders and listing.** A key ending in `/` is a folder: `PUT /{bucket}/fotos/` creates the
directory with a hidden `S3Validator.folderMarker` file (`.feather-folder`), so empty folders
survive the cleanup of empty parents. Listings show the marker as the key `fotos/` (size 0), stats
and zips skip it, no key may use that name, and a bucket holding only empty folders counts as empty.
Winter drops the trailing `/` from the `{key}` path param; `S3Controller._objectKey` restores it
from the URL. `listFiles` sorts objects and common prefixes together and pages over them like
ListObjectsV2 (`max-keys` up to 1000, `continuation-token` = base64url of the last key returned).
`PUT` with `x-amz-copy-source` is CopyObject and needs the plain `s3.get-object` permission, so an
anonymous rule can never copy. `HEAD` object is served by the `GET` route (Winter sends the headers
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
back. Without a stored `Content-Type` it comes from the extension. Uploads compute the md5 while streaming (`Md5Tap`, also used by UploadPart), copies
reuse the source's ETag and multipart stores `md5(part md5s)-N`. On read (GET/HEAD, listings), a
missing row or one whose size/mtime no longer match (the file changed outside the service) gets its
ETag recomputed by reading the file and saved, keeping its headers; listings only compute it for the objects of the returned
page. Deleting an object, a folder or a bucket, or emptying a bucket, deletes its rows.

**Multipart upload.** `MultipartService` implements CreateMultipartUpload (
`POST /{bucket}/{key}?uploads`, route `s3.post-object`), UploadPart (`PUT ?partNumber=&uploadId=`,
on `s3.put-object`, `ETag` header = md5 of the part), CompleteMultipartUpload (`POST ?uploadId=`, S3
XML or JSON `{"parts": [{"part_number", "etag"}]}`) and AbortMultipartUpload (`DELETE ?uploadId=`).
All need `s3.put-object` (no anonymous multipart). Pending uploads live in
`STORAGE_VOLUME_PATH/.multipart/<uploadId>/` (`upload.json` + `<n>.part`/`<n>.etag`); a dot folder
is not a valid bucket, so it isn't listed. Complete checks ascending order, ETags and the 5 MiB
minimum of every part but the last, joins the parts inside the upload folder and moves the result,
so the object never shows half-written; the final ETag is S3's `md5(part md5s)-N`. Deleting a bucket
aborts its uploads. The upload id is validated as 32 hex chars before it touches a path. ListParts
and ListMultipartUploads are not implemented. CORS exposes `ETag` so the console can read it.

**Tests.** Rules for new tests:

- Every new feature gets tests. `s3_controller_test.dart` holds the happy path (upload → list →
  get → delete); each endpoint gets its own file (`put_object_test.dart`,
  `list_buckets_test.dart`…).
- Use `TestServer` (`test/support/test_server.dart`): `TestServer(port: …, name: …)`, then
  `setUpAll(server.start)` / `tearDownAll(server.stop)`. It sets the env, starts the real server
  with an in-memory SQLite (`FeatherIO.start(database: …)`), logs in to get `server.token`, and
  creates and deletes `./uploads_test/<name>` (gitignored). Helpers: `server.url(path)`,
  `server.auth(json: …)`, `server.createBucket(…)` (tolerates an existing one),
  `server.putObject(…, headers: …)` (creates the bucket first and sends bytes without
  `Content-Type`, so reads fall back to the extension) and `server.sigV4(method, path, query: …)`, the
  headers of a native client signed with SigV4. Uploading with `http.put` needs the bucket created.
- Use one distinct port per file so files run in parallel. Ports in use: 8082–8104.
- Cover auth (missing or invalid token → 401, wrong login credentials → 403), validation (bad bucket
  names, path traversal, forbidden chars → 400), content negotiation (JSON vs XML, including the S3
  error code) and edge cases (404, empty lists).
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
are pending, and it asks before closing the tab while transfers are running); `bucket_admin` is the
*Buckets* section (`BucketAdminScreen`, list + detail tabs) and composes `buckets`,
`anonymous_access` and `browser` ("Open in browser" uses `BrowserScreen.navigator.openBucket`). A
feature may consume another feature's models, cubits and views, but never its client or repo, and
dependencies go one way only (`browser` → `buckets`/`transfers`, `transfers` → `buckets`,
`bucket_admin` → everything else, never the reverse). A screen that composes several features
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
`AuthCubit.auth` is null. Route names and their query params live in `config/route_names.dart` (
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
  `GlobalMaterialLocalizations.delegates` (`_localizationsDelegates` in `main.dart`), never the
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

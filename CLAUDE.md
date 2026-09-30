# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository. It is the single source of truth for project rules.

## Overview

Monorepo for a lightweight S3-compatible storage system:

- `service/` — Dart backend built on **Winter**, an internal framework at `../winter` (path dependency `../../winter` from `service/`, i.e. a sibling of this repo). Read its source there when a Winter API is unclear.
- `console/` — Flutter Web admin console. Talks to the service over REST.

The two packages are strictly decoupled: they share nothing but the HTTP contract.

Scope relaxations still in force: focus on core S3 CRUD. Ignore bucket policies, MD5/checksum validation and advanced multipart edge cases for now.

`ROADMAP.md` lists the pending work in order, as checkboxes. When a change completes a roadmap task, mark it `[x]` in the same change; add new pending work to the right phase.

## Commands

The project pins Flutter via FVM (`.fvmrc` in both packages, Flutter 3.47.1 / Dart 3.13). Both packages need Dart SDK ^3.13.0. The system `dart` on PATH may be older, so prefix commands with `fvm` (`fvm dart …`, `fvm flutter …`).

### Service (run from `service/`)

The SQLite path is relative to the working directory (`./uploads_local/feather-io.sqlite`), so always run from `service/`.

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

Required env: `FEATHER_ACCESS`, `FEATHER_SECRET`, `JWT_SECRET`, `STORAGE_VOLUME_PATH`. Optional: `ADMIN_PREFIX` (default `_admin`) and `RESERVED_BUCKET_NAMES`. See `service/README.md` (in Spanish; its endpoint table lists only some routes, so treat the controllers as the source of truth).

The SQLite path is hardcoded in `database.dart` and does **not** follow `STORAGE_VOLUME_PATH`.

`service/Dockerfile` builds from `dart:3.12.2`, which is older than the `^3.13.0` SDK constraint. It also runs on a `scratch` image that has no `libsqlite3`.

### Console (run from `console/`)

```bash
fvm flutter pub get
fvm flutter gen-l10n                                            # after editing lib/l10n/arb/*.arb
fvm flutter run -d chrome --web-port=8081
fvm flutter analyze
```

- Runtime config comes from `web/env.js` (`window.env`: `SERVICE_URL`, `ADMIN_PREFIX`), which is gitignored. `ADMIN_PREFIX` must match the service.
- The console has no test directory.
- On web, Dio reports 401/403 as `connectionError` rather than `badResponse`. `ApiExceptionConverter` therefore maps web connection errors to `GlobalExceptionType.auth`.

## HTTP contract (both sides)

- JSON keys are `snake_case`; Dart properties are `camelCase` (e.g. `size_bytes` ↔ `sizeBytes`, `access_token` ↔ `accessToken`).
- Auth is JWT (`Authorization: Bearer …`) for the console and AWS SigV4 for native S3 clients. The old `x-feather-access`/`x-feather-secret` header auth no longer exists.
- When a field is renamed, change the service model's `toJson`/`fromJson` **and** the console DTO in the same change.

## Service architecture

**Bootstrap.** `FeatherIO.start()` in `lib/main.dart` registers deserializers on the ObjectMapper (`om`), puts `AppDatabase`, `FileManagementService` and `JwtService` into Winter's `di`, then builds `S3Controller` and `AdminController` and passes their `.routing` to `Winter.start`. `lib/feather.dart` is the barrel file that re-exports Winter and every feature. Source files import `package:service/feather.dart`, never `package:winter/winter.dart` or individual files. Each folder has a barrel (`admin.dart`, `anonymous_access.dart`, `file_core.dart`, …) that must export every new file.

**Two APIs share one router.**
- S3 API is mounted at `/`, with path-style `/{bucket}/{key|.*}`.
- Admin API is mounted at `/{ADMIN_PREFIX}` and always returns JSON.
- Admin paths start with `_` so they cannot collide with valid bucket names. `S3BucketNameFilter` validates bucket names on both parents. `ReservedBucketFilter` blocks `RESERVED_BUCKET_NAMES` plus the admin prefix, and is attached per route rather than to the parent.
- Filters on a parent route are inherited by its children. To stop a parent's `AuthFilter` from applying to child routes, gate it with `shouldFilter: (r) => r.routingContext?.key == '<own key>'`, as `s3.list-objects` does.

**Auth and authorization.**
- The global filter is `JwtFilter`. It populates the `securityContext` from a `Bearer` token issued by `POST /{admin}/login`. That endpoint checks `FEATHER_ACCESS`/`FEATHER_SECRET` and issues a token with a fixed permission list.
- `S3SigV4Filter` handles native S3 clients and is registered only on the S3 parent route, so the admin API accepts JWT only. `JwtFilter` is registered globally and again on both parents. `JwtFilter` and `S3SigV4Filter` both skip themselves (`shouldFilter`) once the request is authenticated.
- Each route declares its own permission with `AuthFilter(rules: hasPermission('s3.put-object') | hasPermission('s3.anonymous.put-object'))`. Route keys and permission names match (`s3.*`, `admin.*`).
- New endpoints need the route key, an `AuthFilter`, **and** the permission added to the list in `admin/auth/rest/auth_controller.dart` (and to `S3SigV4Filter` if native S3 clients should reach it).
- `AnonymousAccessFilter` maps per-bucket prefix rules (stored in the `anonymous_rule` table) to `s3.anonymous.*` permissions. It is defined but not yet registered on any route.

**Folder layout.** Every feature (or sub-feature) under `lib/features/` uses the same folders:

| Folder | Layer | Contents |
| --- | --- | --- |
| `rest/` | Controller | Routes, filters, request parsing, content negotiation, XML mapping. |
| `filter/` | Controller | Winter `Filter`s specific to the feature. |
| `logic/model/` | Model | Typed models and request/response classes. |
| `logic/service/` | Service | Business logic, validation, file I/O. |
| `repo/` | Repository | Drift table access only. |

Current features: `s3/api/{rest,filter}` + `s3/file_core/{logic,repo}`, `admin/rest`, `admin/auth/{rest,logic}`, `admin/anonymous_access/{rest,logic,repo}`, plus `db/` (Drift) and `security/filter/` (JWT, SigV4).

**Layer rules.**
- Controller is the **only** layer that touches HTTP formats: `package:xml`, `Content-Type`, `Accept`, `toJson` output. Use Winter abstractions (`RequestEntity`, `ResponseEntity`, `Route`, `ObjectMapper`); never use `shelf` directly.
- Services and repos return typed models (`BucketModel`, `ListObjectsResponse`…), `File`s or `Stream<List<int>>`. They never import `package:xml`, build raw JSON maps for responses, or inspect headers.
- Repos never know about `Content-Type` or HTTP.
- Avoid `dynamic`; use `Map<String, dynamic>` only for raw JSON input, otherwise strict models.
- Don't add dependencies for things Dart core or Winter already cover.

**Models / serialization.** JSON is hand-written: implement `Serializable` (from Winter) with `toJson()`. Request models have a `fromJson` factory **and** a matching `om.addDeserializer` in `main.dart`, then are read with `request.body<T>()`. Request models that need validation implement `Validatable` and the controller calls `.validate().throwOnFailure()`. No `build_runner` except Drift.

**Content negotiation (S3 only).** Controllers call `_acceptsJson(request)` (checks `Accept` for `application/json`):

```dart
if (_acceptsJson(request)) {
  return ResponseEntity.ok(body: model);            // Winter serializes Serializable to JSON
}
return ResponseEntity.ok(
  body: _mapModelToXml(model),                      // private helper in the controller
  headers: {'content-type': 'application/xml'},
);
```

XML is S3-compliant and the default. The console always asks for JSON. `multiDelete` and the create/put endpoints still answer JSON/plain text only.

**Errors.** Services throw Winter `ApiException` subclasses (`BadRequestException`, `NotFoundException`, `ConflictException`, `ForbiddenException`). A controller that wraps a block in `try/catch` must `if (e is ApiException) rethrow;` before converting unknown errors to `BadRequestException`. The target design is an `S3Exception` mapped to AWS error codes (`NoSuchBucket`, `BucketNotEmpty`, `EntityTooLarge`…) that also respects content negotiation; it does not exist yet, and error bodies are plain strings (currently a mix of Spanish and English).

**Storage & performance.** Buckets are directories under `STORAGE_VOLUME_PATH`. Bucket metadata (description, color, timestamps) and anonymous rules live in SQLite via Drift. Object payloads must always flow as `Stream<List<int>>` (`request.read()`, `file.openRead()`): **never** `readAsBytes()` or `Uint8List` for object data. Multi-object downloads build the zip in a temp file (`FileManagementService.zipObjects`) and stream it with `openAndDeleteTemp`. Every bucket name goes through `S3Validator.isValidBucketName` and every key through `S3Validator.isValidKey` (path traversal protection) before touching the filesystem.

**Tests.** Rules for new tests:
- Every new feature gets tests. `s3_controller_test.dart` holds the happy path (upload → list → get → delete); each endpoint gets its own file (`put_object_test.dart`, `list_buckets_test.dart`…).
- Tests start the real server with `FeatherIO.start(port: …)`, one distinct port per file so files run in parallel.
- Each file uses its own storage folder under `./uploads_test/<name>` (gitignored) and deletes it in `setUpAll` and `tearDownAll`.
- Cover auth (missing token → 401, wrong credentials → 403), validation (bad bucket names, path traversal, forbidden chars → 400), content negotiation (JSON vs XML) and edge cases (404, empty lists).

The existing `service/test/*` files are **stale**: they still use the old header auth and a `STORAGE_PATH` env key, and do not set `JWT_SECRET`/`STORAGE_VOLUME_PATH`. Expect failures until they are migrated to JWT.

## Console architecture

**Feature layout.** Each feature is self-contained in `lib/features/<name>/`:

| Path | Contents |
| --- | --- |
| `data/rest/<feature>_client.dart` | Client extending `BaseClient`; every call passes `options(token: …)`. All DTOs live at the end of the file, each under a `//---------- {NAME} REQUEST/RESPONSE ----------` header. Requests have `toJson()`, responses a `fromJson()` factory. |
| `data/repo/<feature>_repo.dart` | Receives the client by constructor, maps DTOs to models with extensions (`extension XResponseMapping on XResponse`), wraps every call in `try/catch` → `throw ExceptionConverter.parse(e)`. |
| `logic/cubit/` | Cubit and its states in the same file. |
| `logic/model/` | Domain models, view models (e.g. `BrowserObjectWrapper`) and form models. No models inside `view/`. |
| `view/` | `<feature>_screen.dart` entry point, sub-screens, `form/` for dialogs/drawers with data entry. |
| `<feature>.dart` / `<feature>_init.dart` | Barrel, and the init that builds client + repo (+ cubit) and registers them in DI. |

**Cross-feature dependencies.** Each concept has one owning feature: `buckets` owns everything about buckets (`BucketModel`, list/create/delete in `BucketClient`/`BucketRepo`/`BucketCubit`, the list view `BucketsSubScreen` and the create form); `browser` owns object navigation (`BrowserCubit`: list/upload/download/preview/delete objects of the selected bucket). A feature may consume another feature's models, cubits and views, but never its client or repo, and dependencies go one way only (`browser` → `buckets`, never the reverse). A screen that composes several features provides their cubits (e.g. `BrowserScreen.navigator.builder` provides `BrowserCubit` and `BucketCubit`); dialogs opened from it reuse the instance with `BlocProvider.value`.

`FeaturesInit.init()` (`features/features_init.dart`) wires all inits. Add the cubit to `blocProviders` only if it is needed at the root; screen-scoped cubits are created in the screen's navigator `builder`. Everything is imported through `package:console/app_exporter.dart`.

**State naming.** States are prefixed with the feature and follow:
- `{F}InitialState`
- `{F}LoadingInProgressState`, `{F}LoadingSuccessState`, `{F}LoadingErrorState` (fetching data)
- `{F}ProcessInProgressState`, `{F}ProcessingOKState`, `{F}ProcessingErrorState` (actions)

Error states carry the `GlobalException` or its `message`; cubits get it via `ExceptionConverter.parse(e)`, never `e.toString()`. Cubits read the token from `AuthCubit` (`auth.auth?.accessToken`) and pass it as `token:` to the repo.

**Globals.** The `app` singleton in `main.dart` exposes DI (`app.di.find<T>()`, backed by GetX — only `adapter/di.dart` may import `get`), `app.navigator`, `app.dialog`, `app.snack`, `app.loading`, `app.dateFormatter`, `app.storageFormatter`, `app.colors`, `app.dimensions`, `app.assets` and `app.intl`. Routing is `go_router` in `config/route_config.dart`, and it redirects to login when `AuthCubit.auth` is null. Cross-cubit events go through `GlobalEventBusCommunication` (`onBus<State>`).

**View rules.**
- Each screen exposes a static navigator object (`static final XScreenNavigator navigator`) with `name`, `path` and `builder`; routes in `route_config.dart` use it.
- Use the design system (`design_system/`): `CustomAppBar.build(title: …)`, `PrimaryButton.*`, `AppFormInput`, `AppTextSearchField`, `ConfirmDialog`, `FormDrawerTemplate`, colors/dimensions from `app.*`. Spacing with `.gap()`.
- Shared states: `LoadingPage()`, `ErrorPage(message: …, onRetry: …)`, `NoDataPage(title: …)`.
- Access cubits with `context.read<T>()` or `app.di.find<T>()`. Keep widgets small.
- Write `BlocListener`/`BlocConsumer` listeners inline in `build` (`listener: (context, state) { … }`), never extracted to a separate method such as `_onState`.

**Localization (mandatory).** No user-visible string is hardcoded: every label, hint, tooltip, dialog text, error message and validation message comes from `app.intl.<key>` (or `context.intl.<key>` inside a `MaterialApp` builder before the navigator exists, e.g. splash). Rules:
- Add each key to **both** `lib/l10n/arb/app_en.arb` (template) and `app_es.arb`, use placeholders/plurals instead of concatenation, then run `fvm flutter gen-l10n`. `l10n_errors.txt` must stay `{}`.
- Delete keys that are no longer referenced. Don't add "section" pseudo-keys.
- Exempt: brand-neutral technical tokens (`PDF`, `JSON`, units like `KB`), JSON/header keys, file names, log/`toString` output.

**Assets.** SVG icons live in `assets/icons/<group>/` and are only reached through getters in `design_system/assets/app_icons.dart` (`app.assets.icons.actions.delete.build(...)`). Adding an icon = file + getter + folder in `pubspec.yaml`; when a getter loses its last use, delete the getter and the file. `assets/app/app_icon.png` is only used by `flutter_launcher_icons`.

**Claude Design.** The console has two Claude Design artifacts, both named "Feather IO Console" (content in Spanish):
- Design system: https://claude.ai/artifact/1dJk7nhzEP7Y2CcgnTMyuB. Tokens, components and icons from `design_system/`.
- Canvas: https://claude.ai/artifact/XJpCx88PuduoWDgbdcBowC. A faithful replica of the current screens at 1536×720 (125% Windows scaling), used as the base for the redesign.

In canvas artboards, draw coloured icons as inline `<svg>` with `currentColor`. CSS `mask-image: url(/_blob/…)` renders blank because the artboard iframe is sandboxed; `<img>` works.

**Other.** `s3_sig_v4_signer.dart` exists in `features/` but the console uses JWT today.

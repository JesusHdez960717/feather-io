# Contributing

Thanks for helping. This is a monorepo with two packages that share nothing but the HTTP contract:
`service/` (Dart, on Winter) and `console/` (Flutter Web).

## Setup

Both packages pin their Flutter (and Dart) version with [FVM](https://fvm.app) in `.fvmrc`; the
`dart` on your PATH may be older, so prefix every command with `fvm`.

```bash
dart pub global activate fvm
cd service && fvm install && fvm dart pub get
cd ../console && fvm install && fvm flutter pub get
```

How to run each one locally is in the [README](README.md#locally). Docker Desktop (or Docker on
Linux) is needed for the S3 client tests and the images.

## How the code is organized

[`CLAUDE.md`](CLAUDE.md) is the single source of truth for the project rules: the architecture of
both packages, their layers and folders, naming, errors, logging, i18n and tests. Read the part of
the package you touch before changing it. The most important ones:

- **Service**: a feature is `controller/` → `logic/service/` → `repo/`; only controllers know about
  HTTP (`Content-Type`, `Accept`, XML vs JSON). Object data always flows as a stream, never in
  memory. Every bucket name and key is validated before it touches the filesystem. Errors are
  `S3Exception`s with an S3 code; their messages are translated (`lib/i18n/*.i18n.yaml`, both
  languages).
- **Console**: a feature is `data/rest` → `data/repo` → `logic/cubit` → `view`; views only call
  cubit methods. No user-visible text is hardcoded (`lib/l10n/arb/app_en.arb` and `app_es.arb`).
- **Both**: JSON keys are `snake_case`. A field renamed in the service changes the console's DTO in
  the same change.
- Don't add a dependency for something Dart, Flutter or Winter already does.
- A non-obvious decision goes into [`DECISIONS.md`](DECISIONS.md), and a finished roadmap task is
  marked in [`ROADMAP.md`](ROADMAP.md), in the same change.

## Tests

Every change comes with its tests (`service/test/` mirrors `service/lib/`; each test file uses its
own port, see *Tests* in `CLAUDE.md`).

| When                                                                | Run                                                                                                        | Time   |
|---------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|--------|
| Every change                                                        | `fvm dart analyze && fvm dart test` in `service/`, `fvm flutter analyze && fvm flutter test` in `console/` | ~1 min |
| Touching the S3 API (controller, filters, signatures, XML, headers) | also `service/tool/s3_compat/run.sh` against a running service (AWS CLI and rclone in Docker)              | ~2 min |
| Big protocol changes, or before a release                           | also `run.sh mint` (15 suites of SDKs and tools)                                                           | ~5 min |

`dart test` checks responses against our reading of the S3 spec; real clients parse the XML
strictly and sign in their own way, and almost every incompatibility so far was found by them. Look
at the service log too: clients retry, so a 500 may only show up there.

CI (`.github/workflows/ci.yml`) runs the analysis, the tests of both packages, the AWS CLI and
rclone batteries against the Docker image and the console image on `main`, `develop` and every
pull request into them.

## Visual changes

The design of the console lives in its Claude Design canvas, exported to
[`docs/design/`](docs/design/README.md) and described screen by screen in
[`docs/console.md`](docs/console.md). A change to what the console looks like updates the canvas
in the same change, and before every release the export is regenerated and `docs/console.md`
reviewed (how: [`docs/design/README.md`](docs/design/README.md)).

## Branches, commits and pull requests

- Work in a branch and open the pull request against `develop`; `main` gets the releases.
- Commit messages start with the areas they touch, in brackets, then what the change does:

  ```
  [service] Health check at /{admin}/health (database and volume)
  [console][ci][docs] Console Docker image and docker compose for the whole project
  ```

  Areas: `service`, `console`, `ci`, `docs`.
- Keep a pull request to one subject, and say in it how you tested it.

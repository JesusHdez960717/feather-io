# Feather IO

A lightweight, self-hosted storage server compatible with Amazon S3, with a web console to manage
it. One small process (a 24 MB Docker image, ~12 MiB of memory at start) that keeps buckets as
folders on a disk and their metadata in SQLite, next to them.

Point the AWS CLI, rclone, s3cmd, mc or any AWS/MinIO SDK at it and they work as against S3; use
the console to browse, upload and share files, manage buckets, open prefixes to anonymous access
and create access keys per bucket.

![The object browser of the console](docs/screenshots/browser.png)

- **`service/`**: the S3-compatible server, in Dart, on [Winter](https://pub.dev/packages/winter).
  It serves the S3 API and an admin API for the console (JSON, documented with OpenAPI).
- **`console/`**: the web console, in Flutter Web. It only talks to the service over HTTP.

> **Status: release candidate (`1.0.0-rc.1`).** Everything below works and is tested against real
> S3 clients, but it hasn't had long-running production use yet.

## What it supports

|                |                                                                                                                                                                                                                                                             |
|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Buckets**    | Create, list, delete, empty; description and color for the console; statistics                                                                                                                                                                              |
| **Objects**    | Upload (streamed to disk, up to `MAX_OBJECT_SIZE`, 5 GiB by default), download with `Range`, `HEAD`, copy (with `x-amz-copy-source-if-*`), delete one or up to 1000, folders, stored headers (`Content-Type`, `Cache-Control`, `x-amz-meta-*`…), real ETags |
| **Listings**   | ListObjects V1 and V2, prefix and delimiter, paging, `encoding-type=url`                                                                                                                                                                                    |
| **Multipart**  | Create, upload parts (also by copy), complete, abort, list parts and uploads                                                                                                                                                                                |
| **Signatures** | AWS SigV4 in the header or in the query (presigned URLs up to 7 days), `aws-chunked` bodies, clock skew and body sha256 checks                                                                                                                              |
| **Access**     | The root key, managed access keys (read, write or both, per bucket or on every bucket, with expiry), anonymous access per prefix or pattern                                                                                                                 |
| **Console**    | Object browser (list and grid, previews, drag & drop, a background transfer queue), buckets, anonymous rules, access keys, share links; English and Spanish                                                                                                 |
| **Operations** | Health check, structured logs (JSON), a rate limit per IP, login throttling, graceful shutdown, OpenAPI for the admin API                                                                                                                                   |

Tested with real clients in Docker (`service/tool/s3_compat/`): **AWS CLI v2 34/34**, **rclone
19/19**, and the 15 suites of [MinIO Mint](https://github.com/minio/mint) (AWS SDKs for Java, PHP
and Ruby, MinIO SDKs for Go, Java, JS and Python, s3cmd, mc), whose only failures are features out
of scope. The last full run is in
[`service/tool/s3_compat/RESULTS.md`](service/tool/s3_compat/RESULTS.md).

**What it doesn't do (by design, or not yet):** a single node, no replication nor erasure coding;
no versioning, object lock, bucket policies, tags, notifications, S3 Select nor POST policy
uploads; no SigV2. The unimplemented subresources answer `501 NotImplemented`. It serves HTTP:
put a proxy in front for TLS.

## Run it

### With Docker Compose

From the root of the repo, with the four secrets in the environment of the shell (or in a `.env`
file, see [`.env.example`](.env.example)):

```bash
FEATHER_ACCESS=feather-access FEATHER_SECRET=feather-secret-key \
JWT_SECRET=$(openssl rand -hex 32) KEYS_ENCRYPTION_SECRET=$(openssl rand -hex 32) \
docker compose up -d --build
```

- Console: <http://localhost:8081>, log in with `FEATHER_ACCESS` / `FEATHER_SECRET`.
- S3 API: <http://localhost:8080>.
- Objects and database live in the `feather-data` volume.

Keep `KEYS_ENCRYPTION_SECRET`: the secrets of the access keys are encrypted with it, and changing it
makes them unreadable.

### With Docker, one image at a time

What a cloud platform does (Cloud Run, ECS, Kubernetes…): each image reads its configuration from
the environment when it starts.

```bash
docker build -t feather-io service
docker run -p 8080:8080 -v feather-data:/data \
  -e FEATHER_ACCESS=… -e FEATHER_SECRET=… -e JWT_SECRET=… -e KEYS_ENCRYPTION_SECRET=… feather-io

docker build -t feather-io-console console
docker run -p 8081:80 -e SERVICE_URL=https://<the service as the browser sees it> feather-io-console
```

### Locally

Both packages pin their Flutter/Dart version with [FVM](https://fvm.app) (`.fvmrc`).

```bash
# Service, on port 8080
cd service
fvm dart pub get
FEATHER_ACCESS=access FEATHER_SECRET=secret JWT_SECRET=some-jwt-secret \
KEYS_ENCRYPTION_SECRET=some-keys-secret STORAGE_VOLUME_PATH=./uploads_local \
fvm dart run lib/main.dart

# Console, on port 8081 (it reads web/env.js: SERVICE_URL and ADMIN_PREFIX)
cd console
echo "window.env = { SERVICE_URL: 'http://localhost:8080', ADMIN_PREFIX: '_admin' };" > web/env.js
fvm flutter pub get
fvm flutter run -d chrome --web-port=8081
```

Every variable (rate limits, `PUBLIC_URL`, `TRUSTED_PROXIES`, logs…) is in
[`service/README.md`](service/README.md#env), together with the health check and how to
back up the volume.

## Configure an S3 client

Any client works with: the service URL as the endpoint, **path-style** addressing, region
`us-east-1`, and either the root key (`FEATHER_ACCESS` / `FEATHER_SECRET`) or an access key created
in the console.

```ini
# ~/.aws/config
[profile feather]
region = us-east-1
endpoint_url = http://localhost:8080
s3 =
  addressing_style = path
```

```bash
AWS_ACCESS_KEY_ID=feather-access AWS_SECRET_ACCESS_KEY=feather-secret-key \
  aws --profile feather s3 sync ./photos s3://photos
```

```ini
# rclone.conf
[feather]
type = s3
provider = Other
access_key_id = feather-access
secret_access_key = feather-secret-key
endpoint = http://localhost:8080
region = us-east-1
force_path_style = true
```

```bash
mc alias set feather http://localhost:8080 feather-access feather-secret-key
```

More clients (boto3), the endpoints and the permissions are in
[`service/README.md`](service/README.md).

## The console

|                                                              |                                                  |
|--------------------------------------------------------------|--------------------------------------------------|
| ![Bucket details](docs/screenshots/bucket.png)               | ![Access keys](docs/screenshots/access-keys.png) |
| Buckets: details, anonymous access rules and the danger zone | Access keys per bucket, shown once, with expiry  |

![Background transfers](docs/screenshots/transfers.png)

Uploads and downloads run in the background, across folders and buckets; files over 16 MiB go in
parts.

## Documentation

- [`service/README.md`](service/README.md): configuration, endpoints, Docker, health check, backups.
- [`console/README.md`](console/README.md): configuration and Docker image of the console.
- [`DECISIONS.md`](DECISIONS.md): the non-obvious design decisions (rate limits, SigV4, access
  keys, anonymous access…) and the data behind them.
- [`ROADMAP.md`](ROADMAP.md): where it stands and what comes next.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`SECURITY.md`](SECURITY.md).

## What comes next

After 1.0: listings and ListBuckets backed by an index in SQLite (for buckets of hundreds of
thousands of objects), faster reads of small objects, renaming folders, searching a whole folder
from the console, and a higher rate limit for signed requests. See [`ROADMAP.md`](ROADMAP.md).

## License

[Apache License 2.0](LICENSE).

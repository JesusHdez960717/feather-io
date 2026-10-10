# Feather-io Service

## API architecture

The service exposes two APIs:

* **S3 API**: S3 protocol compatibility for managing buckets and objects.
* **Admin API**: routes reserved for administering the system (reached through the prefix set in
  `ADMIN_PREFIX`). This API **always answers in JSON**.

> **Note**: admin resources must use the `_` prefix (e.g. `_admin`, the default value of
> `ADMIN_PREFIX`) so they don't collide with bucket names at the root of the S3 API.

## Content negotiation (S3 API)

The S3 API supports content negotiation based on the `Accept` header:

* **`Accept: application/json`**: the service answers with a JSON body.
* **Anything else / default**: the service answers in **XML**, to stay compatible with the S3
  standard.
* This only applies to the S3 API; the admin API always returns JSON.

## Configuring S3 clients


Any S3 client works with these options: the service endpoint, **path-style** (the bucket goes in
the path, not in the host), region `us-east-1` and the keys `FEATHER_ACCESS` / `FEATHER_SECRET`.
Tested: AWS CLI v2, rclone, s3cmd, mc and the AWS (Java, PHP, Ruby) and MinIO (Go, Java, JS,
Python) SDKs. The tests live in `tool/s3_compat/`.

**AWS CLI**

```ini
# ~/.aws/config
[profile feather]
region = us-east-1
endpoint_url = http://localhost:8080
s3 =
  addressing_style = path
```

```bash
AWS_ACCESS_KEY_ID=access AWS_SECRET_ACCESS_KEY=secret aws --profile feather s3 ls
```

**rclone**

```ini
# rclone.conf
[feather]
type = s3
provider = Other
access_key_id = access
secret_access_key = secret
endpoint = http://localhost:8080
region = us-east-1
force_path_style = true
```

**boto3**

```python
s3 = boto3.client(
    "s3",
    endpoint_url="http://localhost:8080",
    aws_access_key_id="access",
    aws_secret_access_key="secret",
    region_name="us-east-1",
    config=botocore.config.Config(s3={"addressing_style": "path"}),
)
```

Not supported: SigV2, POST policy uploads, versioning, tags, bucket policies, notifications or
S3 Select (the unimplemented subresources answer `501 NotImplemented`).

## Endpoints and permissions

Summary of some of the available actions, their authentication method and the required permission
(the controllers are the full reference).

### S3 API (path: `/`)

| Action          | Method | Path              | Auth        | Permission                |
|:----------------|:-------|:------------------|:------------|:--------------------------|
| `list-buckets`  | GET    | `/`               | JWT / SigV4 | `s3.list-buckets`         |
| `list-objects`  | GET    | `/{bucket}`       | JWT / SigV4 | `s3.list-objects`         |
| `put-object`    | PUT    | `/{bucket}/{key}` | JWT / SigV4 | `s3.put-object`           |
| `get-object`    | GET    | `/{bucket}/{key}` | JWT / SigV4 | `s3.get-object`           |
| `delete-object` | DELETE | `/{bucket}/{key}` | JWT / SigV4 | `s3.delete-object`        |
| `multi-delete`  | POST   | `/{bucket}`       | JWT / SigV4 | `s3.multi-delete-objects` |

### Admin API (path: `/{ADMIN_PREFIX}`)

| Action            | Method | Path                        | Auth         | Permission              |
|:------------------|:-------|:----------------------------|:-------------|:------------------------|
| `login`           | POST   | `/login`                    | ***Public*** | -                       |
| `bucket.download` | POST   | `/bucket/{bucket}/download` | JWT          | `admin.bucket.download` |
| `access-key.list` | GET    | `/access-keys`              | JWT          | `admin.access-key.list` |
| `access-key.create` | POST | `/access-keys`              | JWT          | `admin.access-key.create` |
| `access-key.update` | PUT  | `/access-keys/{id}`         | JWT          | `admin.access-key.update` |
| `access-key.regenerate-secret` | POST | `/access-keys/{id}/secret` | JWT | `admin.access-key.regenerate-secret` |
| `access-key.delete` | DELETE | `/access-keys/{id}`       | JWT          | `admin.access-key.delete` |

*\*The login checks directly against the `FEATHER_ACCESS` and `FEATHER_SECRET` environment
credentials.*

The whole admin API is documented with OpenAPI: `GET /{ADMIN_PREFIX}/openapi.json` gives the
document and `GET /{ADMIN_PREFIX}/docs` opens it in Swagger UI (log in with `/login` and paste its
`access_token` in *Authorize*). Its errors are Problem Details (RFC 9457,
`application/problem+json`) with the S3 error `code` and the `resource`:

```json
{"code": "NoSuchBucket", "resource": "photos", "type": "about:blank", "title": "Not Found",
 "status": 404, "detail": "The bucket \"photos\" does not exist."}
```

### Access keys

Besides the root key of the env, S3 clients can sign with **access keys** created from the console
(or the admin API). Each one has a name, an id (`FIOK…`), a secret shown only when it is created or
regenerated, an optional expiration, and either one level on every bucket (`all_buckets`) or a
level per bucket (`buckets`). Levels are `readOnly` (list and download), `writeOnly` (upload and
delete) and `readWrite`. A key only sees its own buckets in ListBuckets, and only one with write
access to every bucket may create or delete buckets. Managed keys can't log in to the console.

```json
POST /_admin/access-keys
{"name": "Backups NAS", "buckets": [{"bucket": "backups", "access": "readWrite"}],
 "expires_at": "2027-01-01T00:00:00Z"}
```

## Env

Environment variables of the service.

| Variable                    | Required |      Default       | Description                                                                                                       |
|:----------------------------|:--------:|:------------------:|:------------------------------------------------------------------------------------------------------------------|
| `FEATHER_SECRET`            | **Yes**  |         -          | Secret key used to authenticate requests.                                                                         |
| `FEATHER_ACCESS`            | **Yes**  |         -          | Access key used to authenticate requests.                                                                         |
| `STORAGE_VOLUME_PATH`       | **Yes**  |         -          | Local path of the volume where buckets, objects and the SQLite database (`.db/feather-io.sqlite`) are stored. |
| `JWT_SECRET`                | **Yes**  |         -          | Secret key used to sign the JWTs.                                                                                 |
| `KEYS_ENCRYPTION_SECRET`    | **Yes**  |         -          | Encrypts the secrets of the access keys in the database (e.g. `openssl rand -base64 32`). Changing it makes the stored keys unusable. |
| `ADMIN_PREFIX`              |    No    |      `_admin`      | Prefix of the admin API and the system's reserved routes.                                                         |
| `RESERVED_BUCKET_NAMES`     |    No    | ***(empty list)*** | Comma-separated list of reserved bucket names that users cannot create.                                           |
| `MAX_OBJECT_SIZE`           |    No    |    `5368709120`    | Maximum size in bytes of an object uploaded with `PUT` (5 GiB by default); above it the answer is `EntityTooLarge`. |
| `PUBLIC_URL`                |    No    |         -          | Public URL of the service (`https://s3.example.com`, no path) for presigned URLs; without it the scheme and `Host` of the request are used. The proxy must forward the original `Host`. |
| `RATE_LIMIT_REQUESTS`       |    No    |       `2000`       | Requests per IP in each window (general limit; above it, `503 SlowDown` on S3 and `429` on admin); `0` disables it. See `DECISIONS.md`. |
| `RATE_LIMIT_WINDOW_SECONDS` |    No    |        `60`        | Seconds of the general limit window.                                                                              |
| `LOGIN_MAX_FAILURES`        |    No    |        `10`        | Failed logins in a row that lock an IP.                                                                           |
| `LOGIN_LOCK_SECONDS`        |    No    |       `900`        | Seconds an IP stays locked (answers `429` with `Retry-After`).                                                    |
| `LOGIN_FAILURE_DELAY_MS`    |    No    |       `1000`       | Delay before answering each failed login.                                                                         |
| `TRUSTED_PROXIES`           |    No    |        `0`         | Own proxies in front of the service; with 0 the connection IP is used and `X-Forwarded-For` is ignored.           |
| `LOG_FORMAT`                |    No    |         -          | `json` writes one JSON object per line (for a log collector); otherwise readable lines.                          |
| `LOG_LEVEL`                 |    No    |       `info`       | `debug`, `info`, `warning` or `error`.                                                                            |

For local development, `main()` also reads a `.env` file (and `.env.<WINTER_PROFILE>`) from the
working directory, under the variables of the process.

## Docker

`Dockerfile` compiles the service AOT and runs it on a `scratch` image (~25 MB) with the Dart
runtime and the SQLite that the `sqlite3` package bundles. From `service/`:

```bash
docker build -t feather-io .
docker run -p 8080:8080 -v feather-data:/data \
  -e FEATHER_ACCESS=… -e FEATHER_SECRET=… -e JWT_SECRET=… -e KEYS_ENCRYPTION_SECRET=… feather-io
```

The image sets `STORAGE_VOLUME_PATH=/data` (a volume): buckets, objects and the SQLite database
live there, so they survive the container.

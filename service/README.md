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

*\*The login checks directly against the `FEATHER_ACCESS` and `FEATHER_SECRET` environment
credentials.*

## Env

Environment variables of the service.

| Variable                    | Required |      Default       | Description                                                                                                       |
|:----------------------------|:--------:|:------------------:|:------------------------------------------------------------------------------------------------------------------|
| `FEATHER_SECRET`            | **Yes**  |         -          | Secret key used to authenticate requests.                                                                         |
| `FEATHER_ACCESS`            | **Yes**  |         -          | Access key used to authenticate requests.                                                                         |
| `STORAGE_VOLUME_PATH`       | **Yes**  |         -          | Local path of the volume where buckets and objects are stored.                                                    |
| `JWT_SECRET`                | **Yes**  |         -          | Secret key used to sign the JWTs.                                                                                 |
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

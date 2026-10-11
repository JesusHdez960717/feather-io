# The API

A tour of the HTTP API of the service, with real requests and responses (taken from a running
service). The console uses exactly these calls; [`console.md`](console.md) says which one each
screen makes.

The service serves two APIs on the same port (8080 by default):

- **S3 API** at `/`: buckets and objects, path-style (`/{bucket}/{key}`). XML like S3 by default,
  JSON with `Accept: application/json` (what the console asks for).
- **Admin API** at `/{ADMIN_PREFIX}` (`/_admin` by default): what S3 has no operation for (login,
  bucket metadata and statistics, anonymous rules, access keys…). Always JSON. Its paths start with
  `_`, so they can't collide with a bucket name.

The admin API is also described by its OpenAPI document, `GET /_admin/openapi.json`, browsable with
Swagger UI at `/_admin/docs` (log in, then paste the `access_token` in *Authorize*). That document is
generated from the code, so it is the complete reference; this page shows how the calls fit
together.

## Authentication

| Who | How |
|---|---|
| The console (and anything else that logs in) | `Authorization: Bearer <access_token>`, from [`POST /_admin/login`](#log-in). Valid on both APIs |
| S3 clients (AWS CLI, rclone, SDKs) | AWS SigV4 in the `Authorization` header, or in the query of a presigned URL, with the root key or an access key. S3 API only |
| Nobody | Only `/_admin/login`, `/_admin/health`, the OpenAPI document and Swagger UI, and objects opened by an [anonymous rule](#anonymous-access) |

Each route needs a permission (`s3.put-object`, `admin.access-key.create`…): the login token has all
of them; an access key, those of its level on the bucket.

## Errors

Every JSON error is a Problem Details (RFC 9457, `application/problem+json`). Errors of the service
add the S3 error `code`, which clients decide on, and the `resource` it refers to. The `detail` is
in English, or in Spanish with `Accept-Language: es`.

```json
{
  "code": "NoSuchKey",
  "resource": "missing.txt",
  "type": "about:blank",
  "title": "Not Found",
  "status": 404,
  "detail": "The key \"missing.txt\" does not exist."
}
```

Without `Accept: application/json`, the S3 API answers the S3 `<Error>` document, with the request id
of the logs:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>NoSuchKey</Code>
  <Message>The key &quot;missing.txt&quot; does not exist.</Message>
  <Resource>missing.txt</Resource>
  <RequestId>be363eb5-0dac-44e6-91ec-1e20ca8a117e</RequestId>
</Error>
```

A body that can't be read is a `400` naming the field, and one that breaks a rule a `422` with its
`violations` (the console shows each one under its field):

```json
{"type": "about:blank", "title": "Bad Request", "status": 400, "detail": "$.name: expected a string, got an integer"}
```

```json
{
  "violations": [
    {"fieldName": "prefix", "message": "The minimum is 1", "code": "size.min", "params": {"value": 1}}
  ],
  "type": "about:blank",
  "title": "Unprocessable Entity",
  "status": 422
}
```

Other common answers: `401` without credentials, `403` without the permission, `429` (admin) or
`503 SlowDown` (S3) above the rate limit, both with `Retry-After`.

---

# Admin API

## Health

```http
GET /_admin/health
```

```json
{"status": "UP", "checks": {"database": "UP", "storage": "UP"}}
```

`503` with `"status": "DOWN"` when the database or the volume fail. Public and never cached; for the
probes of an orchestrator or a load balancer.

## Log in

```http
POST /_admin/login
Content-Type: application/json

{"access": "feather-access", "secret": "feather-secret-key"}
```

```json
{"access_token": "eyJhbGciOiJIUzI1NiIsInR5…", "expires_in": 43200000, "expire_at": 1791729448032}
```

`access` and `secret` are the service's `FEATHER_ACCESS` and `FEATHER_SECRET` (access keys can't
log in). The token lasts 12 hours (`expires_in` in milliseconds, `expire_at` as epoch milliseconds).
Wrong credentials:

```json
{"code": "InvalidCredentials", "type": "about:blank", "title": "Forbidden", "status": 403, "detail": "Invalid credentials"}
```

Every failure waits a second, and 10 in a row lock the IP for 15 minutes (`429` with `Retry-After`).

## Buckets

### Details and statistics

```http
GET /_admin/bucket/photos
```

```json
{
  "name": "photos",
  "object_count": 3,
  "size_bytes": 18,
  "creation_date": "2026-10-10T20:37:29.000",
  "last_modified": "2026-10-10T20:37:31.160724",
  "description": "Photos of the 2026 trip",
  "color": 4290909806
}
```

`color` is an ARGB integer (`0xFFC0156E`), or `null`.

### Edit description and color

```http
PUT /_admin/bucket/photos
Content-Type: application/json

{"description": "Trip photos", "color": 4280391411}
```

Answers the bucket as above, with the new values. Both fields are replaced (`null` clears them).

### Empty a bucket

```http
DELETE /_admin/bucket/photos/objects
```

`204`. Deletes every object and keeps the bucket, its metadata and its rules.

### Delete a folder with its content

```http
DELETE /_admin/bucket/photos/folder?prefix=2026/
```

`204`. S3 has no such operation: deleting the key `2026/` only removes the empty folder.

### Presigned URL

```http
POST /_admin/bucket/photos/presign
Content-Type: application/json

{"key": "2026/beach.jpg", "expires_in": 3600}
```

```json
{
  "url": "http://localhost:8080/photos/2026/beach.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=feather-access%2F20261011%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261011T023733Z&X-Amz-Expires=3600&X-Amz-Signature=872a1fc3…&X-Amz-SignedHeaders=host",
  "expires_at": "2026-10-11T03:37:33.844464Z"
}
```

A `GET` URL signed with the service keys (the console has no secret to sign it), valid for
`expires_in` seconds, at most 7 days. It uses `PUBLIC_URL` when set, otherwise the scheme and `Host`
of this request.

### Download as a zip

```http
POST /_admin/bucket/photos/download
Content-Type: application/json

{"keys": ["2026/", "notes.txt"]}
```

```http
HTTP/1.1 200 OK
Content-Type: application/zip
Content-Disposition: attachment; filename="download_1791686254154.zip"
```

Keys ending in `/` add the whole folder.

## Anonymous access

Rules that open part of a bucket to requests without credentials. `access` is `readOnly` (list and
download), `writeOnly` (upload and delete) or `readWrite`. A `prefix` without `*` covers every key
that starts with it; with `*` (any characters, `/` included) the whole key must match.

```http
GET /_admin/bucket/photos/anonymous-access
```

```json
[{"prefix": "public/", "access": "readOnly"}]
```

Create, or replace the rule of the same prefix:

```http
POST /_admin/bucket/photos/anonymous-access
Content-Type: application/json

{"prefix": "public/", "access": "readOnly"}
```

```json
{"prefix": "public/", "access": "readOnly"}
```

Delete:

```http
DELETE /_admin/bucket/photos/anonymous-access
Content-Type: application/json

{"prefix": "public/"}
```

## Access keys

Keys for S3 clients besides the root key. A key has one level on every bucket (`all_buckets`) or a
level per bucket (`buckets`), never both.

```http
GET /_admin/access-keys
```

```json
{
  "root_access_key_id": "feather-access",
  "keys": [
    {
      "access_key_id": "FIOKDM2KRXIE2NME33KB",
      "name": "Backups",
      "enabled": true,
      "expired": false,
      "all_buckets": null,
      "buckets": [{"bucket": "photos", "access": "readWrite"}],
      "expires_at": null,
      "created_at": "2026-10-11T02:37:35.000Z",
      "last_used_at": null
    }
  ]
}
```

### Create a key

```http
POST /_admin/access-keys
Content-Type: application/json

{
  "name": "Backups",
  "enabled": true,
  "all_buckets": null,
  "buckets": [{"bucket": "photos", "access": "readWrite"}],
  "expires_at": null
}
```

`201` with the key and, **only in this answer**, its secret:

```json
{
  "access_key_id": "FIOKDM2KRXIE2NME33KB",
  "name": "Backups",
  "enabled": true,
  "expired": false,
  "all_buckets": null,
  "buckets": [{"bucket": "photos", "access": "readWrite"}],
  "expires_at": null,
  "created_at": "2026-10-11T02:37:35.000Z",
  "last_used_at": null,
  "secret_access_key": "LLRVwK6sfeWzG5awZrFzUy356UowKum6GSoF0QzY"
}
```

### Update a key

```http
PUT /_admin/access-keys/FIOKDM2KRXIE2NME33KB
Content-Type: application/json

{"name": "Backups", "enabled": false, "all_buckets": "readOnly", "buckets": [], "expires_at": "2027-01-01T00:00:00.000Z"}
```

Answers the key (without the secret). This one now reads every bucket, is disabled and expires at
the start of 2027.

### Regenerate the secret

```http
POST /_admin/access-keys/FIOKDM2KRXIE2NME33KB/secret
```

Answers the key with its new `secret_access_key`; the old one stops working.

### Delete a key

```http
DELETE /_admin/access-keys/FIOKDM2KRXIE2NME33KB
```

`204`. Clients using it get `403 InvalidAccessKeyId` right away.

---

# S3 API

What any S3 client does. The examples send the console's token and `Accept: application/json`; an
S3 client signs with SigV4 instead and gets the XML documents of S3 (shown for some of them). The
full list of operations is in the [README](../README.md#what-it-supports).

## Buckets

### List buckets

```http
GET /
```

```json
[
  {
    "name": "photos",
    "object_count": 0,
    "size_bytes": 0,
    "creation_date": "2026-10-10T20:37:29.000",
    "last_modified": null,
    "description": "Photos of the 2026 trip",
    "color": 4290909806
  }
]
```

The same, as an S3 client sees it:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Owner>
    <ID>feather-io</ID>
    <DisplayName>feather-io</DisplayName>
  </Owner>
  <Buckets>
    <Bucket>
      <Name>photos</Name>
      <Description>Photos of the 2026 trip</Description>
      <Color>4290909806</Color>
      <CreationDate>2026-10-11T02:37:29.000Z</CreationDate>
      <ObjectCount>0</ObjectCount>
      <Size>0</Size>
    </Bucket>
  </Buckets>
</ListAllMyBucketsResult>
```

An access key only sees its own buckets.

### Create a bucket

```http
PUT /photos
Content-Type: application/json

{"description": "Photos of the 2026 trip", "color": 4290909806}
```

```http
HTTP/1.1 200 OK
Location: /photos
```

The body is optional (S3 clients send none, or an XML `CreateBucketConfiguration`). The name follows
the S3 rules; otherwise:

```json
{"code": "InvalidBucketName", "resource": "Bad_Name", "type": "about:blank", "title": "Bad Request", "status": 400, "detail": "The bucket name \"Bad_Name\" is not valid."}
```

### Delete a bucket

```http
DELETE /photos
```

`204`, only when it is empty (`409 BucketNotEmpty` otherwise). It also deletes its metadata, rules
and pending uploads.

## Objects

### List objects

```http
GET /photos?prefix=2026/&delimiter=/&max-keys=25
```

```json
{
  "name": "photos",
  "prefix": "2026/",
  "delimiter": "/",
  "max_keys": 25,
  "key_count": 1,
  "continuation_token": null,
  "is_truncated": false,
  "next_continuation_token": null,
  "total_keys": 1,
  "contents": [
    {
      "key": "2026/beach.jpg",
      "size_bytes": 6,
      "last_modified": "2026-10-10T20:38:17.214390",
      "etag": "b1946ac92492d2347c6235b4d2611184"
    }
  ],
  "common_prefixes": []
}
```

With `delimiter=/` only the level of the prefix is listed, and subfolders come as
`common_prefixes` (`"2026/"`). Pages hold up to `max-keys` (at most 1000); the next one is asked for
with `continuation-token=<next_continuation_token>`. S3 clients get `ListBucketResult`: V2 with
`list-type=2`, V1 otherwise, and `encoding-type=url` is honoured.

### Upload

```http
PUT /photos/2026/beach.jpg
Content-Type: image/jpeg

<bytes>
```

```http
HTTP/1.1 200 OK
ETag: "b1946ac92492d2347c6235b4d2611184"
```

The body is streamed to disk. `Content-Type`, `Content-Disposition`, `Cache-Control`, `x-amz-meta-*`
and the other headers S3 stores are kept and sent back on download. Up to `MAX_OBJECT_SIZE` (5 GiB by
default); bigger files go [in parts](#multipart-upload).

A key ending in `/` without a body creates an empty folder:

```http
PUT /photos/empty/
```

### Download

```http
GET /photos/2026/beach.jpg
Range: bytes=0-1
```

```http
HTTP/1.1 206 Partial Content
Content-Range: bytes 0-1/6
Content-Length: 2
```

Without `Range`, `200` with the whole object. `HEAD` gives only the headers (what the details of the
console show):

```http
HTTP/1.1 200 OK
Content-Type: image/jpeg
Content-Length: 6
ETag: "b1946ac92492d2347c6235b4d2611184"
Last-Modified: Sun, 11 Oct 2026 02:37:30 GMT
Accept-Ranges: bytes
```

### Copy (rename and move)

```http
PUT /photos/2026/copy.jpg
x-amz-copy-source: /photos/2026/beach.jpg
```

```json
{
  "key": "2026/copy.jpg",
  "size_bytes": 6,
  "last_modified": "2026-10-10T20:38:17.214390",
  "etag": "b1946ac92492d2347c6235b4d2611184"
}
```

The console renames and moves with a copy followed by a delete. The `x-amz-copy-source-if-*`
conditions and `x-amz-metadata-directive: REPLACE` work as in S3.

### Delete one

```http
DELETE /photos/2026/beach.jpg
```

`204`, also when the key doesn't exist (as in S3).

### Delete many

```http
POST /photos?delete
Content-Type: application/json

{"delete": {"objects": [{"key": "notes.txt"}, {"key": "2026/copy.jpg"}]}}
```

```json
{"deleted": [{"key": "notes.txt"}, {"key": "2026/copy.jpg"}], "errors": []}
```

Up to 1000 keys. S3 clients send the XML `<Delete>` document.

## Multipart upload

How the console uploads files over 16 MiB (in 8 MiB parts). Every part but the last must be at least
5 MiB.

1. Start it:

   ```http
   POST /photos/big.bin?uploads
   ```

   ```json
   {"bucket": "photos", "key": "big.bin", "upload_id": "d5769edd9402635507728e668d0eb391", "initiated": "2026-10-11T02:37:37.231255Z"}
   ```

2. Upload each part; its `ETag` is needed to complete:

   ```http
   PUT /photos/big.bin?partNumber=1&uploadId=d5769edd9402635507728e668d0eb391

   <bytes of the part>
   ```

   ```http
   HTTP/1.1 200 OK
   ETag: "b1946ac92492d2347c6235b4d2611184"
   ```

3. Complete it, with the parts in order:

   ```http
   POST /photos/big.bin?uploadId=d5769edd9402635507728e668d0eb391
   Content-Type: application/json

   {"parts": [{"part_number": 1, "etag": "\"b1946ac92492d2347c6235b4d2611184\""}]}
   ```

   ```json
   {"bucket": "photos", "key": "big.bin", "etag": "6a6d8d4533507d490ab007dfe8314ab7-1", "size_bytes": 6}
   ```

To give up, `DELETE /photos/big.bin?uploadId=…` deletes the parts. S3 clients can also list the
parts (`GET ?uploadId=`) and the pending uploads (`GET /photos?uploads`), and copy a part from
another object (`x-amz-copy-source` on the part).

# Design decisions

Why the service behaves the way it does where that is not obvious from reading the code, with the
data used to decide. When a decision changes, update it here.

## 1. Login attempt limit

**What it does.** `LoginRateLimiter` (in `admin/auth/logic/service/`) counts **failed** logins per
IP:

- Every failure is answered with a **1 second delay** (`LOGIN_FAILURE_DELAY_MS`).
- After **10 failures in a row** (`LOGIN_MAX_FAILURES`) the IP is **locked for 15 minutes**
  (`LOGIN_LOCK_SECONDS`): `429 Too Many Requests` with `Retry-After`, **even if it then gets the
  credentials right**.
- A successful login clears the failures, and failures older than 15 minutes stop counting.
- Credentials are compared in constant time.

**Why.** There is a single user (`FEATHER_ACCESS`/`FEATHER_SECRET`) and the login had no brake at
all: in the security review, 50 wrong passwords in a row were all answered instantly, without a
lock.

- *The 1 s delay* costs nothing to a person who mistypes and limits brute force to ~1 attempt per
  second and connection.
- *The lock* stops parallel attacks, which the delay alone does not.
- *It locks even with the right credentials* because otherwise an attacker would only have to wait
  for the lock to end and keep trying: the lock would cost them nothing.
- *It only counts failures* (not every request): a legitimate user who logs in many times must never
  be locked. That is why Winter's general limiter, which counts everything, is not used.
- *Constant-time comparison*: with `!=` the response time depends on how many characters match and
  leaks hints about the secret.

**The IP.** It is Winter's `request.clientIp(trustedProxies: TRUSTED_PROXIES)`. By default
(`TRUSTED_PROXIES=0`) the connection IP is used and **`X-Forwarded-For` is ignored**, because any
client can send it with a fake IP to get around the limit (a test checks this). Behind your own
proxies (nginx, a load balancer) set how many there are; otherwise every client shares the proxy's
IP and locking one locks them all.

**Known limitations.**

- It lives in memory: with several instances of the service each one keeps its own count, and a
  restart clears the locks.
- An attacker who knows someone's IP cannot lock it unless they share that IP (NAT, the same proxy
  without `TRUSTED_PROXIES`).
- A token already issued stays valid during the lock (it lasts 12 h).

## 2. General request limit

**What it does.** Winter's `RateLimiterFilter`, registered as the **first global filter** in
`main.dart` (sliding window): at most **`RATE_LIMIT_REQUESTS` requests (2000) per IP in each
`RATE_LIMIT_WINDOW_SECONDS` window (60 s)**. Above that it throws Winter's `429`, and
`S3ExceptionHandler` answers it: the **S3 API `503 SlowDown`** with the S3 `<Error>` (XML, or JSON
with `Accept`), like S3, and the **admin API `429`** (a Problem Details with a translated `detail`);
both with `Retry-After`. Every response carries `X-RateLimit-Limit`,
`X-RateLimit-Remaining` and `X-RateLimit-Reset`. `RATE_LIMIT_REQUESTS=0` disables it. The IP is
computed as for the login (`TRUSTED_PROXIES`).

**Why it is needed.** Without it, anyone who reaches the service (including an anonymous client, or
any IP against the login) can send requests without a brake. Every request has a cost: listing a
bucket walks its whole directory, `ListBuckets` walks every object, every upload computes the md5
and writes to SQLite. A few insistent clients are enough to saturate it.

**Why the first filter.** To stop the flood before doing any work: reading the body, checking SigV4
or JWT signatures, querying the anonymous rules in SQLite.

**Why per IP and not per user.** The attack that matters comes from whoever has no credentials; a
per-user limit would not stop an anonymous client or someone trying signatures.

### Why 2000 per minute

The rule is **never to slow down a legitimate client**, because S3 clients work in bursts. To pick
the number, the real traffic was measured with a proxy in front of the service (on Windows):

| Scenario                                                  |      Requests | Peak in 1 s | Peak in 60 s |
|-----------------------------------------------------------|--------------:|------------:|-------------:|
| Full batteries (AWS CLI, rclone and the 15 Mint suites)   | 1373 in 142 s |         125 |      **898** |
| `aws s3 sync` of 1000 small files (+ deleting the bucket) | 2004 in 108 s |         293 |     **1532** |

- **What drives the request count is small files in parallel, not multipart.** A big file in parts
  is few requests (one per 8 MiB part: a 1 GiB file is ~130), while `aws s3 sync` uploads 10 files
  at a time and each one is at least one request. The console runs in parallel too: 2 uploads and 2
  downloads at a time, plus the paged listing.
- **2000/min leaves headroom over the worst case measured (1532)** and still stops a flood: a script
  in a loop makes thousands of requests per second.
- **1000 would fall short:** the `sync` of 1000 files would exceed it.

**Why `503 SlowDown` on the S3 API and not `429`.** It is what S3 answers when a client goes too
fast, and what the AWS SDKs and CLI recognize as "wait and retry". The console is not an S3 client
and goes through the admin API, which keeps `429`.

**What happens to a client that hits the limit** (measured with the limit lowered to 100/min):

| Client                              | With `429` (before)                                                    | With `503 SlowDown` (now)                                                                                                                    |
|-------------------------------------|------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| AWS CLI v2 (`s3 sync` of 200 files) | **Does not retry it**: 102 files fail at once with `Too Many Requests` | **Retries it** (twice, waiting a few seconds), but with a 60 s window there is not enough time: the same 102 fail (`reached max retries: 2`) |
| rclone (`copy` of 200 files)        | Retries it, very slowly                                                | —                                                                                                                                            |

With `503 SlowDown` clients behave as they do with S3, but their retries wait seconds and the window
lasts a minute: **the limit does not act as a throttle**. That is why it must sit **above any
legitimate use**: it is an emergency brake against abuse.

**Careful when tuning it.** The measurements are on Windows, where every upload is slow (Defender,
SQLite). On a fast Linux server the same `sync` would go faster and could exceed 2000/min. If it is
deployed for massive loads (migrations, backups with many small files), measure and raise it, or
disable it for the IPs of those processes. Measured on Linux (`service/tool/benchmark/RESULTS.md`):
8 parallel clients on one IP stay at ~33 requests/s and 98 requests fail in a minute even after the
SDK retries, as expected of a brake; a higher limit for signed requests is under *After 1.0* in
`ROADMAP.md`.

## 3. SigV4 signatures

| Decision                                                                                                                                           | Why                                                                                                                                                                                                                                                |
|----------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| A signature more than **15 minutes** away from the server clock gives `RequestTimeTooSkewed` (and the credential must be from the signature's day) | Without a window, a captured signed request (over HTTP or in a proxy log) could be replayed forever: in the review, one signed 3 days earlier worked. 15 minutes is what S3 uses and tolerates slightly skewed clocks                              |
| A presigned URL cannot have a future date                                                                                                          | With a future date it lasted beyond the 7-day maximum                                                                                                                                                                                              |
| If the client signs the **body's sha256**, it is checked (`XAmzContentSHA256Mismatch`)                                                             | Otherwise a captured request could be replayed **with other content**, and over HTTP someone in the middle could change it. It is checked while reading, without loading the body in memory, and the previous object is left untouched if it fails |
| `UNSIGNED-PAYLOAD` and `aws-chunked` (`STREAMING-…`) bodies are not checked                                                                        | In the first case the client does not sign the content; in the second each chunk's signature would have to be validated. It stays under *Parked* (checksum validation)                                                                             |
| Authentication errors give no internal details                                                                                                     | An exception message can reveal the implementation                                                                                                                                                                                                 |

## 4. Anonymous access

| Decision                                                                                                    | Why                                                                                                                                                                                                                                                  |
|-------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Multipart is never anonymous (create, parts, complete, abort, list uploads and parts)                       | With a write rule, an anonymous client could list other people's uploads in progress, replace their parts or abort them. The operations that go through routes accepting anonymous rules (PUT, DELETE, GET) require the upload permission explicitly |
| An anonymous client cannot copy (CopyObject, UploadPartCopy) nor change the response headers (`response-*`) | Copying reads the source, which may not be covered by any rule                                                                                                                                                                                       |
| Multi-delete is never anonymous                                                                             | Its keys come in the body and cannot be checked against the rules before reading it                                                                                                                                                                  |
| A rule without `*` is a prefix; with `*`, the whole key has to match                                        | `public/` covers everything that starts that way, like an S3 prefix. With `*` a pattern is meant: before, `photos/*.jpg` also opened `photos/copy.jpg.zip`. Rules without `*` keep their meaning. The console explains it next to the field          |
| Anonymous traffic has no limit of its own, only the general one per IP                                      | The general limit already stops floods, anonymous ones included. A lower one is only needed if buckets are published on the internet with many downloads                                                                                             |

## 5. Access keys

| Decision                                                                                                                           | Why                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
|------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| The secret is stored **encrypted** (AES-256-GCM with the sha256 of `KEYS_ENCRYPTION_SECRET`), not hashed                           | SigV4 computes an HMAC with the secret itself, so the service needs it back on every request: a hash like a password's would not do. Encrypting keeps a copy of the SQLite file (a backup, the volume) from giving the secrets away. The key id goes as associated data, so a secret copied onto another row does not decrypt                                                                                                                                                                                                                                                                                                                                                                                            |
| `KEYS_ENCRYPTION_SECRET` is its own variable, not derived from `JWT_SECRET`                                                        | Rotating the JWT secret (to log everyone out) must not make every stored key unreadable. Changing `KEYS_ENCRYPTION_SECRET` does: the keys then have to be recreated                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| The secret is shown **once** (on create and on regenerate)                                                                         | It can't be shown again without decrypting it for the console, and a secret that can be read back can leak from the console's screen or logs. Losing it means regenerating it                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Permissions **per bucket** (read, write or both), or one level on every bucket; not per prefix                                     | It is what clients need (a backup in its bucket, a website reading another) and what S3 policies are mostly used for. Per-prefix access already exists for anonymous rules; for keys it can come later                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| Only a key with write access to **every** bucket may create and delete buckets                                                     | A key scoped to some buckets would otherwise create buckets it can't reach, or delete other people's                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| Only the root key (`FEATHER_ACCESS`) opens the console; managed keys are for S3 clients                                            | The console manages the keys themselves: a key able to log in could raise its own permissions. The admin API only accepts the JWT of the login                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| A disabled, expired or deleted key answers `403 InvalidAccessKeyId`                                                                | As in AWS: it does not tell an attacker whether the key existed                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| As in AWS, the anonymous rules of a bucket also apply to requests signed with an access key: they add to the key's own permissions | A public prefix is public for everyone, signed or not: before, a key with no grant on a bucket got 403 on its public prefix while an unsigned request got the object, and clients that always sign (SDKs, rclone, the AWS CLI) could not read public data with their own key. The signature is still checked first (a disabled key or a bad signature gets 403 even on a public prefix), the key stays the principal, and the same limits as anonymous access hold: no multipart, no multi-delete, and ListBuckets only shows the key's buckets. A key may copy from a public read prefix into a bucket it can write, and override the response headers (`response-*`) of a public object, because its request is signed |
| `last_used_at` is written at most once a minute per key                                                                            | A `sync` of thousands of files would otherwise write to SQLite on every request                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |

## 6. Other security decisions

| Decision                                                                                                              | Why                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
|-----------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| JWTs must carry `exp`                                                                                                 | The ones the service issues always expire (12 h); a token without `exp` (forged with the secret) would never expire                                                                                                                                                                                                                                                                                                                                                                                     |
| Keys cannot contain `\`                                                                                               | On Windows it is a folder separator: `a\b` was another way to write `a/b` and allowed writing the folder marker                                                                                                                                                                                                                                                                                                                                                                                         |
| CORS accepts any origin, without credentials                                                                          | Authentication goes in the `Authorization` header (JWT or SigV4), not in cookies: another site cannot make requests on the user's behalf                                                                                                                                                                                                                                                                                                                                                                |
| Presigned URLs use `PUBLIC_URL` when it is set (otherwise the scheme and `Host` of the request)                       | Behind an HTTPS proxy the service sees `http` and the URLs came out with `http://`; and the client sends the `Host`, so it could point to another domain. Only scheme, host and port (the path is part of the signature), and it is validated at startup. The proxy must forward the original `Host`, which is also part of the signature                                                                                                                                                               |
| Objects are served with their `Content-Type`, including HTML/JS uploaded by an anonymous client with write permission | **The service and the console always run as separate services, on different ports.** A different port is already another *origin* for the browser: a script served by the service cannot read the console's `localStorage` or its token. Cookies are not separated by port, but none are used (see the CORS row). **If they ever shared an origin** (same domain and port behind a proxy), that content would have to be served as a download (`Content-Disposition: attachment` and a restrictive CSP) |

## 7. Localized error messages

It builds on the i18n support of Winter (`winter/DECISIONS.md` §1). Supported languages: English
and Spanish.

| Decision                                                                                                                                                                                           | Why                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| The language is negotiated like the format: English by default, the language of `Accept-Language` when the service supports it (`request.locale`, from Winter)                                     | It mirrors the content negotiation: S3 answers XML in English, as AWS, and whoever asks for something else (`Accept: application/json`, `Accept-Language: es`) gets it. S3 clients (SDKs, AWS CLI, rclone, curl) don't send `Accept-Language`, so they keep getting English. The console sends the app's language                                                                                                                                                                                             |
| Only the text of the message is translated, never the error code (`<Code>`, `code`)                                                                                                                | Clients decide on the code (`NoSuchKey`, `SlowDown`…); the message is only shown or logged. Translating the message changes nothing for them                                                                                                                                                                                                                                                                                                                                                                  |
| Translated error responses carry `Vary: Accept-Language` (Winter adds it when the request's language was read)                                                                                     | A proxy or CDN must not serve one language's error to another client                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| Browsers do send `Accept-Language`, so an expired presigned URL opened in a browser in Spanish shows the error in Spanish                                                                          | It is a person reading it; it is the only visible difference with AWS                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| Translations with `slang`, from YAML files (`en.i18n.yaml` as the base with the parameter types, `es.i18n.yaml` with the texts), generated with `fvm dart run slang` and versioned, as Winter does | Typed access (`intl.errors.s3.noSuchBucket(bucket: name)`) instead of keys as strings; a missing key in a language doesn't compile (`fallback_strategy: none`); the texts are compiled into the binary, so nothing to copy into the `scratch` Docker image; no `build_runner`. YAML rather than ARB because ARB has no nested keys and JSON no comments                                                                                                                                                          |
| Messages are read with the `intl` getter, in the language of the request in progress (Winter's `requestLocale`, kept in a `Zone` per request), and become plain strings when the error is built: `message: intl.errors.s3.bucketNotEmpty(bucket: name)` | Most errors are thrown where there is no request (e.g. `BucketService.deleteBucket`, multipart, copy conditions), and the zone gives them its language without passing it down. It replaced an earlier version where every error and validation rule carried a function from the messages to its text (`(m) => m.errors…`, with a `localized(...)` adapter for Winter), resolved by the exception handler: more ceremony at every `throw` and rule. Discarded too: one exception class per error (~70 small classes) and passing the language to the services (an HTTP detail in the service layer) |
| The messages, logs included, are in the request's language | They are built once, when the error is thrown. The code (`NoSuchKey`…) and the route in the log stay the same in every language, so the diagnosis doesn't depend on reading the text |
| `intl` is a getter and validators are built inside `validate()` | A `final` or `static` value would freeze the language of whoever evaluated it first |

## 8. Errors: Problem Details

Every JSON error of the service (admin API, and S3 API with `Accept: application/json`) is a
Problem Details (RFC 9457, `application/problem+json`), Winter's format. The S3 API keeps the S3
`<Error>` XML by default.

| Decision | Why |
|---|---|
| An `S3Exception` is a Problem Details whose `detail` is the message, plus the extensions `code` (the S3 code) and `resource` | It was `{code, message, resource}`, while the errors of Winter itself (401, 404 of a route, 400 of a body, 422) were already Problem Details: two formats for one client. Now every error reads the same, the console shows `detail`, and it still decides on `code`, which is never translated |
| The 422 is Winter's: a Problem Details with `violations` (`fieldName`, `message`, `code`, `params`), never the value | The value that failed is personal data or a long text that the client already has; the `code` lets a client translate or react without parsing the message |
| Request bodies are read with `json.field<T>()`, and a wrong body is a 400 whose `detail` names the field (`$.buckets[0]: expected an object, got a string`) | With casts every wrong body was the same generic 400 (or a 500 for a wrong type), and the developer of a client had to guess the field. The path never contains the value sent nor a Dart type |
| On the S3 API, a 413 (a body over the limit found while reading) is `EntityTooLarge` and a 429 is `SlowDown`, both as the S3 `<Error>` | S3 clients parse the XML and decide on its code; they don't know Winter's Problem Details. The admin API keeps Winter's answers |
| The S3 `<Error>` carries `<RequestId>`, the request id of the logs | As in S3: a client can report it, and the log lines of that request are found by it |
| An unexpected error inside a multi-delete is logged and answered with a fixed message, never its `toString()` | The text of an exception can reveal paths and the implementation |

## 9. OpenAPI of the admin API

| Decision | Why |
|---|---|
| Only the admin API is documented (`/{admin}/openapi.json`, Swagger UI at `/{admin}/docs`) | The S3 API is the one AWS documents, and its routes multiplex many operations by query and headers (`PUT /{bucket}/{key}` is PutObject, CopyObject, UploadPart and UploadPartCopy) with XML bodies: a generated document would be misleading |
| Both are public, like the login | They describe the API, never its data; the protected routes still need the JWT, which Swagger takes in *Authorize* |
| The bodies come from an `example` of each model, and the constraints from its `validate()` | Nothing is written twice: the example is serialized by the same `toJson()` as a real response, and a rule changed in `validate()` changes the document |

## 10. Logs

| Decision | Why |
|---|---|
| Readable lines by default, one JSON object per line with `LOG_FORMAT=json`; `LOG_LEVEL` (`info` by default) | Readable while developing, and a log collector (Loki, Cloud Logging, Datadog) reads the JSON without parsing rules |
| `LoggingFilter` logs every request after the general rate limit | A flood rejected by the limit doesn't flood the logs too (Winter logs those at `debug`) |
| Never the query string, bodies, tokens, secrets nor what was typed at login; failed logins and locks are logged with the client IP | A presigned URL carries its signature in the query, and a log ends up in more places than the service. The IP is what an operator needs to see a brute force |
| Services log the changes of state (`info`) with ids in `fields` | Who deleted a bucket or created a key is the first question after an incident; the request id of each line ties it to its request |

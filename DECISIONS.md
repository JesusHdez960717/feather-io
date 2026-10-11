# Design decisions

Why the service behaves the way it does where that is not obvious from the code, with the data
behind each number. When a decision changes, update it here.

## 1. Login attempt limit

`LoginRateLimiter` counts **failed** logins per IP. Every failure waits **1 second**
(`LOGIN_FAILURE_DELAY_MS`); **10 failures in a row** (`LOGIN_MAX_FAILURES`) lock the IP for **15
minutes** (`LOGIN_LOCK_SECONDS`, `429` with `Retry-After`), even if it then sends the right
credentials. A success clears the count, and failures older than 15 minutes stop counting.

| Decision                                                                                               | Why                                                                                                                                                                    |
|--------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| A 1 s delay per failure                                                                                | Costs nothing to a person who mistypes and limits brute force to ~1 attempt per second and connection                                                                  |
| A lock after 10 failures                                                                               | Stops parallel attacks, which the delay alone does not                                                                                                                 |
| The lock holds even with the right credentials                                                         | Otherwise an attacker would just wait for it to end and keep trying                                                                                                    |
| Only failures count, not every request                                                                 | A legitimate user who logs in often must never be locked (that's why Winter's general limiter isn't used here)                                                         |
| Constant-time comparison                                                                               | With `!=` the response time leaks how many characters match                                                                                                            |
| The IP is `request.clientIp(trustedProxies: TRUSTED_PROXIES)`; `X-Forwarded-For` is ignored by default | Any client can send that header with a fake IP. Behind your own proxies, declare how many there are, or every client shares the proxy's IP and one lock locks them all |

Limitations: the count lives in memory (per instance, cleared on restart), and a token already
issued stays valid during a lock (12 h).

## 2. General request limit

Winter's `RateLimiterFilter` is the **first global filter**: at most **2000 requests per IP every
60 s** (`RATE_LIMIT_REQUESTS`, `RATE_LIMIT_WINDOW_SECONDS`; `0` disables it), with the IP computed
as for the login. Above it the **S3 API answers `503 SlowDown`** (the S3 `<Error>`) and the **admin
API `429`**, both with `Retry-After`; every response carries `X-RateLimit-*`.

| Decision                                     | Why                                                                                                                                                        |
|----------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| A limit at all                               | Every request costs work (walking a folder, an md5, a write to SQLite); a few insistent clients without credentials could saturate the service             |
| First filter                                 | It stops a flood before reading bodies or checking signatures                                                                                              |
| Per IP, not per user                         | The attack that matters comes from whoever has no credentials                                                                                              |
| `503 SlowDown` on the S3 API                 | It is what S3 answers and what the AWS SDKs and CLI retry; with `429` the AWS CLI fails at once. The console goes through the admin API, which keeps `429` |
| An emergency brake, above any legitimate use | Clients retry after a few seconds while the window lasts a minute, so the limit can't act as a throttle: hitting it means failed requests                  |

**Why 2000.** S3 clients work in bursts, and what drives the request count is many small files in
parallel, not multipart (a 1 GiB file in 8 MiB parts is ~130 requests). Measured with a proxy in
front of the service:

| Scenario                                                  |      Requests | Peak in 1 s | Peak in 60 s |
|-----------------------------------------------------------|--------------:|------------:|-------------:|
| Every battery (AWS CLI, rclone and the 15 Mint suites)    | 1373 in 142 s |         125 |      **898** |
| `aws s3 sync` of 1000 small files (+ deleting the bucket) | 2004 in 108 s |         293 |     **1532** |

2000 leaves headroom over the worst case (1000 would break that `sync`) and still stops a script in
a loop. On a fast Linux server one machine with many parallel workers can exceed it (8 clients on
one IP saw `SlowDown` in `service/tool/benchmark/RESULTS.md`): for bulk loads raise it or disable
it; a higher limit for signed requests is under *After 1.0* in `ROADMAP.md`.

## 3. SigV4 signatures

| Decision                                                                                                                                   | Why                                                                                                                                   |
|--------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| A signature more than **15 minutes** from the server clock is `RequestTimeTooSkewed`, and the credential scope must be the signature's day | Without a window a captured signed request could be replayed forever. 15 minutes is what S3 uses and tolerates slightly skewed clocks |
| A presigned URL can't be dated in the future                                                                                               | It would last beyond the 7-day maximum                                                                                                |
| A signed body **sha256** is checked while reading (`XAmzContentSHA256Mismatch`), leaving the previous object untouched                     | Otherwise a captured request could be replayed with other content, or changed in transit over HTTP                                    |
| `UNSIGNED-PAYLOAD` and `aws-chunked` (`STREAMING-…`) bodies are not checked                                                                | The client doesn't sign the content in the first case; the second would need every chunk signature checked (*Parked*)                 |
| Authentication errors carry no internal details                                                                                            | An exception text can reveal the implementation                                                                                       |

## 4. Anonymous access

| Decision                                                                              | Why                                                                                                               |
|---------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| Multipart is never anonymous (create, parts, complete, abort, list uploads and parts) | With a write rule an anonymous client could list, replace parts of or abort other people's uploads                |
| No anonymous copies (CopyObject, UploadPartCopy) nor `response-*` overrides           | A copy reads a source that no rule may cover                                                                      |
| Multi-delete is never anonymous                                                       | Its keys come in the body and can't be checked against the rules before reading it                                |
| A rule without `*` is a prefix; with `*` the whole key must match                     | `public/` works like an S3 prefix; with `*` a pattern is meant, so `photos/*.jpg` doesn't open `photos/a.jpg.zip` |
| No limit of its own, only the general one per IP                                      | That already stops floods; a lower one would only matter for buckets published with many downloads                |

## 5. Access keys

| Decision                                                                                                                              | Why                                                                                                                                                                                                                                                                                                                     |
|---------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| The secret is stored **encrypted** (AES-256-GCM, key = sha256 of `KEYS_ENCRYPTION_SECRET`, the key id as associated data), not hashed | SigV4 needs the secret itself on every request. Encryption keeps a copy of the database (a backup) from giving the secrets away, and a secret copied onto another row doesn't decrypt                                                                                                                                   |
| `KEYS_ENCRYPTION_SECRET` is its own variable, not derived from `JWT_SECRET`                                                           | Rotating the JWT secret (logging everyone out) must not destroy every key. Changing `KEYS_ENCRYPTION_SECRET` does: the keys then have to be recreated                                                                                                                                                                   |
| The secret is shown **once** (create and regenerate)                                                                                  | A secret that can be read back can leak from the console's screen or logs                                                                                                                                                                                                                                               |
| Permissions **per bucket** (read, write or both) or one level on every bucket, not per prefix                                         | It is what clients need (a backup in its bucket, a website reading another); per-prefix access exists for anonymous rules                                                                                                                                                                                               |
| Only a key with write access to **every** bucket may create or delete buckets                                                         | A scoped key would otherwise create buckets it can't reach, or delete other people's                                                                                                                                                                                                                                    |
| Only the root key opens the console                                                                                                   | The console manages the keys: a key that could log in could raise its own permissions                                                                                                                                                                                                                                   |
| A disabled, expired or deleted key answers `403 InvalidAccessKeyId`                                                                   | As in AWS, it doesn't tell whether the key existed                                                                                                                                                                                                                                                                      |
| The anonymous rules of a bucket also apply to requests signed with a key, adding to its own permissions                               | As in AWS, a public prefix is public for everyone: clients that always sign (SDKs, rclone, the AWS CLI) can read public data with their key. The signature is still checked first, the key stays the principal, and the anonymous limits hold (no multipart, no multi-delete, ListBuckets only shows the key's buckets) |
| `last_used_at` is written at most once a minute per key                                                                               | A `sync` of thousands of files would otherwise write to SQLite on every request                                                                                                                                                                                                                                         |

## 6. Other security decisions

| Decision                                                                                                                           | Why                                                                                                                                                                                                                                                                |
|------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| JWTs must carry `exp`                                                                                                              | The service's expire in 12 h; a token without `exp`, forged with the secret, would never expire                                                                                                                                                                    |
| Keys can't contain `\`                                                                                                             | On Windows it is a folder separator: `a\b` would be another way to write `a/b` and could reach the folder marker                                                                                                                                                   |
| CORS accepts any origin, without credentials                                                                                       | Authentication is a header (JWT or SigV4), never a cookie, so another site can't act on the user's behalf                                                                                                                                                          |
| Presigned URLs use `PUBLIC_URL` when set (scheme, host and port, validated at start-up), otherwise the request's scheme and `Host` | Behind an HTTPS proxy the service sees `http`, and the `Host` comes from the client. The proxy must forward the original `Host`, which is part of the signature                                                                                                    |
| Objects are served with their own `Content-Type`, HTML included                                                                    | The service and the console always run on different origins (another port is another origin), so a script served by the service can't read the console's token. If they ever shared an origin, objects would have to be served as downloads with a restrictive CSP |

## 7. Localized error messages

Built on Winter's i18n (`winter/DECISIONS.md` §1). Languages: English and Spanish.

| Decision                                                                                                                                                                                | Why                                                                                                                                                                                                                                                       |
|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| The language is negotiated like the format: English by default, the one of `Accept-Language` when supported                                                                             | S3 clients don't send `Accept-Language`, so they get English as from AWS; the console sends the app's language. A browser opening an expired presigned URL also gets its language, the only visible difference with AWS                                   |
| Only the message is translated, never the code (`<Code>`, `code`)                                                                                                                       | Clients decide on the code; the message is only shown or logged                                                                                                                                                                                           |
| Translated errors carry `Vary: Accept-Language` (Winter adds it)                                                                                                                        | A proxy or CDN must not serve one language's error to another client                                                                                                                                                                                      |
| `slang`, from YAML (`en.i18n.yaml` as the base with the parameter types, `es.i18n.yaml`), generated and versioned                                                                       | Typed access (`intl.errors.s3.noSuchBucket(bucket: name)`), a missing key doesn't compile, the texts are compiled into the binary (nothing to copy into the `scratch` image), no `build_runner`. YAML because ARB has no nested keys and JSON no comments |
| Messages are read with the `intl` getter, in the language of the request in progress (Winter's `requestLocale`, a `Zone` per request), and become plain strings when the error is built | Most errors are thrown where there is no request (services, multipart, copy conditions); the zone gives them the language without passing it down through the layers                                                                                      |
| Log lines are in the request's language too                                                                                                                                             | The message is built once; the code and the route stay the same in every language                                                                                                                                                                         |
| `intl` is a getter and validators are built inside `validate()`                                                                                                                         | A `final` or `static` value would freeze the language of whoever evaluated it first                                                                                                                                                                       |

## 8. Errors: Problem Details

Every JSON error (admin API, and S3 API with `Accept: application/json`) is a Problem Details (RFC
9457, `application/problem+json`), Winter's format; the S3 API answers the S3 `<Error>` XML by
default.

| Decision                                                                                                                              | Why                                                                                                                   |
|---------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------|
| An `S3Exception` is a Problem Details whose `detail` is the message, plus the extensions `code` (S3) and `resource`                   | One format for every error, Winter's own included; clients show `detail` and decide on `code`, never translated       |
| A 422 is Winter's, with `violations` (`fieldName`, `message`, `code`, `params`), never the value                                      | The value is personal data or text the client already has; the `code` lets a client react without parsing the message |
| Bodies are read with `json.field<T>()`, and a wrong body is a 400 naming the field (`$.buckets[0]: expected an object, got a string`) | The developer of a client sees which field is wrong; the path never holds the value or a Dart type                    |
| On the S3 API a 413 is `EntityTooLarge` and a 429 `SlowDown`, as the S3 `<Error>`                                                     | S3 clients parse the XML and decide on its code                                                                       |
| The S3 `<Error>` carries `<RequestId>`, the id of the logs                                                                            | A client can report it and the log lines are found by it                                                              |
| An unexpected error is logged and answered with a fixed message, never its text                                                       | It can reveal paths and the implementation                                                                            |

## 9. OpenAPI of the admin API

| Decision                                                                                  | Why                                                                                                                                                |
|-------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| Only the admin API is documented (`/{admin}/openapi.json`, Swagger UI at `/{admin}/docs`) | The S3 API is documented by AWS, and its routes multiplex many operations by query and headers with XML bodies: a generated document would mislead |
| Both are public, like the login                                                           | They describe the API, never its data; the protected routes still need the JWT                                                                     |
| Bodies come from an `example` of each model, constraints from its `validate()`            | Nothing is written twice: the example goes through the same `toJson()` as a real response                                                          |

## 10. Logs

| Decision                                                                                                                | Why                                                                                                                                                        |
|-------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Readable lines by default, one JSON object per line with `LOG_FORMAT=json`; `LOG_LEVEL` (`info`)                        | Readable while developing; a log collector reads the JSON without parsing rules                                                                            |
| `LoggingFilter` runs after the rate limit, and skips successful health checks                                           | A rejected flood or a probe every few seconds doesn't flood the logs                                                                                       |
| Never the query string, bodies, tokens, secrets nor what was typed at login; failed logins and locks with the client IP | A presigned URL carries its signature in the query, and logs end up in more places than the service. The IP is what an operator needs to see a brute force |
| Services log changes of state (`info`) with ids in `fields`                                                             | Who deleted a bucket or created a key is the first question after an incident; the request id ties each line to its request                                |

## 11. SQLite

| Decision                                                                            | Why                                                                                                                                                                                                                                                    |
|-------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| WAL mode with `synchronous=NORMAL` (`AppDatabase._setUp`)                           | Every upload writes its metadata. With the defaults (rollback journal, `synchronous=FULL`) each write waited for several fsyncs: 189 PUTs/s of 1 KiB against 2037 in WAL (`service/tool/benchmark/RESULTS.md`). Readers don't wait for a writer either |
| What it gives up                                                                    | A crash of the process loses nothing; a power loss may lose the last writes, never corrupt the database. A lost row is rebuilt on the next read (the ETag from the file), so at worst the headers stored with those objects are lost                   |
| Two more files next to it (`-wal`, `-shm`)                                          | They are part of the database: back up the three with the service stopped, or use SQLite's own backup (`service/README.md`)                                                                                                                            |
| SQLite is bundled by the `sqlite3` package (build hooks), not taken from the system | The same SQLite on every platform, and nothing to install in the `scratch` image                                                                                                                                                                       |

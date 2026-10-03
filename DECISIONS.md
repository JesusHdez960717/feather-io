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

**What it does.** `RateLimitFilter` (`security/filter/`), registered as the **first global filter**
in `main.dart`, with Winter's `RateLimiter` (sliding window): at most **`RATE_LIMIT_REQUESTS`
requests (2000) per IP in each `RATE_LIMIT_WINDOW_SECONDS` window (60 s)**. Above that, the **S3 API
answers `503 SlowDown`** with the S3 `<Error>` (XML, or JSON with `Accept`), like S3, and the
**admin API `429`**; both with `Retry-After`. Every response carries `X-RateLimit-Limit`,
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

| Scenario                                                    |       Requests | Peak in 1 s | Peak in 60 s |
|-------------------------------------------------------------|---------------:|------------:|-------------:|
| Full batteries (AWS CLI, rclone and the 15 Mint suites)     | 1373 in 142 s  |         125 |      **898** |
| `aws s3 sync` of 1000 small files (+ deleting the bucket)   | 2004 in 108 s  |         293 |     **1532** |

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

| Client                                | With `429` (before)                                                           | With `503 SlowDown` (now)                                                                                                                       |
|---------------------------------------|-------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| AWS CLI v2 (`s3 sync` of 200 files)   | **Does not retry it**: 102 files fail at once with `Too Many Requests`        | **Retries it** (twice, waiting a few seconds), but with a 60 s window there is not enough time: the same 102 fail (`reached max retries: 2`)   |
| rclone (`copy` of 200 files)          | Retries it, very slowly                                                       | —                                                                                                                                               |

With `503 SlowDown` clients behave as they do with S3, but their retries wait seconds and the window
lasts a minute: **the limit does not act as a throttle**. That is why it must sit **above any
legitimate use**: it is an emergency brake against abuse.

**Careful when tuning it.** The measurements are on Windows, where every upload is slow (Defender,
SQLite). On a fast Linux server the same `sync` would go faster and could exceed 2000/min. If it is
deployed for massive loads (migrations, backups with many small files), measure and raise it, or
disable it for the IPs of those processes. Measuring it is under *After 1.0* in `ROADMAP.md`.

## 3. SigV4 signatures

| Decision                                                                                                                                         | Why                                                                                                                                                                                                                         |
|--------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| A signature more than **15 minutes** away from the server clock gives `RequestTimeTooSkewed` (and the credential must be from the signature's day) | Without a window, a captured signed request (over HTTP or in a proxy log) could be replayed forever: in the review, one signed 3 days earlier worked. 15 minutes is what S3 uses and tolerates slightly skewed clocks |
| A presigned URL cannot have a future date                                                                                                        | With a future date it lasted beyond the 7-day maximum                                                                                                                                                                      |
| If the client signs the **body's sha256**, it is checked (`XAmzContentSHA256Mismatch`)                                                           | Otherwise a captured request could be replayed **with other content**, and over HTTP someone in the middle could change it. It is checked while reading, without loading the body in memory, and the previous object is left untouched if it fails |
| `UNSIGNED-PAYLOAD` and `aws-chunked` (`STREAMING-…`) bodies are not checked                                                                      | In the first case the client does not sign the content; in the second each chunk's signature would have to be validated. It stays under *Parked* (checksum validation)                                                    |
| Authentication errors give no internal details                                                                                                   | An exception message can reveal the implementation                                                                                                                                                                         |

## 4. Anonymous access

| Decision                                                                                                    | Why                                                                                                                                                                                                                                  |
|-------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Multipart is never anonymous (create, parts, complete, abort, list uploads and parts)                       | With a write rule, an anonymous client could list other people's uploads in progress, replace their parts or abort them. The operations that go through routes accepting anonymous rules (PUT, DELETE, GET) require the upload permission explicitly |
| An anonymous client cannot copy (CopyObject, UploadPartCopy) nor change the response headers (`response-*`) | Copying reads the source, which may not be covered by any rule                                                                                                                                                                     |
| Multi-delete is never anonymous                                                                             | Its keys come in the body and cannot be checked against the rules before reading it                                                                                                                                                |
| A rule without `*` is a prefix; with `*`, the whole key has to match                                        | `public/` covers everything that starts that way, like an S3 prefix. With `*` a pattern is meant: before, `photos/*.jpg` also opened `photos/copy.jpg.zip`. Rules without `*` keep their meaning. The console explains it next to the field |
| Anonymous traffic has no limit of its own, only the general one per IP                                      | The general limit already stops floods, anonymous ones included. A lower one is only needed if buckets are published on the internet with many downloads                                                                          |

## 5. Other security decisions

| Decision                                                                                                    | Why                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
|-------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| JWTs must carry `exp`                                                                                       | The ones the service issues always expire (12 h); a token without `exp` (forged with the secret) would never expire                                                                                                                                                                                                                                                                                                                                                      |
| Keys cannot contain `\`                                                                                     | On Windows it is a folder separator: `a\b` was another way to write `a/b` and allowed writing the folder marker                                                                                                                                                                                                                                                                                                                                                          |
| CORS accepts any origin, without credentials                                                                | Authentication goes in the `Authorization` header (JWT or SigV4), not in cookies: another site cannot make requests on the user's behalf                                                                                                                                                                                                                                                                                                                                |
| Presigned URLs use `PUBLIC_URL` when it is set (otherwise the scheme and `Host` of the request)             | Behind an HTTPS proxy the service sees `http` and the URLs came out with `http://`; and the client sends the `Host`, so it could point to another domain. Only scheme, host and port (the path is part of the signature), and it is validated at startup. The proxy must forward the original `Host`, which is also part of the signature                                                                                                                              |
| Objects are served with their `Content-Type`, including HTML/JS uploaded by an anonymous client with write permission | **The service and the console always run as separate services, on different ports.** A different port is already another *origin* for the browser: a script served by the service cannot read the console's `localStorage` or its token. Cookies are not separated by port, but none are used (see the CORS row). **If they ever shared an origin** (same domain and port behind a proxy), that content would have to be served as a download (`Content-Disposition: attachment` and a restrictive CSP) |

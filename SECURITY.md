# Security

## Reporting a vulnerability

Please **don't open a public issue**. Report it privately through GitHub: the repository's
**Security** tab → **Report a vulnerability**. Include what is affected (service or console, and
the version or commit), how to reproduce it and what an attacker gains.

You'll get an answer within a week. Once it is fixed, the advisory is published with credit to you,
unless you'd rather not.

## Supported versions

Only the latest release gets security fixes (today `1.0.0-rc.1`).

## Security model

What the service protects and how; the reasons and the data behind each decision are in
[`DECISIONS.md`](DECISIONS.md).

**Authentication**

- The console logs in with the root key (`FEATHER_ACCESS` / `FEATHER_SECRET`) and gets a JWT that
  expires in 12 hours; tokens without an expiry are rejected. The admin API accepts only that JWT.
- S3 clients sign with AWS SigV4, with the root key or with managed access keys. A signature more
  than 15 minutes away from the server clock is rejected (no replay of captured requests), and a
  signed body sha256 is checked against the body. Presigned URLs last at most 7 days.
- Failed logins wait 1 second each, and 10 in a row lock the client IP for 15 minutes, even with
  the right credentials afterward. Credentials are compared in constant time.
- A general rate limit per IP (2000 requests per minute by default) stops floods before any work is
  done.

**Authorization**

- Access keys get read, write or both, per bucket or on every bucket, and may expire. Their secrets
  are stored encrypted (AES-256-GCM, key derived from `KEYS_ENCRYPTION_SECRET`) and shown only once.
  A disabled, expired or unknown key answers `InvalidAccessKeyId`, without saying which.
- Managed keys can't log in to the console, so a key can't raise its own permissions.
- Anonymous access is opt-in per bucket prefix or pattern. Anonymous clients can never use
  multipart, multi-delete or copies.

**Data and errors**

- Every bucket name and key is validated before touching the filesystem (no path traversal, no
  `\` that Windows would read as a separator).
- Errors never include internal details (paths, exception texts); unexpected ones are logged with a
  request id and answered generically. Logs never contain query strings (presigned URLs carry their
  signature there), bodies, tokens or secrets.
- CORS accepts any origin without credentials: authentication is a header, never a cookie.

## Deploying it safely

- **TLS**: the service speaks HTTP. Put it behind a proxy that terminates TLS, and set `PUBLIC_URL`
  (so presigned URLs use `https://`) and `TRUSTED_PROXIES` (so rate limits see the client IP, not
  the proxy's). The proxy must forward the original `Host`, which is part of the signatures.
- **Secrets**: use long random values for `FEATHER_SECRET`, `JWT_SECRET` and
  `KEYS_ENCRYPTION_SECRET` (e.g. `openssl rand -hex 32`) and keep them out of the repository.
  Rotating `JWT_SECRET` logs everyone out; changing `KEYS_ENCRYPTION_SECRET` makes the stored access
  keys unusable.
- **Separate origins**: serve the service and the console on different origins (another port or
  domain). Objects are served with their own `Content-Type`, so an HTML file uploaded through an
  anonymous write rule must never run on the console's origin.
- **Backups** of the volume hold the objects and the database, with the access keys' secrets
  encrypted; protect them like the data itself.

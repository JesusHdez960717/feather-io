# Changelog

## 1.0.0-rc.1 (2026-10-10)

First release candidate of the web console.

- **Browser**: buckets and folders in list or grid view, paging, search and filters by type, size
  and date, previews, details, create folders, rename and move, delete, share links (1 hour, 1 day
  or 7 days) and zip downloads. The bucket, folder and view live in the URL.
- **Transfers**: uploads (drag & drop, multipart over 16 MiB) and downloads in a background queue
  that keeps going across folders, buckets and sections, with progress, cancel and retry.
- **Buckets**: create, edit (description and color), details and statistics, anonymous access rules,
  empty and delete.
- **Access keys**: create keys per bucket or for every bucket with an expiry, enable and disable,
  regenerate the secret (shown once).
- Session kept across reloads, the browser's password manager at login, English and Spanish, and a
  Docker image on nginx configured from the container's environment.
- The Feather IO icon ([`docs/brand.md`](../docs/brand.md)) as favicon, web icons and on the
  splash.

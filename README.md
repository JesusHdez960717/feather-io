# Feather-io

S3-compatible storage system.

## API architecture

The backend service exposes two interfaces:

* **S3 API**: compatible with the S3 protocol.
* **Admin API**: internal management of the system (through `ADMIN_PREFIX`).

> **Important**: admin routes start with `_` (e.g. `_admin`) so they don't collide with S3 bucket
> names.

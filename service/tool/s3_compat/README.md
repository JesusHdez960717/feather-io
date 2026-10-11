# S3 compatibility tests

Real S3 clients, in Docker, against a running feather-io. They are not part of `dart test`: run
them by hand before a release or after touching the S3 API.

| Target   | What it is                                                                                                                                 |
|----------|--------------------------------------------------------------------------------------------------------------------------------------------|
| `awscli` | `awscli.sh` with the `amazon/aws-cli` image (current CLI v2: `aws-chunked` chunk signing with CRC32, multipart, ranges, `sync`, presign…). |
| `rclone` | `rclone.sh` with the `rclone/rclone` image: `copy`, `sync`, `check` by md5 (ETag), multipart, `cat` with ranges, `purge`…                  |
| `mint`   | [MinIO Mint](https://github.com/minio/mint) (`minio/mint` image, from 2024): the AWS and MinIO SDK suites, s3cmd and mc.                   |

## Usage

Start the service (see `service/README.md`) with `FEATHER_ACCESS=feather-access` and
`FEATHER_SECRET=feather-secret-key` (the defaults of `run.sh`; `mc` rejects a secret key shorter
than 8 characters) and, from the repo root:

```bash
service/tool/s3_compat/run.sh          # awscli and rclone
service/tool/s3_compat/run.sh mint     # Mint (about 5 min)
MINT_SUITES="minio-go s3cmd" service/tool/s3_compat/run.sh mint            # only some suites
```

Other keys go in `ACCESS_KEY`/`SECRET_KEY` (`FEATHER_ACCESS`/`FEATHER_SECRET`). `ENDPOINT` (by default
`http://host.docker.internal:8080`) is the service as seen from the containers. Each step prints
`PASS` or `FAIL` (with the error output) and the script exits with an error if anything fails. The
output of each target is saved in `out/` (`awscli.txt`, `rclone.txt`, `mint.txt` and
`mint-logs/log.json`; another folder with `OUT_DIR`), which is not committed.

Check the service log too: clients retry, so a 500 error may not show in the battery but does on
the server (`[ERROR] Unhandled error`).

## Results summary

`report.py` writes [`RESULTS.md`](RESULTS.md) from `out/` (plus the `dart test` JSON and the static
analyses): the totals of each battery and only what fails, with its cause for Mint. The full
procedure, step by step, is in *Full test run* in `CLAUDE.md`.

```bash
python service/tool/s3_compat/report.py --server-log <service log>
```

The details of the last full run are in [`RESULTS.md`](RESULTS.md). Out of scope (see *Parked* in
`ROADMAP.md`): SigV2, POST policy, validating sha256/checksums, versioning, tags, notifications,
S3 Select, retention/object lock, MinIO's own APIs and keys with characters the filesystem doesn't
support.

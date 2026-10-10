# Performance benchmarks

How fast feather-io is, where its limits are and what would move them, measured with MinIO's
[warp](https://github.com/minio/warp). The results are in [`RESULTS.md`](RESULTS.md).

feather-io is a lightweight storage (a bucket of a thousand objects is already a big one for it):
these benchmarks describe that range and a bit beyond, not a race with storage built for millions
of objects.

## What runs

- The service from its own Docker image (AOT, on Linux, data in a Docker volume) and warp in
  another container of the same network, with the general rate limit off.
- Objects: PUT and GET of 1 KiB, 1 MiB and 16 MiB with 8 clients; PUT of 1 MiB with 1 and 32
  clients; HEAD; a mixed load (GET, HEAD, PUT, DELETE); multipart uploads of 64 MiB.
- Listings in buckets of 100, 1000, 5000 and 10000 objects (`LIST_SIZES`), and ListBuckets
  timed after each one with every object stored so far (`list_buckets.py`).
- A flat bucket of 10000 objects (every one at its root) listed by `list_flat.py`: warp can't
  measure it (with `--noprefix` it counts errors, also against MinIO).
- The memory of the server, sampled every 2 s during each scenario.
- The same scenarios against MinIO (`elestio/minio`: MinIO no longer publishes its images on
  Docker Hub) as a reference.
- `limited`: a mixed load with the default general limit (2000 requests/min per IP).

## Running it

Docker Desktop must be running. From the repo root:

```bash
docker build -t feather-io service/
service/tool/benchmark/run.sh feather minio limited    # ~25 min
python service/tool/benchmark/report.py                 # rewrites RESULTS.md
```

`DURATION` (20 s by default) sets how long each scenario runs, `LIST_SIZES` the buckets of the
listings, and `ONLY` (a regular expression) runs only the matching scenarios, keeping the other
outputs (`ONLY=list-flat run.sh feather`). The outputs go to `out/` (gitignored). The reading of the numbers (summary, limits and
improvements) is written by hand in the constants of `report.py`: review it when a run changes the
picture.

Docker Desktop on Windows or macOS runs the containers in a Linux VM: the absolute numbers depend
on the machine, so compare runs of the same machine, and feather-io with MinIO within one run.

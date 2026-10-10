# Performance results

Run on **2026-10-09** on commit `7452639` (`feature/poc`) with uncommitted changes, on Windows 11 with Docker Desktop: the service runs from its own image (`docker build -t feather-io service/`, AOT on a Linux container, data in a Docker volume) and [warp](https://github.com/minio/warp) runs in another container of the same network. Generated with `service/tool/benchmark/report.py`; to repeat it, see the README of this folder.

**feather-io is a lightweight storage**: a bucket of a thousand objects is already a big one for it. These numbers say how it behaves within that size, where its limits are, and what would move them; they are not a goal of competing with storage built for millions of objects. MinIO (`elestio/minio:latest`) runs the same scenarios on the same machine as a reference of a server built for that.

The general rate limit is off in every scenario (`RATE_LIMIT_REQUESTS=0`) except in [the limited one](#4-with-the-default-rate-limit), so the numbers are the server's.

## Summary

- **Within its size, it is fast enough and light.** With buckets of up to a thousand objects every operation answers in milliseconds: a listing page in ~60 ms, a HEAD in ~2 ms, a GET of 1 MiB in ~11 ms. The process starts with **12 MiB** of memory and its peak in the whole run was **394 MiB**, against MinIO's 126 MiB and 1.5 GiB.
- **Medium transfers are close to MinIO, big single uploads are not.** PUT of 1 MiB with 8 clients goes at the same speed (130 vs 132 MiB/s), with 32 clients it is faster (106 vs 86 MiB/s), and multipart reaches 116 vs 145 MiB/s; but a PUT of 16 MiB stays at 113 MiB/s against 477, about the speed of one stream. Reads are about half: 739 vs 1303 MiB/s with 1 MiB objects.
- **The fixed cost of each request is what separates it from MinIO**: 189 PUTs/s of 1 KiB against 1040 (5.5x), and 2305 GETs/s against 7629 (3.3x). An upload creates a temporary file, computes the md5, renames it and writes its metadata to SQLite, which is opened with its defaults (a rollback journal and `synchronous=FULL`: several fsyncs per upload).
- **Listing gets slower with the size of the bucket, not of the page.** Each page walks the whole bucket and reads the metadata (`stat`) of every file before keeping 100 keys: a page costs ~0.05 ms per object in the bucket, ~60 ms with 1000 objects and ~500 ms with 10 000 (MinIO stays at ~30 ms). ListBuckets walks every object of every bucket: ~1 s with 16 000 objects in total.
- **The default rate limit (2000 requests/min per IP) caps one machine at ~33 requests/s.** With 8 clients sharing an IP, 98 requests failed in a minute even after the SDK retries. It is the emergency brake it was designed to be (`DECISIONS.md` §2), not a throttle: a bulk load from one machine needs it raised.

## 1. Objects

Throughput (MiB/s and operations per second) and latency of each request (median and 99th percentile).

| Scenario | What it measures | feather-io | MinIO | feather p50 / p99 | MinIO p50 / p99 |
|---|---|---:|---:|---:|---:|
| `put-1KiB` | PutObject of 1 KiB, 8 clients: the cost of each request (md5, temp file, rename, SQLite) | 189 ops/s | 1.0 MiB/s (1,040 ops/s) | 40.5 / 64.1 ms | 7.1 / 23.0 ms |
| `put-1MiB` | PutObject of 1 MiB, 8 clients | 130 MiB/s (130 ops/s) | 132 MiB/s (132 ops/s) | 56.6 / 118 ms | 40.0 / 137 ms |
| `put-16MiB` | PutObject of 16 MiB, 8 clients: streaming to disk | 113 MiB/s (7.1 ops/s) | 477 MiB/s (29.8 ops/s) | 841 / 2,449 ms | 740 / 954 ms |
| `get-1KiB` | GetObject of 1 KiB, 8 clients, 1000 objects | 2.2 MiB/s (2,305 ops/s) | 7.5 MiB/s (7,629 ops/s) | 3.0 / 9.6 ms | 1.0 / 3.1 ms |
| `get-1MiB` | GetObject of 1 MiB, 8 clients, 200 objects | 739 MiB/s (739 ops/s) | 1,303 MiB/s (1,303 ops/s) | 11.0 / 20.3 ms | 5.1 / 14.6 ms |
| `get-16MiB` | GetObject of 16 MiB, 8 clients, 40 objects | 1,087 MiB/s (67.9 ops/s) | 2,298 MiB/s (144 ops/s) | 114 / 160 ms | 53.3 / 75.3 ms |
| `put-1MiB-c1` | PutObject of 1 MiB, 1 client | 73.1 MiB/s (73.1 ops/s) | 84.8 MiB/s (84.8 ops/s) | 12.1 / 30.8 ms | 11.5 / 20.7 ms |
| `put-1MiB-c32` | PutObject of 1 MiB, 32 clients | 106 MiB/s (106 ops/s) | 86.2 MiB/s (86.2 ops/s) | 238 / 1,340 ms | 447 / 811 ms |
| `stat` | HeadObject, 8 clients, 1000 objects | 3,604 ops/s | 8,998 ops/s | 2.4 / 5.5 ms | 0.8 / 2.3 ms |
| `mixed` | A mixed load (45% GET, 30% HEAD, 15% PUT, 10% DELETE) of 1 MiB, 8 clients | 252 MiB/s (420 ops/s) | 337 MiB/s (561 ops/s) | — | — |
| `multipart` | Multipart uploads of 64 MiB (8 parts of 8 MiB), 2 uploads at once | 116 MiB/s (14.5 ops/s) | 145 MiB/s (18.1 ops/s) | 406 / 482 ms | 770 / 1,668 ms |

The mixed load, by operation (feather-io):

| Operation | ops/s | p50 | p99 |
|---|---:|---:|---:|
| GET | 189 | 18.9 ms | 41.6 ms |
| STAT | 126 | 7.6 ms | 24.1 ms |
| PUT | 63.1 | 36.2 ms | 65.2 ms |
| DELETE | 41.9 | 14.4 ms | 37.0 ms |

## 2. Listings and bucket size

Each listing page (100 keys) walks the whole bucket, so its cost grows with the objects of the bucket, not with the page. ListBuckets walks every object of every bucket to give their counts and sizes: it is timed after each listing scenario, with every object stored so far.

Each warp client lists its own prefix of the bucket from start to end (N / 8 objects, by pages of 100 keys). The time of a page is the median time of that whole listing divided by its pages.

| Objects in the bucket | feather-io objects listed/s | MinIO objects listed/s | feather-io per page | MinIO per page |
|---:|---:|---:|---:|---:|
| 100 | 10,397 | 46,100 | 9.8 ms | 2.1 ms |
| 1,000 | 8,620 | 48,501 | 57.0 ms | 10.0 ms |
| 5,000 | 2,673 | 51,941 | 268 ms | 14.0 ms |
| 10,000 | 1,517 | 37,445 | 507 ms | 28.3 ms |

| Buckets | Objects in total | ListBuckets (average) |
|---:|---:|---:|
| 2 | 104 | 16.3 ms |
| 3 | 1,104 | 86.2 ms |
| 4 | 6,104 | 376 ms |
| 5 | 16,104 | 1,006 ms |

## 3. Memory

The RSS of the server's process (what it takes from the machine), sampled every 2 s. The scenarios run one after the other on the same process, and a heap that grew is not given back at once, so the peak of the run is reached in one scenario and carried to the next.

| Server | At start | With small objects (`put-1KiB`) | Peak of the run |
|---|---:|---:|---:|
| feather-io | 12.1 MiB | 53.4 MiB | 394 MiB (`multipart`) |
| MinIO | 126 MiB | 339 MiB | 1,483 MiB (`list-1000`) |

## 4. With the default rate limit

A mixed load of 64 KiB objects from 8 clients for 60 s, with the default general limit (2000 requests per minute per IP). Every warp client shares one IP, as a backup tool on one machine would.

| Operation | ops/s | Errors |
|---|---:|---:|
| DELETE | 1.9 | 6 |
| GET | 8.8 | 48 |
| PUT | 2.9 | 14 |
| STAT | 5.8 | 30 |
| Total | 19.2 | 98 |

## 5. Limits

- **Objects per bucket.** Up to ~1000 objects the console browses without noticing; at 5000 a page takes ~0.3 s and at 10 000 ~0.5 s; by extrapolation, 100 000 objects would be ~5 s per page, and listing a whole bucket that size (1000 pages) more than an hour. The size of the objects doesn't matter, their number does.
- **Objects in the whole storage.** ListBuckets (the console's bucket list, and every S3 client that starts with `ls`) costs ~0.06 ms per stored object: 1 s with 16 000, ~6 s with 100 000.
- **Small files.** ~190 uploads/s of 1 KiB with 8 clients (~40 ms each): a `sync` of 10 000 small files takes about a minute.
- **One machine at a time.** With the default rate limit a client of many parallel workers on one IP gets `SlowDown` above 2000 requests/min.
- **Memory grows with concurrency and big objects and is not given back:** ~50 MiB with small objects, ~150 MiB with 1 MiB objects, ~400 MiB at the peak (multipart and 32 clients). It is the Dart heap keeping what it reached; plan ~512 MiB for a container.

## 6. What would improve it

- **Listing only what the page needs (biggest gain, little code).** Read the metadata (`stat`) of the objects of the page only, not of every file of the bucket; with a delimiter (the console always sends `/`) walk only the directory of the prefix instead of the whole bucket, since a folder is a directory. A folder of the console would then cost what is in it, not what the bucket holds.
- **SQLite in WAL mode with `synchronous=NORMAL`** (a `PRAGMA` when the database opens): one write per upload instead of several fsyncs, the usual way to speed up small writes without losing durability against a crash of the process.
- **ListBuckets from the database.** The object count and size of each bucket can come from the `object_meta` table (a `SUM`/`COUNT` grouped by bucket) instead of walking the disk; the walk is still needed when files change outside the service, so it could become a periodic reconciliation.
- **An index of keys** (the `object_meta` table already has one row per object) would make a listing page a query `WHERE key > ? ORDER BY key LIMIT 100`: constant per page, whatever the size of the bucket. It is the change that takes it to hundreds of thousands of objects, at the price of keeping the table as the source of truth of what exists.
- **Big single uploads.** A PUT of 16 MiB with 8 clients stays at ~115 MiB/s (MinIO: 477), while multipart (the same bytes in 8 MiB parts) gets about as much with 2 uploads: worth profiling the write path (the md5 computed in Dart over every chunk, the size of the chunks written) before changing it.
- **The rate limit for signed requests.** The limit exists against clients without credentials (`DECISIONS.md` §2); requests signed with a valid key, or with the JWT, could have a higher limit (or none), so a backup or a migration doesn't need the global one raised.

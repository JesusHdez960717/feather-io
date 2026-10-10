# Performance results

Run on **2026-10-09** on commit `ea0dc7b` (`feature/poc`) with uncommitted changes, on Windows 11 with Docker Desktop: the service runs from its own image (`docker build -t feather-io service/`, AOT on a Linux container, data in a Docker volume) and [warp](https://github.com/minio/warp) runs in another container of the same network. Generated with `service/tool/benchmark/report.py`; to repeat it, see the README of this folder.

**feather-io is a lightweight storage**: a bucket of a thousand objects is already a big one for it. These numbers say how it behaves within that size, where its limits are, and what would move them; they are not a goal of competing with storage built for millions of objects. MinIO (`elestio/minio:latest`) runs the same scenarios on the same machine as a reference of a server built for that.

The general rate limit is off in every scenario (`RATE_LIMIT_REQUESTS=0`) except in [the limited one](#4-with-the-default-rate-limit), so the numbers are the server's.

## Summary

- **Within its size, it is fast and light.** With buckets of up to a few thousand objects every operation answers in milliseconds: a listing page in ~25 ms, a HEAD in ~2 ms, a GET of 1 MiB in ~10 ms. The process starts with **12 MiB** of memory and its peak in the whole run was **414 MiB**, against MinIO's 126 MiB and 1.5 GiB.
- **Uploads are as fast as MinIO or faster**, since SQLite runs in WAL mode: 2037 PUTs/s of 1 KiB (MinIO 1040), and 159 vs 132 MiB/s with 1 MiB objects; with 32 clients 136 vs 86 MiB/s. The exception is a big single upload: a PUT of 16 MiB reaches 147 MiB/s against 477.
- **Reads carry a fixed cost per request**: 2047 GETs/s of 1 KiB against 7629 (3.7x), and about half the throughput with 1 MiB objects (691 vs 1303 MiB/s). Each GET looks up the metadata in SQLite and checks the file's size and date.
- **A listing page costs what its folder holds, no longer what the bucket holds.** A page walks only the folder of the prefix (one level with the delimiter `/`, the console's) and reads the metadata of its own 100 keys only: 25 ms with 1000 objects, 67 ms with 10 000 (MinIO 10 and 28 ms), and ~50 ms in a flat bucket of 10 000 objects listed from its root. ListBuckets still walks every object of every bucket: ~1 s with 16 000 objects in total.
- **The default rate limit (2000 requests/min per IP) caps one machine at ~33 requests/s.** With 8 clients sharing an IP, 98 requests failed in a minute even after the SDK retries. It is the emergency brake it was designed to be (`DECISIONS.md` §2), not a throttle: a bulk load from one machine needs it raised.

## What changed

The first run found the bottlenecks; these are the numbers of the same scenarios before and after each change.

| Change | Scenario | Before | After |
|---|---|---:|---:|
| SQLite in WAL mode with `synchronous=NORMAL` | PUT of 1 KiB, 8 clients | 189 ops/s | 2037 ops/s |
|  | PUT of 1 MiB with 1 / 8 / 32 clients | 73 / 130 / 106 MiB/s | 108 / 159 / 136 MiB/s |
|  | PUT of 16 MiB, 8 clients | 113 MiB/s | 147 MiB/s |
|  | Mixed load, 8 clients | 420 ops/s | 518 ops/s |
| Listings walk only the folder of the prefix and `stat` only the page | A page in a bucket of 1000 / 10 000 objects | 57 / 507 ms | 25 / 67 ms |
|  | A page of a flat bucket of 10 000 objects (from its root) | ~500 ms | ~50 ms |

## 1. Objects

Throughput (MiB/s and operations per second) and latency of each request (median and 99th percentile).

| Scenario | What it measures | feather-io | MinIO | feather p50 / p99 | MinIO p50 / p99 |
|---|---|---:|---:|---:|---:|
| `put-1KiB` | PutObject of 1 KiB, 8 clients: the cost of each request (md5, temp file, rename, SQLite) | 2.0 MiB/s (2,037 ops/s) | 1.0 MiB/s (1,040 ops/s) | 4.3 / 13.4 ms | 7.1 / 23.0 ms |
| `put-1MiB` | PutObject of 1 MiB, 8 clients | 159 MiB/s (159 ops/s) | 132 MiB/s (132 ops/s) | 49.1 / 74.6 ms | 40.0 / 137 ms |
| `put-16MiB` | PutObject of 16 MiB, 8 clients: streaming to disk | 147 MiB/s (9.2 ops/s) | 477 MiB/s (29.8 ops/s) | 861 / 1,000 ms | 740 / 954 ms |
| `get-1KiB` | GetObject of 1 KiB, 8 clients, 1000 objects | 2.0 MiB/s (2,047 ops/s) | 7.5 MiB/s (7,629 ops/s) | 3.4 / 10.6 ms | 1.0 / 3.1 ms |
| `get-1MiB` | GetObject of 1 MiB, 8 clients, 200 objects | 691 MiB/s (691 ops/s) | 1,303 MiB/s (1,303 ops/s) | 10.3 / 21.4 ms | 5.1 / 14.6 ms |
| `get-16MiB` | GetObject of 16 MiB, 8 clients, 40 objects | 1,043 MiB/s (65.2 ops/s) | 2,298 MiB/s (144 ops/s) | 118 / 147 ms | 53.3 / 75.3 ms |
| `put-1MiB-c1` | PutObject of 1 MiB, 1 client | 108 MiB/s (108 ops/s) | 84.8 MiB/s (84.8 ops/s) | 8.5 / 17.4 ms | 11.5 / 20.7 ms |
| `put-1MiB-c32` | PutObject of 1 MiB, 32 clients | 136 MiB/s (136 ops/s) | 86.2 MiB/s (86.2 ops/s) | 231 / 304 ms | 447 / 811 ms |
| `stat` | HeadObject, 8 clients, 1000 objects | 3,523 ops/s | 8,998 ops/s | 2.0 / 7.2 ms | 0.8 / 2.3 ms |
| `mixed` | A mixed load (45% GET, 30% HEAD, 15% PUT, 10% DELETE) of 1 MiB, 8 clients | 310 MiB/s (518 ops/s) | 337 MiB/s (561 ops/s) | — | — |
| `multipart` | Multipart uploads of 64 MiB (8 parts of 8 MiB), 2 uploads at once | 120 MiB/s (15.1 ops/s) | 145 MiB/s (18.1 ops/s) | 390 / 428 ms | 770 / 1,668 ms |

The mixed load, by operation (feather-io):

| Operation | ops/s | p50 | p99 |
|---|---:|---:|---:|
| GET | 232 | 18.9 ms | 36.1 ms |
| STAT | 156 | 3.7 ms | 10.3 ms |
| PUT | 78.0 | 30.8 ms | 49.4 ms |
| DELETE | 52.1 | 4.8 ms | 12.8 ms |

## 2. Listings and bucket size

A listing page walks the folder of its prefix (one level with the delimiter `/`) and reads the metadata of its own keys only, so its cost grows with what that folder holds. ListBuckets walks every object of every bucket to give their counts and sizes: it is timed after each listing scenario, with every object stored so far.

Each warp client lists its own prefix of the bucket from start to end (N / 8 objects, by pages of 100 keys). The time of a page is the median time of that whole listing divided by its pages.

| Objects in the bucket | feather-io objects listed/s | MinIO objects listed/s | feather-io per page | MinIO per page |
|---:|---:|---:|---:|---:|
| 100 | 11,512 | 46,100 | 7.9 ms | 2.1 ms |
| 1,000 | 19,390 | 48,501 | 25.0 ms | 10.0 ms |
| 5,000 | 15,594 | 51,941 | 44.4 ms | 14.0 ms |
| 10,000 | 11,555 | 37,445 | 67.2 ms | 28.3 ms |

The worst case, a flat bucket (every object at its root), listed by `list_flat.py` against feather-io (warp can't measure it):

| Objects at the root | One page with `/` | One page without delimiter | The whole bucket |
|---:|---:|---:|---:|
| 10,000 | 51.1 ms | 45.0 ms | 5.4 s (100 pages) |

| Buckets | Objects in total | ListBuckets (average) |
|---:|---:|---:|
| 2 | 104 | 15.0 ms |
| 3 | 1,104 | 74.1 ms |
| 4 | 6,104 | 401 ms |
| 5 | 16,104 | 1,047 ms |

## 3. Memory

The RSS of the server's process (what it takes from the machine), sampled every 2 s. The scenarios run one after the other on the same process, and a heap that grew is not given back at once, so the peak of the run is reached in one scenario and carried to the next.

| Server | At start | With small objects (`put-1KiB`) | Peak of the run |
|---|---:|---:|---:|
| feather-io | 12.4 MiB | 69.2 MiB | 414 MiB (`multipart`) |
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

- **Objects per folder.** A page costs what its folder holds: ~5 ms per thousand objects in it (~50 ms with 10 000 at one level). A bucket organized in folders scales with the size of each folder, not of the bucket; listing a whole flat bucket of 10 000 objects takes ~5 s (100 pages), and of 100 000 objects about 9 minutes by extrapolation, since every page walks the folder again.
- **Objects in the whole storage.** ListBuckets (the console's bucket list, and every S3 client that starts with `ls`) costs ~0.06 ms per stored object: 1 s with 16 000, ~6 s with 100 000.
- **Reads of small objects.** ~2000 GETs/s of 1 KiB with 8 clients, a third of MinIO.
- **One machine at a time.** With the default rate limit a client of many parallel workers on one IP gets `SlowDown` above 2000 requests/min.
- **Memory grows with concurrency and big objects and is not given back:** ~70 MiB with small objects, ~150 MiB with 1 MiB objects, ~400 MiB at the peak (multipart and 32 clients). It is the Dart heap keeping what it reached; plan ~512 MiB for a container.

## 6. What would improve it

- **ListBuckets from the database.** The object count and size of each bucket can come from the `object_meta` table (a `SUM`/`COUNT` grouped by bucket) instead of walking the disk; the walk is still needed when files change outside the service, so it could become a periodic reconciliation.
- **An index of keys** (the `object_meta` table already has one row per object) would make a listing page a query `WHERE key > ? ORDER BY key LIMIT 100`: constant per page, whatever the size of the folder. It is the change that takes it to hundreds of thousands of objects, at the price of keeping the table as the source of truth of what exists.
- **Big single uploads.** A PUT of 16 MiB with 8 clients stays at ~150 MiB/s (MinIO: 477), while multipart (the same bytes in 8 MiB parts) gets about as much with 2 uploads: worth profiling the write path (the md5 computed in Dart over every chunk, the size of the chunks written) before changing it.
- **Reads.** A GET checks the metadata in SQLite and the file's size and date on every request; caching it in memory for the hot objects would cut the fixed cost of small reads.
- **The rate limit for signed requests.** The limit exists against clients without credentials (`DECISIONS.md` §2); requests signed with a valid key, or with the JWT, could have a higher limit (or none), so a backup or a migration doesn't need the global one raised.

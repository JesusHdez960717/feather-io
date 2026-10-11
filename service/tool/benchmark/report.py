#!/usr/bin/env python3
"""Writes RESULTS.md from the outputs of run.sh.

Usage (from the repo root):

    python service/tool/benchmark/report.py [--out DIR]

Reads from --out (service/tool/benchmark/out by default) one folder per target (feather, minio,
limited) with warp's summary of each scenario (<scenario>.txt), the memory of the server while it
ran (<scenario>.mem) and, for feather, the ListBuckets timings (listbuckets.txt).

What is kept by hand lives in the constants below: what each scenario measures (SCENARIOS) and the
reading of the numbers (FINDINGS, LIMITS, IMPROVEMENTS), written after looking at a run. Update them
when a run changes the picture.
"""
import argparse
import datetime
import platform
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
from md_tables import align_tables  # noqa: E402

# (scenario, what it measures)
SCENARIOS = [
    ('put-1KiB', 'PutObject of 1 KiB, 8 clients: the cost of each request (md5, temp file, rename, SQLite)'),
    ('put-1MiB', 'PutObject of 1 MiB, 8 clients'),
    ('put-16MiB', 'PutObject of 16 MiB, 8 clients: streaming to disk'),
    ('get-1KiB', 'GetObject of 1 KiB, 8 clients, 1000 objects'),
    ('get-1MiB', 'GetObject of 1 MiB, 8 clients, 200 objects'),
    ('get-16MiB', 'GetObject of 16 MiB, 8 clients, 40 objects'),
    ('put-1MiB-c1', 'PutObject of 1 MiB, 1 client'),
    ('put-1MiB-c32', 'PutObject of 1 MiB, 32 clients'),
    ('stat', 'HeadObject, 8 clients, 1000 objects'),
    ('mixed', 'A mixed load (45% GET, 30% HEAD, 15% PUT, 10% DELETE) of 1 MiB, 8 clients'),
    ('multipart', 'Multipart uploads of 64 MiB (8 parts of 8 MiB), 2 uploads at once'),
]

LIST_DESC = 'ListObjectsV2 by pages of 100 keys, 8 clients, in a bucket of {n} objects'

# Filled in by hand after reading a run (see the docstring)
FINDINGS = [
    '**Within its size, it is fast and light.** With buckets of up to a few thousand objects every '
    'operation answers in milliseconds: a listing page in ~25 ms, a HEAD in ~2 ms, a GET of 1 MiB in '
    '~10 ms. The process starts with **12 MiB** of memory and its peak in the whole run was '
    '**414 MiB**, against MinIO\'s 126 MiB and 1.5 GiB.',
    '**Uploads are as fast as MinIO or faster**, since SQLite runs in WAL mode: 2037 PUTs/s of 1 KiB '
    '(MinIO 1040), and 159 vs 132 MiB/s with 1 MiB objects; with 32 clients 136 vs 86 MiB/s. The '
    'exception is a big single upload: a PUT of 16 MiB reaches 147 MiB/s against 477.',
    '**Reads carry a fixed cost per request**: 2047 GETs/s of 1 KiB against 7629 (3.7x), and about '
    'half the throughput with 1 MiB objects (691 vs 1303 MiB/s). Each GET looks up the metadata in '
    'SQLite and checks the file\'s size and date.',
    '**A listing page costs what its folder holds, no longer what the bucket holds.** A page walks '
    'only the folder of the prefix (one level with the delimiter `/`, the console\'s) and reads the '
    'metadata of its own 100 keys only: 25 ms with 1000 objects, 67 ms with 10 000 (MinIO 10 and '
    '28 ms), and ~50 ms in a flat bucket of 10 000 objects listed from its root. ListBuckets still '
    'walks every object of every bucket: ~1 s with 16 000 objects in total.',
    '**The default rate limit (2000 requests/min per IP) caps one machine at ~33 requests/s.** With 8 '
    'clients sharing an IP, 98 requests failed in a minute even after the SDK retries. It is the '
    'emergency brake it was designed to be (`DECISIONS.md` §2), not a throttle: a bulk load from one '
    'machine needs it raised.',
]

# Before and after each change that made it faster: (change, metric, before, after)
HISTORY = [
    ('SQLite in WAL mode with `synchronous=NORMAL`', 'PUT of 1 KiB, 8 clients', '189 ops/s', '2037 ops/s'),
    ('', 'PUT of 1 MiB with 1 / 8 / 32 clients', '73 / 130 / 106 MiB/s', '108 / 159 / 136 MiB/s'),
    ('', 'PUT of 16 MiB, 8 clients', '113 MiB/s', '147 MiB/s'),
    ('', 'Mixed load, 8 clients', '420 ops/s', '518 ops/s'),
    ('Listings walk only the folder of the prefix and `stat` only the page', 'A page in a bucket of 1000 / 10 000 objects', '57 / 507 ms', '25 / 67 ms'),
    ('', 'A page of a flat bucket of 10 000 objects (from its root)', '~500 ms', '~50 ms'),
]

LIMITS = [
    '**Objects per folder.** A page costs what its folder holds: ~5 ms per thousand objects in it '
    '(~50 ms with 10 000 at one level). A bucket organized in folders scales with the size of each '
    'folder, not of the bucket; listing a whole flat bucket of 10 000 objects takes ~5 s (100 '
    'pages), and of 100 000 objects about 9 minutes by extrapolation, since every page walks the '
    'folder again.',
    '**Objects in the whole storage.** ListBuckets (the console\'s bucket list, and every S3 client '
    'that starts with `ls`) costs ~0.06 ms per stored object: 1 s with 16 000, ~6 s with 100 000.',
    '**Reads of small objects.** ~2000 GETs/s of 1 KiB with 8 clients, a third of MinIO.',
    '**One machine at a time.** With the default rate limit a client of many parallel workers on one '
    'IP gets `SlowDown` above 2000 requests/min.',
    '**Memory grows with concurrency and big objects and is not given back:** ~70 MiB with small '
    'objects, ~150 MiB with 1 MiB objects, ~400 MiB at the peak (multipart and 32 clients). It is '
    'the Dart heap keeping what it reached; plan ~512 MiB for a container.',
]
IMPROVEMENTS = [
    '**ListBuckets from the database.** The object count and size of each bucket can come from the '
    '`object_meta` table (a `SUM`/`COUNT` grouped by bucket) instead of walking the disk; the walk '
    'is still needed when files change outside the service, so it could become a periodic '
    'reconciliation.',
    '**An index of keys** (the `object_meta` table already has one row per object) would make a '
    'listing page a query `WHERE key > ? ORDER BY key LIMIT 100`: constant per page, whatever the '
    'size of the folder. It is the change that takes it to hundreds of thousands of objects, at the '
    'price of keeping the table as the source of truth of what exists.',
    '**Big single uploads.** A PUT of 16 MiB with 8 clients stays at ~150 MiB/s (MinIO: 477), while '
    'multipart (the same bytes in 8 MiB parts) gets about as much with 2 uploads: worth profiling '
    'the write path (the md5 computed in Dart over every chunk, the size of the chunks written) '
    'before changing it.',
    '**Reads.** A GET checks the metadata in SQLite and the file\'s size and date on every request; '
    'caching it in memory for the hot objects would cut the fixed cost of small reads.',
    '**The rate limit for signed requests.** The limit exists against clients without credentials '
    '(`DECISIONS.md` §2); requests signed with a valid key, or with the JWT, could have a higher '
    'limit (or none), so a backup or a migration doesn\'t need the global one raised.',
]


def read(path):
    try:
        return path.read_text(encoding='utf-8', errors='replace')
    except FileNotFoundError:
        return None


def parse_warp(text):
    """The sections of warp's summary: {op: {...}} with throughput and latencies."""
    sections = {}
    if not text:
        return sections
    for block in re.split(r'\n(?=Report: )', text):
        head = re.match(r'Report: (\w+)\. Concurrency: (\d+)\. Ran: (\w+)', block)
        if not head:
            continue
        op = head.group(1)
        data = {'concurrency': int(head.group(2)), 'ran': head.group(3)}
        avg = re.search(r'Average: (?:([\d.]+) (\w+)/s, )?([\d.]+) obj/s', block)
        if avg:
            if avg.group(1):
                data['mib_s'] = to_mib(float(avg.group(1)), avg.group(2))
            data['obj_s'] = float(avg.group(3))
        reqs = re.search(
            r'Reqs: Avg: ([\d.]+\w+), 50%: ([\d.]+\w+), 90%: ([\d.]+\w+), 99%: ([\d.]+\w+)',
            block,
        )
        if reqs:
            data['avg'], data['p50'], data['p90'], data['p99'] = (to_ms(v) for v in reqs.groups())
        errors = re.search(r'Errors: (\d+)', block)
        data['errors'] = int(errors.group(1)) if errors else 0
        sections[op] = data
    total = re.search(r'Cluster Total: ([\d.]+) (\w+)/s, ([\d.]+) obj/s', text)
    if total:
        sections['TOTAL'] = {
            'mib_s': to_mib(float(total.group(1)), total.group(2)),
            'obj_s': float(total.group(3)),
        }
    warp_errors = re.findall(r'(?im)^.*error.*$', text)
    if warp_errors:
        sections.setdefault('_log', {})['errors'] = warp_errors
    return sections


def to_mib(value, unit):
    return value * {'B': 1 / 1048576, 'KiB': 1 / 1024, 'MiB': 1, 'GiB': 1024}.get(unit, 1)


def to_ms(value):
    number, unit = re.match(r'([\d.]+)(\w+)', value).groups()
    return float(number) * {'ns': 1e-6, 'µs': 1e-3, 'us': 1e-3, 'ms': 1, 's': 1000}.get(unit, 1)


def peak_memory(path):
    """The highest RSS of the server sampled while a scenario ran (KiB in the file), in MiB."""
    text = read(path)
    if not text:
        return None
    values = [int(line) / 1024 for line in text.split() if line.isdigit()]
    return max(values) if values else None


def list_buckets(path):
    rows = []
    for line in (read(path) or '').splitlines():
        fields = dict(re.findall(r'(\w+)=([\d.]+)', line))
        if fields:
            rows.append(fields)
    return rows


def fmt(value, digits=1):
    if value is None:
        return '—'
    if value >= 100:
        return f'{value:,.0f}'
    return f'{value:,.{digits}f}'


def git(*args):
    try:
        return subprocess.run(['git', *args], capture_output=True, text=True, check=True).stdout.strip()
    except Exception:
        return '?'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', default=str(HERE / 'out'))
    out = Path(parser.parse_args().out)

    feather_dir = out / 'feather'
    minio_dir = out / 'minio'
    targets = {
        'feather': {f.stem: parse_warp(read(f)) for f in feather_dir.glob('*.txt')},
        'minio': {f.stem: parse_warp(read(f)) for f in minio_dir.glob('*.txt')},
    }
    list_sizes = sorted(
        int(name.split('-')[1])
        for name in targets['feather']
        if name.startswith('list-') and name.split('-')[1].isdigit()
    )

    lines = []
    w = lines.append
    commit = git('rev-parse', '--short', 'HEAD')
    branch = git('rev-parse', '--abbrev-ref', 'HEAD')
    dirty = ' with uncommitted changes' if git('status', '--porcelain') else ''
    minio_image = (read(minio_dir / 'image.txt') or '').strip() or 'not run'

    w('# Performance results')
    w('')
    w(f'Run on **{datetime.date.today().isoformat()}** on commit `{commit}` (`{branch}`){dirty}, '
      f'on {platform.system()} {platform.release()} with Docker Desktop: the service runs from its '
      'own image (`docker build -t feather-io service/`, AOT on a Linux container, data in a Docker '
      'volume) and [warp](https://github.com/minio/warp) runs in another container of the same '
      'network. Generated with `service/tool/benchmark/report.py`; to repeat it, see the README of '
      'this folder.')
    w('')
    w('**feather-io is a lightweight storage**: a bucket of a thousand objects is already a big one '
      'for it. These numbers say how it behaves within that size, where its limits are, and what '
      'would move them; they are not a goal of competing with storage built for millions of objects. '
      f'MinIO (`{minio_image}`) runs the same scenarios on the same machine as a reference of a server '
      'built for that.')
    w('')
    w('The general rate limit is off in every scenario (`RATE_LIMIT_REQUESTS=0`) except in '
      '[the limited one](#4-with-the-default-rate-limit), so the numbers are the server\'s.')
    w('')

    if FINDINGS:
        w('## Summary')
        w('')
        for finding in FINDINGS:
            w(f'- {finding}')
        w('')
    if HISTORY:
        w('## What changed')
        w('')
        w('The first run found the bottlenecks; these are the numbers of the same scenarios before '
          'and after each change.')
        w('')
        w('| Change | Scenario | Before | After |')
        w('|---|---|---:|---:|')
        for change, metric, before, after in HISTORY:
            w(f'| {change} | {metric} | {before} | {after} |')
        w('')

    w('## 1. Objects')
    w('')
    w('Throughput (MiB/s and operations per second) and latency of each request (median and 99th '
      'percentile).')
    w('')
    w('| Scenario | What it measures | feather-io | MinIO | feather p50 / p99 | MinIO p50 / p99 |')
    w('|---|---|---:|---:|---:|---:|')
    for name, desc in SCENARIOS:
        f = targets['feather'].get(name, {})
        m = targets['minio'].get(name, {})
        fo = main_op(f)
        mo = main_op(m)
        w(f'| `{name}` | {desc} | {rate(fo)} | {rate(mo)} | {lat(fo)} | {lat(mo)} |')
    w('')
    mixed = targets['feather'].get('mixed', {})
    if mixed:
        w('The mixed load, by operation (feather-io):')
        w('')
        w('| Operation | ops/s | p50 | p99 |')
        w('|---|---:|---:|---:|')
        for op in ('GET', 'STAT', 'PUT', 'DELETE'):
            if op in mixed:
                d = mixed[op]
                w(f'| {op} | {fmt(d.get("obj_s"))} | {fmt(d.get("p50"))} ms | {fmt(d.get("p99"))} ms |')
        w('')

    w('## 2. Listings and bucket size')
    w('')
    w('A listing page walks the folder of its prefix (one level with the delimiter `/`) and reads '
      'the metadata of its own keys only, so its cost grows with what that folder holds. ListBuckets '
      'walks every object of every bucket to give their counts and sizes: it is timed after each '
      'listing scenario, with every object stored so far.')
    w('')
    w('Each warp client lists its own prefix of the bucket from start to end (N / 8 objects, by '
      'pages of 100 keys). The time of a page is the median time of that whole listing divided by '
      'its pages.')
    w('')
    w('| Objects in the bucket | feather-io objects listed/s | MinIO objects listed/s | feather-io per page | MinIO per page |')
    w('|---:|---:|---:|---:|---:|')
    for n in list_sizes:
        f = main_op(targets['feather'].get(f'list-{n}', {}))
        m = main_op(targets['minio'].get(f'list-{n}', {}))
        w(f'| {n:,} | {fmt(f.get("obj_s"))} | {fmt(m.get("obj_s"))} | {per_page(f, n)} | '
          f'{per_page(m, n)} |')
    w('')
    flat = list_buckets(feather_dir / 'listflat.txt')
    if flat:
        w('The worst case, a flat bucket (every object at its root), listed by `list_flat.py` against '
          'feather-io (warp can\'t measure it):')
        w('')
        w('| Objects at the root | One page with `/` | One page without delimiter | The whole bucket |')
        w('|---:|---:|---:|---:|')
        by_name = {}
        for line in (read(feather_dir / 'listflat.txt') or '').splitlines():
            parts = line.split()
            if len(parts) > 2:
                by_name[parts[1]] = dict(re.findall(r'(\w+)=([\d.]+)', line))
        objects = int(float(next(iter(by_name.values()))['objects']))
        delim = by_name.get('page-delimiter', {})
        recursive = by_name.get('page-recursive', {})
        whole = by_name.get('whole-bucket', {})
        w(f'| {objects:,} | {fmt(float(delim.get("avg_ms", 0)))} ms | '
          f'{fmt(float(recursive.get("avg_ms", 0)))} ms | '
          f'{fmt(float(whole.get("total_ms", 0)) / 1000)} s ({int(float(whole.get("pages", 0)))} pages) |')
        w('')

    rows = list_buckets(feather_dir / 'listbuckets.txt')
    if rows:
        w('| Buckets | Objects in total | ListBuckets (average) |')
        w('|---:|---:|---:|')
        for row in rows:
            w(f'| {int(float(row["buckets"]))} | {int(float(row["objects"])):,} | '
              f'{fmt(float(row["avg_ms"]))} ms |')
        w('')

    w('## 3. Memory')
    w('')
    w('The RSS of the server\'s process (what it takes from the machine), sampled every 2 s. The '
      'scenarios run one after the other on the same process, and a heap that grew is not given '
      'back at once, so the peak of the run is reached in one scenario and carried to the next.')
    w('')
    w('| Server | At start | With small objects (`put-1KiB`) | Peak of the run |')
    w('|---|---:|---:|---:|')
    for name, folder in (('feather-io', feather_dir), ('MinIO', minio_dir)):
        start, small, peak, peak_at = memory_summary(folder)
        w(f'| {name} | {fmt(start)} MiB | {fmt(small)} MiB | {fmt(peak)} MiB (`{peak_at}`) |')
    w('')

    limited = parse_warp(read(out / 'limited' / 'mixed.txt'))
    w('## 4. With the default rate limit')
    w('')
    if limited:
        w('A mixed load of 64 KiB objects from 8 clients for 60 s, with the default general limit '
          '(2000 requests per minute per IP). Every warp client shares one IP, as a backup tool on '
          'one machine would.')
        w('')
        w('| Operation | ops/s | Errors |')
        w('|---|---:|---:|')
        for op, d in limited.items():
            if op.startswith('_'):
                continue
            w(f'| {op} | {fmt(d.get("obj_s"))} | {d.get("errors", 0)} |')
        w('')
    else:
        w('Not run (`run.sh limited`).')
        w('')

    if LIMITS:
        w('## 5. Limits')
        w('')
        for limit in LIMITS:
            w(f'- {limit}')
        w('')
    if IMPROVEMENTS:
        w('## 6. What would improve it')
        w('')
        for improvement in IMPROVEMENTS:
            w(f'- {improvement}')
        w('')

    (HERE / 'RESULTS.md').write_text(align_tables('\n'.join(lines).rstrip()) + '\n', encoding='utf-8')
    print(f'Wrote {HERE / "RESULTS.md"}')


def main_op(sections):
    """The operation a scenario measures (its only one, or the total of a mixed one)."""
    ops = {k: v for k, v in sections.items() if not k.startswith('_')}
    if not ops:
        return {}
    for total in ('Total', 'TOTAL'):
        if total in ops:
            return ops[total]
    if len(ops) == 1:
        return next(iter(ops.values()))
    # A mixed load: the operations add up; each one's latency is in its own table
    return {
        'obj_s': sum(d.get('obj_s', 0) for d in ops.values()),
        'mib_s': sum(d.get('mib_s', 0) for d in ops.values()),
    }


def rate(d):
    if not d:
        return '—'
    if d.get('mib_s') is not None and d['mib_s'] >= 1:
        return f'{fmt(d["mib_s"])} MiB/s ({fmt(d.get("obj_s"))} ops/s)'
    return f'{fmt(d.get("obj_s"))} ops/s'


def per_page(d, objects, clients=8, page=100):
    """The median time of one page: each client lists objects / clients keys in pages of 100."""
    if not d or d.get('p50') is None:
        return '—'
    pages = max(1, -(-objects // clients // page))
    return f'{fmt(d["p50"] / pages)} ms'


def memory_summary(folder):
    """RSS (MiB) at the start of the run, during put-1KiB, and the peak with its scenario."""
    first = read(folder / 'put-1KiB.mem') or ''
    samples = [int(v) / 1024 for v in first.split() if v.isdigit()]
    start = samples[0] if samples else None
    small = max(samples) if samples else None
    peak, peak_at = None, '—'
    for path in folder.glob('*.mem'):
        value = peak_memory(path)
        if value is not None and (peak is None or value > peak):
            peak, peak_at = value, path.stem
    return start, small, peak, peak_at


def lat(d):
    if not d or d.get('p50') is None:
        return '—'
    return f'{fmt(d["p50"])} / {fmt(d["p99"])} ms'


if __name__ == '__main__':
    main()

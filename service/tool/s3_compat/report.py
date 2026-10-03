#!/usr/bin/env python3
"""Writes RESULTS.md from the outputs of a full test run.

Usage (from the repo root, see "Full test run" in CLAUDE.md):

    python service/tool/s3_compat/report.py [--out DIR] [--server-log FILE]

Reads from --out (service/tool/s3_compat/out by default):
    service_tests.jsonl   fvm dart test --reporter json (from service/)
    service_analyze.txt   fvm dart analyze (optional)
    console_analyze.txt   fvm flutter analyze (optional)
    awscli.txt, rclone.txt, mint.txt, mint-logs/log.json   run.sh awscli rclone mint

--server-log is the service log during the run, to count the unhandled errors
(optional).

What is kept by hand lives in the constants below: what each test file covers
(TEST_DESC), why each Mint test fails (REASONS) and the status of each suite
(SUITE_STATUS). A Mint failure without a known cause shows up as
**Unclassified** and has to be reviewed.
"""
import argparse
import collections
import datetime
import json
import platform
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent

TEST_DESC = {
    'anonymous_access_test.dart': 'Anonymous access rules (admin CRUD, effect on list/get/put/delete, a prefix without `*` and the whole key with `*`) and multipart never being anonymous.',
    'aws_chunked_test.dart': '`aws-chunked` bodies (chunk signatures and trailers), lines split mid-way, errors, and a failed upload not overwriting the object.',
    'body_size_test.dart': 'Size limits: objects > 10 MB, 2 MB bodies, chunked without `Content-Length`.',
    'copy_object_test.dart': 'CopyObject: copies, across buckets, onto itself, errors and the `x-amz-copy-source-if-*` conditions.',
    'cors_test.dart': 'CORS (preflight and the exposed `ETag`).',
    'create_bucket_test.dart': 'CreateBucket: JWT and SigV4, no body nor `Content-Length`, metadata, validation and reserved names.',
    'create_folder_test.dart': 'Folders (`key/`): create, list, HEAD/GET and S3-like deletion (only the marker).',
    'delete_bucket_test.dart': 'DeleteBucket: empty, not empty, missing, reserved, SigV4.',
    'delete_folder_test.dart': 'Admin endpoint to delete a folder with its content.',
    'delete_object_test.dart': 'DeleteObject and DeleteObjects (JSON and S3 XML), parallel deletes and the retry on Windows.',
    'empty_bucket_test.dart': 'Admin endpoint to empty a bucket.',
    'get_bucket_location_test.dart': 'GetBucketLocation (`?location`).',
    'get_bucket_test.dart': 'Bucket details (admin): metadata and statistics.',
    'get_object_test.dart': 'GET/HEAD: content types, ETag, `Range` (206/416), `response-*` overrides.',
    'list_buckets_test.dart': 'ListBuckets: JSON/XML, UTC dates, `Owner`, statistics.',
    'list_objects_test.dart': 'ListObjects V1 and V2: prefixes, paging (token, `marker`, `start-after`), ETags, `encoding-type=url`.',
    'login_rate_limiter_test.dart': 'Login attempt limit (unit, fake clock): penalty, lock, unlock and reset.',
    'login_rate_limit_test.dart': 'Login attempt limit against the server: 429 with `Retry-After`, fake `X-Forwarded-For`, end of the lock.',
    'rate_limit_test.dart': 'General limit per IP: `X-RateLimit-*` headers, `503 SlowDown` on S3 and 429 on admin with `Retry-After`, fake `X-Forwarded-For`, next window.',
    'login_test.dart': 'Console login (JWT) and tampered tokens: no `exp`, expired, another secret, `alg: none`; errors without internal details.',
    'multipart_test.dart': 'Multipart: create, parts, complete, abort, ListMultipartUploads, ListParts, UploadPartCopy.',
    'object_metadata_test.dart': 'Metadata: `Content-Type`, `x-amz-meta-*`, storage class, on copies and multipart.',
    'presign_public_url_test.dart': 'Presigned URLs with `PUBLIC_URL`: public domain even with a tampered `Host`, valid through a proxy, and validation of the variable.',
    'presign_test.dart': 'Presigned URLs (admin endpoint and SigV4 query verification).',
    'put_object_test.dart': 'PutObject: uploads, ETag, missing bucket, key validation, path traversal and replacing an open object (Windows).',
    's3_controller_test.dart': 'Full happy path (create bucket → upload → list → download → delete).',
    's3_error_test.dart': 'S3 errors in XML/JSON and SigV4 signatures: wrong signature and key, replay (±15 min), credential date, body sha256, presigned URL dated in the future.',
    'sig_v4_signer_test.dart': 'SigV4 signature against the official example of the AWS docs.',
    'unsupported_subresource_test.dart': '`501 NotImplemented` for subresources and the reads that are answered anyway (tagging, versioning).',
    'update_bucket_test.dart': 'Editing the description and color of a bucket (admin).',
}

SUITE_ORDER = ['awscli', 'aws-sdk-go', 'aws-sdk-java', 'aws-sdk-java-v2', 'aws-sdk-php',
               'aws-sdk-ruby', 'minio-go', 'minio-py', 'minio-js', 'minio-java', 'mc', 's3cmd',
               'healthcheck', 's3select', 'versioning']

SUITE_STATUS = {
    'awscli': 'Stops at `s3 presign` (SigV2, from CLI v1).',
    'aws-sdk-go': 'Stops at the first test: it expects a presigned URL to verify an `x-amz-content-sha256` header.',
    'aws-sdk-java': 'Passes entirely.',
    'aws-sdk-java-v2': 'Passes entirely.',
    'aws-sdk-php': 'Stops when aborting a missing upload (MinIO behavior).',
    'aws-sdk-ruby': 'Stops at POST policy.',
    'minio-go': 'Passes entirely with SigV4; the SigV2 part gets 401.',
    'minio-py': 'Stops at snowball (a MinIO API).',
    'minio-js': 'Reaches the end with isolated failures (each block goes on after a failure).',
    'minio-java': 'Reaches the end with isolated failures.',
    'mc': 'Stops at POST policy.',
    's3cmd': 'Passes entirely.',
    'healthcheck': 'Out of scope: MinIO health endpoints.',
    's3select': 'Out of scope: S3 Select.',
    'versioning': 'Out of scope: versioning.',
}

# (text found in the test or its error, cause). The first match wins
REASONS = [
    ('s3 presign', 'Out of scope: CLI v1 signs `s3 presign` with SigV2.'),
    ('XAmzContentSHA256Mismatch', 'Out of scope: `x-amz-content-sha256` is not verified on presigned URLs (it is with header signatures).'),
    ('PresignedPut', 'Out of scope: `x-amz-content-sha256` is not verified on presigned URLs (it is with header signatures).'),
    ('non-existent', 'MinIO behavior: aborting a missing upload gives 204; AWS S3 (and feather-io) give 404 `NoSuchUpload`.'),
    ('presignedPost', 'Out of scope: POST policy uploads.'),
    ('PresignedPost', 'Out of scope: POST policy uploads.'),
    ('post_policy', 'Out of scope: POST policy uploads.'),
    ('testFunctionalV2', 'Out of scope: SigV2 signatures.'),
    ('snowball', 'Out of scope: snowball is a MinIO API.'),
    ('Snowball', 'Out of scope: snowball is a MinIO API.'),
    ('lists 11 objects', 'Knock-on: `datafile-1-b` stays, the POST policy tests (out of scope) delete it.'),
    ('lists 1 objects', "Knock-on: MinIO's own prefix force-delete."),
    ('Force Deletion', "Knock-on: MinIO's own prefix force-delete."),
    ('listenBucketNotification', 'Out of scope: notifications (minio-java also repeats the `events` query parameter; see the notes).'),
    ('Retention', 'Out of scope: retention / object lock.'),
    ('retention', 'Out of scope: retention / object lock.'),
    ('is not valid or contains forbidden characters', 'Limitation: keys with `<>:"|?*`, which the filesystem (Windows) does not support.'),
    ('selectObjectContent', 'Out of scope: S3 Select.'),
    ('select_object_content', 'Out of scope: S3 Select.'),
    ('post select', "Knock-on: the S3 Select bucket isn't emptied."),
    ('"after all" hook in "functional tests"', 'Knock-on: the main bucket keeps objects from tests that failed before.'),
    ('removeBucket', "Knock-on: the snowball bucket isn't emptied."),
    ('addUser', 'Out of scope: MinIO admin API.'),
    ('addCannedPolicy', 'Out of scope: MinIO admin API.'),
    ('setPolicy', 'Out of scope: MinIO admin API.'),
    ('getUserInfo', 'Out of scope: MinIO admin API.'),
    ('listUsers', 'Out of scope: MinIO admin API.'),
    ('listCannedPolicies', 'Out of scope: MinIO admin API.'),
    ('minio/health', "Out of scope: MinIO's own health endpoint."),
    ('versioning', 'Out of scope: versioning.'),
]

UNCLASSIFIED = '**Unclassified: review it**'

NOT_WORKING = """**Out of scope** (under *Parked* in `ROADMAP.md`; they answer `501 NotImplemented` or 401)

- SigV2 signatures (including `aws s3 presign` from CLI v1).
- Verifying checksums (`Content-MD5`, the `aws-chunked` CRC, each chunk's signature) and
  `x-amz-content-sha256` on presigned URLs (it is verified with header signatures).
- POST policy uploads (presigned forms).
- Versioning (only answered as never enabled) and tags (only answered as none).
- Bucket policies, ACLs, encryption, lifecycle, per-bucket CORS, website, logging, replication.
- Notifications, S3 Select, retention / object lock / legal hold.
- MinIO's own APIs: admin, health, snowball, prefix force-delete.
- Keys with characters the filesystem doesn't support (`<>:"|?*` on Windows).

**Notes**

- The SigV4 canonical query keeps a single value per parameter: a signed request that repeats a
  parameter (`events=…&events=…`, only MinIO's `listenBucketNotification` does) gets
  `SignatureDoesNotMatch`.
- The php test that aborts a missing upload expects MinIO's behavior; feather-io follows AWS S3.
- On Windows, replacing an object another request keeps open is retried for 5 s and then answers
  `503 ServiceUnavailable` (clients retry it). It doesn't happen on Linux."""

NOT_TESTED = """- **Linux**: the service of these runs is on Windows. Production would run in Docker on Linux,
  and the `Dockerfile` still has to be fixed (roadmap phase 5).
- **HTTPS**: every test goes over HTTP.
- **Virtual-hosted style** (`bucket.host`): path-style only.
- **High load and concurrency**: only the concurrency the clients add themselves (parallel uploads
  and deletes).
- **Console**: it has no automated tests.
- **Other clients**: Cyberduck, s3fs, the .NET and Rust SDKs, boto3 directly (the AWS CLI and s3cmd
  use it underneath)."""


def md(text):
    return str(text).replace('|', '\\|').replace('\n', ' ').strip()


def short(text, size):
    text = md(text)
    return text if len(text) <= size else text[:size - 1] + '…'


def run(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=60).stdout.strip()
    except Exception:
        return ''


def read(path):
    return path.read_text(encoding='utf-8', errors='replace') if path.exists() else ''


def load_service_tests(path):
    suites, tests = {}, {}
    for line in read(path).splitlines():
        try:
            event = json.loads(line)
        except ValueError:
            continue
        kind = event.get('type')
        if kind == 'suite':
            suites[event['suite']['id']] = event['suite']['path']
        elif kind == 'testStart':
            test = event['test']
            tests[test['id']] = {'name': test['name'], 'suite': test['suiteID']}
        elif kind == 'testDone' and event['testID'] in tests:
            tests[event['testID']].update(
                result='skipped' if event['skipped'] else event['result'],
                hidden=event['hidden'],
            )
    by_file = collections.defaultdict(list)
    for test in tests.values():
        if test.get('hidden') or 'result' not in test:
            continue
        name = re.split(r'[\\/]', suites.get(test['suite'], '?'))[-1]
        by_file[name].append(test)
    return dict(sorted(by_file.items()))


def load_steps(text):
    return re.findall(r'^(PASS|FAIL)  (.+)$', text, re.M)


def load_mint(out):
    rows = []
    for line in read(out / 'mint-logs' / 'log.json').splitlines():
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        rows.append({
            'suite': str(entry.get('name', '')).split(':')[0].strip(),
            'function': str(entry.get('function') or '').strip(),
            'status': entry.get('status'),
            'text': ' '.join(str(entry.get(k) or '') for k in ('name', 'function', 'error', 'message')),
        })
    done = {m.group(1): m.group(2) == 'done'
            for m in re.finditer(r'Running (\S+) tests \.\.\. (done|FAILED)', read(out / 'mint.txt'))}
    return rows, done


def reason(row):
    for pattern, why in REASONS:
        if pattern in row['text']:
            return why
    return UNCLASSIFIED


def analyze_summary(text, empty):
    if not text:
        return 'Not run'
    if 'No issues found' in text:
        return 'No issues'
    found = re.search(r'(\d+) issues? found', text)
    if not found:
        return empty
    issues = int(found.group(1))
    return f'{issues} issue{"s" if issues != 1 else ""} (see the output)'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', default=str(HERE / 'out'))
    parser.add_argument('--server-log')
    parser.add_argument('--output', default=str(HERE / 'RESULTS.md'))
    args = parser.parse_args()
    out = Path(args.out)

    tests = load_service_tests(out / 'service_tests.jsonl')
    steps = {name: load_steps(read(out / f'{name}.txt')) for name in ('awscli', 'rclone')}
    # Only the first token: `aws-cli/2.37.9`, `rclone v1.75.1`
    versions = {}
    for name in ('awscli', 'rclone'):
        found = re.search(r'^version: (.+)$', read(out / f'{name}.txt'), re.M)
        text = found.group(1) if found else '?'
        versions[name] = ' '.join(text.split()[:2]) if name == 'rclone' else text.split()[0]
    mint, mint_done = load_mint(out)
    by_suite = collections.OrderedDict((s, []) for s in SUITE_ORDER)
    for row in mint:
        by_suite.setdefault(row['suite'], []).append(row)
    counts = {s: collections.Counter(r['status'] for r in rows) for s, rows in by_suite.items()}
    failures = [r for rows in by_suite.values() for r in rows if r['status'] not in ('PASS', 'NA')]
    unclassified = [r for r in failures if reason(r) == UNCLASSIFIED]
    server_errors = None
    if args.server_log:
        server_errors = read(Path(args.server_log)).count('Unhandled error')

    commit = run(['git', 'rev-parse', '--short', 'HEAD']) or '?'
    branch = run(['git', 'rev-parse', '--abbrev-ref', 'HEAD']) or '?'
    # The report itself and this folder don't count as changes to the tested code
    dirty = ' with uncommitted changes' if run(
        ['git', 'status', '--porcelain', '--', 'service', 'console', ':!service/tool/s3_compat']) else ''
    total = sum(len(v) for v in tests.values())
    passed = sum(1 for v in tests.values() for t in v if t['result'] == 'success')

    L = []
    w = L.append
    w('# Test results (full run from scratch)')
    w('')
    w(f'Run on **{datetime.date.today().isoformat()}** on commit `{commit}` (`{branch}`){dirty},')
    w(f'on {platform.system()} {platform.release()} with {run(["docker", "--version"]) or "Docker ?"}.')
    w('Generated with `service/tool/s3_compat/report.py`; to repeat it, see *Full test run* in `CLAUDE.md`.')
    w('')
    w('| What | Result |')
    w('|---|---|')
    w(f'| `dart analyze` (service) | {analyze_summary(read(out / "service_analyze.txt"), "See the output")} |')
    w(f'| `flutter analyze` (console) | {analyze_summary(read(out / "console_analyze.txt"), "See the output")} |')
    w(f'| `dart test` (service) | **{passed}/{total}** in {len(tests)} files |')
    for name, label in (('awscli', 'AWS CLI v2'), ('rclone', 'rclone')):
        ok = sum(1 for s, _ in steps[name] if s == 'PASS')
        w(f'| {label} (`{versions[name]}`) | **{ok}/{len(steps[name])}** |')
    clean = [s for s in SUITE_ORDER if mint_done.get(s) and counts[s]['FAIL'] == 0]
    partial = [s for s in SUITE_ORDER if mint_done.get(s) and counts[s]['FAIL'] > 0]
    w(f'| MinIO Mint ({len([s for s in SUITE_ORDER if s in mint_done])} suites) | '
      f'No failures: {", ".join(f"`{s}`" for s in clean) or "none"}. '
      f'Finish with out-of-scope failures: {", ".join(f"`{s}`" for s in partial) or "none"}. '
      f'Unclassified failures: **{len(unclassified)}** |')
    if server_errors is not None:
        w(f'| Unhandled errors in the service log | **{server_errors}** |')
    w('')

    w('## 1. Service tests (`dart test`)')
    w('')
    w('| File | Tests | What it covers |')
    w('|---|---:|---|')
    for name, items in tests.items():
        ok = sum(1 for t in items if t['result'] == 'success')
        w(f'| `{name}` | {ok}/{len(items)} | {TEST_DESC.get(name, "**No description: add it to report.py**")} |')
    w('')
    failed_tests = [(name, t) for name, items in tests.items() for t in items
                    if t['result'] != 'success']
    if failed_tests:
        w('Failing tests:')
        w('')
        for name, t in failed_tests:
            w(f'- `{name}`: {md(t["name"])} ({t["result"]})')
        w('')
    w('The console has no tests (it is in the roadmap, phase 5); it is only analyzed.')
    w('')

    w('## 2. Real clients: AWS CLI v2 and rclone')
    w('')
    w('Scripts `awscli.sh` and `rclone.sh` (see the scripts for what each step checks). Every step')
    w('that downloads something also compares the content.')
    w('')
    w('| Client | Steps | Failing |')
    w('|---|---:|---|')
    for name, label in (('awscli', 'AWS CLI v2'), ('rclone', 'rclone')):
        ok = sum(1 for s, _ in steps[name] if s == 'PASS')
        failed = [md(step) for status, step in steps[name] if status != 'PASS']
        w(f'| {label} (`{versions[name]}`) | {ok}/{len(steps[name])} | {"; ".join(failed) or "—"} |')
    w('')

    w('## 3. MinIO Mint')
    w('')
    w('Each suite tests with one SDK or tool. Many stop at their first failure; NA are tests the')
    w('suite itself skips. `aws-sdk-java`, `aws-sdk-java-v2` and `minio-go` only log failures and')
    w('skipped tests: that they pass is known from their exit code (*Finishes OK*).')
    w('')
    w('| Suite | Finishes OK | ✅ | ❌ | NA | Status |')
    w('|---|:---:|---:|---:|---:|---|')
    for s in SUITE_ORDER:
        if s not in mint_done:
            continue
        c = counts[s]
        ok = c['PASS'] if c['PASS'] or not mint_done.get(s) else '—'
        w(f'| `{s}` | {"✅" if mint_done.get(s) else "❌"} | {ok} | {c["FAIL"]} | {c["NA"]} | {SUITE_STATUS.get(s, "")} |')
    w('')
    w('### Failures and their cause')
    w('')
    w('| Suite | Test | Cause |')
    w('|---|---|---|')
    for row in failures:
        w(f'| `{row["suite"]}` | {short(row["function"], 90)} | {md(reason(row))} |')
    w('')

    w("## 4. What doesn't work")
    w('')
    if unclassified or server_errors:
        w('**To review in this run**')
        w('')
        for row in unclassified:
            w(f'- Mint `{row["suite"]}`: {short(row["function"], 90)}')
        if server_errors:
            w(f'- {server_errors} unhandled errors in the service log.')
        w('')
    w(NOT_WORKING)
    w('')
    w("## 5. What isn't tested")
    w('')
    w(NOT_TESTED)

    Path(args.output).write_text('\n'.join(L) + '\n', encoding='utf-8', newline='\n')
    print(f'Wrote {args.output}')
    print(f'dart test {passed}/{total}; Mint: {len(failures)} failures, {len(unclassified)} unclassified'
          + (f'; {server_errors} errors in the log' if server_errors is not None else ''))
    for row in unclassified:
        print(f'  UNCLASSIFIED {row["suite"]}: {row["function"][:80]}')


if __name__ == '__main__':
    main()

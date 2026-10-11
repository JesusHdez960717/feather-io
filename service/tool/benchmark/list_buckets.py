#!/usr/bin/env python3
"""Times ListBuckets (`GET /`) against a running feather-io, which walks every object of every
bucket to answer its counts and sizes. Logs in to the admin API for a JWT and asks for the JSON
list, the console's call.

Usage: python list_buckets.py ENDPOINT ACCESS SECRET [REPEAT]
Prints one line: `listbuckets buckets=N objects=N avg_ms=X min_ms=X max_ms=X`.
"""
import json
import sys
import time
import urllib.request


def main():
    endpoint, access, secret = sys.argv[1:4]
    repeat = int(sys.argv[4]) if len(sys.argv) > 4 else 5

    login = urllib.request.Request(
        f'{endpoint}/_admin/login',
        data=json.dumps({'access': access, 'secret': secret}).encode(),
        headers={'content-type': 'application/json'},
    )
    with urllib.request.urlopen(login) as response:
        token = json.load(response)['access_token']

    request = urllib.request.Request(
        f'{endpoint}/',
        headers={'authorization': f'Bearer {token}', 'accept': 'application/json'},
    )
    times = []
    buckets = []
    for _ in range(repeat):
        start = time.perf_counter()
        with urllib.request.urlopen(request, timeout=600) as response:
            buckets = json.load(response)
        times.append((time.perf_counter() - start) * 1000)

    objects = sum(bucket['object_count'] for bucket in buckets)
    print(
        f'listbuckets buckets={len(buckets)} objects={objects} '
        f'avg_ms={sum(times) / len(times):.1f} min_ms={min(times):.1f} max_ms={max(times):.1f}'
    )


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""The worst case of a listing in feather-io: a flat bucket (every object at its root, no folders).
Uploads N objects of 1 byte to a new bucket, then times one page of 100 keys with the delimiter `/`
(what the console asks for), one page without it (`aws s3 ls --recursive`), and listing the whole
bucket page by page. Uses the admin login (JWT) and the JSON answers, the console's calls.

Usage: python list_flat.py ENDPOINT ACCESS SECRET [OBJECTS]
Prints one line per measure: `listflat <name> objects=N avg_ms=X ...`.
"""
import concurrent.futures
import json
import sys
import time
import urllib.parse
import urllib.request

BUCKET = 'list-flat'


def main():
    endpoint, access, secret = sys.argv[1:4]
    count = int(sys.argv[4]) if len(sys.argv) > 4 else 10000

    login = urllib.request.Request(
        f'{endpoint}/_admin/login',
        data=json.dumps({'access': access, 'secret': secret}).encode(),
        headers={'content-type': 'application/json'},
    )
    with urllib.request.urlopen(login) as response:
        token = json.load(response)['access_token']
    auth = {'authorization': f'Bearer {token}', 'accept': 'application/json'}

    def call(method, path, data=None):
        request = urllib.request.Request(f'{endpoint}{path}', data=data, headers=auth, method=method)
        with urllib.request.urlopen(request, timeout=600) as response:
            return response.read()

    call('PUT', f'/{BUCKET}')
    with concurrent.futures.ThreadPoolExecutor(16) as pool:
        list(pool.map(lambda i: call('PUT', f'/{BUCKET}/object-{i:06d}', b'x'), range(count)))

    def page(query):
        start = time.perf_counter()
        body = json.loads(call('GET', f'/{BUCKET}?list-type=2&max-keys=100&{query}'))
        return (time.perf_counter() - start) * 1000, body

    def timed(name, query, repeat=5):
        times = [page(query)[0] for _ in range(repeat)]
        print(f'listflat {name} objects={count} avg_ms={sum(times) / len(times):.1f} '
              f'min_ms={min(times):.1f} max_ms={max(times):.1f}')

    timed('page-delimiter', 'delimiter=%2F')
    timed('page-recursive', '')

    # The whole bucket, as a client that lists everything (no delimiter)
    total, pages, token_param = 0.0, 0, ''
    while True:
        elapsed, body = page(token_param)
        total += elapsed
        pages += 1
        next_token = body.get('next_continuation_token')
        if not next_token:
            break
        token_param = 'continuation-token=' + urllib.parse.quote(next_token)
    print(f'listflat whole-bucket objects={count} pages={pages} total_ms={total:.1f} '
          f'avg_ms={total / pages:.1f}')


if __name__ == '__main__':
    main()

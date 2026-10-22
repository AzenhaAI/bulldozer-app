#!/usr/bin/env python3
"""Bakes the site's data into the app as one gzipped file.

    python3 scripts/bake_offline_data.py            # from the live site
    python3 scripts/bake_offline_data.py --dist ~/Projects/bulldozer/dist

Writes assets/offline/data.json.gz: {"asOf": "<freshestParse>", "files":
{"/data/x.json": "<the file's JSON text>", ...}}. Values stay text so the app
never has to hold the whole catalogue as objects: it only writes them out into
its cache (lib/offline_bundle.dart).

Exists because a phone with no connection on first launch showed empty
screens — the same reason PapaGaio ships its dictionary. Run before every
release so the baked copy is not older than the build: 514 files, ~24 MB of
JSON, ~1.9 MB gzipped (22 Oct 2026).
"""
import argparse
import gzip
import json
import os
import sys
import urllib.request

SITE = 'https://azenha.ai/bulldozer'
INDEXES = ['manifest', 'catalog', 'country-index', 'country-meta', 'stories',
           'releases', 'brands', 'cities', 'quiz-pool']
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'offline', 'data.json.gz')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dist', help='a local site build instead of the live site')
    a = ap.parse_args()

    def read(path):
        if a.dist:
            with open(os.path.join(os.path.expanduser(a.dist), path.lstrip('/')), encoding='utf-8') as f:
                return f.read()
        # Cloudflare answers Python's default user agent with 403.
        req = urllib.request.Request(SITE + path, headers={'User-Agent': 'BullDozer-bake/1.0'})
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.read().decode('utf-8')

    files = {}
    for n in INDEXES:
        files[f'/data/{n}.json'] = read(f'/data/{n}.json')
    catalog = json.loads(files['/data/catalog.json'])
    countries = json.loads(files['/data/country-index.json'])
    paths = [f"/data/{e['slug']}.json" for e in catalog]
    paths += [f"/data/brief/{c['iso'].lower()}.json" for c in countries]
    for i, p in enumerate(paths, 1):
        files[p] = read(p)
        if i % 100 == 0:
            print(f'  {i}/{len(paths)}', file=sys.stderr)

    # Every value must be valid JSON: a CDN error page baked in would be served
    # offline for the life of the build.
    for p, text in files.items():
        json.loads(text)

    as_of = json.loads(files['/data/manifest.json']).get('freshestParse', '')
    body = json.dumps({'asOf': as_of, 'files': files}, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'wb') as f:
        f.write(gzip.compress(body, 9))
    print(f'{len(files)} files, data as of {as_of}: {len(body)/1e6:.1f} MB raw, '
          f'{os.path.getsize(OUT)/1e6:.2f} MB gzipped -> {os.path.normpath(OUT)}')


if __name__ == '__main__':
    main()

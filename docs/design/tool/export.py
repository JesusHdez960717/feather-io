"""Exports the console design from the files of the Claude Design canvas.

    python docs/design/tool/export.py <folder>

<folder> holds the canvas files as the artifact serves them: `project/canvas.json`,
`project/*.dc.html` and the uploaded flag (`<asset id>.svg`). It renders the screens listed in
PICK with headless Chrome (support.js stands in for the canvas runtime), and rewrites
`docs/design/screens/` and `docs/design/feather-io-console-design.pdf`. Needs Chrome and ffmpeg.
"""
import json
import shutil
import subprocess
import sys
import tempfile
import threading
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

DESIGN = Path(__file__).resolve().parent.parent
CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe' if sys.platform == 'win32' \
    else 'google-chrome'
FLAG = 'b78ce1432609f9c95c8462b3917deac7'

# Placeholder data left in the canvas, replaced so the screenshots read as real use
SUBS = [
    ('Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece '
     'of classical Latin literature from 45 BC, making it over 2000 years old',
     'Product photos for the online store'),
    ('asdasd', 'store-photos'),
    ("'asd'", "'tests'"), ('>asd<', '>tests<'), ('"asd"', '"tests"'),
    (f'/_blob/{FLAG}', f'/_blob/{FLAG}.svg'),
]

# (section, file name, artboard, caption): the screens worth keeping, in reading order
PICK = [
    ('Access', 'splash', 'Splash', 'Splash while the app loads'),
    ('Access', 'login', 'Login', 'Login'),
    ('Browser', 'buckets-list', 'Main', 'Browser: buckets, list view'),
    ('Browser', 'buckets-grid', 'BucketsGrid', 'Browser: buckets, grid view with the bucket menu'),
    ('Browser', 'create-bucket', 'CreateBucketFlow', 'Create bucket'),
    ('Browser', 'create-bucket-validation', 'CBErrorValidacion', 'Create bucket: validation of the name'),
    ('Browser', 'bucket-color', 'CBColorPersonalizado', 'Create bucket: custom color'),
    ('Browser', 'objects-list', 'ObjectsList', 'Inside a bucket: list view'),
    ('Browser', 'objects-grid', 'ObjectsGrid', 'Inside a bucket: grid view with the object menu'),
    ('Browser', 'objects-menu', 'ObjectsP3', 'Object menu: details, share, rename, move'),
    ('Browser', 'objects-selected', 'P3Selected', 'Several objects selected: download, move or delete'),
    ('Browser', 'objects-filters', 'ObjectsFilter', 'Filters by type, size and date'),
    ('Browser', 'objects-drop', 'ObjectsDrop', 'Dropping files to upload them'),
    ('Browser', 'delete-objects', 'DeleteDialog', 'Delete objects'),
    ('Browser', 'object-details', 'P3Details', 'Object details'),
    ('Browser', 'new-folder', 'P3NewFolder', 'New folder'),
    ('Browser', 'rename', 'P3Rename', 'Rename an object'),
    ('Browser', 'move', 'P3Move', 'Move objects to another folder'),
    ('Browser', 'share-link', 'P4Share', 'Share link (presigned URL)'),
    ('Browser', 'transfers', 'P4Uploads', 'Background transfers'),
    ('Buckets', 'bucket-general', 'BucketDetail', 'Buckets: general tab'),
    ('Buckets', 'bucket-access', 'BDAccess', 'Buckets: anonymous access rules'),
    ('Buckets', 'bucket-add-rule', 'BDAddRule', 'Add an anonymous access rule'),
    ('Buckets', 'bucket-danger', 'BDDanger', 'Buckets: danger zone'),
    ('Buckets', 'bucket-empty-confirm', 'BDEmptyConfirm', 'Empty a bucket, confirmed with its name'),
    ('Buckets', 'edit-bucket', 'EditBucket', 'Edit a bucket'),
    ('Access keys', 'access-keys', 'AccessKeys', 'Access keys'),
    ('Access keys', 'access-key-menu', 'AKMenu', 'Menu of a key'),
    ('Access keys', 'access-key-create', 'AKCreate', 'Create a key with permissions per bucket'),
    ('Access keys', 'access-key-created', 'AKCreated', 'Key created: the secret is shown once'),
    ('Navigation', 'rail-expanded', 'RailFooterExpanded', 'Navigation rail, expanded'),
]


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def main(source: Path) -> None:
    canvas = json.loads((source / 'project/canvas.json').read_text(encoding='utf-8'))
    work = Path(tempfile.mkdtemp(prefix='fio-design-'))
    for f in (source / 'project').glob('*.dc.html'):
        text = f.read_text(encoding='utf-8')
        for a, b in SUBS:
            text = text.replace(a, b)
        (work / f.name).write_text(text, encoding='utf-8')
    (work / '_blob').mkdir()
    shutil.copy(source / f'{FLAG}.svg', work / '_blob')
    shutil.copy(Path(__file__).parent / 'support.js', work)

    server = ThreadingHTTPServer(('127.0.0.1', 0), partial(QuietHandler, directory=work))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    port = server.server_address[1]

    screens = DESIGN / 'screens'
    # Emptied rather than deleted: on Windows a folder open elsewhere can't be removed
    screens.mkdir(exist_ok=True)
    for old in screens.glob('*.png'):
        old.unlink()
    pages = []
    for i, (section, name, board, caption) in enumerate(PICK, 1):
        frame = canvas['boards'][f'{board}.dc.html']
        w, h = frame['w'], frame['h']
        raw, out = work / f'{name}.raw.png', screens / f'{i:02d}-{name}.png'
        # Headless Chrome takes ~96 px of the window height: render taller and crop
        subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                        '--force-device-scale-factor=1', f'--window-size={w},{h + 96}',
                        '--virtual-time-budget=8000', f'--screenshot={raw}',
                        f'http://127.0.0.1:{port}/{board}.dc.html'], check=True, capture_output=True)
        subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', str(raw),
                        '-vf', f'crop={w}:{h}:0:0', str(out)], check=True)
        pages.append(f'<div class="p"><div><div class="s">{section}</div><h1>{caption}</h1></div>'
                     f'<img src="{out.as_uri()}"></div>')
        print(out.name)

    html = work / 'print.html'
    html.write_text(PRINT.replace('<!--pages-->', '\n'.join(pages)), encoding='utf-8')
    pdf = DESIGN / 'feather-io-console-design.pdf'
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--no-pdf-header-footer',
                    '--virtual-time-budget=8000', f'--print-to-pdf={pdf}', html.as_uri()],
                   check=True, capture_output=True)
    server.shutdown()
    shutil.rmtree(work)
    print(pdf.name)


PRINT = """<!doctype html><html><head><meta charset="utf-8">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;700&display=swap">
<style>
@page{size:1600px 900px;margin:0}
body{margin:0;background:#0d0b14;color:#fff;font-family:"DM Sans",system-ui,sans-serif}
.p{width:1600px;height:900px;box-sizing:border-box;padding:40px 32px;page-break-after:always;
   display:flex;flex-direction:column;gap:20px}
.p img{width:1536px;border:1px solid #2f2c3f;border-radius:8px}
.s{color:#9484c5;font-size:16px;letter-spacing:1px;text-transform:uppercase}
h1{margin:0;font-size:28px}
.cover{justify-content:center;align-items:center;text-align:center}
.cover h1{font-size:72px}.cover h1 span{color:#fdca3c}
</style></head><body>
<div class="p cover"><h1>Feather <span>IO</span></h1>
<p style="font-size:24px;color:#afafaf">Console design</p></div>
<!--pages-->
</body></html>"""

if __name__ == '__main__':
    main(Path(sys.argv[1]))

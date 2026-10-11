"""Exports the brand (icon and presentation images) from the files of its Claude Design canvas.

    python docs/design/tool/export_brand.py <folder>

<folder> holds the canvas files as the artifact serves them: `project/canvas.json` and
`project/*.dc.html`. It renders the icon (transparent PNGs) and the artboards listed in BOARDS with
headless Chrome (support.js stands in for the canvas runtime) into `docs/design/brand/`, and the
SVGs of the icon parts (kept by hand in that folder) as PNG. Needs Chrome and ffmpeg.
"""
import json
import shutil
import subprocess
import sys
import tempfile
import threading
from functools import partial
from http.server import ThreadingHTTPServer
from pathlib import Path

from export import CHROME, QuietHandler

BRAND = Path(__file__).resolve().parent.parent / 'brand'

# (file name, variant of the Icon artboard): the icon at ICON_SIZE px, transparent background
ICONS = [
    ('icon.png', 'A'),
    ('icon-square.png', 'B'),
]
ICON_SIZE = 1024

# The Icon artboard fills its container, so it is rendered inside a page of a fixed size
ICON_PAGE = """<!doctype html><html><head><meta charset="utf-8"><script src="./support.js"></script></head>
<body><x-dc><helmet><style>body{margin:0;background:transparent}</style></helmet>
<div style="width: SIZEpx"><dc-import name="Icon" variant="{{variant}}"></dc-import></div></x-dc>
<script type="text/x-dc" data-dc-script data-props='{"variant":{"default":"A"}}'>
class Component extends DCLogic { renderVals() { return { variant: this.props.variant }; } }
</script></body></html>"""

# The SVGs of the icon parts (kept by hand in brand/) also as PNG, at ICON_SIZE px
PARTS = ['icon-background', 'icon-feather', 'icon-square-background']
PART_PAGE = '<!doctype html><body style="margin:0;background:transparent"><img src="NAME.svg" width="SIZE" height="SIZE" style="display:block"></body>'

# (file name, artboard): the artboards exported at their size on the canvas
BOARDS = [
    ('images/icon-sheet.png', 'Main'),
    ('images/presentation-lockup.png', 'PresentationLockup'),
    ('images/presentation-product.png', 'PresentationProduct'),
    ('images/presentation-terminal.png', 'PresentationTerminal'),
    ('images/social-preview.png', 'SocialPreview'),
]


def shot(port: int, page: str, w: int, h: int, out: Path, transparent: bool = False) -> None:
    raw = out.with_suffix('.raw.png')
    extra = ['--default-background-color=00000000'] if transparent else []
    # Headless Chrome takes ~96 px of the window height and some of its width: render larger
    # and crop
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    '--force-device-scale-factor=1', f'--window-size={w + 40},{h + 96}', *extra,
                    '--virtual-time-budget=8000', f'--screenshot={raw}',
                    f'http://127.0.0.1:{port}/{page}'], check=True, capture_output=True)
    subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', str(raw),
                    '-vf', f'crop={w}:{h}:0:0', str(out)], check=True)
    raw.unlink()
    print(out.relative_to(BRAND))


def main(source: Path) -> None:
    canvas = json.loads((source / 'project/canvas.json').read_text(encoding='utf-8'))
    work = Path(tempfile.mkdtemp(prefix='fio-brand-'))
    for f in (source / 'project').glob('*.dc.html'):
        shutil.copy(f, work)
    shutil.copy(Path(__file__).parent / 'support.js', work)
    for part in PARTS:
        shutil.copy(BRAND / f'{part}.svg', work)
        (work / f'{part}.html').write_text(PART_PAGE.replace('NAME', part).replace('SIZE', str(ICON_SIZE)),
                                         encoding='utf-8')
    (work / 'IconExport.dc.html').write_text(ICON_PAGE.replace('SIZE', str(ICON_SIZE)), encoding='utf-8')

    server = ThreadingHTTPServer(('127.0.0.1', 0), partial(QuietHandler, directory=work))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    port = server.server_address[1]

    (BRAND / 'images').mkdir(parents=True, exist_ok=True)
    for name, variant in ICONS:
        shot(port, f'IconExport.dc.html?variant={variant}', ICON_SIZE, ICON_SIZE, BRAND / name,
             transparent=True)
    for part in PARTS:
        shot(port, f'{part}.html', ICON_SIZE, ICON_SIZE, BRAND / f'{part}.png', transparent=True)
    for name, board in BOARDS:
        frame = canvas['boards'][f'{board}.dc.html']
        shot(port, f'{board}.dc.html', frame['w'], frame['h'], BRAND / name)

    server.shutdown()
    shutil.rmtree(work)


if __name__ == '__main__':
    main(Path(sys.argv[1]))

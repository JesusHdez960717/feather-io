# Console design

The visual design of the console, exported from its Claude Design canvas so it can be seen without
access to it:

- [`feather-io-console-design.pdf`](feather-io-console-design.pdf): every screen worth keeping, one
  per page, grouped by section.
- [`screens/`](screens): the same screens as PNG (1536×720, the console at 125% Windows scaling),
  used by [`../console.md`](../console.md) and the [README](../../README.md).

Loading states, the intermediate states of the forms and the variants of the color picker stay only
in the canvas.

[`brand/`](brand) holds the icon (SVG and PNG) and the presentation images, exported from a third
canvas, "Feather IO Brand"; they are described, with how to regenerate them, in
[`../brand.md`](../brand.md).

## Sources

Two Claude Design artifacts, both named "Feather IO Console" (in English):

- Design system: https://claude.ai/artifact/1dJk7nhzEP7Y2CcgnTMyuB (tokens, components and icons
  of `console/lib/design_system/`).
- Canvas: https://claude.ai/artifact/XJpCx88PuduoWDgbdcBowC (a faithful replica of every screen and
  state of the console; the export comes from here).

## Keeping it up to date

**When a change touches what the console looks like, update the canvas in the same change, and
before every release regenerate this export and review [`../console.md`](../console.md)** (a new
screen, URL or action gets its section there).

1. Download the canvas files into a folder, as the artifact serves them: `project/canvas.json`,
   `project/*.dc.html` and the uploaded flag (`b78ce1432609f9c95c8462b3917deac7.svg`).
2. From the root of the repo, with Chrome and ffmpeg installed:

   ```bash
   python docs/design/tool/export.py <that folder>
   ```

   It renders the screens listed in `PICK` with headless Chrome (`tool/support.js` stands in for
   the canvas runtime: it runs each artboard's `renderVals()` with its default props) and rewrites
   `screens/` and the PDF. A new screen goes into `PICK`; placeholder data left in the canvas
   (bucket names like `asdasd`) is replaced through `SUBS`.
3. Look at the result and commit it with the change.

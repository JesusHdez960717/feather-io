"""Aligns the Markdown tables of a text the way the IDE formats them: every column padded to its
widest cell and the separator row with dashes across the whole width (see CLAUDE.md).

Used by the report.py of s3_compat/ and benchmark/ before writing RESULTS.md; it also works on any
Markdown file: `python service/tool/md_tables.py FILE...` rewrites them in place.
"""
import re
import sys
from pathlib import Path

_SEPARATOR = re.compile(r'^\s*\|[\s:\-|]+\|\s*$')


def _cells(line: str) -> list[str]:
    """The cells of a table row. A `|` inside a code span or escaped with `\\` is not a border."""
    cells, current, code, escaped = [], '', False, False
    for ch in line.strip()[1:-1]:
        if escaped:
            current += ch
            escaped = False
        elif ch == '\\' and not code:
            current += ch
            escaped = True
        elif ch == '`':
            current += ch
            code = not code
        elif ch == '|' and not code:
            cells.append(current.strip())
            current = ''
        else:
            current += ch
    cells.append(current.strip())
    return cells


def _align(rows: list[str]) -> list[str]:
    table = [_cells(row) for row in rows]
    columns = max(len(row) for row in table)
    table = [row + [''] * (columns - len(row)) for row in table]
    sides = ['c' if c.startswith(':') and c.endswith(':') else 'r' if c.endswith(':') else 'l'
             for c in table[1]]
    widths = [max([len(row[j]) for i, row in enumerate(table) if i != 1] + [3])
              for j in range(columns)]
    out = []
    for i, row in enumerate(table):
        parts = []
        for j, width in enumerate(widths):
            if i == 1:
                parts.append({'c': ':' + '-' * width + ':', 'r': '-' * (width + 1) + ':'}
                             .get(sides[j], '-' * (width + 2)))
            else:
                cell = {'c': row[j].center, 'r': row[j].rjust}.get(sides[j], row[j].ljust)(width)
                parts.append(f' {cell} ')
        out.append('|' + '|'.join(parts) + '|')
    return out


def align_tables(text: str) -> str:
    """`text` with every table aligned; code blocks are left untouched."""
    lines, out, i, code = text.split('\n'), [], 0, False
    while i < len(lines):
        line = lines[i]
        if line.lstrip().startswith('```'):
            code = not code
        if (not code and line.strip().startswith('|') and i + 1 < len(lines)
                and _SEPARATOR.match(lines[i + 1])):
            end = i
            while end < len(lines) and lines[end].strip().startswith('|'):
                end += 1
            indent = line[:len(line) - len(line.lstrip())]
            out += [indent + row for row in _align(lines[i:end])]
            i = end
            continue
        out.append(line)
        i += 1
    return '\n'.join(out)


if __name__ == '__main__':
    for name in sys.argv[1:]:
        path = Path(name)
        text = path.read_text(encoding='utf-8')
        aligned = align_tables(text)
        if aligned != text:
            path.write_text(aligned, encoding='utf-8', newline='\n')
            print(f'aligned {name}')

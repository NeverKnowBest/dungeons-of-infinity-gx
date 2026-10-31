"""Puts the two sides of every seam between painted rooms together (R1 seventh round).

    python tools/test/seam_sheet.py castle_top_seams            # tools/test/out/<scenario>: writes seams/*.png there
    python tools/test/seam_sheet.py <folder> --scale 0.5        # the contact sheet smaller (default 0.5)

The step "doorshots" of a scenario photographs every door of every painted room in use, Link a little inside it, and
logs a "doorshot" line with the door cell in the level. The camera stops at the room's edge, so the photo of a bottom
door shows the bottom of its room and the photo of the top door of the room below shows that room's top: one above the
other they are the seam as the camera transition scrolls through it (side doors: one beside the other). Writes
seams/<name>_r<A>p<P>_r<B>p<Q>.png per seam at full size and seams/sheet_<name>.png with all of them. Needs Pillow.
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LINE = re.compile(r'doorshot name=(\S+) room=(\d+) pos=(\d+) (\w+) status=(\d+) to=(-?\d+) cell=(-?\d+),(-?\d+)')
GAP = 56        # door cells of a seam: a bottom (right) door cell is 56 px above (left of) the top (left) one behind it


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('folder', help='scenario name (tools/test/out/<name>) or a folder with log.txt and the shots')
    ap.add_argument('--scale', type=float, default=0.5, help='size of the contact sheet (default 0.5)')
    a = ap.parse_args()
    from PIL import Image, ImageDraw
    folder = a.folder if os.path.isdir(a.folder) else os.path.join(HERE, 'out', a.folder)
    log = os.path.join(folder, 'log.txt')
    if not os.path.exists(log):
        sys.exit('no log.txt in %s' % folder)
    doors = {}
    for line in open(log, encoding='utf-8', errors='replace'):
        m = LINE.search(line)
        if m:
            name, room, pos, loc, status, to, x, y = m.groups()
            doors[(name, loc, int(x), int(y))] = (int(room), int(pos), int(status))
    out = os.path.join(folder, 'seams')
    os.makedirs(out, exist_ok=True)
    sheets = {}
    for (name, loc, x, y), (room, pos, status) in sorted(doors.items()):
        if loc not in ('Bottom', 'Right'):
            continue
        other = doors.get((name, 'Top', x, y + GAP) if loc == 'Bottom' else (name, 'Left', x + GAP, y))
        if not other:
            continue
        files = [os.path.join(folder, '%s_r%d_p%d.png' % (name, r, p)) for r, p in ((room, pos), other[:2])]
        if not all(os.path.exists(f) for f in files):
            print('missing shot for %s room %d door %d' % (name, room, pos))
            continue
        ia, ib = (Image.open(f).convert('RGB') for f in files)
        if loc == 'Bottom':
            img = Image.new('RGB', (max(ia.width, ib.width), ia.height + ib.height))
            img.paste(ia, (0, 0))
            img.paste(ib, (0, ia.height))
        else:
            img = Image.new('RGB', (ia.width + ib.width, max(ia.height, ib.height)))
            img.paste(ia, (0, 0))
            img.paste(ib, (ia.width, 0))
        label = '%s_r%dp%d_r%dp%d' % (name, room, pos, other[0], other[1])
        img.save(os.path.join(out, label + '.png'))
        sheets.setdefault(name, []).append((label, status, other[2], img))
    for name, items in sheets.items():
        w = max(int(i.width * a.scale) for _, _, _, i in items)
        h = max(int(i.height * a.scale) for _, _, _, i in items) + 12
        cols = 4
        rows = (len(items) + cols - 1) // cols
        sheet = Image.new('RGB', (cols * (w + 8), rows * (h + 8)), (40, 40, 40))
        d = ImageDraw.Draw(sheet)
        for k, (label, sa, sb, img) in enumerate(items):
            x, y = (k % cols) * (w + 8), (k // cols) * (h + 8)
            sheet.paste(img.resize((int(img.width * a.scale), int(img.height * a.scale)), Image.NEAREST), (x, y + 12))
            d.text((x + 2, y), '%s (%d/%d)' % (label, sa, sb), fill=(255, 255, 255))
        sheet.save(os.path.join(out, 'sheet_%s.png' % name))
        print('%s: %d seams in %s' % (name, len(items), os.path.relpath(os.path.join(out, 'sheet_%s.png' % name))))


if __name__ == '__main__':
    main()

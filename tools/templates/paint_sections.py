"""Sections of painted rooms (rooftops' third round, oct/2026): a part of the room cut off by a low wall, as the layouts
of the dungeons ask (Section_ID of a room), painted with the region's tiles instead of the dungeon's golden rails.

The floor of a painted room is seen as a 5x5 grid of bands: three door slots across (the columns of doors 11, 12 and 1,
the rows of doors 10, 9 and 8) and the two lines between them, where the low wall stands. A section is a set of band
cells, its wall the line cells around it. The canonical sections of the shared templates (1 corner, 2 top middle, 9
wide, 17 strip, and the big corner 21 of the built-in Sections rooms, 1x1 only) are drawn on that grid and turned by the
game's own tables (rt_tables, and the 2x1 table of GetTransformedSectionIDReversed read from the game's code), so every
section id a layout gives has its painted shape.

The low wall is made of the frame's own pieces (kit "parapet"): its rows are rows of the frame's top and bottom walls
(the top edge of the bottom wall over the face of the top wall), its columns the inner edges of the side walls, and
where it meets the frame or itself it takes the frame's corner pieces, so it joins as the approved frame does; under the
top wall a column only hangs from the face's foot (R1 seventh round), the wall whole above it.
"""
import os
import re

import convert
import rt_tables

GRID = 8
CANON = {       # band cells of the section and of its wall, on the grid of a room with the section at the top left
    1: ({(0, 0)}, {(1, 0), (1, 1), (0, 1)}),
    2: ({(2, 0)}, {(1, 0), (1, 1), (2, 1), (3, 1), (3, 0)}),
    9: ({(0, 0), (1, 0), (2, 0)}, {(3, 0), (3, 1), (2, 1), (1, 1), (0, 1)}),
    17: ({(i, 0) for i in range(5)}, {(i, 1) for i in range(5)}),
    # the big corner (doors 11, 12, 10 and 9), a built-in section of the shared Sections templates that layouts give
    # only to 1x1 rooms; outdoor levels paint it like the others (R1 eighth round), in the corners' group
    21: ({(i, j) for i in range(3) for j in range(3)}, {(3, j) for j in range(4)} | {(i, 3) for i in range(3)}),
}
ONLY_1X1 = {21}
GROUP_OF_ID = {}
for _g, _ids in enumerate(((1, 3, 6, 8, 21, 22, 23, 24), (2, 4, 5, 7), tuple(range(9, 17)), (17, 18, 19, 20))):
    for _s in _ids:
        GROUP_OF_ID[_s] = _g
# the door slots on the band grid: (cell, wall)
DOOR_SLOT = {11: ((0, 0), 'Top'), 12: ((2, 0), 'Top'), 1: ((4, 0), 'Top'), 2: ((4, 0), 'Right'), 3: ((4, 2), 'Right'),
             4: ((4, 4), 'Right'), 5: ((4, 4), 'Bottom'), 6: ((2, 4), 'Bottom'), 7: ((0, 4), 'Bottom'),
             8: ((0, 4), 'Left'), 9: ((0, 2), 'Left'), 10: ((0, 0), 'Left')}
# the transforms on the band grid (checked against the door positions of rt_tables in selftest())
BAND_T = {
    'None': lambda i, j: (i, j), 'FlipH': lambda i, j: (4 - i, j), 'FlipV': lambda i, j: (i, 4 - j),
    'FlipHV': lambda i, j: (4 - i, 4 - j), 'RotateCW': lambda i, j: (4 - j, i), 'RotateCCW': lambda i, j: (j, 4 - i),
    'FlipHRotateCW': lambda i, j: (4 - j, 4 - i), 'FlipHRotateCCW': lambda i, j: (j, i),
}
# px of the five column bands and the five row bands, per room size (w, h): door slots and the lines between them.
# The lines are as thick as the parapet: 2 tiles across (a column), 3 tiles down (a row)
BANDS = {
    (256, 256): ([(48, 96), (96, 112), (112, 144), (144, 160), (160, 208)],
                 [(64, 88), (88, 112), (112, 144), (144, 168), (168, 208)]),
    (256, 512): ([(48, 96), (96, 112), (112, 144), (144, 160), (160, 208)],
                 [(64, 160), (160, 184), (184, 336), (336, 360), (360, 464)]),
    (512, 256): ([(48, 160), (160, 176), (176, 336), (336, 352), (352, 464)],
                 [(64, 88), (88, 112), (112, 144), (144, 168), (168, 208)]),
}
GML_TRANSFORMS = os.path.join(convert.REPO, 'game', 'scripts', '__Transformations', '__Transformations.gml')


class SectionError(Exception):
    pass


def _reversed_2x1():
    """{(template id, needed id): transform name} for 2x1 rooms, read from GetTransformedSectionIDReversed."""
    src = open(GML_TRANSFORMS, encoding='utf-8').read()
    start = src.index('function GetTransformedSectionIDReversed(')
    end = src.find('\nfunction ', start + 10)
    body = src[start:end if end != -1 else len(src)]
    out = {}
    parts = re.split(r'\n\t\tcase (\d+):', body)
    for k in range(1, len(parts), 2):
        tid, chunk = int(parts[k]), parts[k + 1]
        if 'if(_2x1Room)' in chunk:
            chunk = chunk.split('if(_2x1Room)', 1)[1].split('}else{', 1)[0]
        for n, t in re.findall(r'case (\d+): return ObjTransformation\.(\w+)', chunk):
            out[(tid, int(n))] = t
    return out


def shapes(size):
    """{section id: (section cells, wall cells)} on the band grid of a room of that size (w, h)."""
    out = {}
    if size == (512, 256):
        rev = _reversed_2x1()
        for c, (sec, wall) in CANON.items():
            if c in ONLY_1X1:
                continue
            for (tid, n), t in rev.items():
                if tid == c and n not in out:
                    f = BAND_T[t]
                    out[n] = ({f(*x) for x in sec}, {f(*x) for x in wall})
        return out
    names = convert.TRANSFORMS if size == (256, 256) else ['None', 'FlipH', 'FlipV', 'FlipHV']
    for c, (sec, wall) in CANON.items():
        if c in ONLY_1X1 and size != (256, 256):
            continue
        for t in names:
            n = c if t == 'None' else rt_tables.SECTION_ID[t].get(c, c)
            if n not in out:
                f = BAND_T[t]
                out[n] = ({f(*x) for x in sec}, {f(*x) for x in wall})
    return out


def doors_of(sec):
    return sorted(p for p, (cell, _) in DOOR_SLOT.items() if cell in sec)


def selftest():
    inv = {v: k for k, v in DOOR_SLOT.items()}
    side = {'None': {}, 'FlipH': {'Left': 'Right', 'Right': 'Left'}, 'FlipV': {'Top': 'Bottom', 'Bottom': 'Top'},
            'FlipHV': {'Left': 'Right', 'Right': 'Left', 'Top': 'Bottom', 'Bottom': 'Top'},
            'RotateCW': {'Top': 'Right', 'Right': 'Bottom', 'Bottom': 'Left', 'Left': 'Top'},
            'RotateCCW': {'Top': 'Left', 'Left': 'Bottom', 'Bottom': 'Right', 'Right': 'Top'},
            'FlipHRotateCW': {'Top': 'Right', 'Right': 'Top', 'Bottom': 'Left', 'Left': 'Bottom'},
            'FlipHRotateCCW': {'Top': 'Left', 'Left': 'Top', 'Bottom': 'Right', 'Right': 'Bottom'}}
    for ti, t in enumerate(convert.TRANSFORMS):
        for p, (cell, wall) in DOOR_SLOT.items():
            q = inv[(BAND_T[t](*cell), side[t].get(wall, wall))]
            if q != convert.transformed_door_position(p, ti):
                raise SectionError('band transform %s moves door %d to %d, the game to %d'
                                   % (t, p, q, convert.transformed_door_position(p, ti)))
    # the canonical doors are the ones of make_rooms.SECTIONS
    for c, d in ((1, [10, 11]), (2, [12]), (9, [10, 11, 12]), (17, [1, 2, 10, 11, 12]), (21, [9, 10, 11, 12])):
        if doors_of(CANON[c][0]) != d:
            raise SectionError('section %d has doors %s, not %s' % (c, doors_of(CANON[c][0]), d))


class Parapet:
    """Paints the low wall of a section on a grid of 8x8 tiles, with the kit's frame pieces."""

    def __init__(self, kit, frame, where):
        p = kit.parapet
        if not p:
            raise SectionError('%s: sections need a "parapet" in the kit' % where)
        self.kit, self.where = kit, where
        self.part = {}
        for row, names in (('top', frame['top']), ('middle', frame['middle']), ('bottom', frame['bottom'])):
            self.part[row] = [kit.get(n, where) for n in names]
        self.h = p['h']             # rows: [frame row, block row, "t" or "b"]
        self.v = p['v']             # columns: [side ("left" or "right" pieces), block column, "l" or "r"]
        if len(self.h) != 3 or len(self.v) != 2:
            raise SectionError('%s: the parapet is 3 rows of the frame ("h") by 2 columns ("v")' % where)

    def tile(self, cell, qx, qy):
        """(tile, flags) at quadrant qx, qy of a cell (block, mirrored, flipped), or None."""
        block, m, v = cell
        k = ((1 - qx) if m else qx) + 2 * ((1 - qy) if v else qy)
        t, fl = self.kit.blocks[block][k]
        if not t:
            return None
        return (t, fl ^ (1 if m else 0) ^ (2 if v else 0))

    def piece_cell(self, row, col, brow, bcol):
        """The cell at block row, block column of a frame piece (row: top/middle/bottom; col 0 left, 1 mid, 2 right)."""
        piece = self.part[row][col]
        return piece[brow % len(piece)][bcol % len(piece[0])]

    def h_tiles(self, r, col, bcol, qx):
        frow, brow, half = self.h[r]
        return self.tile(self.piece_cell(frow, col, brow, bcol), qx, 0 if half == 't' else 1)

    def paint(self, grid, wall, cols, rows, W, H):
        """Paints the wall band cells of a section on grid (rows of 8x8 tiles)."""
        def put(tx, ty, t):
            if t is not None and 0 <= ty < len(grid) and 0 <= tx < len(grid[0]):
                grid[ty][tx] = t
        ix = [(a // GRID, b // GRID) for a, b in cols]
        iy = [(a // GRID, b // GRID) for a, b in rows]
        if ix[1][1] - ix[1][0] != 2 or iy[1][1] - iy[1][0] != 3:
            raise SectionError('%s: the lines of the bands are not 2 tiles across and 3 down' % self.where)
        mid_w = len(self.part['top'][1][0])
        v_side = {'left': 0, 'right': 2}

        def v_tile(c, ty):      # column c (0 left, 1 right) of a straight low wall
            side, bcol, half = self.v[c]
            return self.tile(self.piece_cell('middle', v_side[side], 0, bcol), 0 if half == 'l' else 1, ty % 2)

        # straight columns (line bands 1 and 3 across, door rows 0, 2, 4 down)
        for (i, j) in wall:
            if i % 2 == 1 and j % 2 == 0:
                for ty in range(iy[j][0], iy[j][1]):
                    for c in range(2):
                        put(ix[i][0] + c, ty, v_tile(c, ty))
        # straight rows, through the crossings
        hrows = {}
        for (i, j) in wall:
            if j % 2 == 1:
                hrows.setdefault(j, set()).add(i)
        for j, cells in hrows.items():
            for i in cells:
                for tx in range(ix[i][0], ix[i][1]):
                    for r in range(3):
                        put(tx, iy[j][0] + r, self.h_tiles(r, 1, (tx // 2) % mid_w, tx % 2))
            # its ends: at a side wall the frame's corner pieces (the bottom wall's and the top wall's joins with the
            # side walls), else a free end, cut like the wall beside a passage of the top wall
            lo, hi = min(cells), max(cells)
            for end, i in (('left', lo), ('right', hi)):
                at_frame = (i == 0 and end == 'left') or (i == 4 and end == 'right')
                for r in range(3):
                    ty = iy[j][0] + r
                    if at_frame:
                        x0 = ix[0][0] - 4 if end == 'left' else ix[4][1]
                        col = 0 if end == 'left' else 2
                        bcols = (1, 2) if end == 'left' else (0, 1)
                        for n, bc in enumerate(bcols):
                            for qx in range(2):
                                put(x0 + n * 2 + qx, ty, self.h_tiles(r, col, bc, qx))
                    elif r > 0:
                        opening = self.kit.get(self.kit.openings['Top'], self.where)
                        frow, brow, half = self.h[r]
                        cell = opening[brow % len(opening)][-1 if end == 'left' else 0]
                        x0 = ix[i][0] if end == 'left' else ix[i][1] - 2
                        for qx in range(2):
                            put(x0 + qx, ty, self.tile(cell, qx, 0 if half == 't' else 1))
        # where a column meets the frame or a row: 4 tiles across, the frame's own corners
        for (i, j) in wall:
            if not (i % 2 == 1 and j % 2 == 0):
                continue
            x0 = ix[i][0] - 1
            for dj, edge in ((-1, 'top'), (1, 'bottom')):
                nj = j + dj
                if not 0 <= nj <= 4:
                    # the frame: under its top wall the column just hangs from the face's foot, the wall whole above
                    # it (R1 seventh round: the frame's corners on both sides of the column, with their posts up to
                    # the room's edge, cut the top wall into blocks and ran into the next top door's wall end);
                    # onto its bottom wall's edge row it takes the bottom wall's corners
                    if edge == 'top':
                        continue
                    else:
                        for qy in range(2):
                            ty = iy[4][1] + qy
                            self._join(put, x0, ty, 'bottom', 0, qy, True, True, v_tile)
                    continue
                if (i, nj) not in wall:
                    continue
                left, right = (i - 1, nj) in wall, (i + 1, nj) in wall
                if edge == 'bottom':
                    # onto a row from above: the bottom wall's corners at the row's edge (and the tile above it)
                    frow, brow, half = self.h[0]
                    self._join(put, x0, iy[nj][0] - 1, frow, brow, 0, left, right, v_tile)
                    self._join(put, x0, iy[nj][0], frow, brow, 1, left, right, v_tile)
                else:
                    # under a row: the top wall's corners at the row's face
                    for r in range(1, 3):
                        frow, brow, half = self.h[r]
                        self._join(put, x0, iy[nj][0] + r, frow, brow, 0 if half == 't' else 1, left, right, v_tile)

    def _join(self, put, x0, ty, frow, brow, qy, left, right, v_tile):
        """4 tiles at x0..x0+3 across a column (x0 + 1, x0 + 2): the right piece's columns 0-1 inner halves and the
        left piece's columns 1-2 inner halves, as where a side wall meets the frame's top or bottom wall. On a side
        the row does not go to, the column keeps its own edge and the floor beside it stays."""
        cells = [(2, 0, 1), (2, 1, 0), (0, 1, 1), (0, 2, 0)]     # (piece, block column, quadrant x)
        for n, (col, bc, qx) in enumerate(cells):
            if (n < 2 and not left) or (n >= 2 and not right):
                if n in (1, 2):
                    put(x0 + n, ty, v_tile(n - 1, ty))
                continue
            put(x0 + n, ty, self.tile(self.piece_cell(frow, col, brow, bc), qx, qy))

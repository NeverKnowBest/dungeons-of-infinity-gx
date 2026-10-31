"""Painted rooms (roadmap F12b): whole rooms painted tile by tile with a region tileset, for make_rooms.py.

A room set's rooms.json may have, beside its "halves", a "kit" and a list of "painted" rooms:

    "kit": {
      "tiles": "CastleTop",                     # region tileset (data/room-templates/tilesets/<Name>.json, imported)
      "area": "1B",                             # ALttP area the pieces are cut from (tiles/areas.json of the region)
      "pieces": {                               # cells of that area, 16x16 blocks: [col, row, w, h] or rows of [col, row]
        "floor": [15, 7, 1, 1],                 #   ([col, row, "m"] is that cell mirrored, "v" flipped, and any other
        "bottom_left": [[[16, 0], ...]]},       #   word a recolored copy from the region's tiles/extra.json)
      "frame": {"top": ["top_left", "top_mid", "top_right"],          # the walls: left and right pieces at the corners,
                "middle": ["side_left", "floor", "side_right"],       #   the mid piece repeated across; the middle row
                "bottom": ["bottom_left", "bottom_mid", "bottom_right"]},   # repeated down between top and bottom
      "frames": {"view_left": {...}},           # other frames a room may take ("frame": "view_left")
      "openings": {"Top": "open_top", "Bottom": "open_bottom"},       # painted on RegionOpen over a door in use,
                                                                      #   16 px left of the door cell, at the wall
      "gate": {"piece": "gate", "at": [-32, 16]},                     # RegionGate: the entrance or exit of the level in
                                                                      #   a top door, px from the door cell's x (and y)
      "grass": {"full": [16, 44], "top": [48, 57, "floor"], ...},     # grass spreading over the floor (nature motifs)
      "nature": {"tree": "tree", "bush": "bush", "tufts": ["tuft"]}   # the pieces of the nature motifs
    },
    "painted": [
      {"name": "Terrace", "size": "1x1", "doors": [12, 6],           # 1x1, 1x2 or 2x1; door positions of the room (DOOR_XY)
       "decor": [{"piece": "tower", "at": [48, 16], "pair": true},    # px on the 8 px grid; pair: mirrored copy too
                 {"piece": "crest", "at": [112, 112]}],
       "nature": ["Nature/trees"],                                    # nature motifs (see NATURE_MOTIFS)
       "frame": "view_left",                                          # optional, a frame of kit "frames"
       "transforms": "None,FlipH",                                    # optional; that is the default
       "props": {...}}
    ]

The room becomes a Whole Main_Upper template with the tile layers Region (the room, every door closed),
RegionOpen (the passage of each door) and RegionGate (the gate of each top door that has room for it), its Doors,
an enemy area and a treasure and crystal spot on the floor. The game paints it with the transform it picks and makes
the walls from the tile classes (RegionRoom_Paint). Pieces are cells of a real ALttP area, so the walls, their ends
and the decoration keep the original light and perspective.
"""
import json
import os

import convert
import paint_auto
import paint_sections

GRID = 8
SIZES = {'1x1': (256, 256, 0), '1x2': (256, 512, 1), '2x1': (512, 256, 2)}    # w, h, RoomSize
ROOM_KEYS = {'name', 'size', 'doors', 'decor', 'transforms', 'props', 'comment', 'frame', 'nature', 'sections', 'fallback'}
SPECIAL_KEYS = {'frame', 'comment'}
SPECIAL_LAYERS = ('Water', 'FloorObjs', 'Objs')      # the objects of a special room that are copied into its painted copy
WALKED_OBJECTS = {86}       # Objs Link walks over (Rupee_05: picked up); the others (chests, statues, the altar, shops...) block
KIT_KEYS = {'tiles', 'area', 'pieces', 'frame', 'frames', 'openings', 'gate', 'grass', 'nature', 'parapet', 'auto',
            'comment'}
GRASS_KEYS = ('full', 'top', 'bottom', 'left', 'corner', 'inner')
# Nature motifs (docs/design/direcao.md, "Natureza invadindo"): pieces on a patch of grass that spreads over the
# floor. Trees (solid tiles): one in the middle of each half of a 2x1 or 1x2 room (a pair); bushes: a 2x2 clump on each
# side of the middle axis (a mirrored pair), at the first height that keeps the door lanes free, each bush an oBush the
# game puts on the grass (RegionBushes). Tufts go on the grass only.
NATURE_MOTIFS = ('Nature/trees', 'Nature/bushes')
DECOR_KEYS = {'piece', 'at', 'pair', 'mirror'}
TILESETS_DIR = os.path.join(convert.TEMPLATE_DIR, 'tilesets')
TILED_H, TILED_V = 0x80000000, 0x40000000


class PaintError(Exception):
    pass


class Kit:
    """The pieces of a region tileset a set paints with, resolved to 16x16 blocks."""

    def __init__(self, d, where):
        for k in d:
            if k not in KIT_KEYS:
                raise PaintError('%s: unknown key "%s" (keys: %s)' % (where, k, ', '.join(sorted(KIT_KEYS))))
        self.name = d.get('tiles')
        ts = os.path.join(TILESETS_DIR, '%s.json' % self.name)
        if not os.path.exists(ts):
            raise PaintError('%s: no Tiled tileset %s (tools/import/import_region.py writes it)'
                             % (where, os.path.relpath(ts, convert.REPO)))
        self.tileset_path = ts
        tsj = json.load(open(ts, encoding='utf-8'))
        folder = os.path.dirname(os.path.normpath(os.path.join(TILESETS_DIR, tsj['image'])))
        tiles = json.load(open(os.path.join(folder, 'tiles.json'), encoding='utf-8'))
        self.blocks = [b['tiles'] for b in tiles['blocks']]
        self.auto = None
        if d.get('auto') is not None:
            # rooms painted from the set's frame under the fitting rules (roadmap F12b-2, paint_auto.py)
            set_dir = os.path.join(convert.TEMPLATE_DIR, 'sets', where.split()[0])
            try:
                self.auto = paint_auto.AutoKit(d['auto'], folder, set_dir, where)
            except paint_auto.AutoError as e:
                raise PaintError(str(e))
            self.blocks = self.auto.rules.blocks
            data = os.path.join(convert.REPO, 'game', 'datafiles', 'data', 'tiles', self.name + '.json')
            self.solid = json.load(open(data, encoding='utf-8'))['solid']
            self.frames, self.frame, self.openings, self.gate, self.grass = {'': {}}, {}, {}, {}, {}
            self.parapet, self.nature, self.pieces = None, {}, {}
            return
        # recolored copies of area cells (tiles/extra.json): (map16, recolor name) -> block
        self.recolored = {(b['map16'], b['recolor']): i for i, b in enumerate(tiles['blocks']) if b.get('recolor')}
        self.block_map16 = [b['map16'] for b in tiles['blocks']]
        self.halves = {}    # (col, row, recolor, down) of an "h" or "vh" cell -> its block, after the region's (half_block)
        data = os.path.join(convert.REPO, 'game', 'datafiles', 'data', 'tiles', self.name + '.json')
        self.solid = json.load(open(data, encoding='utf-8'))['solid']
        areas = json.load(open(os.path.join(folder, 'areas.json'), encoding='utf-8'))
        if d.get('area') not in areas:
            raise PaintError('%s: area "%s" not in %s/areas.json (areas: %s)'
                             % (where, d.get('area'), os.path.relpath(folder, convert.REPO), ', '.join(areas)))
        self.area = areas[d['area']]
        self.pieces = {n: self.piece(v, '%s piece %s' % (where, n)) for n, v in (d.get('pieces') or {}).items()}
        self.frames = {'': self.check_frame(d.get('frame') or {}, where)}
        for name, f in (d.get('frames') or {}).items():
            self.frames[name] = self.check_frame(f, '%s frame %s' % (where, name))
        self.frame = self.frames['']
        self.openings = d.get('openings') or {}
        for loc, n in self.openings.items():
            if loc not in ('Top', 'Bottom', 'Left', 'Right'):
                raise PaintError('%s: openings are Top, Bottom, Left or Right, not %s' % (where, loc))
            self.get(n, where)
        # the level's entrance and exit in a door of the wall (a gate in the top wall, stairs down through the bottom)
        self.gate = {}
        for loc, g in (d.get('gate') or {}).items():
            if loc not in ('Top', 'Bottom') or not isinstance(g, dict) or set(g) - {'piece', 'at'}:
                raise PaintError('%s: gate is {"Top" or "Bottom": {"piece", "at": [dx, dy]}} (dy from the top edge, or '
                                 'from the bottom edge for Bottom)' % where)
            self.get(g.get('piece'), where)
            self.gate[loc] = g
        self.grass = {}
        if d.get('grass'):
            for k in GRASS_KEYS:
                if k not in d['grass']:
                    raise PaintError('%s: grass needs %s' % (where, ', '.join(GRASS_KEYS)))
                self.grass[k] = self.piece([[d['grass'][k]]], '%s grass %s' % (where, k))[0][0]
        self.parapet = d.get('parapet')     # the low wall of a section (paint_sections)
        self.nature = d.get('nature') or {}
        for k, n in self.nature.items():
            for name in (n if isinstance(n, list) else [n]):
                self.get(name, where)

    def check_frame(self, f, where):
        for row in ('top', 'middle', 'bottom'):
            names = f.get(row)
            if not (isinstance(names, list) and len(names) == 3):
                raise PaintError('%s: frame "%s" needs three pieces (left, middle, right)' % (where, row))
            for n in names:
                self.get(n, where)
        return f

    def cell(self, cell, where):
        """(block, mirrored, flipped) of [col, row, flags...]: "m" mirrored, "v" flipped, "h" the right half of the
        cell beside the left half of the next one (half_block), "vh" the bottom half of the cell above the top half of
        the one below it, any other word the copy of that cell recolored by the region's tiles/extra.json (with "h" or
        "vh", of each half that has that copy)."""
        c, r = cell[0], cell[1]
        block = self.area[r][c]
        m = v = False
        for half in ('h', 'vh'):
            if half in cell[2:]:
                words = [f for f in cell[2:] if f not in ('m', 'v', 'h', 'vh')]
                return (self.half_block(c, r, words[0] if words else None, where, half == 'vh'),
                        'm' in cell[2:], 'v' in cell[2:])
        for f in cell[2:]:
            if f == 'm':
                m = True
            elif f == 'v':
                v = True
            else:
                key = (self.block_map16[block], f)
                if key not in self.recolored:
                    raise PaintError('%s: cell %d,%d has no "%s" copy (add it to "recolor" in the region\'s '
                                     'tiles/extra.json and run tools/alttp/owdump.py tiles)' % (where, c, r, f))
                block = self.recolored[key]
        return (block, m, v)

    def half_block(self, c, r, recolor, where, down=False):
        """A block that no map has: the right half of cell c, r beside the left half of cell c + 1, r (each the copy
        recolored by recolor where the region has one). A wall's end moved half a block, so a passage cut in a wall
        ends with the wall's own corner and stays as wide as its door (R1, sixth round). down: the bottom half of
        cell c, r above the top half of cell c, r + 1, a wall's edge moved half a block down, so a side passage
        between two thin rims is as tall as its door (R1, seventh round)."""
        if (r + 1 >= len(self.area)) if down else (c + 1 >= len(self.area[r])):
            raise PaintError('%s: cell %d,%d "%s" needs the cell %s' % (where, c, r, 'vh' if down else 'h',
                                                                       'below it' if down else 'to its right'))
        key = (c, r, recolor, down)
        if key not in self.halves:
            parts = []
            for cc, rr in ((c, r), (c, r + 1)) if down else ((c, r), (c + 1, r)):
                b = self.area[rr][cc]
                if recolor is not None:
                    b = self.recolored.get((self.block_map16[b], recolor), b)
                parts.append(self.blocks[b])
            self.halves[key] = len(self.blocks)
            if down:
                self.blocks.append([parts[0][2], parts[0][3], parts[1][0], parts[1][1]])
            else:
                self.blocks.append([parts[0][1], parts[1][0], parts[0][3], parts[1][2]])
        return self.halves[key]

    def piece(self, v, where):
        """Rows of (block, mirrored, flipped)."""
        try:
            if len(v) == 4 and all(isinstance(x, int) for x in v):
                c, r, w, h = v
                cells = [[[c + i, r + j] for i in range(w)] for j in range(h)]
            else:
                cells = v
            out = [[self.cell(cell, where) for cell in row] for row in cells]
        except (TypeError, IndexError, ValueError):
            raise PaintError('%s: a piece is [col, row, w, h] or rows of [col, row] (cells of the area)' % where)
        if not out or any(len(r) != len(out[0]) for r in out):
            raise PaintError('%s: the rows of a piece must have the same length' % where)
        return out

    def get(self, name, where):
        if name not in self.pieces:
            raise PaintError('%s: no piece "%s" in the kit' % (where, name))
        return self.pieces[name]


class Painted:
    """A whole painted room, laid out like a Half for build_map (layers, groups, split ids) plus its tile layers."""
    painted = True
    symmetric = True
    split_ids = [0]

    def __init__(self, d, kit, where, special=None):
        self.d, self.kit, self.where = d, kit, where
        # special: a painted copy of a shared special room ({"type", "objects": {layer: [Tiled objects]}, "props"}):
        # class Special, one door in use at a time (so any two may touch), its own objects instead of enemies and spots
        self.special = special
        for k in d:
            if k not in ROOM_KEYS:
                raise PaintError('%s: unknown key "%s" (keys: %s)' % (where, k, ', '.join(sorted(ROOM_KEYS))))
        self.name = d.get('name')
        if not self.name:
            raise PaintError('%s: needs a "name"' % where)
        self.cls = 'Special' if special else 'Main_Upper'
        self.room_type = special['type'] if special else ''
        if d.get('size', '1x1') not in SIZES:
            raise PaintError('%s: size must be 1x1, 1x2 or 2x1' % where)
        self.w, self.h, self.size_index = SIZES[d.get('size', '1x1')]
        self.cw, self.ch = self.w // 16, self.h // 16       # 16x16 cells
        self.layers, self.groups = {}, {}
        self.base = [[None] * (self.cw * 2) for _ in range(self.ch * 2)]     # 8x8 tiles: (tile, flags) or None
        self.open = [[None] * (self.cw * 2) for _ in range(self.ch * 2)]
        # the door each tile of RegionOpen belongs to (the last passage stamped on it): the game opens only the tiles of
        # the door, so a passage never runs on into a neighbouring position's (R1 seventh round, rooms with every door)
        self.owner = [[0] * (self.cw * 2) for _ in range(self.ch * 2)]
        self.gate = [[None] * (self.cw * 2) for _ in range(self.ch * 2)]
        self.gate_doors = []
        self.gate_boxes = []
        self.bushes = []        # px of the 16x16 cells where the game puts an oBush (Nature/bushes, R1 eighth round)
        self.object_boxes = [(o['x'], o['y'], o['width'], o['height']) for objs in (special or {}).get('objects', {}).values()
                             for o in objs]
        self.build()

    # ---------------------------------------------------------------- painting

    def stamp(self, grid, piece, x, y, mirror=False, where='', clip_top=0):
        """Paints a piece with its top left corner at x, y (px, 8 px grid); mirror turns the whole piece. Rows above
        clip_top (px) are left as they are."""
        if x % GRID or y % GRID:
            raise PaintError('%s: %s,%s is off the 8 px grid' % (where, x, y))
        w = len(piece[0])
        for j, row in enumerate(piece):
            for i in range(w):
                block, m, v = row[w - 1 - i] if mirror else row[i]
                m = m != mirror
                for k, (tile, fl) in enumerate(self.kit.blocks[block]):
                    tx, ty = k % 2, k // 2
                    if m:
                        tx, fl = 1 - tx, fl ^ 1
                    if v:
                        ty, fl = 1 - ty, fl ^ 2
                    gx, gy = x // GRID + i * 2 + tx, y // GRID + j * 2 + ty
                    if 0 <= gy < len(grid) and 0 <= gx < len(grid[0]) and gy * GRID >= clip_top:
                        grid[gy][gx] = (tile, fl) if tile else None

    def fill(self, grid, piece, x0, y0, x1, y1):
        """Repeats a piece over the box x0..x1, y0..y1 (px), cut at its right and bottom edges."""
        pw, ph = len(piece[0]) * 16, len(piece) * 16
        for y in range(y0, y1, ph):
            for x in range(x0, x1, pw):
                tmp = [[None] * len(grid[0]) for _ in grid]
                self.stamp(tmp, piece, x, y)
                for gy in range(y // GRID, min(y1, y + ph) // GRID):
                    for gx in range(x // GRID, min(x1, x + pw) // GRID):
                        if tmp[gy][gx] is not None or grid[gy][gx] is not None:
                            grid[gy][gx] = tmp[gy][gx]

    def build(self):
        k, d, where = self.kit, self.d, self.where
        if k.auto:
            return self.build_auto()
        W, H = self.w, self.h
        if d.get('frame', '') not in k.frames:
            raise PaintError('%s: no frame "%s" in the kit (frames: %s)' % (where, d.get('frame'), ', '.join(sorted(k.frames))))
        frame = k.frames[d.get('frame', '')]
        top, mid, bot = ([k.get(n, where) for n in frame[r]] for r in ('top', 'middle', 'bottom'))
        th, bh = len(top[0]) * 16, len(bot[0]) * 16
        lw, rw = len(mid[0][0]) * 16, len(mid[2][0]) * 16
        self.inner = (lw, th, W - rw, H - bh)          # the floor between the walls
        for row, y0, y1 in ((top, 0, th), (mid, th, H - bh), (bot, H - bh, H)):
            left, centre, right = row
            self.fill(self.base, left, 0, y0, len(left[0]) * 16, y1)
            self.fill(self.base, centre, len(left[0]) * 16, y0, W - len(right[0]) * 16, y1)
            self.fill(self.base, right, W - len(right[0]) * 16, y0, W, y1)

        # doors: the Doors objects and the passages painted on RegionOpen
        coords = convert.DOOR_XY[self.size_index]
        doors = d.get('doors')
        # "all": every position, a room for whatever doors the layout gives (passages of neighbouring positions touch,
        # but the layouts never use two neighbours); it is picked only when no other room of the set fits (fallback)
        self.all_doors = doors == 'all'
        if self.all_doors:
            doors = list(range(1, 13))
        if not isinstance(doors, list) or not doors:
            raise PaintError('%s: "doors" lists the door positions of the room (1 to 12), or is "all"' % where)
        self.doors = {}
        boxes = []
        self.blocked_doors = []
        under = []
        for p in doors:
            if not isinstance(p, int) or not 1 <= p <= 12:
                raise PaintError('%s: door %s is not a position 1 to 12' % (where, p))
            loc = convert.door_location(p)
            if self.special and self.door_blocked(p, loc, k.get(k.openings[loc], where), W, H, th, bh, lw, rw):
                self.blocked_doors.append(p)
                continue
            if loc not in k.openings:
                raise PaintError('%s: door %d is on the %s wall and the kit has no opening there' % (where, p, loc))
            x, y = coords[(p - 1) * 2], coords[(p - 1) * 2 + 1]
            box = {'Top': (x, y, 32, 24), 'Bottom': (x, y, 32, 24), 'Left': (x, y, 24, 32), 'Right': (x, y, 24, 32)}[loc]
            gid = {'Top': 'DoorT', 'Bottom': 'DoorB', 'Left': 'DoorL', 'Right': 'DoorR'}[loc]
            self.doors[p] = (loc, box)
            self.add('Doors', gid, box)
            piece = k.get(k.openings[loc], where)
            pw, ph = len(piece[0]) * 16, len(piece) * 16
            ox = {'Top': (x - 16, 0), 'Bottom': (x - 16, H - ph), 'Left': (0, y - 16), 'Right': (W - pw, y - 16)}[loc]
            # a side door by the top corner (positions 2 and 10) runs under the top wall: its passage leaves the
            # wall's face whole above it instead of cutting the corner away (R1, sixth round: "canto com aresta vazia"),
            # and the top wall goes on over it to the room's edge (under_top_wall). Only there: the first row of any
            # other side passage is the edge of the cream above the corridor, with its outline (R1 eighth round: it was
            # cut at the door cell, and the cream ended straight)
            side = loc in ('Left', 'Right')
            self.stamp_open(piece, ox[0], ox[1], p, clip_top=th if side else 0)
            if side and y - 16 < th:
                under.append((p, loc, y))
            boxes.append((p, (ox[0], ox[1], pw, ph)))
        for p, loc, y in under:         # after every passage: it keeps off the tiles of the next top door's
            self.under_top_wall(p, loc, y, top[1], th, lw, rw)
        for i, (p, a) in enumerate([] if self.special or self.all_doors else boxes):
            for q, b in boxes[i + 1:]:
                if convert.rect_overlap((a[0], a[1], a[0] + a[2], a[1] + a[3]), (b[0], b[1], b[0] + b[2], b[1] + b[3])):
                    raise PaintError('%s: the passages of doors %d and %d touch' % (where, p, q))

        self.decor_boxes = []
        self.bare = [row[:] for row in self.base]      # the frame without decoration (what a gate shows around it)
        for dd in d.get('decor', []):
            if not isinstance(dd, dict) or any(key not in DECOR_KEYS for key in dd):
                raise PaintError('%s: decor is {"piece", "at": [x, y], "pair", "mirror"}' % where)
            piece = k.get(dd.get('piece'), where)
            x, y = dd.get('at', [0, 0])
            pw, ph = len(piece[0]) * 16, len(piece) * 16
            spots = [(x, y, dd.get('mirror', False))]
            if dd.get('pair'):
                spots.append((W - x - pw, y, not dd.get('mirror', False)))
            for sx, sy, m in spots:
                for p, b in boxes:
                    if convert.rect_overlap((sx, sy, sx + pw - 1, sy + ph - 1), (b[0], b[1], b[0] + b[2] - 1, b[1] + b[3] - 1)):
                        raise PaintError('%s: decor %s at %d,%d covers the passage of door %d' % (where, dd['piece'], sx, sy, p))
                self.stamp(self.base, piece, sx, sy, m, where)
                self.decor_boxes.append((sx, sy, pw, ph))

        self.gates()
        for motif in d.get('nature', []):
            self.nature(motif)
        self.check_passages()
        if self.special:
            self.copy_objects()
        else:
            self.furnish()
            self.sections()

    def stamp_open(self, piece, x, y, p, clip_top=0):
        """Stamps door p's passage on RegionOpen, the tiles marked as door p's."""
        tmp = [[None] * len(self.open[0]) for _ in self.open]
        self.stamp(tmp, piece, x, y, where=self.where, clip_top=clip_top)
        for gy, row in enumerate(tmp):
            for gx, t in enumerate(row):
                if t is not None:
                    self.open[gy][gx] = t
                    self.owner[gy][gx] = p

    def under_top_wall(self, p, loc, y, centre, th, lw, rw):
        """The passage of a side door by the top corner runs under the top wall (R1 seventh round): over it the wall
        goes on to the room's edge, as the 0x1B moat runs under its wall, instead of the corner's post with the roof's
        cream cut straight above the passage. The wall's middle piece goes on in step over the side wall's columns,
        the corner's post included, except on the tiles of another door's passage (the next top door's in a room with
        every door, whose wall end overlaps the corner's last 8 px), and where the top wall is not as low as the door
        (the special rooms' frame) the floor goes up to it."""
        W = self.w
        pw = len(centre[0]) * 16
        tmp = [[None] * len(self.open[0]) for _ in self.open]
        x0 = lw - pw * ((lw + pw - 1) // pw)
        for bx in range(x0, W, pw):
            self.stamp(tmp, centre, bx, 0, where=self.where)
        cols = range(0, lw // GRID) if loc == 'Left' else range((W - rw) // GRID, W // GRID)
        floor = self.kit.get('floor', self.where)[0][0]
        for gx in cols:
            for gy in range(th // GRID):
                if tmp[gy][gx] is not None and self.owner[gy][gx] in (0, p):
                    self.open[gy][gx] = tmp[gy][gx]
                    self.owner[gy][gx] = p
        if y > th:
            fcols = range(0, lw // GRID) if loc == 'Left' else range((W - rw) // GRID, W // GRID)
            ftmp = [[None] * len(self.open[0]) for _ in self.open]
            for gx in fcols:
                for gy in range(th // GRID, y // GRID):
                    self.stamp(ftmp, [[floor]], (gx // 2) * 16, (gy // 2) * 16, where=self.where)
                    self.open[gy][gx] = ftmp[gy][gx]
                    self.owner[gy][gx] = p

    def door_blocked(self, p, loc, piece, W, H, th, bh, lw, rw):
        """Whether Link cannot walk from door p of a special room into the room: from inside its passage, 16x16 at a
        time over walkable tiles (the frame with this passage open) clear of the room's objects (Objs and Water; floor
        objects and rupees are walked over), he must get 40 px past the wall. The objects are laid out for the dungeon's walls,
        thinner than the painted frame: under a dungeon's top wall the altar of a treasure room or a corner statue
        leaves 16 px to walk round it, under the painted one none, and the top door led into the altar (R1 seventh
        round). The game then takes another special room for that door."""
        x, y = convert.DOOR_XY[self.size_index][(p - 1) * 2], convert.DOOR_XY[self.size_index][(p - 1) * 2 + 1]
        grid = [row[:] for row in self.base]
        pw, ph = len(piece[0]) * 16, len(piece) * 16
        ox = {'Top': (x - 16, 0), 'Bottom': (x - 16, H - ph), 'Left': (0, y - 16), 'Right': (W - pw, y - 16)}[loc]
        self.stamp(grid, piece, ox[0], ox[1], where=self.where, clip_top=th if loc in ('Left', 'Right') else 0)
        cw, ch = len(grid[0]), len(grid)
        free = [[grid[j][i] is not None and not self.solid_at(grid, i, j) for i in range(cw)] for j in range(ch)]
        for layer in ('Objs', 'Water'):
            for o in self.special['objects'].get(layer, []):
                if o.get('gid') in WALKED_OBJECTS:
                    continue
                for j in range(max(0, o['y'] // GRID), min(ch, (o['y'] + o['height'] + GRID - 1) // GRID)):
                    for i in range(max(0, o['x'] // GRID), min(cw, (o['x'] + o['width'] + GRID - 1) // GRID)):
                        free[j][i] = False

        def ok(i, j):
            return 0 <= i < cw - 1 and 0 <= j < ch - 1 and free[j][i] and free[j][i + 1] and free[j + 1][i] and free[j + 1][i + 1]
        # the start: Link in the door cell's lane, just inside the wall; the goal: 40 px past the wall
        if loc in ('Top', 'Bottom'):
            sy = (th - 16) // GRID if loc == 'Top' else (H - bh) // GRID
            start = [(i, sy) for i in range(x // GRID, (x + 16) // GRID + 1)]
        else:
            sx = (lw - 16) // GRID if loc == 'Left' else (W - rw) // GRID
            start = [(sx, j) for j in range(y // GRID, (y + 16) // GRID + 1)]
        goal = {'Top': lambda i, j: j * GRID >= th + 40, 'Bottom': lambda i, j: (j + 2) * GRID <= H - bh - 40,
                'Left': lambda i, j: i * GRID >= lw + 40, 'Right': lambda i, j: (i + 2) * GRID <= W - rw - 40}[loc]
        todo = [c for c in start if ok(*c)]
        seen = set(todo)
        while todo:
            i, j = todo.pop()
            if goal(i, j):
                return False
            for n in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)):
                if n not in seen and ok(*n):
                    seen.add(n)
                    todo.append(n)
        return True

    def build_auto(self):
        """The room from the set's frame (paint_auto.py): the shared border around the reference room's inside, the
        decoration, the passage of each door and the gate of the level's entrance or exit, each checked against the
        fitting rules and the approved joins."""
        k, d, where = self.kit, self.d, self.where
        A = k.auto
        W, H, cw, ch = self.w, self.h, self.cw, self.ch
        self.inner = (16, 16, W - 16, H - 16)
        g = A.room(cw, ch)
        self.decor_boxes = []
        for dd in d.get('decor', []):
            if not isinstance(dd, dict) or any(key not in DECOR_KEYS for key in dd):
                raise PaintError('%s: decor is {"piece", "at": [x, y], "pair", "mirror"}' % where)
            if dd.get('piece') not in A.pieces:
                raise PaintError('%s: no piece "%s" in the kit\'s auto pieces' % (where, dd.get('piece')))
            piece = A.pieces[dd['piece']]
            x, y = dd.get('at', [0, 0])
            if x % 16 or y % 16:
                raise PaintError('%s: decor %s at %d,%d is off the 16 px grid of the blocks' % (where, dd['piece'], x, y))
            pw, ph = len(piece[0]), len(piece)
            spots = [(x // 16, y // 16, dd.get('mirror', False))]
            if dd.get('pair'):
                spots.append((cw - x // 16 - pw, y // 16, not dd.get('mirror', False)))
            for sx, sy, m in spots:
                for j in range(ph):
                    for i in range(pw):
                        b = piece[j][pw - 1 - i] if m else piece[j][i]
                        if m:
                            if b not in A.rules.mirror_of:
                                raise PaintError('%s: decor %s mirrored needs the frame\'s "mirror"' % (where, dd['piece']))
                            b = A.rules.mirror_of[b]
                        g[sy + j][sx + i] = b
                self.decor_boxes.append((sx * 16, sy * 16, pw * 16, ph * 16))
        if cw > 16 or ch > 16:
            # a room larger than the frame's: the solver paints its inside around the border and the decoration
            fixed = {(x, y) for y in range(ch) for x in range(cw) if x in (0, cw - 1) or y in (0, ch - 1)}
            fixed |= {(bx // 16 + i, by // 16 + j) for bx, by, bw, bh in self.decor_boxes
                      for i in range(bw // 16) for j in range(bh // 16)}
            try:
                g = A.paint(g, fixed, cw, ch)
            except paint_auto.AutoError as e:
                raise PaintError('%s: %s' % (where, e))
        coords = convert.DOOR_XY[self.size_index]
        doors = d.get('doors')
        self.all_doors = False
        if not isinstance(doors, list) or not doors:
            raise PaintError('%s: "doors" lists the door positions of the room (1 to 12)' % where)
        self.doors, opens, owner, gates = {}, {}, {}, {}
        for p in doors:
            if not isinstance(p, int) or not 1 <= p <= 12:
                raise PaintError('%s: door %s is not a position 1 to 12' % (where, p))
            loc = convert.door_location(p)
            x, y = coords[(p - 1) * 2], coords[(p - 1) * 2 + 1]
            box = {'Top': (x, y, 32, 24), 'Bottom': (x, y, 32, 24), 'Left': (x, y, 24, 32), 'Right': (x, y, 24, 32)}[loc]
            gid = {'Top': 'DoorT', 'Bottom': 'DoorB', 'Left': 'DoorL', 'Right': 'DoorR'}[loc]
            self.doors[p] = (loc, box)
            self.add('Doors', gid, box)
            off = x if loc in ('Top', 'Bottom') else y
            try:
                cells = A.passage(loc, off, cw, ch)
                gate = A.gate(loc, off, cw, ch)
                if A.misfits(self.with_cells(g, cells)):
                    cells = self.repaint_door(g, cells, loc, x, y)
            except paint_auto.AutoError as e:
                raise PaintError('%s: door %d: %s' % (where, p, e))
            for c, b in cells.items():
                if c in opens and opens[c] != b:
                    raise PaintError('%s: doors %d and %d need different blocks at %d,%d (neighbouring doors share '
                                     'the end of a passage: give the room one of them)' % (where, owner[c], p, c[0], c[1]))
                opens[c], owner[c] = b, p
            if gate and not any(convert.rect_overlap((gx * 16, gy * 16, gx * 16 + 15, gy * 16 + 15),
                                                     (o[0], o[1], o[0] + o[2] - 1, o[1] + o[3] - 1))
                                for gx, gy in gate for o in self.object_boxes + self.decor_boxes):
                gates[p] = gate

        def misfit(cells, what):
            bad = A.misfits(self.with_cells(g, cells))
            if bad:
                x, y, kind = bad[0]
                raise PaintError('%s: %s does not fit at block %d,%d (%s; %d misfits): blocks the maps never put '
                                 'together and no approved join (incoming/<region>/tiles/joins.json)'
                                 % (where, what, x, y, kind, len(bad)))
        misfit({}, 'the room')
        for p in self.doors:
            misfit({c: b for c, b in opens.items() if owner[c] == p}, 'door %d open' % p)
        for p, gate in gates.items():
            misfit(gate, 'the gate of door %d' % p)
        self.block_grid = g
        self.open_cells = opens
        self.gate_cells = gates

        def put(grid, x, y, b):
            for q, t in enumerate(A.tiles(b)):
                grid[y * 2 + q // 2][x * 2 + q % 2] = (t[0], t[1]) if t[0] else None
        for y in range(ch):
            for x in range(cw):
                put(self.base, x, y, g[y][x])
        for (x, y), b in opens.items():
            put(self.open, x, y, b)
        # a top door's cell (16 to 48 px down) is below the border's cut: the floor under the cut goes on the open
        # layer too, so the game's flood from the door cell reaches it (RegionRoom_OpenPassage); a passage painted
        # again (repaint_door) keeps its own blocks there
        for p, (loc, (x, y, w, h)) in self.doors.items():
            if loc == 'Top':
                for bx in range(x // 16, (x + 32 + 15) // 16):
                    if (bx, 0) in opens:
                        for by in (1, 2):
                            put(self.open, bx, by, opens.get((bx, by), g[by][bx]))
        self.gate_doors, self.gate_boxes = [], []
        for p, gate in sorted(gates.items()):
            for (x, y), b in gate.items():
                put(self.gate, x, y, b)
            xs = [c[0] for c in gate]
            ys = [c[1] for c in gate]
            self.gate_doors.append(p)
            self.gate_boxes.append((min(xs) * 16, min(ys) * 16, (max(xs) - min(xs) + 1) * 16, (max(ys) - min(ys) + 1) * 16))
        self.bare = [row[:] for row in self.base]
        self.check_passages()
        if self.special:
            self.copy_objects()
        else:
            self.furnish()
            self.sections()

    @staticmethod
    def with_cells(g, cells):
        gg = [row[:] for row in g]
        for (x, y), b in cells.items():
            gg[y][x] = b
        return gg

    def repaint_door(self, g, cells, loc, x, y):
        """The passage of a door whose frame cells do not fit the inside the solver painted: a box around it painted
        again with the cells fixed and its lane walkable. Returns every cell the open door changes."""
        A, cw, ch = self.kit.auto, self.cw, self.ch
        if loc in ('Top', 'Bottom'):
            c0, c1 = x // 16, (x + 32 + 15) // 16
            ys = range(0, 7) if loc == 'Top' else range(ch - 7, ch)
            box = {(bx, by) for bx in range(c0 - 3, c1 + 3) for by in ys}
            lane = {(bx, by) for bx in range(c0, c1) for by in (range(0, 5) if loc == 'Top' else range(ch - 5, ch))}
        else:
            c0, c1 = y // 16, (y + 32 + 15) // 16
            xs = range(0, 7) if loc == 'Left' else range(cw - 7, cw)
            box = {(bx, by) for by in range(c0 - 3, c1 + 3) for bx in xs}
            lane = {(bx, by) for by in range(c0, c1) for bx in (range(0, 5) if loc == 'Left' else range(cw - 5, cw))}
        gg = self.with_cells(g, cells)
        # the border stays the frame's (or the frame's passage), or the neighbouring room would not meet it
        fixed = {(bx, by) for by in range(ch) for bx in range(cw)
                 if (bx, by) not in box or bx in (0, cw - 1) or by in (0, ch - 1)} | set(cells)
        new = A.paint(gg, fixed, cw, ch, lanes=lane - set(cells), what='the passage of a door at %d,%d' % (x, y))
        return {(bx, by): new[by][bx] for by in range(ch) for bx in range(cw) if new[by][bx] != g[by][bx]}

    def copy_objects(self):
        """The special room's own objects (shop, rupees, chests, fountain...), refused where they would stand on the
        painted walls."""
        for layer in SPECIAL_LAYERS:
            for o in self.special['objects'].get(layer, []):
                x, y, w, h = o['x'], o['y'], o['width'], o['height']
                for gy in range(max(0, y // GRID), min(len(self.base), (y + h + GRID - 1) // GRID)):
                    for gx in range(max(0, x // GRID), min(len(self.base[0]), (x + w + GRID - 1) // GRID)):
                        if self.solid_at(self.base, gx, gy):
                            raise PaintError('%s: object of %s at %d,%d stands on the painted walls' % (self.where, layer, x, y))
                props = {q['name']: q['value'] for q in o.get('properties', []) if q['name'] != 'Room'}
                self.add(layer, o.get('gid'), (x, y, w, h), props, obj_type=o.get('type', ''))

    def gates(self):
        """RegionGate: the gate (top wall) or stairs (bottom wall) of each door, painted by the game in place of the
        passage when the door is the level's entrance or exit. The gate wins over the decoration: any piece it
        touches is painted bare (the frame without it) on the same layer, so it goes whole. A door whose gate would
        reach into the side walls gets none (the game then leaves the plain passage there)."""
        k = self.kit
        x0 = self.inner[0]
        x1 = self.inner[2]
        frame_gate = k.frames[self.d.get('frame', '')].get('gate', {})
        for p, (loc, (x, y, w, h)) in sorted(self.doors.items()):
            g = frame_gate.get(loc) or k.gate.get(loc)
            if not g:
                continue
            piece = k.get(g['piece'], self.where)
            pw, ph = len(piece[0]) * 16, len(piece) * 16
            gx = x + g['at'][0]
            gy = g['at'][1] if loc == 'Top' else self.h + g['at'][1]
            if gx < x0 - 16 or gx + pw > x1 + 16:
                continue
            box = (gx, gy, gx + pw - 1, gy + ph - 1)
            if any(convert.rect_overlap(box, (b[0], b[1], b[0] + b[2] - 1, b[1] + b[3] - 1)) for b in self.object_boxes):
                continue                # a gate never covers the objects of a special room
            for b in self.decor_boxes:
                if convert.rect_overlap(box, (b[0], b[1], b[0] + b[2] - 1, b[1] + b[3] - 1)):
                    for gy2 in range(b[1] // GRID, (b[1] + b[3]) // GRID):
                        for gx2 in range(b[0] // GRID, (b[0] + b[2]) // GRID):
                            self.gate[gy2][gx2] = self.bare[gy2][gx2]
            self.stamp(self.gate, piece, gx, gy, where=self.where)
            # the game paints the gate instead of the passage, so the passage's tiles between the floor and the gate
            # go on the gate layer too: the stairs of a bottom exit start under the rim, which stayed shut above them
            # and left the level with no way out (R1, seventh round)
            rows = range(self.inner[3], gy) if loc == 'Bottom' else range(gy + ph, self.inner[1])
            for py in rows:
                for px in range(gx, gx + pw, GRID):
                    t = self.open[py // GRID][px // GRID]
                    if t is not None and self.gate[py // GRID][px // GRID] is None:
                        self.gate[py // GRID][px // GRID] = t
            self.gate_doors.append(p)
            self.gate_boxes.append((gx, gy, pw, ph))

    # ---------------------------------------------------------------- nature (motifs)

    def lanes(self):
        """8x8 cells that must stay free for walking: each door's lane from its cell to the middle of the room, and
        the middle (treasure spot)."""
        x0, y0, x1, y1 = self.inner
        cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
        out = set()

        def box(a0, b0, a1, b1):
            for gx in range(min(a0, a1) // GRID, (max(a0, a1) + GRID - 1) // GRID):
                for gy in range(min(b0, b1) // GRID, (max(b0, b1) + GRID - 1) // GRID):
                    out.add((gx, gy))
        for p, (loc, (x, y, w, h)) in self.doors.items():
            if loc in ('Top', 'Bottom'):
                box(x, y, x + 32, cy + 16)
            else:
                box(x, y, cx + 16, y + 32)
        box(cx - 24, cy - 24, cx + 24, cy + 24)
        return out

    def nature(self, motif):
        """A nature motif: pieces (trees solid, bushes an oBush each) in a symmetric layout off the door lanes, on a
        patch of grass spreading over the floor around them (marching squares over a grid of corners; the kit's grass
        pieces are the edges). Bushes are a 2x2 clump on each side, or, where the door lanes leave no room for it (a
        1x1 room with a door low on each side), a smaller one: 2x1, 1x2, a single bush (R1 eighth round)."""
        if motif not in NATURE_MOTIFS:
            raise PaintError('%s: nature motif "%s" (motifs: %s)' % (self.where, motif, ', '.join(NATURE_MOTIFS)))
        clumps = [(2, 2), (2, 1), (1, 2), (1, 1)] if motif == 'Nature/bushes' else [(1, 1)]
        kept = ([row[:] for row in self.base], list(self.decor_boxes), list(self.bushes))
        for i, clump in enumerate(clumps):
            try:
                return self._nature(motif, clump)
            except PaintError:
                if i == len(clumps) - 1:
                    raise
                self.base, self.decor_boxes, self.bushes = [row[:] for row in kept[0]], list(kept[1]), list(kept[2])

    def _nature(self, motif, clump):
        k, where = self.kit, self.where
        if not k.grass:
            raise PaintError('%s: nature motifs need "grass" in the kit' % where)
        x0, y0, x1, y1 = self.inner
        lanes = self.lanes()
        name = {'Nature/trees': 'tree', 'Nature/bushes': 'bush'}[motif]
        piece = k.get(k.nature.get(name), where)
        pw, ph = len(piece[0]) * 16, len(piece) * 16
        if name == 'bush':
            piece = [row * clump[0] for row in piece] * clump[1]       # a clump of clump[0] x clump[1] bushes
            pw, ph = pw * clump[0], ph * clump[1]
        # where the pieces go: one in each half (trees, a 2x1 or 1x2 room), or a pair on the two sides of the middle
        # axis (bushes); of the spots whose pieces keep the door lanes and the decoration free, the nearest to the
        # middle of the half (trees) or to a quarter of the room (bushes)
        cands = []
        if name == 'tree':
            # one tree in each half, mirrored (2x1) or repeated half a room lower (1x2), nearest the middle of the half
            if self.w > self.h:
                ideal = ((3 * x0 + x1) // 4 - pw // 2, (y0 + y1 - ph) // 2)
                for sx in range(x0 + 8, (x0 + x1) // 2 - pw, 16):
                    for sy in range(y0 + 8, y1 - ph - 7, 16):
                        cands.append([(sx, sy), (self.w - sx - pw, sy)])
            elif self.h > self.w:
                ideal = ((x0 + x1 - pw) // 2, (3 * y0 + y1) // 4 - ph // 2)
                for sx in range(x0 + 8, x1 - pw - 7, 16):
                    for sy in range(y0 + 8, self.h // 2 - ph, 16):
                        cands.append([(sx, sy), (sx, sy + self.h // 2 - 32)])
            else:
                raise PaintError('%s: Nature/trees needs a 2x1 or 1x2 room (a tree is too big for half a 1x1 room)' % where)
        else:
            ideal = ((3 * x0 + x1) // 4 - pw // 2, (y0 + y1 - ph) // 2)
            for sy in range(y0 + 16, y1 - ph - 8, 16):
                for sx in range(x0 + 16, (x0 + x1) // 2 - pw, 16):
                    cands.append([(sx, sy), (self.w - sx - pw, sy)])
        cands = [[(sx // 16 * 16, sy // 16 * 16) for sx, sy in c] for c in cands]
        cands.sort(key=lambda c: (abs(c[0][0] - ideal[0]) + abs(c[0][1] - ideal[1]), c[0][1], c[0][0]))

        def fits(spots):
            for sx, sy in spots:
                if sx < x0 + 8 or sy < y0 + 8 or sx + pw > x1 - 8 or sy + ph > y1 - 8:
                    return False
                cells = {(gx, gy) for gx in range(sx // GRID, (sx + pw) // GRID) for gy in range(sy // GRID, (sy + ph) // GRID)}
                if cells & lanes:
                    return False
                if any(convert.rect_overlap((sx, sy, sx + pw - 1, sy + ph - 1), (b[0], b[1], b[0] + b[2] - 1, b[1] + b[3] - 1))
                       for b in self.decor_boxes + self.gate_boxes):
                    return False
            return True
        spots = next((c for c in cands if fits(c)), None)
        if spots is None:
            raise PaintError('%s: motif %s finds no place off the door lanes and the decoration' % (where, motif))
        # the grass: corners of the 16 px cells inside an ellipse around each piece and two smaller lobes, so the
        # patch looks grown rather than drawn; never on the walls or the decoration
        corners = set()
        fx0, fy0, fx1, fy1 = x0 // 16, y0 // 16, x1 // 16, y1 // 16
        for sx, sy in spots:
            ccx, ccy = (sx + pw / 2) / 16, (sy + ph / 2) / 16
            rx, ry = pw / 32 + 1.6, ph / 32 + 1.4
            for lx, ly, sc in ((0, 0, 1.0), (-rx * 0.8, ry * 0.4, 0.55), (rx * 0.7, -ry * 0.5, 0.5)):
                for gx in range(fx0, fx1 + 1):
                    for gy in range(fy0, fy1 + 1):
                        if ((gx - ccx - lx) / (rx * sc)) ** 2 + ((gy - ccy - ly) / (ry * sc)) ** 2 <= 1:
                            corners.add((gx, gy))
        corners = {(gx, gy) for gx, gy in corners if fx0 < gx < fx1 and fy0 < gy < fy1}
        # the grass goes round the decoration with its edge (a crest stays on the floor), never in a straight cut
        corners = {(gx, gy) for gx, gy in corners
                   if not any(b[0] <= gx * 16 <= b[0] + b[2] and b[1] <= gy * 16 <= b[1] + b[3]
                              for b in self.decor_boxes + self.gate_boxes)}
        changed = True
        while changed:                  # a cell with only two opposite grass corners has no piece: fill it
            changed = False
            for gx in range(fx0, fx1):
                for gy in range(fy0, fy1):
                    q = [(gx, gy) in corners, (gx + 1, gy) in corners, (gx, gy + 1) in corners, (gx + 1, gy + 1) in corners]
                    if q in ([True, False, False, True], [False, True, True, False]):
                        corners |= {(gx, gy), (gx + 1, gy), (gx, gy + 1), (gx + 1, gy + 1)}
                        changed = True
        G = k.grass

        def turn(b, m=False, v=False):
            return (b[0], b[1] != m, b[2] != v)
        T = {(1, 1, 1, 1): G['full'], (1, 1, 0, 0): G['top'], (0, 0, 1, 1): G['bottom'],
             (1, 0, 1, 0): G['left'], (0, 1, 0, 1): turn(G['left'], m=True),
             (0, 0, 1, 0): G['corner'], (0, 0, 0, 1): turn(G['corner'], m=True),
             (1, 0, 0, 0): turn(G['corner'], v=True), (0, 1, 0, 0): turn(G['corner'], m=True, v=True),
             (1, 1, 0, 1): G['inner'], (1, 1, 1, 0): turn(G['inner'], m=True),
             (0, 1, 1, 1): turn(G['inner'], v=True), (1, 0, 1, 1): turn(G['inner'], m=True, v=True)}
        full = set()
        for gx in range(fx0, fx1):
            for gy in range(fy0, fy1):
                q = tuple(int(c in corners) for c in ((gx, gy), (gx + 1, gy), (gx, gy + 1), (gx + 1, gy + 1)))
                if sum(q) == 0:
                    continue
                if any(self.base[gy * 2 + j][gx * 2 + i] is None or self.kit.solid[self.base[gy * 2 + j][gx * 2 + i][0]]
                       for i in (0, 1) for j in (0, 1)):
                    continue            # never over a wall
                if any(convert.rect_overlap((gx * 16, gy * 16, gx * 16 + 15, gy * 16 + 15),
                                            (b[0], b[1], b[0] + b[2] - 1, b[1] + b[3] - 1)) for b in self.decor_boxes):
                    continue            # nor over the decoration
                self.stamp(self.base, [[T[q]]], gx * 16, gy * 16, where=where)
                if q == (1, 1, 1, 1):
                    full.add((gx, gy))
        used = set()
        for sx, sy in spots:
            cells = {(gx, gy) for gx in range(sx // 16, (sx + pw) // 16) for gy in range(sy // 16, (sy + ph) // 16)}
            if not cells <= full:
                raise PaintError('%s: the grass of %s does not cover its pieces' % (where, motif))
            used |= cells
            if name == 'bush':
                # each bush of the clump is an oBush on the grass, as in the DoI (cut with the sword, lifted), never a
                # tile of wall (R1 eighth round)
                self.bushes += [(bx, by) for by in range(sy, sy + ph, 16) for bx in range(sx, sx + pw, 16)]
            else:
                self.stamp(self.base, piece, sx, sy, where=where)
            self.decor_boxes.append((sx, sy, pw, ph))
        # tufts on the grass, mirrored about the middle axis, off the pieces
        tufts = [k.get(n, where) for n in (k.nature.get('tufts') or [])]
        n = 0
        for gx, gy in sorted(full, key=lambda c: (c[1], c[0])):
            mx = self.w // 16 - 1 - gx
            if not tufts or gx >= mx or (gx, gy) in used or (mx, gy) in used or (mx, gy) not in full or (gx + 2 * gy) % 3:
                continue
            t = tufts[n % len(tufts)]
            self.stamp(self.base, t, gx * 16, gy * 16, where=where)
            self.stamp(self.base, t, mx * 16, gy * 16, True, where=where)
            used |= {(gx, gy), (mx, gy)}
            n += 1

    def solid_at(self, grid, gx, gy):
        t = grid[gy][gx]
        return t is not None and self.kit.solid[t[0]] == 1

    def floor_cells(self):
        """8x8 cells nothing blocks with every door open."""
        out = set()
        for gy in range(len(self.base)):
            for gx in range(len(self.base[0])):
                g = self.open if self.open[gy][gx] is not None else self.base
                if not self.solid_at(g, gx, gy):
                    out.add((gx, gy))
        return out

    def check_passages(self):
        """Each door's passage is walkable from the room's inner floor to the edge, and closed without it."""
        floor = self.floor_cells()
        x0, y0, x1, y1 = self.inner
        cx, cy = (x0 + x1) // 2 // GRID, (y0 + y1) // 2 // GRID
        if (cx, cy) not in floor:
            raise PaintError('%s: the middle of the room is not floor' % self.where)
        seen, todo = {(cx, cy)}, [(cx, cy)]
        while todo:
            x, y = todo.pop()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if n in floor and n not in seen:
                    seen.add(n)
                    todo.append(n)
        gw, gh = len(self.base[0]), len(self.base)
        for p, (loc, (x, y, w, h)) in sorted(self.doors.items()):
            # Link (16 px wide) goes through the middle of the door cell to the room's edge
            if loc in ('Top', 'Bottom'):
                cells = [(gx, gy) for gx in (x // GRID + 1, x // GRID + 2)
                         for gy in (range(0, y0 // GRID) if loc == 'Top' else range(y1 // GRID, gh))]
            else:
                cells = [(gx, gy) for gy in (y // GRID + 1, y // GRID + 2)
                         for gx in (range(0, x0 // GRID) if loc == 'Left' else range(x1 // GRID, gw))]
            if not all(c in seen for c in cells):
                raise PaintError('%s: the passage of door %d is not open floor from the room to the edge' % (self.where, p))
        self.reach = seen

    def furnish(self):
        """An enemy area over the inner floor and a treasure and a crystal spot in its middle (special objects)."""
        x0, y0, x1, y1 = self.inner
        self.add('Enemies', None, (x0 + 8, y0 + 8, x1 - x0 - 16, y1 - y0 - 16), group='main', obj_type='Area')
        cx, cy = (x0 + x1) // 2 - 8, (y0 + y1) // 2 - 8
        for gx in range(cx // GRID, cx // GRID + 2):
            for gy in range(cy // GRID, cy // GRID + 2):
                if (gx, gy) not in self.reach:
                    raise PaintError('%s: the middle of the room (treasure spot) is not open floor' % self.where)
        self.add('Treasures', 'Treasure', (cx, cy, 16, 16), group='main')
        self.add('Crystals', 'Crystal', (cx, cy, 16, 16), group='main')

    # ---------------------------------------------------------------- sections (paint_sections)

    def sections(self):
        """The sections the room can have ("sections": ids, one per group): the low wall of each on its own tile
        layer (RegionSection<group>, painted by the game over the room when the section is the room's), and its
        section group (area, enemies outside it, a treasure and a crystal spot in it and outside it)."""
        self.section_grids = {}
        ids = self.d.get('sections') or []
        if not ids:
            return
        size = (self.w, self.h)
        try:
            shapes = paint_sections.shapes(size)
            # a room painted from a frame has no low wall yet: its section stays open (roadmap F12b-2)
            par = None if self.kit.auto else paint_sections.Parapet(self.kit, self.kit.frames[self.d.get('frame', '')],
                                                                    self.where)
        except paint_sections.SectionError as e:
            raise PaintError(str(e))
        cols, rows = paint_sections.BANDS[size]
        self.split_ids = [0, 0, 0, 0]
        for sid in ids:
            where = '%s section %s' % (self.where, sid)
            if sid not in shapes:
                raise PaintError('%s: a %s room has sections %s' % (where, self.d.get('size', '1x1'), sorted(shapes)))
            g = paint_sections.GROUP_OF_ID[sid]
            if self.split_ids[g]:
                raise PaintError('%s: sections %d and %d are of the same group' % (where, self.split_ids[g], sid))
            self.split_ids[g] = sid
            sec, wall = shapes[sid]
            missing = [p for p in paint_sections.doors_of(sec) if p not in self.doors]
            if missing and par is not None:
                raise PaintError('%s: the section needs doors %s' % (where, missing))
            grid = [[None] * len(self.base[0]) for _ in self.base]
            try:
                if par is not None:
                    par.paint(grid, wall, cols, rows, self.w, self.h)
            except paint_sections.SectionError as e:
                raise PaintError(str(e))
            self.section_grids[g] = grid

            def bbox(cells):
                return (min(cols[i][0] for i, _ in cells), min(rows[j][0] for _, j in cells),
                        max(cols[i][1] for i, _ in cells), max(rows[j][1] for _, j in cells))
            sx0, sy0, sx1, sy1 = bbox(sec)
            self.add('SectionArea', None, (sx0, sy0, sx1 - sx0, sy1 - sy0), group=g)
            # the main floor: the largest box of band cells outside the section and its wall
            free = {(i, j) for i in range(5) for j in range(5)} - sec - wall
            best = None
            for i0 in range(5):
                for j0 in range(5):
                    for i1 in range(i0, 5):
                        for j1 in range(j0, 5):
                            cells = {(i, j) for i in range(i0, i1 + 1) for j in range(j0, j1 + 1)}
                            if cells <= free:
                                b = bbox(cells)
                                a = (b[2] - b[0]) * (b[3] - b[1])
                                if best is None or a > best[0]:
                                    best = (a, b)
            mx0, my0, mx1, my1 = best[1]
            self.add('Enemies', None, (mx0 + 8, my0 + 8, mx1 - mx0 - 16, my1 - my0 - 16), group=g, obj_type='Area')
            for x0, y0, x1, y1 in ((sx0, sy0, sx1, sy1), (mx0, my0, mx1, my1)):
                # the middle, and in a long area its two ends too (more places for a key or a crystal)
                # in a low area (a strip under the top wall) 8 px down: a spot within 16 px of a door is refused (SpawnObj)
                cx = ((x0 + x1) // 2 - 8) // GRID * GRID
                cy = y0 + 8 if y1 - y0 < 40 else ((y0 + y1) // 2 - 8) // GRID * GRID
                spots = [(cx, cy)]
                if x1 - x0 >= 96:
                    spots += [(x0 + 8, cy), ((x1 - 24) // GRID * GRID, cy)]
                elif y1 - y0 >= 96:
                    spots += [(cx, y0 + 8), (cx, (y1 - 24) // GRID * GRID)]
                for spot in spots:
                    self.add('Treasures', 'Treasure', spot + (16, 16), group=g)
                    self.add('Crystals', 'Crystal', spot + (16, 16), group=g)
                    if x0 == sx0 and y0 == sy0:
                        # a pot too: a chest wants 16 px free around it, more than a strip under the top wall has,
                        # and a key may go in a pot (SpawnPots)
                        self.add('Pots', 'Pot', spot + (16, 16), group=g)
            if par is not None:
                self.check_section(sid, grid, (sx0, sy0, sx1, sy1), (mx0, my0, mx1, my1))

    def check_section(self, sid, grid, sbox, mbox):
        """With every door open and the section's wall up, its area and the main floor do not meet."""
        def solid(gx, gy):
            for layer in (grid, self.open, self.base):
                t = layer[gy][gx]
                if t is not None:
                    return self.kit.solid[t[0]] == 1
            return False
        start = ((sbox[0] + sbox[2]) // 2 // GRID, (sbox[1] + sbox[3]) // 2 // GRID)
        goal = ((mbox[0] + mbox[2]) // 2 // GRID, (mbox[1] + mbox[3]) // 2 // GRID)
        x0, y0, x1, y1 = (v // GRID for v in self.inner)
        seen, todo = {start}, [start]
        while todo:
            x, y = todo.pop()
            for n in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if x0 <= n[0] < x1 and y0 <= n[1] < y1 and n not in seen and not solid(*n):
                    seen.add(n)
                    todo.append(n)
        if goal in seen:
            raise PaintError('%s section %d: its low wall leaves a way between the section and the room' % (self.where, sid))

    def section_grid(self, g):
        return self.section_grids.get(g) or [[None] * len(self.base[0]) for _ in self.base]

    def add(self, layer, gid, box, props=None, group=None, obj_type=''):
        dst = self.layers if group is None else self.groups.setdefault(group, {})
        dst.setdefault(layer, []).append((gid, tuple(box), dict(props or {}), obj_type))

    def room_props(self):
        if self.special:
            p = dict(self.special['props'])
            p['Transforms'] = 'None'            # special rooms are picked untransformed (RoomTemplates_PickSpecial)
            if any(any(row) for row in self.owner):
                p['OpenOwners'] = owners_rle(self.owner)
            if self.kit.auto and self.gate_doors:
                p['GateDY'] = self.kit.auto.gate_dy
            return p
        # a room painted from a frame is never turned: a mirror would change its border, which every room shares
        default = 'None' if self.kit.auto else ','.join(convert.DEFAULT_PAINTED_TRANSFORMS)
        p = {'Whole': 1, 'Transforms': self.d.get('transforms', default)}
        if self.kit.auto and self.gate_doors:
            p['GateDY'] = self.kit.auto.gate_dy     # how far below the door cell the gate's doorway is (RegionRoom_Paint)
        if self.d.get('fallback', self.all_doors):
            p['Fallback'] = 1       # picked only when no other room of the set fits (RoomTemplates_Pick)
        if any(any(row) for row in self.owner):
            p['OpenOwners'] = owners_rle(self.owner)    # convert.py makes it Region.own
        if self.bushes:
            p['RegionBushes'] = ','.join('%d,%d' % b for b in self.bushes)     # convert.py makes it Region.bushes
        p.update(self.d.get('props') or {})
        return p

    def gids(self, grid, firstgid):
        """The 8x8 tiles as Tiled gids (mirror and flip bits)."""
        out = []
        for row in grid:
            line = []
            for t in row:
                if t is None:
                    line.append(0)
                else:
                    tile, fl = t
                    line.append((firstgid + tile) | (TILED_H if fl & 1 else 0) | (TILED_V if fl & 2 else 0))
            out.append(line)
        return out


def owners_rle(grid):
    """The door of each RegionOpen tile, row by row, as runs "count*door" (0: no door), for the map's room property
    OpenOwners (convert.py reads it into Region.own)."""
    flat = [v for row in grid for v in row]
    out, i = [], 0
    while i < len(flat):
        j = i
        while j < len(flat) and flat[j] == flat[i]:
            j += 1
        out.append('%d*%d' % (j - i, flat[i]))
        i = j
    return ','.join(out)


def specials(d, kit, where):
    """Painted copies of the shared special rooms (shop, treasure, rupees, fairy...), so that they match the region
    (docs/design/direcao.md, "Salas especiais seguem a área"): each 1x1 room of the shared Special map whose floor
    is one level and open (no lower floor, no walls inside) and whose objects keep clear of the painted walls,
    painted with the kit's frame d["specials"]["frame"], all twelve doors (one is in use) and its objects.
    Returns ([Painted], {type: [skipped room ids]})."""
    spec = d['specials']
    if not isinstance(spec, dict) or set(spec) - SPECIAL_KEYS:
        raise PaintError('%s: specials is {"frame": <a frame of the kit>}' % where)
    ci = [c[0] for c in convert.CLASSES].index('Special')
    js = json.load(open(convert.map_path(ci), encoding='utf-8'))
    layers = {l['name']: l for l in js['layers']}
    rooms = layers['Rooms']['objects']

    def room_of(o):
        for q in o.get('properties', []):
            if q['name'] == 'Room':
                return q['value']
    content = {r['id']: {} for r in rooms}
    for name, l in layers.items():
        if name == 'Rooms' or l.get('type') != 'objectgroup':
            continue
        for o in l['objects']:
            rid = room_of(o)
            if rid in content:
                content[rid].setdefault(name, []).append(o)
    out, skipped = [], {}
    for r in sorted(rooms, key=lambda r: (r['type'], r['id'])):
        c = content[r['id']]
        x0, y0 = r['x'], r['y']
        inner_walls = any(40 <= o['x'] - x0 and 40 <= o['y'] - y0 and o['x'] - x0 + o['width'] <= 216 and
                          o['y'] - y0 + o['height'] <= 216 for o in c.get('WallsUpper', []))
        if r['width'] != 256 or r['height'] != 256 or c.get('LowerFloor') or c.get('WallsLower') or inner_walls:
            skipped.setdefault(r['type'], []).append(r['id'])
            continue
        objects = {}
        for layer in SPECIAL_LAYERS:
            for o in c.get(layer, []):
                q = dict(o)
                q['x'], q['y'] = o['x'] - x0, o['y'] - y0
                objects.setdefault(layer, []).append(q)
        props = {q['name']: q['value'] for q in r.get('properties', [])}
        sets = auto_variants(kit, '1x1', cover=True) if kit.auto else [list(range(1, 13))]
        for v, doors in enumerate(sets):
            room = {'name': '%s%d' % (r['type'], r['id']) + ('_%d' % (v + 1) if len(sets) > 1 else ''), 'size': '1x1',
                    'doors': doors, 'frame': spec.get('frame', '')}
            try:
                out.append(Painted(room, kit, '%s special %s' % (where, room['name']),
                                   {'type': r['type'], 'objects': objects, 'props': props}))
            except PaintError:
                skipped.setdefault(r['type'], []).append(r['id'])
    return out, skipped


def auto_variants(kit, size, cover=False):
    """Door sets for a room of a frame-painted set that would take every door: neighbouring doors whose passages end
    in the same cell with different blocks cannot share a room, and the layouts never use two neighbours, so the
    room comes in variants, the largest sets of doors that do not clash (cover: only as many as it takes for each
    door to be in one, for rooms that use one door at a time)."""
    w, h, si = SIZES[size]
    cw, ch = w // 16, h // 16
    coords = convert.DOOR_XY[si]
    cells = {}
    for p in range(1, 13):
        loc = convert.door_location(p)
        x, y = coords[(p - 1) * 2], coords[(p - 1) * 2 + 1]
        cells[p] = kit.auto.passage(loc, x if loc in ('Top', 'Bottom') else y, cw, ch)
    clash = {p: {q for q in cells if q != p and any(c in cells[q] and cells[q][c] != b for c, b in cells[p].items())}
             for p in cells}
    out = []

    def grow(chosen, rest):
        if not rest:
            out.append(sorted(chosen))
            return
        p = rest[0]
        if not (clash[p] & set(chosen)):
            grow(chosen + [p], rest[1:])
        grow(chosen, rest[1:])
    grow([], list(range(1, 13)))
    out = [v for v in out if not any(set(v) < set(o) for o in out)]
    if cover:
        picked, covered = [], set()
        while covered != set(cells):
            v = max(out, key=lambda v: (len(set(v) - covered), len(v)))
            picked.append(v)
            covered |= set(v)
        out = picked
    return out


def expand_all(kit, rooms):
    """The rooms of a frame-painted set with "doors": "all" as their variants (auto_variants), each a fallback."""
    out = []
    for r in rooms:
        if r.get('doors') != 'all':
            out.append(r)
            continue
        for v, doors in enumerate(auto_variants(kit, r.get('size', '1x1'))):
            q = dict(r)
            q['name'] = '%s_%d' % (r.get('name'), v + 1)
            q['doors'] = doors
            q['fallback'] = True
            out.append(q)
    return out


def load(d, where):
    """(kit, [Painted]) of a rooms.json, or (None, [])."""
    rooms = d.get('painted', [])
    if not rooms:
        return None, []
    if 'kit' not in d:
        raise PaintError('%s: painted rooms need a "kit"' % where)
    kit = Kit(d['kit'], where + ' kit')
    names = set()
    out = []
    if kit.auto:
        rooms = expand_all(kit, rooms)
    for i, r in enumerate(rooms):
        w = '%s painted %d (%s)' % (where, i, r.get('name', '?'))
        if r.get('name') in names:
            raise PaintError('%s: the name is used twice' % w)
        names.add(r.get('name'))
        out.append(Painted(r, kit, w))
    if d.get('specials'):
        sp, skipped = specials(d, kit, where)
        missing = sorted({r for r in skipped} - {p.room_type for p in sp})
        if missing:
            raise PaintError('%s: no special room of %s fits the frame "%s"' % (where, ', '.join(missing), d['specials'].get('frame', '')))
        out += sp
    return kit, out


def render(rooms, path, scale=2):
    """Preview without the game: each room twice, every door closed and every door open (with its door cells
    outlined), side by side, one row per room. Needs Pillow (python -m pip install --user pillow)."""
    from PIL import Image, ImageDraw
    if not rooms:
        return
    kit = rooms[0].kit
    tsj = json.load(open(kit.tileset_path, encoding='utf-8'))
    sheet = Image.open(os.path.normpath(os.path.join(TILESETS_DIR, tsj['image']))).convert('RGBA')
    cols = tsj['columns']

    def tile(t, fl):
        im = sheet.crop(((t % cols) * GRID, (t // cols) * GRID, (t % cols + 1) * GRID, (t // cols + 1) * GRID))
        if fl & 1:
            im = im.transpose(Image.FLIP_LEFT_RIGHT)
        if fl & 2:
            im = im.transpose(Image.FLIP_TOP_BOTTOM)
        return im

    def paint(room, with_open):
        im = Image.new('RGBA', (room.w, room.h), (0, 0, 0, 255))
        for gy in range(len(room.base)):
            for gx in range(len(room.base[0])):
                t = room.open[gy][gx] if with_open and room.open[gy][gx] is not None else room.base[gy][gx]
                if with_open and room.gate[gy][gx] is not None:
                    t = room.gate[gy][gx]
                if t is not None:
                    im.paste(tile(*t), (gx * GRID, gy * GRID))
        if with_open:
            d = ImageDraw.Draw(im)
            for p, (loc, (x, y, w, h)) in room.doors.items():
                d.rectangle((x, y, x + w - 1, y + h - 1), outline=(255, 0, 255, 255))
        return im

    W, H = max(r.w for r in rooms) * 2 + 16, sum(r.h + 16 for r in rooms)
    out = Image.new('RGBA', (W, H), (40, 40, 40, 255))
    y = 0
    for r in rooms:
        out.paste(paint(r, False), (0, y))
        out.paste(paint(r, True), (r.w + 16, y))
        ImageDraw.Draw(out).text((2, y + r.h + 2), '%s %s doors %s' % (r.name, r.d.get('size', '1x1'), r.d.get('doors')),
                                 fill=(255, 255, 255, 255))
        y += r.h + 16
    out = out.resize((W * scale, H * scale), Image.NEAREST)
    out.save(path)


def text_map(room):
    """The room as text, 8 px a character: # wall, . floor, o a passage (RegionOpen), D a door cell."""
    rows = []
    for gy in range(len(room.base)):
        line = ''
        for gx in range(len(room.base[0])):
            if room.open[gy][gx] is not None:
                line += 'o' if not room.solid_at(room.open, gx, gy) else 'O'
            else:
                line += '#' if room.solid_at(room.base, gx, gy) else '.'
        rows.append(line)
    for p, (loc, (x, y, w, h)) in room.doors.items():
        for gy in range(y // GRID, (y + h) // GRID):
            r = rows[gy]
            rows[gy] = r[:x // GRID] + 'D' * (w // GRID) + r[(x + w) // GRID:]
    return '\n'.join(rows)

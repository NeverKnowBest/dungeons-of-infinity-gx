"""Room template converter: Tiled maps (data/room-templates) to the game's room template files.

Python port of the GameMaker project that used to do this (editors/room-template-parser, which
wrote one 46 MB data_r). The output is one file per class, game/datafiles/data/rooms/<Class>.json,
with one template per line so git diffs stay small. RoomTemplates_Load reads them in class order.

    python tools/templates/convert.py                 # writes game/datafiles/data/rooms/
    python tools/templates/convert.py -o out/rooms    # writes somewhere else
    python tools/templates/convert.py --summary       # also prints the template count per class

Room sets (roadmap F11): data/room-templates/sets/<Set>/ holds a set's own Tiled maps, with the same names
and layers as the shared ones and only the classes the set has. They become
game/datafiles/data/rooms/sets/<Set>/<Class>.json, every template with "RoomSet": "<Set>", plus the index
rooms/sets.json ({"<Set>": ["<Class>", ...]}) that RoomTemplates_Load reads. A level picks a set with RoomSet
in its level sheet. The set files are registered in Zelda.yyp as included files here (and dropped when the
set goes away). tools/templates/make_rooms.py writes the maps of a set from a short description.

Standard library only. See tools/README.md and docs/dev/engine-notes.md ("Room templates").
"""
import argparse
import copy
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)
import rt_tables  # noqa: E402

TEMPLATE_DIR = os.path.join(REPO, 'data', 'room-templates')
SETS_DIR = os.path.join(TEMPLATE_DIR, 'sets')
ROOMS_DIR = os.path.join(REPO, 'game', 'datafiles', 'data', 'rooms')
YYP = os.path.join(REPO, 'game', 'Zelda.yyp')
SET_NAME = re.compile(r'^[A-Za-z][A-Za-z0-9_]*$')
GML_ENUMS = os.path.join(REPO, 'game', 'scripts', '__RoomTemplates', '__RoomTemplates.gml')

# ObjTransformation enum, in order
TRANSFORMS = ['None', 'FlipH', 'FlipV', 'FlipHV', 'RotateCW', 'RotateCCW', 'FlipHRotateCW', 'FlipHRotateCCW']
T = {name: i for i, name in enumerate(TRANSFORMS)}

# RoomTemplateClass enum, in order: (file, subclasses). Subclasses are either a room size
# index (None) or a list of Tiled room "type" names in enum order.
CLASSES = [
    ('Main_Upper', 'Main Upper', 2, None),
    ('Main_Lower', 'Main Lower', 2, None),
    ('Stairs', 'Stairs', 3, None),
    ('Jails', 'Jails', 3, None),
    ('Village', 'Village', 4, ['Main', 'House', 'Maze', 'Exit']),
    ('Mines', 'Mines', 2, ['Main', 'House']),
    ('Obstacles', 'Obstacles', 3, ['Blocks', 'MovingFloors', 'SpikeBlocks']),
    ('Sections', 'Sections', 3, None),
    ('Special', 'Special', 8, ['Fairy', 'Shop', 'GemPond', 'Treasure', 'TreasureLarge', 'Rupee', 'Gem', 'Kinstone']),
    ('Other', 'Other', 4, ['Boss', 'Start', 'Unique', 'Save']),
]

# Tiled object layers of each class (same lists as RoomTemplates_Load in the game)
OBJ_TYPES = {
    'Main_Upper': ["Water", "CarpetsFull", "Carpets", "Spikes", "WallsUpper", "Doors", "ExtraCeilings", "OutOfBounds", "SplitConnections"],
    'Main_Lower': ["Water", "CarpetsFull", "Carpets", "Spikes", "WallsLower", "WallsUpper", "Doors", "LowerFloor", "OutOfBounds", "SplitConnections"],
    'Stairs': ["Water", "Spikes", "WallsLower", "WallsUpper", "WallsCommon", "Stairs", "Doors", "LowerFloor", "OutOfBounds"],
    'Jails': ["Water", "WallsUpper", "Objs", "Doors", "OutOfBounds"],
    'Obstacles': ["Pit", "Water", "CarpetsFull", "FloorObjs", "WallsLower", "Holes", "Spikes", "WallsUpper", "WallsCommon", "Doors"],
    'Sections': ["Pit", "Water", "Spikes", "WallsLower", "Holes", "WallsUpper", "WallsCommon", "Doors", "LowerFloor", "OutOfBounds"],
    'Special': ["Water", "FloorObjs", "WallsLower", "WallsUpper", "Objs", "Doors", "LowerFloor", "OutOfBounds"],
    'Other': ["Pit", "Holes", "Water", "FloorObjs", "WallsLower", "WallsUpper", "WallsCommon", "Objs", "Stairs", "Doors", "LowerFloor", "ExtraCeilings", "OutOfBounds"],
    'Village': ["Pit", "Holes", "Water", "FloorObjs", "WallsLower", "WallsUpper", "WallsCommon", "Objs", "Doors", "LowerFloor", "ExtraCeilings", "OutOfBounds"],
    'Mines': ["Pit", "Holes", "Water", "FloorObjs", "WallsLower", "WallsUpper", "WallsCommon", "Objs", "Stairs", "Doors", "LowerFloor", "OutOfBounds"],
}
SECTION_OBJ_TYPES = {
    'Main_Upper': ["SectionArea", "Zones", "Enemies", "SectionWalls", "MovingSpikeBlocks", "RollingSpikes", "GuruBars", "Jails", "Altars", "Kinstones", "Monuments", "Torches", "Crystals", "PotTreasures", "Treasures", "Pots"],
    'Main_Lower': ["Zones", "Enemies", "MovingSpikeBlocks", "GuruBars", "Altars", "Kinstones", "Monuments", "Torches", "Crystals", "PotTreasures", "Treasures", "Pots"],
    'Stairs': ["Zones", "Enemies", "MovingSpikeBlocks", "Altars", "Kinstones", "Monuments", "Torches", "Crystals", "PotTreasures", "Treasures", "Pots"],
    'Jails': ["Zones", "Enemies", "Jails", "Altars", "Kinstones", "Monuments", "Torches", "PotTreasures", "Treasures", "Pots"],
    'Obstacles': ["Zones", "Enemies", "MovingSpikeBlocks", "RollingSpikes", "GuruBars", "Altars", "Kinstones", "Monuments", "Torches", "Crystals", "PotTreasures", "Treasures", "Pots"],
    'Sections': ["SectionArea", "Enemies", "SectionWalls", "MovingSpikeBlocks", "RollingSpikes", "GuruBars", "Altars", "Kinstones", "Monuments", "Torches", "Crystals", "PotTreasures", "Treasures", "Pots"],
    'Special': [], 'Other': [], 'Village': [], 'Mines': [],
}
OBJS_THAT_CAN_ROTATE = {"PotTreasures", "Kinstones", "Altars", "Jails"}
SECTION_COUNT = 31  # section 0 (main) plus 1..30

# RoomSize enum: global.RoomSizeIndex[w/256][h/256]
ROOM_SIZE = {(1, 1): 0, (1, 2): 1, (2, 1): 2, (2, 2): 3}

# Door positions 1..24 per room size (Data_InitDoorCoordinates)
DOOR_XY = [
    [168, 16, 216, 56, 216, 112, 216, 168, 168, 216, 112, 216, 56, 216, 16, 168, 16, 112, 16, 56, 56, 16, 112, 16,
     152, 40, 192, 72, 192, 112, 192, 152, 152, 192, 112, 192, 72, 192, 40, 152, 40, 112, 40, 72, 72, 40, 112, 40],
    [168, 16, 216, 112, 216, 240, 216, 368, 168, 472, 112, 472, 56, 472, 16, 368, 16, 240, 16, 112, 56, 16, 112, 16,
     152, 40, 192, 112, 192, 240, 192, 368, 152, 448, 112, 448, 72, 448, 40, 368, 40, 240, 40, 112, 72, 40, 112, 40],
    [368, 16, 472, 56, 472, 112, 472, 168, 368, 216, 240, 216, 112, 216, 16, 168, 16, 112, 16, 56, 112, 16, 240, 16,
     368, 40, 448, 72, 448, 112, 448, 152, 368, 192, 240, 192, 112, 192, 40, 152, 40, 112, 40, 72, 112, 40, 240, 40],
    [368, 16, 472, 112, 472, 240, 472, 368, 368, 472, 240, 472, 112, 472, 16, 368, 16, 240, 16, 112, 112, 16, 240, 16,
     368, 40, 448, 112, 448, 240, 448, 368, 368, 448, 240, 448, 112, 448, 40, 368, 40, 240, 40, 112, 112, 40, 240, 40],
]


def door_location(position):
    if position in (11, 12, 1, 23, 24, 13):
        return 'Top'
    if position in (2, 3, 4, 14, 15, 16):
        return 'Right'
    if position in (5, 6, 7, 17, 18, 19):
        return 'Bottom'
    return 'Left'


class ConvertError(Exception):
    pass


def read_gid_enum():
    """TemplateObjGID from the game's __RoomTemplates.gml (name -> number)."""
    src = open(GML_ENUMS, encoding='utf-8').read()
    body = re.search(r'enum TemplateObjGID\{(.*?)\}', src, re.S).group(1)
    vals, cur = {}, -1
    for item in body.split(','):
        item = re.sub(r'//.*', '', item).strip()
        if not item:
            continue
        if '=' in item:
            n, v = item.split('=')
            n, cur = n.strip(), int(v)
        else:
            n, cur = item, cur + 1
        vals[n] = cur
    return vals


GIDS = read_gid_enum()
GID_TABLE = {t: {GIDS[a]: GIDS[b] for a, b in m.items()} for t, m in rt_tables.GID.items()}
WALL_SIDES_LR = {GIDS['WallSideL'], GIDS['WallSideR'], GIDS['WallLowerSideL'], GIDS['WallLowerSideR']}


# ---------------------------------------------------------------- helpers

def to_real(v):
    """GameMaker keeps every number as a double; data_r stores them that way."""
    if isinstance(v, bool):
        return v
    if isinstance(v, (int, float)):
        return float(v)
    if isinstance(v, list):
        return [to_real(x) for x in v]
    if isinstance(v, dict):
        return {k: to_real(x) for k, x in v.items()}
    return v


def get_prop(props, name):
    """GetPropertyValue: first property with that name, or -1."""
    for p in props or []:
        if p['name'] == name:
            return p['value']
    return -1


def set_prop(props, name, value):
    """SetPropertyValue: only changes a property that already exists."""
    for p in props or []:
        if p['name'] == name:
            p['value'] = value
            return


def split_reals(s):
    """SplitStrToArray(s, ",", true): a trailing comma adds nothing."""
    out = []
    parts = s.split(',')
    if parts and parts[-1] == '':
        parts = parts[:-1]
    for x in parts:
        out.append(float(x))
    return out


def gm_str(v):
    """string() of a GameMaker number: whole numbers have no decimals."""
    if isinstance(v, float) and v.is_integer():
        return str(int(v))
    return str(v)


def transformed_door_position(pos, t):
    """GetTransformedDoorPosition."""
    if pos == -1:
        return -1
    if t == 0:
        return pos
    new = rt_tables.DOOR_POSITION[TRANSFORMS[t]].get(int(pos), pos)
    return new + (12 if pos > 12 else 0)


def transformed_section_id(sid, t):
    if t == 0:
        return sid
    return float(rt_tables.SECTION_ID[TRANSFORMS[t]].get(int(sid), sid))


def transformed_rotation(rot, t):
    if t == 0:
        return rot
    return float(rt_tables.ROTATION[TRANSFORMS[t]].get(int(rot), rot))


def transform_chars(code, table, t, upper):
    if upper:
        code = code.upper()
    if t == 0:
        return code
    m = table[TRANSFORMS[t]]
    return ''.join(m.get(c, c) for c in code)


def transform_obj_array(objs, t, obj_type, room_w, room_h):
    """TransformObjArray: copies of the objects, moved, resized and re-pointed for transform t."""
    if not objs:
        return objs
    out = []
    for old in objs:
        new = copy.deepcopy(old)
        ox, oy, ow, oh = old['x'], old['y'], old['width'], old['height']
        nx, ny, nw, nh = ox, oy, ow, oh
        name = TRANSFORMS[t]
        if name == 'FlipH':
            nx = room_w - ox - ow
        elif name == 'FlipV':
            ny = room_h - oy - oh
        elif name == 'FlipHV':
            nx, ny = room_w - ox - ow, room_h - oy - oh
        elif name == 'RotateCW':
            nw, nh, ny, nx = oh, ow, ox, room_h - oy - oh
        elif name == 'RotateCCW':
            nw, nh, nx, ny = oh, ow, oy, room_w - ox - ow
        elif name == 'FlipHRotateCW':
            nw, nh, nx, ny = oh, ow, room_h - oy - oh, room_w - ox - ow
        elif name == 'FlipHRotateCCW':
            nw, nh, nx, ny = oh, ow, oy, ox

        props = old.get('properties')
        v = get_prop(props, 'SpawnDir')            # pots
        if v != -1:
            set_prop(new.get('properties'), 'SpawnDir',
                     rt_tables.POT_SPAWN_DIR.get(name, {}).get(v, v) if t else v)
        for key in ('SB', 'SBShift'):                # switch blocks
            v = get_prop(props, key)
            if v != -1:
                set_prop(new.get('properties'), key, transform_chars(v, rt_tables.SB_SHIFT, t, True))
        for key in ('DoorsFrom', 'DoorsTo'):         # carpet door codes
            v = get_prop(props, key)
            if v != -1 and v != '':
                # Note: the GML version passed these as strings; see engine-notes "Room templates".
                positions = [int(x.strip()) for x in str(v).split(',')]
                set_prop(new.get('properties'), key,
                         ','.join(gm_str(transformed_door_position(p, t)) for p in positions))

        new['x'], new['y'], new['width'], new['height'] = nx, ny, nw, nh
        if obj_type in OBJS_THAT_CAN_ROTATE:
            new['rotation'] = transformed_rotation(old['rotation'], t)
        if 'gid' in old:
            new['gid'] = float(GID_TABLE.get(name, {}).get(int(old['gid']), old['gid'])) if t else old['gid']
        out.append(new)
    return out


def fix_obj_rotation(obj):
    """RoomTemplates_FixObjRotation: Tiled rotates around the corner, the game wants a plain box."""
    r = obj.get('rotation')
    if r in (90, -90):
        obj['width'], obj['height'] = obj['height'], obj['width']
    if r == 90:
        obj['x'] -= obj['width']
    elif r == -90:
        obj['y'] -= obj['height']
    elif r == 180:
        obj['x'] -= obj['width']
        obj['y'] -= obj['height']


def rect_overlap(a, b):
    """rectangle_in_rectangle(...) > 0 with inclusive pixel boxes."""
    ax1, ay1, ax2, ay2 = a
    bx1, by1, bx2, by2 = b
    return not (ax2 < bx1 or ax1 > bx2 or ay2 < by1 or ay1 > by2)


# ---------------------------------------------------------------- split rooms (Main Upper / Lower)

def split_add_objs(main, second, obj_types, flip, section_types):
    """RoomTemplates_Parse_SplitRoom_AddObjs: put the flipped second half under the main one."""
    h = main['height']
    main['height'] *= 2
    for ot in obj_types:
        for o in transform_obj_array(second[ot], flip, ot, 256, h):
            o = copy.deepcopy(o)
            o['y'] += h
            main[ot].append(o)

    main_s0 = main['Sections'][0]
    second_s0 = second['Sections'][0]
    new_ids = []
    for i in range(1, 5):
        old_id = second['Split_MainSectionIDs'][i]
        if old_id == 0:
            continue
        sec2 = second['Sections'][int(old_id)]
        new_id = transformed_section_id(old_id, flip)
        dst = main['Sections'][int(new_id)]
        for ot in section_types:
            for o in transform_obj_array(sec2[ot], flip, ot, 256, h):
                o = copy.deepcopy(o)
                o['y'] += h
                dst[ot].append(o)
        new_ids.append(new_id)

    # main's own split sections get the flipped section 0 of the second half
    for i in range(1, 5):
        sid = main['Split_MainSectionIDs'][i]
        if sid == 0:
            continue
        dst = main['Sections'][int(sid)]
        for ot in section_types:
            for o in transform_obj_array(second_s0[ot], flip, ot, 256, h):
                o = copy.deepcopy(o)
                o['y'] += h
                dst[ot].append(o)

    # the new sections get main's section 0 for the top half
    for sid in new_ids:
        dst = main['Sections'][int(sid)]
        for ot in section_types:
            for o in main_s0[ot]:
                dst[ot].append(copy.deepcopy(o))

    # section 0 gets the second half's section 0
    for ot in section_types:
        for o in transform_obj_array(second_s0[ot], flip, ot, 256, h):
            o = copy.deepcopy(o)
            o['y'] += h
            main_s0[ot].append(o)

    main['Split_MainSectionIDs'] = sorted(main['Split_MainSectionIDs'] + new_ids)


def split_combine_walls(tpl, wall_type):
    """RoomTemplates_Parse_SplitRoom_CombineWalls: join vertical side walls that touch."""
    walls = tpl[wall_type]
    combined = True
    while combined:
        combined = False
        n = len(walls)
        for i1 in range(n):
            w1 = walls[i1]
            if int(w1['gid']) not in WALL_SIDES_LR:
                continue
            x1, y1 = w1['x'], w1['y']
            x2, y2 = x1 + w1['width'] - 1, y1 + w1['height'] - 1
            for i2 in range(n):
                w2 = walls[i2]
                if w1 is w2 or int(w2['gid']) not in WALL_SIDES_LR:
                    continue
                bx1, by1 = w2['x'], w2['y']
                bx2, by2 = bx1 + w2['width'] - 1, by1 + w2['height'] - 1
                if w1['gid'] != w2['gid']:
                    continue
                c12 = y2 == by1 - 1
                c21 = by2 == y1 - 1
                if x1 == bx1 and x2 == bx2 and (c12 or c21):
                    if c12:
                        w1['height'] += w2['height']
                        del walls[i2]
                    else:
                        w2['height'] += w1['height']
                        del walls[i1]
                    combined = True
                    break
            if combined:
                break


def split_merge_doors(tpl):
    """RoomTemplates_Parse_SplitRoom_MergeDoors: drop doors that ended up on top of each other."""
    doors = tpl['Doors']
    removed = True
    while removed:
        removed = False
        for i1 in range(len(doors) - 1):
            d1 = doors[i1]
            for i2 in range(i1 + 1, len(doors)):
                d2 = doors[i2]
                if d1['gid'] == d2['gid'] and d1['x'] == d2['x'] and d1['y'] == d2['y']:
                    del doors[i2]
                    removed = True
                    break
            if removed:
                break


def unique(seq):
    out = []
    for x in seq:
        if x not in out:
            out.append(x)
    return out


def split_fix_carpets(tpl):
    """RoomTemplates_Parse_SplitRoom_FixCarpets: carpets of each half also lead to the doors of the other."""
    carpets = tpl['Carpets']
    if not carpets:
        return
    half = tpl['height'] / 2
    second_idx = -1
    for i, c in enumerate(carpets):
        if c['y'] < half < c['y'] + c['height']:
            continue
        if c['y'] >= half and second_idx == -1:
            second_idx = i
    # second_idx stays -1 when no carpet starts in the bottom half (the second half has none, or
    # they all cross the middle). Then nothing is merged, as in the GML, whose loops ran empty.

    from_old, to_old = [], []
    for c in carpets:
        f = get_prop(c.get('properties'), 'DoorsFrom')
        t = get_prop(c.get('properties'), 'DoorsTo')
        from_old.append([] if f == -1 else split_reals(f))
        to_old.append([] if t == -1 else split_reals(t))
    from_new = [list(x) for x in from_old]
    to_new = [list(x) for x in to_old]
    n = len(carpets)
    for m in range(second_idx):
        for s in range(second_idx, n):
            to_new[m] += from_old[s] + to_old[s]
    for s in range(second_idx, n):
        for m in range(second_idx):
            to_new[s] += from_old[m] + to_old[m]
    for i, c in enumerate(carpets):
        set_prop(c.get('properties'), 'DoorsFrom', ','.join(gm_str(x) for x in unique(from_new[i])))
        set_prop(c.get('properties'), 'DoorsTo', ','.join(gm_str(x) for x in unique(to_new[i])))


# ---------------------------------------------------------------- door and zone codes

def generate_door_codes(tpl, cls, name):
    """RoomTemplates_Parse_GenerateDoorCodes: a bit per door position, for every allowed transform."""
    doors = tpl['Doors']
    if not doors:
        return
    allowed = tpl['RoomTransformationsAllowed']
    coords = DOOR_XY[tpl['SizeIndex']]
    code = [0.0] * 8
    for d in doors:
        for p in range(24):
            if d['x'] == coords[p * 2] and d['y'] == coords[p * 2 + 1]:
                d['Position'] = float(p + 1)
                d['Location'] = door_location(p + 1)
                for t in range(8):
                    if allowed[t]:
                        np = transformed_door_position(p + 1, t)
                        code[t] = int(code[t]) | (1 << (int(np) - 1))
                break
    tpl['DoorCode'] = code

    if cls in ('Special', 'Sections'):
        return

    has_ids = 'Split_MainSectionIDs' in tpl
    n_ids = len(tpl['Split_MainSectionIDs']) if has_ids else 1
    zone = [[[0.0] * 4 for _ in range(n_ids)] for _ in range(8)]
    for t in range(8):
        if not allowed[t]:
            continue
        for si in range(n_ids):
            sid = int(tpl['Split_MainSectionIDs'][si]) if has_ids else 0
            zones = tpl['Sections'][sid]['Zones']
            for zi, z in enumerate(zones):
                zr = (z['x'], z['y'], z['x'] + z['width'] - 1, z['y'] + z['height'] - 1)
                for d in doors:
                    if 'Position' not in d:
                        raise ConvertError('%s template %s: door at %s,%s is not on a door position'
                                           % (name, gm_str(tpl['id']), gm_str(d['x']), gm_str(d['y'])))
                    np = transformed_door_position(d['Position'], t)
                    dr = (d['x'], d['y'], d['x'] + d['width'] - 1, d['y'] + d['height'] - 1)
                    if rect_overlap(dr, zr):
                        row = zone[t][si]
                        while len(row) <= zi:
                            row.append(0.0)
                        row[zi] = int(row[zi]) | (1 << (int(np) - 1))
    tpl['ZoneCodes'] = zone


# ---------------------------------------------------------------- painted rooms (roadmap F12b)

REGION_SECTION_LAYERS = ('RegionSection1', 'RegionSection2', 'RegionSection3', 'RegionSection4')
REGION_LAYERS = ('Region', 'RegionOpen', 'RegionGate') + REGION_SECTION_LAYERS   # tile layers of a region tileset:
#   the room, its open door passages, the gates (the level's entrance or exit) of the doors that have one, and the low
#   wall of the room's section of each section group (paint_sections.py)
TILED_FLIP_H, TILED_FLIP_V, TILED_FLIP_D = 0x80000000, 0x40000000, 0x20000000
DEFAULT_PAINTED_TRANSFORMS = ['None', 'FlipH']   # turning ALttP art upside down or sideways puts the wall faces wrong


def region_tilesets(js, where):
    """[(firstgid, name)] of the map's region tilesets (data/room-templates/tilesets/<Name>.json), highest first."""
    out = []
    for ts in js.get('tilesets', []):
        src = ts.get('source', '').replace('\\', '/')
        if '/tilesets/' in '/' + src:
            out.append((int(ts['firstgid']), os.path.splitext(os.path.basename(src))[0]))
    return sorted(out, reverse=True)


def region_cells(layer, room, tilesets, where):
    """The 8x8 cells of a tile layer under a room: (tileset name or None, [value per cell, row by row]). A value is
    the tile of the region tileset with its flips: index | flags << 16, flags 1 mirrored, 2 flipped, 4 diagonal (the
    order Tiled applies them: diagonal, then mirror, then flip); 0 is no tile."""
    lw = int(layer['width'])
    data = layer['data']
    x0, y0 = int(room['x']) // 8, int(room['y']) // 8
    w, h = int(room['width']) // 8, int(room['height']) // 8
    name, cells = None, []
    for j in range(h):
        for i in range(w):
            gid = int(data[(y0 + j) * lw + x0 + i])
            raw = gid & 0x1FFFFFFF
            if raw == 0:
                cells.append(0)
                continue
            first = next(((f, n) for f, n in tilesets if raw >= f), None)
            if first is None:
                raise ConvertError('%s: room %s: layer %s has a tile of no region tileset'
                                   % (where, gm_str(room['id']), layer['name']))
            if name not in (None, first[1]):
                raise ConvertError('%s: room %s paints with two tilesets (%s, %s)' % (where, gm_str(room['id']), name, first[1]))
            name = first[1]
            index = raw - first[0]
            flags = (1 if gid & TILED_FLIP_H else 0) | (2 if gid & TILED_FLIP_V else 0) | (4 if gid & TILED_FLIP_D else 0)
            cells.append(float(index | (flags << 16)) if index else 0)
    return name, cells


def add_region(t, room, layers, tilesets, where):
    """Region: {tileset, w, h, base, open[, gate]} (tiles of 8x8, row by row) of a painted room, from its tile layers."""
    found = {l['name']: l for l in layers if l.get('name') in REGION_LAYERS and l.get('type') == 'tilelayer'}
    if 'Region' not in found:
        return
    name, base = region_cells(found['Region'], room, tilesets, where)
    if name is None:
        return
    opened = [0] * len(base)
    if 'RegionOpen' in found:
        n2, opened = region_cells(found['RegionOpen'], room, tilesets, where)
        if n2 not in (None, name):
            raise ConvertError('%s: room %s: Region and RegionOpen use two tilesets' % (where, gm_str(room['id'])))
    t['Region'] = {'tileset': name, 'w': float(int(room['width']) // 8), 'h': float(int(room['height']) // 8),
                   'base': base, 'open': opened}
    # the door each RegionOpen tile belongs to (paint_rooms.owners_rle), so the game opens only that door's passage
    owners = get_prop(t.get('properties'), 'OpenOwners')
    if owners != -1:
        own = []
        for run in str(owners).split(','):
            n, door = run.split('*')
            own += [float(door)] * int(n)
        if len(own) != len(base):
            raise ConvertError('%s: room %s: OpenOwners has %d cells, the room %d' % (where, gm_str(room['id']), len(own), len(base)))
        t['Region']['own'] = own
        t['properties'] = [q for q in t['properties'] if q.get('name') != 'OpenOwners']
    if 'RegionGate' in found:
        n3, gate = region_cells(found['RegionGate'], room, tilesets, where)
        if n3 not in (None, name):
            raise ConvertError('%s: room %s: Region and RegionGate use two tilesets' % (where, gm_str(room['id'])))
        if any(gate):
            t['Region']['gate'] = gate
            # how far below its door cell the gate's doorway is (paint_auto: the 0x1B facade's palace door, 64 px)
            gd = get_prop(room.get('properties'), 'GateDY')
            if gd != -1:
                t['Region']['gate_dy'] = float(gd)
    # sections: [[], group 1, ..., group 4] (index = the section group of Split_MainSectionIDs), [] where none
    secs = [[]]
    for ln in REGION_SECTION_LAYERS:
        cells = []
        if ln in found:
            n4, cells = region_cells(found[ln], room, tilesets, where)
            if n4 not in (None, name):
                raise ConvertError('%s: room %s: Region and %s use two tilesets' % (where, gm_str(room['id']), ln))
        secs.append(cells if any(cells) else [])
    if any(secs):
        t['Region']['sections'] = secs


def painted_transforms(t, where):
    """RoomTransformationsAllowed of a painted room: its Transforms property ("None,FlipH"), else None and FlipH."""
    v = get_prop(t.get('properties'), 'Transforms')
    names = DEFAULT_PAINTED_TRANSFORMS if v == -1 else [s.strip() for s in str(v).split(',') if s.strip()]
    bad = [n for n in names if n not in T]
    if bad or not names:
        raise ConvertError('%s: room %s: Transforms "%s" (names: %s)' % (where, gm_str(t['id']), v, ', '.join(TRANSFORMS)))
    return [n in names for n in TRANSFORMS]


# ---------------------------------------------------------------- one Tiled map

def find_layer(layers, name, where):
    for l in layers:
        if l.get('name') == name:
            return l
    raise ConvertError('%s: layer "%s" not found' % (where, name))


def map_path(ci, set_name=None):
    """The Tiled map of a class, shared or of a room set."""
    folder = TEMPLATE_DIR if set_name is None else os.path.join(SETS_DIR, set_name)
    return os.path.join(folder, 'Room Templates %s.json' % CLASSES[ci][1])


def parse_class(ci, warnings, set_name=None):
    cls, fname, n_sub, sub_types = CLASSES[ci]
    path = map_path(ci, set_name)
    js = to_real(json.load(open(path, encoding='utf-8')))
    where = os.path.basename(path) if set_name is None else 'sets/%s/%s' % (set_name, os.path.basename(path))
    layers = js['layers']
    obj_types = OBJ_TYPES[cls]
    sec_types = SECTION_OBJ_TYPES[cls]

    rooms_layer = layers[0]
    rooms = rooms_layer['objects']
    known = {'Rooms', 'Sections'} | set(obj_types) | set(REGION_LAYERS)
    tilesets = region_tilesets(js, where)
    for l in layers:
        if l.get('name') not in known:
            warnings.append('%s: layer "%s" is ignored by the converter' % (where, l.get('name')))

    temps = []
    index_of = {}
    for i, r in enumerate(rooms):
        t = copy.deepcopy(r)
        for ot in obj_types:
            t[ot] = []
        t['Sections'] = [{st: [] for st in sec_types} for _ in range(SECTION_COUNT)]
        ids = get_prop(t.get('properties'), 'Split_MainSectionIDs')
        if ids != -1:
            t['Split_MainSectionIDs'] = [0.0] + split_reals(ids)
        whole = get_prop(t.get('properties'), 'Whole') == 1
        if cls in ('Main_Upper', 'Main_Lower') and not whole:
            t['SizeIndex'] = 0 if t['height'] == 128 else 1
        else:
            key = (int(t['width'] // 256), int(t['height'] // 256))
            if key not in ROOM_SIZE or t['width'] % 256 or t['height'] % 256:
                raise ConvertError('%s: room %s has size %sx%s' % (where, gm_str(t['id']), gm_str(t['width']), gm_str(t['height'])))
            t['SizeIndex'] = ROOM_SIZE[key]
        t['RoomTransformationsAllowed'] = [True] * 8
        add_region(t, r, layers, tilesets, where)
        if whole:
            if cls != 'Main_Upper':
                raise ConvertError('%s: room %s: Whole rooms are only Main_Upper for now' % (where, gm_str(t['id'])))
            if t['SizeIndex'] > 2:
                raise ConvertError('%s: room %s: a Whole Main_Upper room is 1x1, 1x2 or 2x1' % (where, gm_str(t['id'])))
            t['Whole'] = True
            t.setdefault('Split_MainSectionIDs', [0.0])
        elif 'Region' in t and cls in ('Main_Upper', 'Main_Lower'):
            raise ConvertError('%s: room %s is a half room with a Region layer (painted rooms are Whole)' % (where, gm_str(t['id'])))
        if 'Region' in t:
            t['RoomTransformationsAllowed'] = painted_transforms(t, where)
        if set_name is not None:
            t['RoomSet'] = set_name
        temps.append(t)
        index_of[r['id']] = i

    def room_index(obj):
        rid = get_prop(obj.get('properties'), 'Room')
        if rid == -1 or rid not in index_of:
            raise ConvertError('%s: Room ID not found for Obj ID: %s' % (where, gm_str(obj['id'])))
        return index_of[rid]

    # objects of the main layers
    for ot in obj_types:
        for obj in find_layer(layers, ot, where)['objects']:
            ri = room_index(obj)
            fix_obj_rotation(obj)
            obj['x'] -= rooms[ri]['x']
            obj['y'] -= rooms[ri]['y']
            temps[ri][ot].append(obj)

    # objects of the section layers
    if sec_types:
        groups = find_layer(layers, 'Sections', where)['layers']
        n_groups = 5 if cls == 'Main_Upper' else 1
        for st_i, st in enumerate(sec_types):
            for g in range(n_groups):
                if g >= len(groups):
                    raise ConvertError('%s: section group %d missing' % (where, g))
                sub = groups[g]['layers']
                if st_i >= len(sub) or sub[st_i].get('name') != st:
                    raise ConvertError('%s: section group "%s" should have layer "%s" at position %d'
                                       % (where, groups[g].get('name'), st, st_i))
                for obj in sub[st_i]['objects']:
                    ri = room_index(obj)
                    fix_obj_rotation(obj)
                    obj['x'] -= rooms[ri]['x']
                    obj['y'] -= rooms[ri]['y']
                    sid = int(temps[ri]['Split_MainSectionIDs'][g]) if cls == 'Main_Upper' else 0
                    temps[ri]['Sections'][sid][st].append(obj)

    # final arrays, one per subclass
    final = [[] for _ in range(n_sub)]
    target = None
    for mi, main in enumerate(temps):
        if sub_types is None:
            target = final[min(main['SizeIndex'], 1) if main.get('Whole') else main['SizeIndex']]
        elif main.get('type') in sub_types:
            target = final[sub_types.index(main['type'])]
        else:
            # GML kept the previous template's array here (function scoped var)
            warnings.append('%s: room %s has unknown type "%s"; it goes with the previous room'
                            % (where, gm_str(main['id']), main.get('type')))
            if target is None:
                raise ConvertError('%s: first room has unknown type "%s"' % (where, main.get('type')))

        sym = get_prop(main.get('properties'), 'Symetry')
        allowed = main['RoomTransformationsAllowed']

        if cls in ('Village', 'Mines', 'Other'):
            main['RoomTransformationsAllowed'] = [True] + [False] * 7
            target.append(copy.deepcopy(main))
        elif main.get('Whole'):   # a whole painted room (roadmap F12b): no halves to join
            generate_door_codes(main, cls, where)
            target = final[min(main['SizeIndex'], 1)]     # a 2x1 one goes with the 1x2 rooms, as 2x1 rooms look there
            target.append(copy.deepcopy(main))
        elif cls in ('Obstacles', 'Sections', 'Special'):
            generate_door_codes(main, cls, where)
            target.append(copy.deepcopy(main))
        elif cls == 'Jails':
            if sym == 1:
                allowed[T['FlipH']] = False
            for n in ('FlipV', 'FlipHV', 'RotateCW', 'RotateCCW', 'FlipHRotateCW', 'FlipHRotateCCW'):
                allowed[T[n]] = False
            generate_door_codes(main, cls, where)
            target.append(copy.deepcopy(main))
        elif cls == 'Stairs':
            for n in ('RotateCW', 'RotateCCW', 'FlipHRotateCW', 'FlipHRotateCCW'):
                allowed[T[n]] = False
            if sym == 1:
                allowed[T['FlipH']] = False
                allowed[T['FlipHV']] = False
            generate_door_codes(main, cls, where)
            target.append(copy.deepcopy(main))
        else:  # Main_Upper, Main_Lower: every pair of halves whose split connections fit
            for si in range(mi, len(temps)):
                second = temps[si]
                if main['height'] != second['height'] or second.get('Whole'):
                    continue
                fit = False
                for mc in main['SplitConnections'][:2]:
                    fit = any(mc['x'] == sc['x'] and mc['y'] == sc['y'] for sc in second['SplitConnections'][:2])
                    if not fit:
                        break
                if not fit:
                    continue
                sym2 = get_prop(second.get('properties'), 'Symetry')
                add_flip_h = sym == 0 and sym2 == 0
                for _ in range(2 if add_flip_h else 1):
                    # 11115 joined with itself unflipped looks like 32820 and 32847 but makes bad zones
                    if main['id'] == 11115 and second['id'] == 11115 and not add_flip_h:
                        continue
                    new = copy.deepcopy(main)
                    second_copy = copy.deepcopy(second)
                    if add_flip_h:
                        flip = T['FlipHV']
                        add_flip_h = False
                    else:
                        flip = T['FlipV']
                    if set_name is not None:    # set rooms are named after both halves, for the test logs
                        new['name'] = '%s+%s%s' % (main['name'], second['name'], '' if flip == T['FlipV'] else '~')
                    split_add_objs(new, second_copy, obj_types, flip, sec_types)
                    split_combine_walls(new, 'WallsUpper')
                    if cls == 'Main_Lower':
                        split_combine_walls(new, 'WallsLower')
                    split_merge_doors(new)
                    split_fix_carpets(new)
                    generate_door_codes(new, cls, where)
                    target.append(copy.deepcopy(new))
    return final


def convert(warnings=None):
    """Returns global.Templates_Room: [class][subclass][template]."""
    if warnings is None:
        warnings = []
    return [parse_class(ci, warnings) for ci in range(len(CLASSES))]


def set_names():
    """Room sets with a Tiled map in data/room-templates/sets, sorted."""
    if not os.path.isdir(SETS_DIR):
        return []
    out = []
    for n in sorted(os.listdir(SETS_DIR)):
        if not os.path.isdir(os.path.join(SETS_DIR, n)):
            continue
        if not any(os.path.exists(map_path(ci, n)) for ci in range(len(CLASSES))):
            continue
        if not SET_NAME.match(n):
            raise ConvertError('sets/%s: a set name has only letters, digits and _ (it is a level sheet value)' % n)
        out.append(n)
    return out


def convert_sets(warnings=None):
    """{set: {class: [subclass][template]}} for every room set, only the classes it has a map of."""
    if warnings is None:
        warnings = []
    out = {}
    for n in set_names():
        out[n] = {}
        for ci, (cls, _, _, _) in enumerate(CLASSES):
            if os.path.exists(map_path(ci, n)):
                out[n][cls] = parse_class(ci, warnings, n)
    return out


def sets_index(sets):
    """rooms/sets.json: the classes of every set."""
    return json.dumps({n: list(c) for n, c in sets.items()}, indent=1, sort_keys=True) + '\n'


def class_text(subclasses):
    """One class file: an array of subclasses, one template per line."""
    def dump(t):
        return json.dumps(t, separators=(',', ':'), ensure_ascii=False)
    return '[\n' + ',\n'.join('[\n' + ',\n'.join(dump(t) for t in sub) + '\n]' if sub else '[]'
                              for sub in subclasses) + '\n]\n'


def save(data, out_dir, sets=None):
    """Writes <out_dir>/<Class>.json for every class and, given the sets, <out_dir>/sets.json and
    <out_dir>/sets/<Set>/<Class>.json (and removes the files of sets and classes that are gone).
    Returns the total size in bytes."""
    os.makedirs(out_dir, exist_ok=True)
    total = 0
    for (cls, _, _, _), subclasses in zip(CLASSES, data):
        raw = class_text(subclasses).encode('utf-8')
        with open(os.path.join(out_dir, cls + '.json'), 'wb') as f:
            f.write(raw)
        total += len(raw)
    if sets is None:
        return total
    with open(os.path.join(out_dir, 'sets.json'), 'wb') as f:
        f.write(sets_index(sets).encode('utf-8'))
    sets_out = os.path.join(out_dir, 'sets')
    for n, classes in sets.items():
        d = os.path.join(sets_out, n)
        os.makedirs(d, exist_ok=True)
        for cls, subclasses in classes.items():
            raw = class_text(subclasses).encode('utf-8')
            with open(os.path.join(d, cls + '.json'), 'wb') as f:
                f.write(raw)
            total += len(raw)
        fit = fit_text(n)
        if fit is not None:
            with open(os.path.join(d, FIT + '.json'), 'wb') as f:
                f.write(fit.encode('utf-8'))
    if os.path.isdir(sets_out):
        for n in os.listdir(sets_out):
            d = os.path.join(sets_out, n)
            for f in os.listdir(d):
                if f[:-len('.json')] not in sets.get(n, {}) and not (f == FIT + '.json' and fit_text(n) is not None):
                    os.remove(os.path.join(d, f))
            if not os.listdir(d):
                os.rmdir(d)
    return total


FIT = 'Fit'     # sets/<Set>/Fit.json: the fitting rules of a set painted from a frame (tile_rules.fit_text)


def fit_text(name):
    """Fit.json of a room set painted from a frame (roadmap F12b-2), or None."""
    import tile_rules
    return tile_rules.fit_text(os.path.join(SETS_DIR, name))


def set_files(sets):
    """(filePath, name) of every included file that the room sets need in Zelda.yyp."""
    out = [('datafiles/data/rooms', 'sets.json')]
    for n, classes in sets.items():
        out += [('datafiles/data/rooms/sets/' + n, cls + '.json') for cls in classes]
        if fit_text(n) is not None:
            out.append(('datafiles/data/rooms/sets/' + n, FIT + '.json'))
    return out


INCLUDED = ('    {"$GMIncludedFile":"","%%Name":"%s","CopyToMask":-1,"filePath":"%s","name":"%s",'
            '"resourceType":"GMIncludedFile","resourceVersion":"2.0",},\n')
INCLUDED_ROW = re.compile(r'    \{"\$GMIncludedFile":"","%Name":"([^"]*)","CopyToMask":-1,"filePath":"([^"]*)"[^\n]*\n')


def register_sets(sets, yyp=YYP):
    """Makes the included files in Zelda.yyp match the room sets. Returns (added, removed)."""
    s = open(yyp, encoding='utf-8').read()
    want = set_files(sets)
    have = [(fp, n) for n, fp in INCLUDED_ROW.findall(s)]
    removed = 0
    for fp, n in have:
        if fp.startswith('datafiles/data/rooms/sets/') and (fp, n) not in want:
            s = s.replace(INCLUDED % (n, fp, n), '')
            removed += 1
    added = 0
    for fp, n in want:
        if (fp, n) in have:
            continue
        rooms = [m for m in INCLUDED_ROW.finditer(s) if m.group(2).startswith('datafiles/data/rooms')]
        at = rooms[-1].end()
        s = s[:at] + INCLUDED % (n, fp, n) + s[at:]
        added += 1
    if added or removed:
        with open(yyp, 'w', encoding='utf-8', newline='') as f:
            f.write(s)
    return added, removed


def load(path):
    """Reads room templates back: a rooms directory, or an old single file data_r."""
    def read(p):
        raw = open(p, 'rb').read()
        if raw.startswith(b'version https://git-lfs'):
            sys.exit('%s is a Git LFS pointer; run "git lfs pull" first' % p)
        return json.loads(raw.rstrip(b'\0').decode('utf-8'))
    if os.path.isdir(path):
        return [read(os.path.join(path, cls + '.json')) for cls, _, _, _ in CLASSES]
    return read(path)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('-o', '--out', default=ROOMS_DIR, help='output directory (default: game/datafiles/data/rooms)')
    ap.add_argument('--summary', action='store_true', help='print the number of templates per class and subclass')
    a = ap.parse_args()
    warnings = []
    try:
        data = convert(warnings)
        sets = convert_sets(warnings)
    except ConvertError as e:
        print('error:', e)
        return 1
    for w in warnings:
        print('warning:', w)
    size = save(data, a.out, sets)
    if os.path.abspath(a.out) == os.path.abspath(ROOMS_DIR):
        added, removed = register_sets(sets)
        if added or removed:
            print('Zelda.yyp: %d included files added, %d removed (room sets)' % (added, removed))

    def counts(ci, subclasses):
        names = CLASSES[ci][3] or ['1x1', '1x2', '2x1'][:len(subclasses)]
        return '%-11s %s' % (CLASSES[ci][0], ', '.join('%s %d' % (n, len(s)) for n, s in zip(names, subclasses)))
    if a.summary:
        for ci in range(len(CLASSES)):
            print(counts(ci, data[ci]))
        for n, classes in sets.items():
            print('set %s:' % n)
            for cls, subclasses in classes.items():
                print('  ' + counts([c[0] for c in CLASSES].index(cls), subclasses))
    files = len(CLASSES) + 1 + sum(len(c) for c in sets.values())
    print('wrote %d files to %s (%.1f MB)' % (files, a.out, size / 1e6))
    return 0


if __name__ == '__main__':
    sys.exit(main())

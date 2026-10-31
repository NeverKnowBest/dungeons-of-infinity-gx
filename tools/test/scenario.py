"""Test scenarios (roadmap F3): reading, checking and turning names into the numbers the game uses.

A scenario is JSON (format in tools/README.md, "test/"). Any string "Enum.Member" is replaced by the enum's value,
read from the GML enums in game/scripts. "level" and "item" also take a bare member name (DungeonLevel, ItemClass).
Standard library only, so the validator can use it too.
"""
import glob
import json
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
SCRIPTS = os.path.join(REPO, 'game', 'scripts')

VERBS = ['up', 'down', 'left', 'right', 'sword', 'action', 'item', 'map', 'strafe', 'inventory', 'menu_access', 'hud']

# step name -> allowed keys (besides "do")
STEPS = {
    'wait': {'frames'},
    'hold': {'keys', 'key', 'frames'},
    'press': {'key', 'keys', 'frames'},
    'shot': {'name'},
    'room': {'x', 'y'},
    'level': {'level', 'seed'},
    'spawn': {'enemy', 'dist'},
    'probe': {'enemies', 'dist'},
    'trace': {'frames', 'every'},
    'arch': {'enemy', 'state', 'move', 'time'},
    'give': {'item', 'index', 'amount'},
    'state': set(),
    'rooms': set(),
    'log': {'text'},
    'expect': {'alive', 'level', 'room', 'enemies', 'kills_min', 'exit_level', 'set_rooms_min', 'free'},
    'sheet': {'level', 'seeds'},
    'paint': {'x', 'y', 'w', 'h', 'blocks', 'mirror', 'flip', 'transform'},
    'painted': {'index', 'at', 'remake'},
    'seams': set(),
    'pass': {'positions', 'frames', 'optional'},
    'lock': {'side', 'frames', 'optional'},
    'at': {'index', 'x', 'y'},
    'tour': {'name', 'sections'},
    'doorshots': {'name', 'in'},
    'passall': {'in', 'frames'},
    'walkall': {'in', 'frames'},
    'cut': set(),
    'bomb': {'in', 'frames', 'optional'},
    'grid': {'cells', 'x', 'y', 'w', 'name'},
    'exit': {'which', 'frames'},
    'end': set(),
}
TOP_KEYS = {'name', 'seed', 'level', 'cheats', 'items', 'steps', 'max_frames', 'sound', 'speed', 'comment', 'dump', 'levels'}

_enums = None


def enums():
    """{EnumName: {Member: value}} from every enum in game/scripts."""
    global _enums
    if _enums is not None:
        return _enums
    _enums = {}
    for path in glob.glob(os.path.join(SCRIPTS, '*', '*.gml')):
        src = open(path, encoding='utf-8', errors='replace').read()
        src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
        src = re.sub(r'//[^\n]*', '', src)
        for m in re.finditer(r'\benum\s+(\w+)\s*\{(.*?)\}', src, re.S):
            members, value = {}, -1
            for part in m.group(2).split(','):
                part = part.strip()
                if not part:
                    continue
                name, _, expr = part.partition('=')
                name, expr = name.strip(), expr.strip()
                if expr:
                    try:
                        value = int(expr, 0)
                    except ValueError:
                        ref = expr.split('.')
                        value = members.get(expr, _enums.get(ref[0], {}).get(ref[-1], value + 1))
                else:
                    value += 1
                members[name] = value
            _enums[m.group(1)] = members
    return _enums


def _member(enum, name, errors, where):
    value = enums().get(enum, {}).get(name)
    if value is None:
        errors.append('%s: unknown %s.%s' % (where, enum, name))
        return 0
    return value


def _resolve(value, errors, where):
    if isinstance(value, dict):
        return {k: _resolve(v, errors, where) for k, v in value.items()}
    if isinstance(value, list):
        return [_resolve(v, errors, where) for v in value]
    if isinstance(value, str) and re.fullmatch(r'[A-Za-z_]\w*\.[A-Za-z_]\w*', value):
        enum, name = value.split('.')
        if enum in enums():
            return _member(enum, name, errors, where)
    return value


def _named(value, enum, errors, where):
    if isinstance(value, str) and '.' not in value:
        return _member(enum, value, errors, where)
    return value


def resolve(scenario):
    """Returns (scenario ready for the game, list of errors)."""
    errors = []
    if not isinstance(scenario, dict):
        return scenario, ['the scenario must be a JSON object']
    for key in scenario:
        if key not in TOP_KEYS:
            errors.append('unknown key "%s"' % key)
    out = _resolve(scenario, errors, 'scenario')
    if 'levels' in out:
        out['levels'] = _levels(out['levels'], errors)
    if 'level' in out and out['level'] != 'Hub':
        out['level'] = _named(out['level'], 'DungeonLevel', errors, 'level')
    for i, item in enumerate(out.get('items', [])):
        item['item'] = _named(item.get('item'), 'ItemClass', errors, 'items[%d]' % i)
    cheats = cheat_keys()
    for c in out.get('cheats', []):
        if cheats and c not in cheats:
            errors.append('unknown cheat "%s"' % c)
    for i, step in enumerate(out.get('steps', [])):
        where = 'steps[%d]' % i
        do = step.get('do') if isinstance(step, dict) else None
        if do not in STEPS:
            errors.append('%s: unknown step "%s"' % (where, do))
            continue
        for key in step:
            if key != 'do' and key not in STEPS[do]:
                errors.append('%s: "%s" does not take "%s"' % (where, do, key))
        for key in ([step['key']] if 'key' in step else []) + step.get('keys', []):
            if key not in VERBS:
                errors.append('%s: unknown key "%s" (use %s)' % (where, key, ', '.join(VERBS)))
        if 'level' in step:
            step['level'] = _named(step['level'], 'DungeonLevel', errors, where)
        if do == 'exit' and step.get('which', 'main') not in ('main', 'extra'):
            errors.append('%s: "which" is "main" or "extra"' % where)
        if do == 'give':
            step['item'] = _named(step.get('item'), 'ItemClass', errors, where)
        if do == 'arch':
            step['state'] = _named(step.get('state'), 'EnemyState', errors, where)
            if step.get('move', 'Dir') not in ('', 'Dir', 'Toward', 'Scuttle', 'Dash'):
                errors.append('%s: unknown move "%s" (scripts/__EnemyArch)' % (where, step.get('move')))
        if do in ('spawn', 'arch') and not os.path.isdir(os.path.join(REPO, 'game', 'objects', str(step.get('enemy')))):
            errors.append('%s: no object "%s"' % (where, step.get('enemy')))
        if do == 'paint' and not (isinstance(step.get('blocks', [0]), list) and step.get('blocks', [0]) and
                                  all(isinstance(b, int) and b >= 0 for b in step.get('blocks', [0]))):
            errors.append('%s: "blocks" is a list of block numbers of the region tileset' % where)
        for enemy in (step.get('enemies', []) if do == 'probe' else []):
            if not os.path.isdir(os.path.join(REPO, 'game', 'objects', str(enemy))):
                errors.append('%s: no object "%s"' % (where, enemy))
    return out, errors


def level_fields():
    """Field names of the level sheet (Level_Create in __Levels.gml)."""
    path = os.path.join(SCRIPTS, '__Levels', '__Levels.gml')
    if not os.path.exists(path):
        return set()
    src = open(path, encoding='utf-8').read()
    body = re.search(r'function Level_Create\(.*?\n\}', src, re.S)
    return set(re.findall(r'^\t(\w+) = ', body.group(0), re.M)) if body else set()


def tile_bands():
    """Names of the imported tile bands (TileBands_Init in __Tiles.gml, written by import_region.py)."""
    path = os.path.join(SCRIPTS, '__Tiles', '__Tiles.gml')
    if not os.path.exists(path):
        return set()
    return set(re.findall(r'global\.TileBands\[\$ "(\w+)"\]', open(path, encoding='utf-8').read()))


def exit_looks():
    """Names of the exit looks (ExitLooks_Init in __Doors.gml)."""
    path = os.path.join(SCRIPTS, '__Doors', '__Doors.gml')
    if not os.path.exists(path):
        return set()
    return set(re.findall(r'^\t\t(\w+): \{Draw:', open(path, encoding='utf-8').read(), re.M))


def room_sets():
    """Room sets the game loads (roadmap F11)."""
    path = os.path.join(REPO, 'game', 'datafiles', 'data', 'rooms', 'sets.json')
    return json.load(open(path, encoding='utf-8')) if os.path.exists(path) else {}


def _levels(changes, errors):
    """Scenario "levels" ({LevelName: {Field: value}}) into the list the game reads ([{level, Field: value}])."""
    if not isinstance(changes, dict):
        errors.append('"levels" must be an object: {"Castle": {"NextPool": [["CastleBasement", 2], ["Sewers", 1]]}}')
        return []
    fields, looks, out = level_fields(), exit_looks(), []
    for name, change in changes.items():
        where = 'levels.%s' % name
        entry = {'level': _named(name, 'DungeonLevel', errors, where)}
        for field, value in (change.items() if isinstance(change, dict) else []):
            if fields and field not in fields:
                errors.append('%s: the level sheet has no field "%s"' % (where, field))
            if field == 'NextPool':
                value = [[_named(v[0], 'DungeonLevel', errors, where), v[1]] for v in value]
            if field == 'ExitLook' and looks and value not in looks:
                errors.append('%s: unknown exit look "%s" (%s)' % (where, value, ', '.join(sorted(looks))))
            if field == 'RoomSet' and value and value not in room_sets():
                errors.append('%s: unknown room set "%s" (game/datafiles/data/rooms/sets.json)' % (where, value))
            if field == 'TilesBand' and value and value not in tile_bands():
                errors.append('%s: unknown tile band "%s" (TileBands_Init in __Tiles.gml)' % (where, value))
            if field == 'RegionTiles' and value and not os.path.exists(
                    os.path.join(REPO, 'game', 'datafiles', 'data', 'tiles', str(value) + '.json')):
                errors.append('%s: unknown region tileset "%s" (game/datafiles/data/tiles)' % (where, value))
            entry[field] = value
        out.append(entry)
    return out


def cheat_keys():
    path = os.path.join(SCRIPTS, 'Init_Gameplay_Cheats', 'Init_Gameplay_Cheats.gml')
    if not os.path.exists(path):
        return set()
    return set(re.findall(r'Key:\s*"(\w+)"', open(path, encoding='utf-8').read()))


def load(path):
    """Reads and resolves a scenario file. Returns (scenario, errors)."""
    try:
        data = json.load(open(path, encoding='utf-8'))
    except (OSError, ValueError) as e:
        return None, ['%s: %s' % (path, e)]
    return resolve(data)

"""Counts the rooms of a test log by template (R1 eighth round): which class they come from, how many come from the
level's room set, and of those how many have nature or a view.

    python tools/test/census.py castle_top_census            # tools/test/out/<scenario>/log.txt (or out/log.txt)
    python tools/test/census.py castle_top_census --top 20   # the 20 most used templates

Reads the "layout" lines of the step "rooms" (one per room of each level built) and the set's rooms.json for which
painted rooms have "nature" or a "view_..." frame. Standard library only.
"""
import argparse
import collections
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
CLASSES = ['Main_Upper', 'Main_Lower', 'Stairs', 'Jails', 'Village', 'Mines', 'Obstacles', 'Sections', 'Special', 'Other']
SEED = re.compile(r' seed (\d+)$')     # the step "log" of each level ("seed 7")
LINE = re.compile(r'layout (\d+) grid=\S+ size=(\S+) template=(\d+)/(\d+)/(.*?)#\S*( set=(\S+))? doors=(\S*) special=(\S+) section=(\d+)')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('scenario', help='scenario name (tools/test/out/<name>/log.txt), or a log file')
    ap.add_argument('--top', type=int, default=12, help='how many templates to list (default 12)')
    a = ap.parse_args()
    log = a.scenario if os.path.isfile(a.scenario) else os.path.join(HERE, 'out', a.scenario, 'log.txt')
    if not os.path.exists(log):
        log = os.path.join(HERE, 'out', 'log.txt')
    if not os.path.exists(log):
        sys.exit('no log for %s' % a.scenario)
    rooms, seed = [], '?'
    for line in open(log, encoding='utf-8', errors='replace'):
        ms = SEED.search(line)
        if ms:
            seed = ms.group(1)
        m = LINE.search(line)
        if m:
            rooms.append(m.groups() + (seed,))
    if not rooms:
        sys.exit('no "layout" lines in %s (step rooms)' % log)
    sets = {r[6] for r in rooms if r[6]}
    painted = {}
    for s in sets:
        d = json.load(open(os.path.join(REPO, 'data', 'room-templates', 'sets', s, 'rooms.json'), encoding='utf-8'))
        for p in d.get('painted', []):
            painted[p['name']] = p
    by_class = collections.Counter(CLASSES[int(r[2])] if int(r[2]) < len(CLASSES) else r[2] for r in rooms)
    in_set = [r for r in rooms if r[6]]
    nature = [r for r in in_set if painted.get(r[4], {}).get('nature')]
    view = [r for r in in_set if str(painted.get(r[4], {}).get('frame', '')).startswith('view')]
    n = len(rooms)
    print('rooms %d, from the set %d (%d%%)' % (n, len(in_set), 100 * len(in_set) // n))
    print('by class: ' + ', '.join('%s %d' % kv for kv in by_class.most_common()))
    print('with nature %d (%d%%), with a view %d (%d%%)' % (len(nature), 100 * len(nature) // n, len(view), 100 * len(view) // n))
    sec = [r for r in rooms if r[2] == '7']
    if sec:
        print('Sections class: ' + ', '.join('seed %s room %s section %s' % (r[10], r[0], r[9]) for r in sec))
    big = [r for r in rooms if int(r[9]) > 20]
    if big:
        print('sections over 20: ' + ', '.join('seed %s room %s section %s %s' % (r[10], r[0], r[9], r[4]) for r in big))
    print('templates: ' + ', '.join('%s %d' % kv for kv in collections.Counter(r[4] for r in rooms).most_common(a.top)))


if __name__ == '__main__':
    main()

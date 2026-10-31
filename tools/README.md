# External tools

These third-party tools were used during development. Their binaries are **not**
stored in this repo. Download them from the archives if you need them for any reason:

* Archive.org: https://archive.org/details/dungeons-of-infinity-src-1.2.1
* Personal Mirror: https://castie.ddns.net/zdoi/dungeons-of-infinity-1.2.1-src.zip

The full original tool folder (including binaries) is preserved in the project's
archived `.zip` backups.

Never commit ROMs (`.sfc`, `.smc`), save files or emulator states. `.gitignore`
blocks the common extensions.

## Needed to work on the project

| Tool | Version used | Used for |
|------|--------------|----------|
| GameMaker | IDE 2024.13.1.193 / Runtime 2024.13.1.242 (Template Editor: 2023.11.0.121 / 2023.11.0.157). See the root README | Opening `game/` and `editors/dungeon-editor`. Room templates are converted by `templates/convert.py` (the old GameMaker parser was retired in roadmap F5) |
| [Tiled](https://www.mapeditor.org/) | 1.11.2 | Editing room templates in `data/room-templates/` |
| Aseprite | n/a | Editing the `.aseprite` / `.ase` art sources in `art/` |
| xzip (xgasoft GameMaker extension) | 1.0.2 | Zip support in the game. Already imported into `game/`, so you only need it again to update the extension |

## Optional / historical

| Tool | Version used | Used for |
|------|--------------|----------|
| [Stockfish](https://stockfishchess.org/) | n/a | Chess engine for the village chess NPC. That NPC is currently disabled (see `game/datafiles/Change Log.txt`). The bridge scripts are in `stockfish-bridge/` |
| [AutoIt](https://www.autoitscript.com/) | n/a | Compiling `stockfish-bridge/*.au3` and `editors/dungeon-editor/WinOnTop.au3` |
| SNES GSS (SNES Game Sound System, by Shiru) | 1.42 | SNES-style music/sound experiments |
| SPCTool | n/a | Playing and ripping SPC music for reference |
| vSNES | 2.91 | Viewing SNES savestates to rip reference graphics |
| SNESTilesKitten | n/a | Viewing and editing SNES tile graphics |
| ZSNES | 1.51 | SNES emulator for reference play |
| [Lunar IPS](https://www.fusoya.eu/) | n/a | Applying IPS patches to reference ROMs |
| PaletteGenerator | 3.0.1 | Generating color palettes |
| Retro Palette Swapper | 1.0 | Palette-swapping sprites |

## `stockfish-bridge/`

Our own AutoIt scripts that let the game talk to `Stockfish.exe` over the UCI
protocol. The game writes command files (`Command`), and `SF.au3` relays them to
Stockfish and writes the responses back. `UCI notes.txt` has quick notes on the
protocol.

## Scripts added in this fork

### `check/` (Python 3, standard library only)

`validate.py` checks the project without GameMaker. Run it before every delivery:

```
python tools/check/validate.py            # report; exit code 1 on errors
python tools/check/validate.py --orphans  # list folders on disk that Zelda.yyp does not register
python tools/check/validate.py --strict   # warnings also fail
```

| Check | Level |
|-------|-------|
| Every resource in `Zelda.yyp` exists on disk (ignoring letter case, like Windows) | error |
| Resource path only matches ignoring letter case (breaks on Linux and macOS) | warning |
| Resource folder on disk that `Zelda.yyp` does not register (orphan) | warning |
| Asset name used by two resources | error |
| Object parent, sprite, mask and collision objects are in the project | error |
| Every event in an object's `eventList` has its `.gml` file | error |
| `.gml` file that is not an event of the object (never runs) | warning |
| Sprite frame images and sound files exist | error |
| Global function defined in two scripts | error |
| Asset style name (`sX`, `oX`, `Sound_X`, `Music_X`) used in GML that does not exist | warning (error if it only exists as an orphan) |
| Array literal starting with `#RRGGBB` | error |
| A variable or struct field named like a constant macro (`Night = ...`, `Cfg.Night`, `{Night: ...}`: the macro's value takes its place; `Night` is 3 in `__Chess`) | error |
| Lower case text drawn with `global.Font_Small` | warning |
| `a[i] = ...i++` (GML evaluates the right side first) | warning |
| Level rule on `global.Level.Index` (`switch`, comparison or formula) outside `__Levels` and `__Test`: read a `LevelDef` field instead | warning |
| Every included file in `Zelda.yyp` exists on disk | error |
| `data_d`, the room template files (`game/datafiles/data/rooms`) and the Tiled templates parse as JSON (LFS pointers are skipped) | error |
| The room template files match what `templates/convert.py` makes from the Tiled maps right now (adds about 10 s) | error |
| Control characters in scripts, GML, docs and scenario or room set JSON (a backslash lost on the way, e.g. a regex `\b` turned into a backspace) | error |
| Room sets: `templates/make_rooms.py --selftest` is SAME (outlines, `motifs.json` up to date, loose compositions refused), the maps it writes match their `rooms.json`, `rooms/sets.json` and `rooms/sets/<Set>/<Class>.json` match the set maps, every set file is an included file in `Zelda.yyp` (and no other file under `rooms/sets`), every `RoomSet` in `__Levels.gml` is a set, and a level whose set has painted rooms has the `RegionTiles` they are painted with (roadmap F12b) | error |
| Room sets painted from a frame (roadmap F12b-2, `tile_rules.check_set`): every room's blocks are blocks of the region and fit the rules and the approved joins (closed, with its doors open, with its gate), its border is the frame's and, with the doors open, the frame's passages; `incoming/<region>/tiles/rules.json` and `rooms/sets/<Set>/Fit.json` up to date | error |
| A data file over 45 MB (GitHub warns at 50 MB) | warning |
| Arrows or em dashes in the Portuguese docs (including `docs/ref/` and `docs/regioes/`) | warning |
| Region spec (`docs/regioes/*.md`) has every `##` section and every header field (`* **Capítulo:**`...) of `_modelo.md` and a valid `**Estado:**` | error |
| Every `ExitLook` the level sheet names is a look of `ExitLooks_Init` (`__Doors.gml`) | error |
| Tilesets (roadmap F6b): `tile_count` fits the sprite and `output_tileset.png` (the texture the game draws from) exists with the size that count needs; every `TilesBand` of the level sheet is in `TileBands_Init` and every `RegionTiles` has its `data/tiles/<Name>.json`, included in `Zelda.yyp`, with a tileset `ts_<Name>` and a class for each tile its blocks use | error |
| Archetype enemies (`scripts/__EnemyArch`): every child of `oEnemy_Archetype` has an `EnemyArch` entry and every entry names such a child; the sprites the entries name exist (with or without `_Left/_Right/_Up/_Down`) | error |
| Archetype enemy with events of its own | warning |
| `object_get_parent(...) == oEnemy` in GML (misses the archetype enemies; use `object_is_ancestor`) | warning |
| `Zelda.resource_order` lists a file that does not exist | warning |
| Region spec cites an asset (`oX`, `sX`, `Sound_X`, `Music_X` in backticks) that is not in `Zelda.yyp`, unless the line says "(novo)" | error |
| Reference sheet (`docs/ref/*.md`) cites an asset that is not in `Zelda.yyp` | warning |
| A cited `docs/...md` file does not exist | warning |
| Test scenario (`test/scenarios/*.json`) with an unknown step, key, cheat, enemy object or enum name | error |

When a new GML or data trap is found, add a check here.

### `test/` (Python 3, standard library only; needs GameMaker installed)

Automated test (roadmap F3, F3b): compiles the game with Igor, runs scenarios with nobody at the keyboard and out of sight, and prints the result as text. The game side is `game/scripts/__Test` (test mode) and the object `oTest`.

```
python tools/test/run.py smoke                       # a scenario in test/scenarios (or a path to a .json)
python tools/test/run.py boot smoke arch_trace       # several: one build, then each scenario in a new game
python tools/test/run.py --all                       # every scenario (the battery before a delivery, about 15 min)
python tools/test/run.py --all --only ref_           # only the ones whose name contains "ref_"
python tools/test/run.py --all --save after          # also keep the results as the baseline "after" (baseline.py compare)
python tools/test/run.py smoke --no-build            # run the last build again (8 s instead of about 80 s); only when no GML changed
python tools/test/run.py --sheet Castle --seeds 4    # contact sheet: levels of seeds 1..4, every room in one PNG
python tools/test/run.py --sheet Sewers --seeds 7,9  # chosen seeds
python tools/test/run.py smoke --full                # also print the "step" lines of the log
python tools/test/run.py smoke --show                # the game on the screen, as the IDE runs it (it takes the focus)
```

* It finds the active runtime (`C:\ProgramData\GameMakerStudio2-LTS2026\runtime.json`) and the IDE user folder in `%APPDATA%` by itself, builds in `%TEMP%\doi-test` with Igor `Compile` (builds without starting the game; compile output in `%TEMP%\doi-test\build_output.txt`) and starts `Runner.exe` itself. The scenario goes through the environment variable `DOI_TEST` (the game also takes `-test <file>`) to `%LOCALAPPDATA%\Zelda\test\scenario.json`.
* Out of sight (F3b): the game runs on a hidden Windows desktop of its own (`CreateDesktop`, one per call, gone when the call ends). Nothing shows on the screen and the game never takes the focus or the keyboard, so tests can run while someone uses the PC. It runs `Zelda_test.win`, a copy of the build with the "start fullscreen" option off (bit 0 of the GEN8 info flags; see `docs/dev/engine-notes.md`); `Zelda.win` itself is not touched. `--show` runs `Zelda.win` on the screen instead.
* One game per scenario, one after the other, never one game for several: the generator, the instance and ds numbers and the globals would carry over and a scenario's result would depend on the ones before it. Two calls at the same time clash (same scenario file and output folder in `%LOCALAPPDATA%\Zelda\test`); run one at a time.
* Results go to `tools/test/out/` (ignored by git): with one scenario `log.txt` and the PNGs right there, with several one folder per scenario (`out/<scenario>/`). One scenario prints compile and runtime errors, the log and `RESULT: ok`; several print one line per scenario (with the `FAIL`/`crash` lines of the ones that failed) and `RESULT: ok (N scenarios)` or `RESULT: FAILED k of N: <names>`. Exit code 0 when every log ends with `end ok` and has no `FAIL` line. `--timeout` (default 600 s per scenario) stops a run that hangs.
* The game keeps going without focus and ignores the real keyboard. Sound is muted unless the scenario says `"sound": true`. Nothing is saved (user file, stats, achievements, options).
* On the hidden desktop the runtime makes one more surface at start than on the screen, so in the dumps every `ref surface N` is one higher than in a baseline made with `--show` or before F3b. `baseline.py compare --handles` ignores it; baselines made out of sight compare SAME among themselves without it.
* `scenario.py` reads and checks scenarios; the validator uses it too.

Reference runs (roadmap F4): `baseline.py` runs every `scenarios/ref_*.json` (one per level: three builds of the level with `"dump": true`, the level's enemies with per-level stats in a `probe` step, a short walk, a contact sheet of seeds 2 and 3) and keeps the results under a label, so two versions of the code can be compared.

```
python tools/test/baseline.py save before                # compiles once and runs the 14 ref_* scenarios (about 15 min, out of sight)
python tools/test/baseline.py save after --only Mines    # only the scenarios whose name contains "Mines"
python tools/test/baseline.py save after --no-build      # reuse the last build
python tools/test/baseline.py compare before after       # SAME, or every text line and image that differs
python tools/test/baseline.py compare before after --handles   # same, ignoring sprite and surface numbers in the dumps
```

Seams of painted rooms (R1 seventh round): `seam_sheet.py` reads the `doorshot` lines of a scenario's log and puts the photos of the two sides of each seam together, one above the other (bottom and top doors) or side by side (right and left), as the camera transition scrolls through it; the camera stops at the room's edge, so the two photos meet exactly. Writes `seams/<name>_r<A>p<P>_r<B>p<Q>.png` and `seams/sheet_<name>.png` in the scenario's out folder. Needs Pillow.

```
python tools/test/run.py castle_top_seams
python tools/test/seam_sheet.py castle_top_seams            # out/castle_top_seams/seams/
python tools/test/seam_sheet.py castle_top_seams --scale 1  # the sheet at full size
```

* Results go to `tools/test/baseline/<label>/<scenario>/` (ignored by git, about 60 MB per label). The same code gives the same files, so any difference is a change in behaviour (or in the dumped data: a renamed or removed global shows up too).
* A baseline of the code before a change can be made after the change too: `git worktree add --detach %TEMP%\doi-base HEAD`, copy the test tools in, `save before` there and copy `tools/test/baseline/before` back (see `docs/dev/receitas.md`, "Comparar antes e depois").
* `compare` shows pixel counts for images when Pillow is installed. It ignores the `step` lines of the log: they echo the scenario as GML writes it, and the key order changes between builds.
* F4 result, for reference: every file the same except three lines per dump, the globals `DungeonNames` and `Music_LevelSongIndex` (gone) and `LevelDefs` (new).
* `--handles`: a change that creates sprites or surfaces (even temporary ones) shifts the numbers of every sprite and surface made after them, so every dump differs in lines like `MapSurface=ref surface 127`. With `--handles` those numbers (and `OldWinFocus`, which depends on the window focus) are ignored and only real differences are left, plus the new globals themselves (`+global LinkSpr_Ascending_Top1=...`).
* `scenarios/arch_trace.json` is the behaviour check of the archetype enemies (roadmap F7): it spawns them and the soldiers in four levels, hits them with the sword and traces every enemy. Run it on both versions (in the worktree copy as well) and compare the two `log.txt` with `python tools/test/logdiff.py before.txt after.txt`, which ignores the frame numbers, the `step` lines and the `ref ds_list/instance` numbers (`--frames` compares the frames too). F7 result: SAME (1321 lines, frames included).
* F4b result: SAME in all 14 against the F4 baseline. A busy PC can make one `oMusic` line differ (`SongPlaying_Intro`, `SongPlaying_Inst`): the music intro ends on the real clock, so a slower run reaches the loop before the third build. Run that scenario again (`save <label> --only ref_01 --no-build`) with nothing else running before calling it a change.

Scenario format (JSON). Strings like `"Swords.Master"` become the GML enum value; `level` and `item` also take a bare name (`"Sewers"`, `"Shield"`).

| Key | Meaning |
|-----|---------|
| `name` | Name in the log |
| `seed` | Random seed (default 1). The same scenario on the same code always plays the same way |
| `level` | First level (`DungeonLevel` name, default `Castle`), or `"Hub"` for the Sanctuary |
| `cheats` | Cheat keys of `global.CheatList` turned on (`"Cheat_Inf_Health"`...) |
| `items` | Items given at the start: `{"item": "Sword", "index": "Swords.Master", "amount": 1}` |
| `max_frames` | The test fails with `timeout` after this many frames (default 36000) |
| `speed` | Frames per second (default 60) |
| `sound` | `true` to hear it |
| `dump` | `true`: every level built writes `dump_<n>_<level>_s<seed>.txt` (level and room structs, instances with their variables, MD5 of each tile layer per room, globals). For comparing two versions of the code |
| `levels` | Temporary changes to the level sheet for this test only: `{"Castle": {"NextPool": [["CastleBasement", 1], ["Catacombs", 1]]}, "Catacombs": {"ExitLook": "StairsUp"}}`. Field names are checked against `Level_Create`, `NextPool` takes level names, `ExitLook` a look of `ExitLooks_Init`. For trying a branch of the run that no level has yet (`scenarios/branch_exits.json`) |
| `steps` | List of steps, run in order (below) |

| Step | Keys | What it does |
|------|------|--------------|
| `wait` | `frames` | Waits |
| `hold` | `keys` (list), `frames` | Holds the keys together. Keys: `up down left right sword action item map strafe inventory menu_access hud` |
| `press` | `key`, `frames` (default 8) | Holds one key, then releases it for 4 frames |
| `shot` | `name` | Screenshot of the game view at 1x (256x224, no HUD) to `<name>.png` |
| `room` | `x`, `y` | Moves Link into the room at that grid position (0..7), just inside one of its doors |
| `level` | `level`, `seed` | Builds a level (the next level of a run normally comes through the stairs) |
| `spawn` | `enemy`, `dist` (default 48) | Creates an enemy object (`oEnemy_Rat`) in front of Link |
| `probe` | `enemies` (list), `dist` | Creates each enemy in front of Link, logs a `probe` line with its variables (energy, attack, `Type`...) and removes it. An enemy outside the levels its code knows may crash (the soldiers no longer do: they take their default variant) |
| `trace` | `frames` (default 120), `every` (default 10) | Every `every` frames, one `trace` line per enemy: position, `z`, state, `Dir`, sprite, image, speed, energy, `alarm[0]` and Link's position. Two versions of the code that log the same lines move the same way (`scenarios/arch_trace.json`, roadmap F7) |
| `arch` | `enemy`, `state` (`EnemyState` name), `move`, `time` (`[min, max]`) | Changes a state of an archetype enemy (`scripts/__EnemyArch`) for this test only, e.g. a rat that chases Link (`scenarios/arch_patterns.json`) |
| `give` | `item`, `index`, `amount` | Gives an item |
| `state` | | Logs level, room, Link's position and health, enemies and kills |
| `rooms` | | Logs a `layout` line per room of the level: `layout <index> grid= size= template=<class>/<subclass>/<name>#<id> [set=<Set>] doors=<position>:<DoorStatus>,... special=<SpecialDungeonObj> section=<Section_ID>`; for measuring what a room set covers (scenario `castle_top_layouts`) |
| `log` | `text` | Writes a note in the log |
| `expect` | `alive`, `level`, `room` (`[x, y]`), `enemies`, `kills_min`, `exit_level`, `set_rooms_min`, `free` | Checks; a mismatch is a `FAIL` line. `"exit_level": true`: the current level is the one the last `exit` step's door leads to (not the rest stop). `set_rooms_min`: at least that many rooms of the level come from its room set (roadmap F11). `"free": true`: Link does not stand in a wall that blocks him (roadmap F12b) |
| `exit` | `which` (`main` or `extra`), `frames` (default 60) | Puts Link 40 px in front of the level's main or extra exit (roadmap F4b; for a gate, 48 px below its doorway, `GateDY` under the door cell) and walks into it for `frames`. Fails if there is no such exit |
| `paint` | `x`, `y` (px in Link's room), `w`, `h` (in 16x16 blocks), `blocks` (list, used in turn), `mirror`, `flip`, `transform` | Paints blocks of the level's region tileset (`RegionTiles` in the sheet, roadmap F6b) and logs `paint tileset=ts_X blocks=<painted> of <asked> classes=<classes read back>`; a block not painted is a failure. With `transform` (0 to 7, `ObjTransformation`) the grid is turned the way a painted room is (roadmap F12b) and the line is `paint transform=<name> blocks=<n>` |
| `painted` | `index` (room, default the first painted one), `at` (`center`, default just inside a door), `remake` | Painted room (roadmap F12b): with `remake`, first makes the room's walls again while it sleeps (what a bombed secret door does to the room behind it: the old walls must go, not double); then puts Link in it, waits 10 frames and checks every 8x8 cell: a solid tile must be inside one of the room's walls and no other cell may be. Logs `painted room= template= transform= tiles=<painted>/<cells> solid= walls= passages= mismatch=<cells wrong> [first=x,y]`; no painted room or a mismatch is a failure |
| `lock` | `side` (px across from the door's middle, default 0), `frames` (default 120), `optional` | A locked door of a painted room (R1): puts Link 32 px inside the first locked door of a painted room, `side` px across, and walks him into it. He must end in the same room, out of the walls and with no camera transition: `lock held x= y=`, otherwise `lock passed: <why>` and the step fails. With `optional`, a level with no such door logs `lock none` instead of failing. Where the start spot is inside a wall (the posts under a top wall), Link starts 8 px further in, up to 6 times. Scenario `castle_top_lock` (4 seeds, one door on each side, 7 tries each) |
| `pass` | `positions` (door positions 1 to 12 to pick from, default any), `frames` (default 90), `optional` | An open door of a painted room (R1 sixth round): puts Link 16 px inside the first open door at one of `positions` (lower where his box would be in the wall above) and walks him through it. After the camera transition he must be in another room and out of the walls: `pass went to room=`, otherwise the step fails. Scenario `castle_top_pass` (the side doors by the top corner, 2 and 10) |
| `tour` | `name` (default `tour`), `sections` | A photo of every room of the level (with `sections`, only the rooms with a section; scenario `castle_top_section_photos`, seeds 1 to 12): Link at the top of each 256 px cell of each room and at the bottom of its last row, 12 frames each, `<name>_<room>_<n>.png`. The agreed photo set of a visual task (`CLAUDE.md`, "Uma revisão só"). Scenario `castle_top_photos` (seeds 1 and 7, 64 photos) |
| `doorshots` | `name` (default `door`), `in` (default 40) | A photo of every door in use of every painted room (R1 seventh round): Link `in` px inside in front of it, 12 frames each, `<name>_r<room>_p<position>.png`, and a `doorshot` line per door with its cell in the level. `tools/test/seam_sheet.py <scenario>` puts the two sides of each seam together. Scenario `castle_top_seams` (seeds 1 and 7) |
| `passall` | `in` (default 24), `frames` (default 240) | Every open or locked door of every room of the level (R1 seventh round): Link at the mouth of its passage, `in` px inside (where that is a wall, the first free spot 16 to 56 px in, and for a side door 4 to 16 px lower), walks through it; he must reach the room behind (`ConnectedRoomIndex`), out of the walls: `passall room= door= <wall> -> <room> ok`, else a failure with a photo `passall_fail_<n>.png` and the walls in front of him. It proves the passage, not the way to it across the room. Give keys first (`give` `Key`) for the locked ones. The room's enemies die first |
| `bomb` | `in`, `frames`, `optional` | Every secret door of the level, the top ones (with the crack) first: Link walks into the wall for 20 frames, a lit bomb goes down in front of him as the item puts it, the wall must open (`bomb: the wall stayed shut` otherwise) and he walks through to the room behind, from the mouth of the opened passage. Photos `bomb_<n>_before.png` (the wall, with its crack) and `bomb_<n>_after.png` (opened). The door behind a bombed one is skipped (`opened from the other side`). With `optional`, a level with none is not a failure. Scenario `castle_top_doors` (seeds 1 to 8, with `passall` and the main exit) |
| `at` | `index` (room, default Link's), `x`, `y` (px in the room, default 128) | Puts Link at that spot of a room and waits 10 frames (the room wakes, the camera gets there): for photos (`shot`) of a given spot. Logs `at room=` with the room's layout line. Fails during a camera transition (when it ends the game puts the new room to sleep, and Link with it if he was moved there): wait for it first |
| `grid` | `cells` (block * 2 + mirror, -1 leaves the cell), `w` (default 16), `x`, `y`, `name` | Paints a grid of blocks of the level's region tileset over Link's room (pictures only, the walls stay): previews of painted rooms in the game, at the level's light. Logs `grid <name> blocks=N` |
| `seams` | | The seams between neighbouring painted rooms of the level (roadmap F12b-2): every 2x2 window of blocks across the edge of two rooms (doors in use open) must be on the region's maps or an approved join, read from `rooms/sets/<Set>/Fit.json`; windows where four rooms meet are skipped (the screen never shows them). Line `seams pairs=N windows=N misfits=N`; on a misfit also `first=rooms A/B (<template>/<template>) at x,y blocks a,b,c,d`, `seams edge A: ... B: ...` (both rooms' blocks along that edge) and `seams doors` (each door with its status), and the step fails. Scenario `castle_top_seams` (12 seeds) |
| `sheet` | `level`, `seeds` | Contact sheet (what `--sheet` runs): `sheet_<level>_<seed>.png` per seed and `sheet_<level>.png` with all of them at half size |
| `end` | | Ends the test (it also ends after the last step) |

Log lines start with the frame (`f152`): `start`, `level <index> "<name>" rooms= dungeon=`, `room <index> grid= size= template=<class>/<subclass>/<name>#<id>` (plus ` set=<Set>` when the template is of the level's room set), `roomset <Set> rooms=<from the set>/<all>` (after the `level` line, only in levels with a `RoomSet`), `kill <object>`, `damage`, `dead`, `boss defeated`, `shot`, `dump <file>`, `probe <object> ...`, `trace <frame> <object> ...`, `arch <object> ...`, `state`, `expect ok`, `levels <index> "<name>" <field>=<value>` (scenario changes), `exits main-><level> count=1|2 extra=room <n> grid= Top|Bottom [secret]-><level> main=room <n> grid=` (only in levels whose exits can lead to more than one level), `exit main|extra room= -> level <n>`, `painted room= ...`, `layout ...` (step `rooms`), `weather level=<n> {fields}` (a level's `oWeather` starts), `FAIL ...`, `crash ...` (a GML error, with the stack) and last `end ok|timeout|crash|error`.

### `region/` (Python 3, standard library only)

Where a region stands in the "nova região" flow (roadmap F10; the flow itself is the Claude skill `.claude/skills/nova-regiao/`):

```
python tools/region/status.py topo-do-castelo                  # by name (docs/regioes/<name>.md)
python tools/region/status.py docs/regioes/topo-do-castelo.md  # or by path
```

It reads the spec (header fields, Inimigos table, Salas, Música e som, Clima e efeitos) and the project (`DungeonLevel`, the level sheet entries with `Depth`, `Next`, `NextPool`, `ExitLook`, `Theme`, the exit looks, `Zelda.yyp`, `EnemyArch` and `EnemyDataInit`, `incoming/<name>/`, the `ref_*` scenarios) and prints one block per step of the flow: `ok` (already there), `todo` (to do), `GAP [key]` (the tools cannot do it yet; the keys are explained in `.claude/skills/nova-regiao/references/lacunas.md`), `WAIT` (Guilherme still has to deliver something) and `note`. The last lines are `STOP: ...`, `WAIT: ...` or `READY`. It only reads files. The gap checks are heuristics on the spec's words; when a gap is solved, take it out of the script and of `lacunas.md` together.

### `templates/` (Python 3, standard library only)

Room template conversion, ported from the old GameMaker project `editors/room-template-parser` (retired in roadmap F5; it is in the git history):

```
python tools/templates/convert.py                  # Tiled maps in data/room-templates -> game/datafiles/data/rooms/<Class>.json
python tools/templates/convert.py -o out/rooms     # write somewhere else
python tools/templates/convert.py --summary        # also print the template count per class and subclass
python tools/templates/compare.py OLD NEW          # compare two rooms folders (or old data_r files) by content (exit code 1 if they differ)
python tools/templates/make_rooms.py Example       # room set: data/room-templates/sets/Example/rooms.json -> that set's Tiled maps
python tools/templates/make_rooms.py Example --dry-run   # only check the description
python tools/templates/make_rooms.py --list        # sets with a description and their halves
python tools/templates/make_rooms.py Example --map # each half as text: walls, door lanes and the composed motifs
python tools/templates/make_rooms.py CastleTop --png out.png   # painted rooms drawn, every door closed and open (Pillow)
python tools/templates/make_rooms.py --selftest    # outlines against ten shared templates, loose compositions refused
python tools/templates/motifs.py                   # composition motifs measured in the shared templates -> data/room-templates/motifs.json
python tools/templates/motifs.py --report          # the catalog layer by layer, with the rules it makes
python tools/templates/motifs.py --check           # exit 1 when motifs.json is out of date
```

| File | What it does |
|------|--------------|
| `convert.py` | Reads the ten `Room Templates <Class>.json` maps, makes positions relative to each room, joins the Main Upper/Lower halves, computes door and zone codes and writes one file per class, one template per line (about 10 s). Also converts the room sets (`data/room-templates/sets/<Set>/`, roadmap F11) to `rooms/sets/<Set>/<Class>.json` plus `rooms/sets.json`, and registers those files as included files in `Zelda.yyp` (only when writing to the default folder). How the data works: `docs/dev/engine-notes.md`, "Room templates" and "Room sets" |
| `make_rooms.py` | Room template helper (roadmap F11): writes the Tiled maps of a room set (`Main_Upper` and `Main_Lower` half rooms, and whole painted rooms, F12b) from a short description, converts them like `convert.py` and prints, per class and size, how many rooms the halves make, the doors and the sections they cover. Never overwrites a map it did not write (maps it writes have the map property `Generator`) |
| `motifs.py` | Composition motifs (roadmap F11b): classifies every piece of the shared `Main_Upper` and `Main_Lower` halves by its anchor on the floor (`corner`, `top`, `top_center`, `side`, `axis`, `field`; `area` for enemy areas and full carpets) and writes `data/room-templates/motifs.json`: per class and layer, the motifs used by at least 3 halves with their sizes, insets, steps, lattice phase and properties, plus the shares that make the rules of `check_half` (mirror, door lane, touching). `--report` prints it and how many shared pieces it explains (96% in Main_Upper, 92% in Main_Lower) |
| `rt_tables.py` | Transform tables (gid, door position, section id, rotation, pot and switch block directions), generated once from the GML `GetTransformed*` functions. Gid names resolve through the `TemplateObjGID` enum in the game's `__RoomTemplates.gml` |
| `compare.py` | Content comparison of two sets of room templates (a rooms folder or an old single file `data_r`), ignoring key order and int versus float. Template order inside a subclass counts (it changes what a seed builds) |

The output was checked equal to the last `data_r` written by the GameMaker parser (roadmap F5). The room files are plain git, not LFS, so `git diff` shows which templates changed (one line each).

Room set description (`data/room-templates/sets/<Set>/rooms.json`; the set name is the level's `DungeonLevel` member and goes in `RoomSet` in the level sheet). Pixels of the half room, 256 wide, on the 8 px grid; the half is the top of a room, and the converter joins it with every half of the same class and size (flipped, below it) whose side walls meet the cut line at the same place:

```
{"halves": [
  {"name": "Hall", "class": "Main_Upper", "size": "1x1",      # Main_Upper or Main_Lower; 1x1 (256x128 half) or 1x2 (256x256)
   "cut": [[16, 16, 48, 48]],                                  # boxes taken out of the outline (walls follow; OutOfBounds over them)
   "doors": "all",                                             # or a list: Main_Upper 11 12 1 (top) 10 9 (left) 2 3 (right),
                                                               #   Main_Lower 23 24 13, 22 21, 14 15; 9 3 21 15 are on the cut line
   "sections": [1, 2, 9, 17],                                  # Main_Upper: top left corner, top middle, wide left, top strip
   "motifs": [                                                 # decoration (F11b): "Layer/anchor" from motifs.json
     "Torches/corner",                                         #   the catalog's first size, inset and step
     {"motif": "Pots/corner", "size": [64, 16]},               #   or one of its sizes, insets [side, top] and steps [x, y]
     {"motif": "Water/axis", "inset": [64, 56], "within": [80, 96, 96, 32]}],   # within: only inside this box
   "zones": [[...]],                                           # only when water splits the floor (the script refuses it otherwise)
   "water": [[...]], "spikes": [[...]], "objects": {"Torches": [[40, 40, 16, 16]]},   # loose pieces: last resort, checked too
   "furnish": true,                                            # false: no composition, only what is given
   "props": {"ForceWallTheme": 3}}                             # more properties of the Tiled room
]}
```

Walls (24 px thick, corner and inner corner pieces), OutOfBounds, the Main_Lower lower floor and the upper walls around it, the doors, the SplitConnections and `Symetry` come from the outline. With `furnish` (the default) every half and every section is composed from motifs: the ones it names in `motifs` and, for the other layers of `DEFAULT_LAYERS` (torches, monuments, pots, pot treasures, treasure and crystal spots, full carpet, enemy area), the most used motif of the class; a named layer drops its default. The pieces go in mirrored pairs, furniture first, then water and spikes around it, then the spots and areas; without spots the generator cannot place keys and crystals. The composition check (`motifs.check_half`) then refuses a loose half: a piece no motif explains, a pair missing in a layer the shared templates mirror (Torches, Monuments, Pots, Treasures...), Torches or Monuments touching, water, guru bars or moving spike blocks on a door lane (the game drops the other layers next to a door in use), solid pieces cutting two doors apart. `--map` prints each half as text to judge the composition before the game. `--selftest` builds ten shared templates (Main_Upper and Main_Lower, with and without cuts) from descriptions and compares walls, doors, OutOfBounds, LowerFloor and SplitConnections with the real ones, checks that `motifs.json` is up to date and explains at least 90% of the shared pieces, and that six loose compositions (the F11 Example pool and gallery statues among them) are refused; the validator runs it too (`docs/dev/engine-notes.md`, "Room sets"). Not done yet: other classes (Stairs, Obstacles, Sections, Jails) and sections in Main_Lower (gap `salas-classe` of the `nova-regiao` skill).

Painted rooms (roadmap F12b, module `paint_rooms.py`): beside its `halves`, a `rooms.json` may have a `kit` and `painted` rooms, whole `Main_Upper` rooms painted tile by tile with a region tileset. The kit's pieces are cells of an ALttP area (16x16 blocks, column and row as in `incoming/<region>/tiles/areas.json`, which `owdump.py tiles` writes); the frame, the openings and the decoration are made of them, so the light and the perspective stay those of the original:

```
"kit": {"tiles": "CastleTop", "area": "1B",                       # region tileset (data/room-templates/tilesets/<Name>.json) and area
        "pieces": {"floor": [15, 7, 1, 1],                        # [col, row, w, h] of the area, or rows of [col, row]: [col, row, "m"]
                   "bottom_left": [[[16, 0], [12, 38], [13, 38]], ...], ...},   #   mirrored, "v" flipped, "h" the right half of the
                                                                  #   cell beside the left half of the next one (a wall's
                                                                  #   end moved half a block, R1 sixth round), "vh" the
                                                                  #   bottom half of the cell above the top half of the one
                                                                  #   below (a rim moved half a block down, R1 seventh
                                                                  #   round), any other word the recolored copy of
                                                                  #   tiles/extra.json (owdump.py tiles; with "h" or "vh",
                                                                  #   of each half that has one)
        "frame": {"top": ["top_left", "top_mid", "top_right"],     # left and right at the corners, the middle repeated across;
                  "middle": ["side_left", "floor", "side_right"],  #   the middle row repeated down between the top and the bottom
                  "bottom": ["bottom_left", "bottom_mid", "bottom_right"]},
        "frames": {"view_left": {...}, "special": {..., "gate": {...}}},   # other frames a room names ("frame"); a frame may
                                                                  #   move the gate ("gate")
        "openings": {"Top": "open_top", "Bottom": "open_bottom"}, # painted on RegionOpen at a door, 16 px left of its cell, at the wall
        "gate": {"Top": {"piece": "gate", "at": [-32, 16]},       # RegionGate: the level's entrance or exit in that door (px from the
                 "Bottom": {"piece": "stairs", "at": [-16, -32]}},#   door cell's x; y from the top, or from the bottom for Bottom)
        "grass": {"full": [16, 44], "top": [48, 57, "floor"], "bottom": ..., "left": ..., "corner": ..., "inner": ...},
        "nature": {"tree": "tree", "bush": "bush", "tufts": ["tuft", "flower"]},
        "parapet": {"h": [["bottom", 0, "b"], ["top", 2, "t"], ["top", 3, "b"]],   # the low wall of a section (below):
                    "v": [["right", 1, "l"], ["left", 1, "r"]]}},                 #   rows and columns of the frame's pieces
"specials": {"frame": "special"},                                 # painted copies of the shared special rooms (see below)
"painted": [{"name": "Terrace", "size": "1x1",                    # 1x1, 1x2 or 2x1 (never turned)
             "doors": [12, 6],                                    # door positions (DOOR_XY); their wall needs an opening in the kit,
                                                                  #   or "all": every position, a fallback room (below)
             "sections": [1, 2, 9, 17],                           # optional: section ids it can have, one per group (below)
             "decor": [{"piece": "tower", "at": [48, 16], "pair": true}],   # px on the 8 px grid; pair: the mirrored copy too
             "nature": ["Nature/trees"],                          # nature motifs: Nature/trees (one in each half of a 2x1 or
                                                                  #   1x2 room), Nature/bushes (a mirrored pair of 2x2 clumps)
             "frame": "view_left",                                # optional: a frame of "frames"
             "transforms": "None,FlipH", "props": {}}]            # transforms the game may use (default None,FlipH)
```

Gates (the rooftops' review, oct/2026): every door of the kit's `gate` walls gets the gate piece on a third tile layer, `RegionGate`, which the game paints instead of the passage when that door is the level's entrance or exit (`RegionRoom_Paint`). The gate wins over the decoration: a piece it touches is painted bare (the frame without it) on the same layer, so it goes whole; a gate that would reach into the side walls, or cover the objects of a special room, is left out (the game keeps the plain passage there).

Nature motifs (docs/design/direcao.md, "Natureza invadindo"): the pieces go in a symmetric layout off the door lanes (each door's straight way to the middle, and the middle) and the decoration, at the free spot nearest the middle of each half (trees) or a quarter of the room (bushes); a patch of grass grows around them over the floor (ellipses on a grid of 16 px cell corners, drawn by marching squares with the kit's `grass` pieces: `top` is grass in the top half of the cell, `left` in the left half, `corner` only in the bottom left corner, `inner` everywhere but the bottom left corner; the others are their mirrored and flipped copies) and must cover the pieces; tufts go on the grass, mirrored. "finds no place" means the doors leave no room: use the motif in a room with fewer or symmetric doors.

Special rooms (`specials`): every 1x1 room of the shared `Room Templates Special.json` with one floor level, no walls inside and objects that keep clear of the painted walls becomes a painted room of class `Special` (same subclass, its `Water`, `FloorObjs` and `Objs`, all twelve doors since one is in use, no transform) in the set's Special map. The game picks a level's special rooms from its set first (`RoomTemplates_PickSpecial`). The script fails if a subclass has no room that fits the frame. The rooftops keep 21 of 66 (the others have a lower floor, walls inside or objects under the top wall).

The room goes into the set's Main Upper map with `Whole` 1 and `Transforms`, its Doors, an enemy area over the floor between the walls and a treasure and a crystal spot in the middle, plus the tile layers `Region` (every door closed) and `RegionOpen` (the passages) over the region's Tiled tileset (firstgid after the object tileset, rounded up to a thousand). Refused: decoration over a passage, passages that touch, a door whose passage is not open floor from the middle of the room to the edge, a middle that is not floor. `--map` prints the room as text (`#` wall, `.` floor, `o` passage, `D` door cell); `--png <file>` draws every painted room of the set, all doors closed beside all doors open with the door cells outlined (needs Pillow), the preview to show before the game. A 2x1 room is 512x256 and goes with the 1x2 templates (`SizeIndex` 2); a painted room only fits rooms of its own size. Passages of neighbouring door positions touch, so choose door sets with no two neighbours (in a 1x1 room the 12 positions make a ring). `convert.py` turns the layers into `Region` (`docs/dev/engine-notes.md`, "Painted rooms"). Each room also gets the property `OpenOwners`, the door of every `RegionOpen` tile as runs `count*door` row by row (0 none), which `convert.py` makes `Region.own` (and drops from the properties): the game opens only a door's own tiles. A side door by the top corner gets the top wall going on over its passage to the room's edge. A special room leaves out the doors from which Link cannot walk into the room round its objects (`door_blocked`).

Fallback rooms and sections (the rooftops' third round, oct/2026, module `paint_sections.py`): `"doors": "all"` gives the room every door position (the touching passages are allowed: the layouts never use two neighbours, and the game opens a passage only inside the 64x64 box of its own opening) and the room property `Fallback` 1: the game picks it only when no other room of the set fits (`RoomTemplates_Pick`), so the set covers every door set the layouts give. `"sections"` lists the section ids the room can have (a part of the room cut off in the layout, `Section_ID`), at most one per section group (1-3-6-8 corners, 2-4-5-7 middles, 9 to 16 wide, 17 to 20 strips). The floor is seen as a 5x5 grid of bands, the door slots and the lines between them (`BANDS`); the canonical sections 1, 2, 9 and 17 are drawn on it and turned by the game's tables (`rt_tables` for 1x1 and 1x2 rooms; for 2x1 rooms `GetTransformedSectionIDReversed`, read from `__Transformations.gml`), so every id has its shape: 20 in a 1x1 room, 12 in a 1x2 one (flips only), 12 in a 2x1 one. The low wall goes on the line bands, 24 px down (3 tiles) and 16 px across (2): its rows are rows of the frame (the bottom wall's top edge over the top wall's face), its columns the inner edges of the side walls, and where it meets the frame or itself it takes the frame's corner pieces (kit `parapet`). It is written on its own tile layer per group, `RegionSection1` to `RegionSection4`, with a section group (the area, the enemies outside it, a treasure, a crystal and a pot spot in it, and a treasure and a crystal spot outside). Refused: a section without its doors, two of one group, a low wall that leaves a way between the section and the room. A 2x1 room's section ids are never mirrored by the game (`"transforms": "None"`). `python -c "import sys; sys.path.insert(0, 'tools/templates'); import paint_sections; paint_sections.selftest()"` checks the band transforms against the game's door positions.

Fitting rules (roadmap F12b-2, module `tile_rules.py`): `python tools/templates/tile_rules.py <region>` learns from the maps of `incoming/<region>/tiles/areas.json` (blocks of 16x16 by number, from `owdump.py tiles` for ALttP; any game that writes the same `tiles.json` and `areas.json` works) which blocks were seen side by side, one above the other and in each 2x2 window, and writes `tiles/rules.json` (with a hash of its sources; `--check` exits 1 when it is missing or out of date). In Python, `tile_rules.Rules(region).check(grid)` lists the misfits of a grid of block numbers (`None` cells skipped) as `(x, y, "right" | "down" | "window")`. The 2x2 window is what catches a corner with an empty edge or a wall that does not join, where each pair alone exists. Standard library only.

Automatic painting (roadmap F12b-2, module `autopaint.py`, called by `paint_auto.py` for the rooms larger than the frame): `Region(region, seeds)` reads the rules and the tile colors (`tiles.png`, by a small PNG reader) and gives each tile a material from the seed blocks (`{"floor": [[col, row]], "wall": [...]}`, cells of the area); `domains(zones, lane_mat, edge_solid)` turns a grid of zone names (`zone_grid(W, H, rects)`) into the blocks each cell may take; `solve(W, H, masks, weights, fixed, wrap, seed)` returns a grid of block numbers that keeps every rule or raises `PaintError`; `reach(grid, start)` is the walkable flood. Standard library only.

Rooms from a frame (roadmap F12b-2, module `paint_auto.py`): a kit with `"auto": {"frame": "frame.json", "seeds": {...}, "pieces": {...}}` paints every room of the set from the frame (`data/room-templates/sets/<Set>/frame.json`: the reference room `ring` whose border every room repeats every 16 blocks, `passages` per door offset, `gates` and `gate_dy`; format in the module's docstring) under the fitting rules and the approved joins of `incoming/<region>/tiles/joins.json`. Rooms larger than the frame get their inside from the solver, and a door whose passage does not fit gets a box around it painted again with the border fixed; the paintings are kept in the set's `solver_cache.json`, so the same question paints the same room. Every room is checked when it is built (closed, each door open, each gate) and refused there, never in the game. `tile_rules.check_set` (run by the validator) checks the game data again: blocks of the region, fitting windows, a border equal to the frame's and, with the doors open, equal to the frame's passages. `tile_rules.fit_text` writes `rooms/sets/<Set>/Fit.json` for the step `seams`. In the game, levels with a region tileset draw their layout again when it has a seam the frame cannot paint, and with `ExitWall` "Top" the entrance and the main exit move to the gate or to a wall with nothing behind (`Dungeon_LayoutSeamsOk`, `Dungeon_ExitToTop`, `docs/dev/engine-notes.md` "Automatic painting").

### `import/` (Python 3, Pillow, numpy)

Graphics and music of a region, from `incoming/<region>/` into the project (roadmap F6). The folder convention (file names, frames, sheets, GIFs, tileset band, music, `manifest.json`) is in `incoming/README.md`.

```
python tools/import/import_region.py <region>              # convert, write the sprites, sounds and tiles, register them, preview
python tools/import/import_region.py <region> --dry-run    # only convert and build the preview; game/ is untouched
python tools/import/import_region.py <region> --remove     # take out everything the last import of the region made
python tools/import/import_region.py --export-band Castle tileset.png   # a theme band of sTiles (1248x48), to paint over
python tools/import/make_example.py [folder]               # example region from existing assets (default tools/import/out/example)
```

| File | What it does |
|------|--------------|
| `import_region.py` | Reads `sprites/` (one file per sprite, numbered frames `_0 _1`, a sheet cut by `"frame"`, or an animated GIF), `palettes/<Name>/<n>.png`, `tileset.png`, `tiles/`, `music/*.wav` and `sounds/*.wav`. Roadmap F6b: `tileset.png` (a theme band) is pasted into `sTiles` below row 99 (rows 100, 106...; `sTiles` grows, `tile_count` follows) and named by a line in `TileBands_Init` (`__Tiles.gml`, marked `// incoming/<region>`), for `TilesBand` in the level sheet; `tiles/` becomes the tileset `ts_<Region>` over `sTileset_<Region>` (folder `Regions/<Region>/Tiles`) and `datafiles/data/tiles/<Region>.json` (included file: the class of each tile, the blocks, the animations), for `RegionTiles`, with `solid` (1 per tile whose class is not in `TILE_WALKABLE`: the walls of a painted room, roadmap F12b) and the Tiled tileset `data/room-templates/tilesets/<Region>.json` over `tiles/tiles.png` (for painted room templates); `sounds/<Name>.wav` becomes `Sound_<Name>` in `audiogroup_SFX` (folder `.../Sounds`, `volume` in the manifest). Every tileset it changes gets its texture `output_tileset.png` rewritten (the game draws from it; see `docs/dev/engine-notes.md`, "Tile bands and region tilesets"). Applies the palette rules of `docs/design/direcao.md`: 32 levels per channel (`round(round(c*31/255)*255/31)`, like the ROM extractions), hard alpha, at most 7 colors (the two closest colors merge until it fits; the outline color is kept) and an outline check (`add` or `darken` fix it). Writes the sprites with `hub/gm_assets.py` into the IDE folder `Regions/<Region>/Sprites` (sounds in `.../Music`), adds `SongIndex.<Song>` and its line in `Music_InitData` (`__Music.gml`, marked `// incoming/<region>`), and records what it made and the source hashes in `incoming/<region>/imported.json` (text sources hashed with LF line endings, so a CRLF checkout matches). Re-importing gives the same files, removes what is no longer in the folder, and never overwrites an asset that is not from that region. Palettes (roadmap F7): recolor `n` of a sprite of the family `s<Name>_*` becomes column `n` of `s<Name>_Pal`, the palette sprite of the palette shader (column 0 holds every color of the family, matched pixel by pixel against the converted base frame; a color that would become two colors is an error). A region given as a path (not under `incoming/`) works the same; its record goes into that folder |
| `compose_band.py` | `compose_band.py <region> [--preview]`: writes `incoming/<region>/tileset.png` (a theme band) from the band of a base theme and the region blocks of `tiles/`, by the recipe `incoming/<region>/band.json` (`base`, `recolor` by luminance rank, `blocks`, `tiles` (8x8 quarters), `fill`, `crenels`); every color comes from the region blocks. `--preview` writes `tools/import/out/<region>/band_preview.png` (base band over the new one). Band layout: `docs/dev/engine-notes.md` ("Composing a band") |
| `make_example.py` | Builds a region that uses every input of the convention from assets the project already has (rat with two recolors for a palette, ropa, bari, a piece of the Sanctuary, the Castle band tinted blue, 6 s of the Sanctuary song). For testing the importer: import it, check, then `--remove` it |

Output: `tools/import/out/<region>/` (ignored by git) with `frames/` (the converted PNGs), `preview.png` (each sprite before and after next to Link at the same scale, the tileset under its base band), `report.txt` and the cut `.wav` files. The validator reads `incoming/*/imported.json`: an imported asset missing from `Zelda.yyp` is an error, sources changed since the import a warning, a region never imported a note.

### `hub/` (Python 3, Pillow, numpy)

Builds the Sanctuary hub: room pictures, sprites, objects and data. Paths are relative to the repo, so run them from anywhere.

| Script | What it does |
|--------|--------------|
| `gm_assets.py` | Writes GameMaker 2024 sprites (multi frame, fps, origin), sounds (with their sample rate) and objects, and registers them in `Zelda.yyp`. Re-running a sprite keeps its frame ids, so files overwrite in place. `folder('A/B')` adds IDE folders, `remove(kind, name)` deletes a resource and unregisters it (from `Zelda.yyp` and `Zelda.resource_order`), `remove_folder` drops IDE folders nothing uses |
| `tiledjson.py` | Serializes objects the way Tiled writes `data/room-templates/*.json` |
| `gids.py` | Tiled gid of each template object type, read from `__RoomTemplates.gml` |
| `build2.py` | Shared helpers: load/save `data_d`, remove objects from the Tiled map, rebuild the room templates (`room_templates()`, calls `templates/convert.py`) |
| `build3.py` | Writes the hub rooms (Sanctuary 2x2, Hall of Fame 2x1) into the Tiled map (Other/Unique templates), rebuilds the room templates from it and writes `data_d` (Special template 5). Edit `ROOMS` to add a room or an NPC. Re-running gives the hub rooms new Tiled ids (harmless) |
| `festive_draw.py` | The Flute Boy's counter decor over `sanct_base4.png` (writes `sanct_base6.png`) |
| `build_pics.py` | Church picture with the side door (`church_base.png`) |
| `build_hall3.py` | Hall of Fame picture (`hall3_base.png`) |
| `statues.py` | Statue figures and pedestals (metal recolor of boss sprites, silhouettes) |
| `z3room.py`, `objrender.py` | Render a zelda3 room dump (BG layers, animated tiles) and OBJ tiles |
| `loopfind.py`, `envloop.py` | Find loop points in rendered SPC music |

Order for the hub pictures: `festive_draw.py`, `build_pics.py`, `build_hall3.py`, `statues.py`, then copy the PNGs into the sprites with `gm_assets.sprite(...)`. Previews go to `hub/preview/` (ignored by git).

`data_d` is a Git LFS file. Make sure the real file is checked out (`git lfs pull`) before running `build3.py`. Install the dependencies with `python -m pip install --user pillow numpy`.

### `alttp/` (C harnesses and `owdump.py`; need the zelda3 source and your own ROM)

Small harnesses compiled against [zelda3](https://github.com/snesrev/zelda3) (the C reimplementation of ALttP). They load the game's assets (`zelda3_assets.dat`, built from your ROM by zelda3's own asset script) and dump data:

| File | Dumps |
|------|-------|
| `roomdump.c` | A dungeon room: VRAM, palettes, BG1/BG2 tilemaps and tile attributes (render it with `hub/z3room.py`). `ANIMFRAME=n` copies animated tile frame n first |
| `sprdump.c` | OBJ VRAM and palettes of an overworld area, plus sprite OAM flags (for extracting NPC sprites) |
| `musicdump.c` | A song rendered to PCM through the SPC emulator (`TRACE=1` prints the song pointer); `musicdump sfx <port> <number> <seconds> <out.pcm>` renders a sound effect instead (roadmap F6b) |
| `entm.c` | The entrance to music table |

`owdump.py` (roadmap F12a) is Python, not C: it reads the overworld straight from the ROM, so it needs no compiler. It imports zelda3's own `assets/util.py` (ROM loading, decompression) and `assets/tables.py` (area, sprite, music and secret names), uses the ROM addresses of zelda3's `assets/extract_resources.py` and `compile_resources.py`, and parses three small tables from `src/load_gfx.c` (`kMainTilesets`, `kAuxTilesets`, `kOwBgPalInfo`). It looks for zelda3 in `$ZELDA3_DIR` or in the `zelda3` folder next to the repository (`--zelda3` to change), and for the ROM at `<zelda3>/zelda3.sfc` (`--rom`). Rendering needs Pillow; the rest uses only the standard library.

```bash
python tools/alttp/owdump.py areas                    # one line per area: size, music per story stage, entrances, holes, secrets, enemies per stage
python tools/alttp/owdump.py area 0x2c                # one area: header, entrances, exits, secrets, sprites, attribute map as text
python tools/alttp/owdump.py edges                    # openings between neighbouring areas (offset+width px, walk or swim)
python tools/alttp/owdump.py stats                    # composition per area: distinct map16/map32, % of each tile class, bush groups
python tools/alttp/owdump.py png 0x2c 0x1b --scale 0.5
python tools/alttp/owdump.py world --scale 0.25       # the whole light world (--world dark)
python tools/alttp/owdump.py vocab --top 64           # the most used map32 blocks, drawn
python tools/alttp/owdump.py tiles 0x1b --region topo-do-castelo   # the area's blocks as a region tileset (F6b), plus tiles/extra.json
```

`tiles` (roadmap F6b) cuts the map16 blocks of the areas into `incoming/<region>/tiles/tiles.png` (8x8 tiles already colored, 32 per row, tile 0 empty; a tile is kept once, its mirrored and flipped copies point to it) and `tiles.json` (`attributes`: the ROM attribute of each tile, `classes`: attribute to class, the short names `floor`, `solid`, `slope`, `deep_water`, `ledge_s`... of the attribute table above; `blocks`: one per distinct map16 of each area, `{"area", "map16", "tiles": [[tile, flags] x 4]}`, flags 1 mirrored, 2 flipped; `animated`: empty for now). Run again with more areas and the old tiles and blocks keep their numbers (the new ones come after), so whatever paints with them stays right; `--fresh` starts over, `--transparent` makes color 0 transparent instead of the area's backdrop. The blocks are drawn in order in `out/tiles_<region>_blocks.png`, and `tiles/areas.json` keeps each area as rows of block numbers (the source of the painted rooms' pieces, `templates/paint_rooms.py`, so they need no ROM). `import_region.py` makes the folder a tileset.

`incoming/<region>/tiles/extra.json` (optional, read by `tiles`) adds blocks that are not in the areas: `"map16": {"<Name>": {"area": "0x1B", "map16": ["0xdb6", ...]}}` draws those map16 numbers with the area's graphics (the frames of a door animation; tiles.json `named` lists their blocks, and the game reads them as `named` in `data/tiles/<Region>.json`), and `"recolor": {"<name>": {"area", "from": [[r, g, b], ...], "to": [r, g, b], "cells": [[col, row], ...]}}` copies area cells with those colors swapped (grass edges over dirt become grass edges over the region's floor). The new blocks go after the old ones, so every index already used keeps its meaning.

`build.py` compiles a harness with whatever C compiler there is (gcc, clang, or the clang inside the `ziglang` Python package: `python -m pip install --user ziglang`, no installer), into `tools/alttp/out/<name>.exe`; it rebuilds only when a source is newer. It leaves out zelda3's `src/main.c`, `config.c`, `opengl.c` and `glsl_shader.c` (SDL, OpenGL, config reader) and `stub/` stands in for what they and opus give. The harnesses read `zelda3_assets.dat` in the zelda3 folder: make it once with zelda3's `python assets/restool.py --extract-from-rom` (needs PyYAML).

`sfx.py` (roadmap F6b) takes a sound effect out of the ROM as a `.wav`: it builds `musicdump`, renders the effect, cuts the silence and writes 16-bit mono 22050 Hz (like the game's effects; `--rate`, `--stereo`). An ambient loop (port 1) is cut at `--seconds`.

```bash
python tools/alttp/build.py musicdump                                          # tools/alttp/out/musicdump.exe
python tools/alttp/sfx.py 2 0x36 incoming/topo-do-castelo/sounds/Thunder.wav   # the thunder of the rain (1.69 s)
python tools/alttp/sfx.py 1 0x01 out.wav --seconds 4                           # the rain, an ambient loop
```

Ports: 1 the ambient sounds (`sound_effect_ambient` in zelda3's source), 2 `sound_effect_1`, 3 `sound_effect_2`; the number is the one the source writes (`OverworldOverlay_HandleRain`: `sound_effect_1 = 54`).

Images go to `tools/alttp/out/` (ignored by git). How it reads an area, from zelda3: each 512x512 screen is 16x16 map32 indices, decompressed from two streams (high and low bytes, `0x82F94D` and `0x82FB2D`); a map32 is four map16 (`0x838000`, `0x83B400`, `0x848000`, `0x84B400`, 6 bytes per four map32); a map16 is four 8x8 tiles (`0x8F8000`, top left, top right, bottom left, bottom right); the tile attribute comes from the tile number (`0x8E9459`). Graphics: main tileset 0x20 (light world) or 0x21 (dark), with the area's aux tileset over slots 3 to 6; 3bpp packs expanded to 4bpp, the "high" slots adding 8 to every non zero pixel. Palette: `Overworld_LoadPalettes` with the area's palette index; `-1` in `kOwBgPalInfo` means "keep the previous one", rendered with the game's defaults. Not drawn: animated water, overlays (fog, clouds, rain), event changes (opened doors, the pyramid hole).

Build them with `build.py` (above), which compiles the file together with zelda3's `src/*.c` and `snes/*.c` like zelda3's own `main.c`.

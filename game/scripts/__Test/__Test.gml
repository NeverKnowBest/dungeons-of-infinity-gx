// Automated test mode (roadmap F3), driven by tools/test/run.py.
// Off unless the game is started with "-test <file>" or with the environment variable DOI_TEST=<file>, where <file>
// is a scenario in the save folder (%LOCALAPPDATA%\Zelda). In test mode the title and menus are skipped, nothing is
// saved, Link follows the scenario's steps, everything worth knowing goes to test/out/log.txt (and to the run output
// as "[Test] ...") and the game closes itself. The scenario format is in tools/README.md ("test/").

#macro TEST_OUT "test/out/"
#macro TEST_SHEET_WAIT 3	// frames to wait after moving the camera before capturing a contact sheet shot

global.TestMode = false;
global.Test = undefined;
global.TestFrame = 0;
global.TestKills = 0;
global.TestDumps = 0;		// level dumps written so far (scenario "dump": true)
global.TestDumpFile = "";
global.TestBuildSeed = 0;
global.TestExitDest = -1;	// level the exit of the last "exit" step leads to (expect "exit_level")

// Verbs a scenario may hold or press (see __input_config_verbs)
global.TestVerbs = ["up", "down", "left", "right", "sword", "action", "item", "map", "strafe", "inventory", "menu_access", "hud"];

/// Called from oInit's Create. Returns true when the game runs in test mode.
function Test_Init(){
	var _File = "";
	for(var i = 0; i < parameter_count() - 1; i++){
		if(parameter_string(i) == "-test") _File = parameter_string(i + 1);
	}
	if(_File == "") _File = environment_get_variable("DOI_TEST");
	if(_File == "") return false;

	global.TestMode = true;
	directory_create("test");
	directory_create(TEST_OUT);
	if(file_exists(TEST_OUT + "log.txt")) file_delete(TEST_OUT + "log.txt");
	exception_unhandled_handler(Test_OnCrash);

	var _Scenario = undefined;
	if(file_exists(_File)){
		var _Buffer = buffer_load(_File);
		try{
			_Scenario = json_parse(buffer_read(_Buffer, buffer_string));
		}catch(_e){
			_Scenario = undefined;
		}
		buffer_delete(_Buffer);
	}

	global.Test = {
		Name: "?",
		Seed: 1,
		Level: DungeonLevel.Castle,
		Cheats: [],
		Items: [],
		Steps: [],
		MaxFrames: 36000,
		Sound: false,
		Speed: 60,
		Dump: false,
		Levels: [],
		Failures: 0,
		Finished: false
	};

	if(!is_struct(_Scenario)){
		Test_Log("error scenario missing or not valid JSON: " + _File);
		Test_Finish("error");
		return true;
	}

	global.Test.Name = _Scenario[$ "name"] ?? "test";
	global.Test.Seed = _Scenario[$ "seed"] ?? 1;
	global.Test.Level = _Scenario[$ "level"] ?? DungeonLevel.Castle;
	global.Test.Cheats = _Scenario[$ "cheats"] ?? [];
	global.Test.Items = _Scenario[$ "items"] ?? [];
	global.Test.Steps = _Scenario[$ "steps"] ?? [];
	global.Test.MaxFrames = _Scenario[$ "max_frames"] ?? 36000;
	global.Test.Sound = _Scenario[$ "sound"] ?? false;
	global.Test.Speed = _Scenario[$ "speed"] ?? 60;
	global.Test.Dump = _Scenario[$ "dump"] ?? false;
	global.Test.Levels = _Scenario[$ "levels"] ?? [];

	// Windowed, and no pause or mute when the window loses focus (the input library is told the same in
	// INPUT_ALLOW_OUT_OF_FOCUS), so a test keeps running while someone uses the PC
	global.Fullscreen = false;
	global.AltTabPause = false;
	game_set_speed(global.Test.Speed, gamespeed_fps);

	instance_create_depth(-10000, -10000, 0, oTest);
	return true;
}

/// Called from oInit instead of going to the title screen: a throwaway user (never saved) and straight to the level
function Test_Begin(){
	global.Users = [new User_Create()];
	global.UserIndex = 0;
	User_VerifyIntegrity();

	var _User = global.Users[0];
	_User.Name = "TEST";
	for(var i = 0; i < array_length(global.Test.Cheats); i++){
		var _Key = global.Test.Cheats[i];
		if(variable_struct_exists(_User.Cheats, _Key)){
			_User.Cheats[$ _Key] = true;
		}else{
			Test_Fail("unknown cheat " + string(_Key));
		}
	}

	global.ChallengeOptions = array_create(array_length(global.ChallengeOptionInfo), 0);
	global.Challenges = array_create(array_length(global.ChallengeInfo), false);

	if(!global.Test.Sound) audio_set_master_gain(0, 0);
	
	// A ghost player takes input only from input_verb_set (the steps), never from the real keyboard or gamepad.
	// Without it the player has no source until someone presses a key, and then its verbs are not updated at all.
	input_player_ghost_set(true);

	if(is_string(global.Test.Level) && global.Test.Level == "Hub") global.HubPending = true;
	
	Test_ChangeLevels();

	Test_Log("start scenario=" + string(global.Test.Name) + " seed=" + string(global.Test.Seed) + " level=" + string(global.Test.Level));
	random_set_seed(global.Test.Seed);
	DungeonSeq_Init(global.UserIndex);
	room_goto(Room_Dungeon);
}

/// Scenario "levels": temporary changes to the level sheet for this test only, such as a branch of the run that no
/// level has yet (roadmap F4b). Each entry is {level, <field>: value, ...}; tools/test/scenario.py checks the fields.
function Test_ChangeLevels(){
	for(var i = 0; i < array_length(global.Test.Levels); i++){
		var _Change = global.Test.Levels[i];
		var _Def = Level_Get(_Change[$ "level"] ?? -1);
		if(_Def == undefined){
			Test_Fail("levels: bad level " + string(_Change[$ "level"]));
			continue;
		}
		var _Names = variable_struct_get_names(_Change);
		array_sort(_Names, true);
		for(var j = 0; j < array_length(_Names); j++){
			var _Field = _Names[j];
			if(_Field == "level") continue;
			if(!variable_struct_exists(_Def, _Field)){
				Test_Fail("levels: no field " + _Field);
				continue;
			}
			_Def[$ _Field] = _Change[$ _Field];
			Test_Log("levels " + string(_Def.Index) + " \"" + _Def.Name + "\" " + _Field + "=" + json_stringify(_Change[$ _Field]));
		}
	}
}

/// Called from oGame's Create in place of the intro level
function Test_StartLevel(){
	if(!is_real(global.Test.Level) || global.Test.Level < 0 || global.Test.Level >= array_length(global.LevelDefs)){
		Test_Fail("bad level " + string(global.Test.Level));
		global.Test.Level = DungeonLevel.Castle;
	}
	Test_BuildLevel(global.Test.Level, global.Test.Seed);
}

/// Builds a level that depends only on the seed: the user's dungeon layout order (normally shuffled once per new
/// user and then followed run after run) is shuffled again from the seed
function Test_BuildLevel(_Level, _Seed){
	random_set_seed(_Seed);
	DungeonSeq_Init(global.UserIndex);
	global.SaveLevel = false;
	global.TestBuildSeed = _Seed;
	Dungeon_InitLevel(_Level);
	Test_DumpGlobals();
}

#region Log

function Test_Log(_Text){
	var _Line = "f" + string(global.TestFrame) + " " + _Text;
	show_debug_message("[Test] " + _Line);
	var _File = file_text_open_append(TEST_OUT + "log.txt");
	if(_File == -1) exit;
	file_text_write_string(_File, _Line);
	file_text_writeln(_File);
	file_text_close(_File);
}

/// Logs only in test mode; for hooks in the game code
function Test_Event(_Text){
	if(global.TestMode) Test_Log(_Text);
}

function Test_Fail(_Text){
	global.Test.Failures++;
	Test_Log("FAIL " + _Text);
}

/// Called from Enemy_Destroy
function Test_OnKill(){
	if(!global.TestMode) exit;
	global.TestKills++;
	Test_Log("kill " + object_get_name(object_index) + " room=" + string(global.CurrentRoomIndex));
}

function Test_OnCrash(_Exception){
	Test_Log("crash " + string_replace_all(string(_Exception.message), "\n", " | "));
	if(is_array(_Exception.stacktrace)){
		for(var i = 0; i < array_length(_Exception.stacktrace); i++) Test_Log("  at " + string(_Exception.stacktrace[i]));
	}
	Test_Log("end crash");
	return 0;
}

function Test_Finish(_Result){
	if(global.Test.Finished) exit;
	global.Test.Finished = true;
	Test_Log("end " + _Result + " failures=" + string(global.Test.Failures) + " kills=" + string(global.TestKills));
	game_end();
}

function Test_LevelName(){
	if(global.HubLevel) return "hub";
	return string(global.Level.Index) + " \"" + LevelDef.Name + "\"";
}

function Test_RoomStr(_RoomIndex){
	var _R = global.Level.Rooms[_RoomIndex];
	var _Template = _R[$ "Template"];
	var _Id = is_struct(_Template) ? _Template[$ "id"] : undefined;
	return string(_RoomIndex) + " grid=" + string(_R.GridX) + "," + string(_R.GridY) + " size=" + string(_R.GridW) + "x" + string(_R.GridH)
		+ " template=" + string(_R.TemplateClass) + "/" + string(_R.TemplateSubClass) + "/" + string(_R.TemplateName) + "#" + string(_Id)
		+ (is_struct(_Template) && _Template[$ "RoomSet"] != undefined ? " set=" + _Template.RoomSet : "");
}

/// Rooms of the level built from templates of its room set (roadmap F11)
function Test_SetRooms(){
	var _N = 0;
	for(var i = 0; i < global.Level.RoomCount; i++){
		var _Template = global.Level.Rooms[i][$ "Template"];
		if(is_struct(_Template) && _Template[$ "RoomSet"] != undefined) _N++;
	}
	return _N;
}

function Test_LogState(){
	Test_Log("state level=" + Test_LevelName() + " room=" + string(global.CurrentRoomIndex) + " x=" + string(round(oLink.x)) + " y=" + string(round(oLink.y))
		+ " hp=" + string(LinkHealth) + "/" + string(global.Inventory.ItemData[ItemClass.HeartPiece].Amount)
		+ " enemies=" + string(instance_number(oEnemy)) + " kills=" + string(global.TestKills) + " linkstate=" + string(oLink.State));
}

/// One "trace" line per enemy that exists: position, state, direction, sprite, speed and energy (step "trace")
function Test_LogEnemies(_Frame){
	var _Link = "link=" + string(oLink.x) + "," + string(oLink.y);
	with(oEnemy){
		Test_Log("trace " + string(_Frame) + " " + object_get_name(object_index) + " x=" + string(x) + " y=" + string(y) + " z=" + string(z)
			+ " state=" + string(State) + " dir=" + string(Dir) + " sprite=" + (sprite_index == -1 ? "-" : sprite_get_name(sprite_index)) + " image=" + string(image_index)
			+ " vx=" + string(vx) + " vy=" + string(vy) + " energy=" + string(Energy) + " alarm0=" + string(alarm[0]) + " " + _Link);
	}
}

#endregion

#region Debug cheats (also usable outside tests)

/// Moves Link into the room at grid (_GridX, _GridY) of the current level, next to one of its doors
function Test_GotoRoom(_GridX, _GridY){
	if(_GridX < 0 || _GridY < 0 || _GridX >= DungeonGridW || _GridY >= DungeonGridW) return false;
	var _RoomIndex = global.Level.Map_RoomIndex[_GridY][_GridX];
	if(_RoomIndex == -1) return false;

	Test_PlaceLink(_RoomIndex, Test_RoomEntryPoint(_RoomIndex));
	return true;
}

/// Moves Link to _Pos [x, y] in a room of the current level and points the camera at it
function Test_PlaceLink(_RoomIndex, _Pos){
	with(oLink){
		x = _Pos[0];
		y = _Pos[1];
		HitBox.x = x;
		HitBox.y = y;
		FloorLevel = GetFloorLevelID(x, y);
		layer = (FloorLevel == UPPER ? global.LayerID_Objs_Upper : global.LayerID_Objs_Lower);
		FallSpawnX = x;
		FallSpawnY = y;
		FallSpawnFloorLevel = FloorLevel;
		FallSpawnFacing = Facing;
		UpdateState(LinkState.Standing);
	}
	//SetToRoomIndex activates the new room and then deactivates the current one: for the same room that would put
	//Link and everything else to sleep
	if(_RoomIndex != global.CurrentRoomIndex) with(oCamera) SetToRoomIndex(_RoomIndex, true);
	global.Level.Rooms[_RoomIndex].Visited = true;
	Map_UpdateExploredRooms();
	global.InWaterSprite = Link_GetInWaterSprite();
}

/// Puts Link at the mouth of the passage of door _Door of room _RoomIndex (a room struct's door), _In px inside; where
/// that is a wall (the face of the top wall over a side door by the corner, a lamp tower's foot, a chest under the
/// door of a special room, the low wall of a section) the first free spot of 16 to 56 px inside, and for a side door
/// 4 to 16 px lower (steps passall and bomb, R1 seventh round)
function Test_PlaceAtPassage(_RoomIndex, _Door, _In){
	var _R = global.Level.Rooms[_RoomIndex];
	var _DX = (_Door.Location == "Left") ? 1 : ((_Door.Location == "Right") ? -1 : 0);
	var _DY = (_Door.Location == "Top") ? 1 : ((_Door.Location == "Bottom") ? -1 : 0);
	var _Ins = [_In, 16, 32, 40, 48, 56];
	for(var i = 0; i < array_length(_Ins); i++){
		for(var _Low = 0; _Low <= (_DX != 0 ? 16 : 0); _Low += 4){
			Test_PlaceLink(_RoomIndex, [_R.x + _Door.x + 16 + _DX * _Ins[i], _R.y + _Door.y + 16 + _DY * _Ins[i] + _Low]);
			if(!Test_LinkInWall()) return;
		}
	}
}

/// True when Link stands in a wall (an oWall that blocks him). Every wall under him counts: instance_place gives one,
/// and an open door's blocker (BlockLink false) over a painted wall hid the wall (R1 seventh round)
function Test_LinkInWall(){
	var _In = false;
	with(oLink){
		var _List = ds_list_create();
		var _N = instance_place_list(x, y, oWall, _List, false);
		for(var i = 0; i < _N && !_In; i++) _In = _List[| i].BlockLink;
		ds_list_destroy(_List);
	}
	return _In;
}

/// The way from the middle of room _Room (a room struct) to where Link stands (the mouth of a passage, step walkall):
/// every spot 8 px apart from him where he fits between the walls (no oWall that blocks him under his mask, and no
/// item), searched breadth first; the path from the spot nearest the middle of the room to him, start first, as [x, y]
/// pairs
function Test_WalkFromMiddle(_Room){
	var _MX = oLink.x, _MY = oLink.y;
	var _I0 = -((_MX - _Room.x - 8) div 8), _J0 = -((_MY - _Room.y - 8) div 8);
	var _GW = (_Room.x + _Room.width - 8 - _MX) div 8 - _I0 + 1, _GH = (_Room.y + _Room.height - 8 - _MY) div 8 - _J0 + 1;
	var _From = array_create(_GW * _GH, -2);	// -2 not reached, -1 the mouth, else the node it was reached from
	var _Root = -_J0 * _GW - _I0;
	_From[_Root] = -1;
	var _Todo = [_Root], _Head = 0;
	var _CX = _Room.x + _Room.width / 2, _CY = _Room.y + _Room.height / 2;
	var _Best = _Root, _BestD = point_distance(_MX, _MY, _CX, _CY);
	var _List = ds_list_create();
	while(_Head < array_length(_Todo)){
		var _K = _Todo[_Head++];
		var _I = _K mod _GW, _J = _K div _GW;
		var _Steps = [[1, 0], [-1, 0], [0, 1], [0, -1]];
		for(var s = 0; s < 4; s++){
			var _NI = _I + _Steps[s][0], _NJ = _J + _Steps[s][1];
			if(_NI < 0 || _NJ < 0 || _NI >= _GW || _NJ >= _GH) continue;
			var _N = _NJ * _GW + _NI;
			if(_From[_N] != -2) continue;
			var _X = _MX + (_NI + _I0) * 8, _Y = _MY + (_NJ + _J0) * 8;
			var _Free = true;
			ds_list_clear(_List);
			with(oLink){
				var _Hits = instance_place_list(_X, _Y, oWall, _List, false);
				for(var h = 0; h < _Hits && _Free; h++) _Free = !_List[| h].BlockLink;
				//nor over an item: the gem of a gem room stops him with its text box
				if(_Free && instance_place(_X, _Y, oItem) != noone) _Free = false;
			}
			if(!_Free){
				_From[_N] = -3;
				continue;
			}
			_From[_N] = _K;
			array_push(_Todo, _N);
			var _D = point_distance(_X, _Y, _CX, _CY);
			if(_D < _BestD){
				_Best = _N;
				_BestD = _D;
			}
		}
	}
	ds_list_destroy(_List);
	var _Path = [];
	for(var _K = _Best; _K >= 0; _K = _From[_K]) array_push(_Path, [_MX + (_K mod _GW + _I0) * 8, _MY + (_K div _GW + _J0) * 8]);
	return _Path;
}

/// The block of the 16x16 cell (_BX, _BY) of a painted room, from its tiles as painted (RegionGrid, doors in use
/// open): its number in the set's Fit.json quads, or -1
function Test_SeamBlock(_Quads, _RoomIndex, _BX, _BY){
	var _G = global.Level.Rooms[_RoomIndex].RegionGrid;
	var _Key = "";
	for(var t = 0; t < 4; t++){
		var _V = _G.Tiles[(_BY * 2 + (t div 2)) * _G.W + _BX * 2 + (t mod 2)];
		_Key += (t == 0 ? "" : ",") + string(_V & 0xFFFF) + ":" + string(_V >> 16);
	}
	return _Quads[$ _Key] ?? -1;
}

/// Every seam between two neighbouring painted rooms of the level (roadmap F12b-2): each 2x2 window of blocks across
/// the edge (one column or row of each room, two blocks along it) must be on the region's maps or an approved join
/// (rooms/sets/<Set>/Fit.json, tools/templates/tile_rules.py). Windows where four rooms meet are skipped: the screen
/// never shows four rooms at once. Logs "seams pairs=N windows=N misfits=N" and fails on a misfit.
function Test_CheckSeams(){
	var _Buffer = buffer_load(GAMEDIR_ROOMTEMPLATES + "sets\\" + LevelDef.RoomSet + "\\Fit.json");
	if(_Buffer == -1){
		Test_Fail("seams: the level's room set has no Fit.json");
		return;
	}
	var _Fit = json_parse(buffer_read(_Buffer, buffer_string));
	buffer_delete(_Buffer);
	var _Ok = {};
	for(var i = 0; i < array_length(_Fit.fit); i++) _Ok[$ _Fit.fit[i]] = true;
	var _M = global.Level.Map_RoomIndex;
	var _Pairs = 0, _Windows = 0, _Bad = 0, _First = "";
	for(var _GY = 0; _GY < array_length(_M); _GY++){
		for(var _GX = 0; _GX < array_length(_M[_GY]); _GX++){
			var _A = _M[_GY][_GX];
			if(_A < 0 || !RegionRoom_Is(_A)) continue;
			var _RA = global.Level.Rooms[_A];
			for(var _Dir = 0; _Dir < 2; _Dir++){	// 0: the room to the right, 1: the room below
				var _NX = _GX + (_Dir == 0), _NY = _GY + (_Dir == 1);
				if(_NY >= array_length(_M) || _NX >= array_length(_M[_NY])) continue;
				var _B = _M[_NY][_NX];
				if(_B < 0 || _B == _A || !RegionRoom_Is(_B)) continue;
				var _RB = global.Level.Rooms[_B];
				_Pairs++;
				// the 16 blocks of this grid cell along the edge, the window from each to the next
				for(var k = 0; k < 16; k++){
					var _Cells = [];	// [room, block x, block y] top left, top right, bottom left, bottom right
					for(var q = 0; q < 2; q++){
						var _Along = k + q;
						var _CellA = (_Dir == 0) ? [_GX, _GY + (_Along div 16)] : [_GX + (_Along div 16), _GY];
						var _CellB = (_Dir == 0) ? [_NX, _NY + (_Along div 16)] : [_NX + (_Along div 16), _NY];
						if(_CellA[1] >= array_length(_M) || _CellA[0] >= array_length(_M[_CellA[1]]) || _CellB[1] >= array_length(_M) || _CellB[0] >= array_length(_M[_CellB[1]])) break;
						if(_M[_CellA[1]][_CellA[0]] != _A || _M[_CellB[1]][_CellB[0]] != _B) break;	// four rooms meet
						var _AX = (_CellA[0] - _RA.GridX) * 16, _AY = (_CellA[1] - _RA.GridY) * 16;
						var _BXo = (_CellB[0] - _RB.GridX) * 16, _BYo = (_CellB[1] - _RB.GridY) * 16;
						var _L = _Along mod 16;
						if(_Dir == 0){
							array_push(_Cells, [_A, _AX + 15, _AY + _L], [_B, _BXo, _BYo + _L]);
						}else{
							array_push(_Cells, [_A, _AX + _L, _AY + 15], [_B, _BXo + _L, _BYo]);
						}
					}
					if(array_length(_Cells) < 4) continue;
					// window order: top left, top right, bottom left, bottom right
					var _W = (_Dir == 0) ? [_Cells[0], _Cells[1], _Cells[2], _Cells[3]] : [_Cells[0], _Cells[2], _Cells[1], _Cells[3]];
					var _Key = "";
					for(var t = 0; t < 4; t++) _Key += (t == 0 ? "" : ",") + string(Test_SeamBlock(_Fit.quads, _W[t][0], _W[t][1], _W[t][2]));
					_Windows++;
					if(!(_Ok[$ _Key] ?? false)){
						_Bad++;
						if(_First == "") _First = " first=rooms " + string(_A) + "/" + string(_B) + " (" + string(_RA.TemplateName) + "/" + string(_RB.TemplateName) + ") at " + string(_W[0][1]) + "," + string(_W[0][2]) + " blocks " + _Key;
						if(_Bad == 1){	// both rooms' blocks along the edge, for finding which of them is off
							var _RowA = "", _RowB = "";
							for(var _I = 0; _I < 16; _I++){
								var _LA = (_Dir == 0) ? [_W[0][1], _W[0][2] - (_W[0][2] mod 16) + _I] : [_W[0][1] - (_W[0][1] mod 16) + _I, _W[0][2]];
								var _LB = (_Dir == 0) ? [_W[1][1], _W[1][2] - (_W[1][2] mod 16) + _I] : [_W[2][1] - (_W[2][1] mod 16) + _I, _W[2][2]];
								_RowA += " " + string(Test_SeamBlock(_Fit.quads, _A, _LA[0], _LA[1]));
								_RowB += " " + string(Test_SeamBlock(_Fit.quads, _B, _LB[0], _LB[1]));
							}
							Test_Log("seams edge A:" + _RowA + " B:" + _RowB);
							var _DS = "";
							for(var _I = 0; _I < array_length(_RA.Doors); _I++) _DS += " A" + _RA.Doors[_I].Location + "@" + string(_RA.Doors[_I].x) + "," + string(_RA.Doors[_I].y) + "=" + string(_RA.Doors[_I].Status);
							for(var _I = 0; _I < array_length(_RB.Doors); _I++) _DS += " B" + _RB.Doors[_I].Location + "@" + string(_RB.Doors[_I].x) + "," + string(_RB.Doors[_I].y) + "=" + string(_RB.Doors[_I].Status);
							Test_Log("seams doors" + _DS);
						}
					}
				}
			}
		}
	}
	Test_Log("seams pairs=" + string(_Pairs) + " windows=" + string(_Windows) + " misfits=" + string(_Bad) + _First);
	if(_Bad > 0) Test_Fail("seams misfits=" + string(_Bad));
}

/// Checks a painted room (roadmap F12b): every 8x8 cell of a solid tile is in one of the room's walls and no other is
function Test_CheckPainted(_RoomIndex){
	var _R = global.Level.Rooms[_RoomIndex];
	var _G = _R.RegionGrid;
	var _Solid = RegionTiles_Get(LevelDef.RegionTiles).solid;
	var _Walls = [];
	with(oWall) if(variable_instance_exists(id, "RegionRoom") && RegionRoom == _RoomIndex) array_push(_Walls, id);
	var _Tiles = 0, _SolidCells = 0, _Bad = 0, _BadWall = 0, _First = "";
	for(var k = 0; k < _G.W * _G.H; k++){
		var _T = _G.Tiles[k];
		if(_T != 0) _Tiles++;
		var _IsSolid = (_T != 0 && _Solid[_T & 0xFFFF] == 1);
		if(_IsSolid) _SolidCells++;
		//a wall: a solid tile, or a walkable one on the room's outermost 8 px off its door lanes (RegionRoom_OffLane),
		//but not the column under an open top gate (RegionRoom_SolidAt)
		var _Want = RegionRoom_SolidAt(_G, _Solid, k mod _G.W, k div _G.W);
		var _PX = _R.x + (k mod _G.W) * 8 + 4;
		var _PY = _R.y + (k div _G.W) * 8 + 4;
		var _InWall = false;
		for(var w = 0; w < array_length(_Walls) && !_InWall; w++){
			var _I = _Walls[w];
			_InWall = (_PX >= _I.x && _PX < _I.x + _I.sprite_width && _PY >= _I.y && _PY < _I.y + _I.sprite_height);
		}
		if(_InWall != _Want){
			_Bad++;
			if(_InWall) _BadWall++;
			if(_First == "") _First = " first=" + string(k mod _G.W) + "," + string(k div _G.W) + (_InWall ? " (a wall on a walkable tile)" : " (a solid tile with no wall)");
		}
	}
	var _Passages = 0;
	for(var d = 0; d < array_length(_R.Doors); d++) if(_R.Doors[d].Status != DoorStatus.Unused && _R.Doors[d].Status != DoorStatus.Secret_Closed) _Passages++;
	Test_Log("painted room=" + string(_RoomIndex) + " template=" + string(_R.TemplateName) + " transform=" + TransformationStr(_R.Template[$ "Transform"] ?? 0)
		+ " tiles=" + string(_Tiles) + "/" + string(_G.W * _G.H) + " solid=" + string(_SolidCells) + " walls=" + string(array_length(_Walls))
		+ " passages=" + string(_Passages) + " mismatch=" + string(_Bad) + (_Bad > 0 ? " walls_on_floor=" + string(_BadWall) : "") + _First);
	if(_Bad > 0) Test_Fail("painted room " + string(_RoomIndex) + ": " + string(_Bad) + " cells where the walls do not match the tiles");
	if(array_length(_Walls) != array_length(_G.Walls)) Test_Fail("painted room " + string(_RoomIndex) + ": " + string(array_length(_Walls)) + " walls, " + string(array_length(_G.Walls)) + " made last (old walls left over)");
}

/// Paints a grid of blocks of the level's region tileset turned by a room transform, like RegionRoom_Paint turns a room
function Test_PaintTransformed(_Blocks, _X, _Y, _BW, _BH, _Transform){
	var _Tiles = RegionTiles_Get(LevelDef.RegionTiles);
	var _PR = global.Level.Rooms[global.CurrentRoomIndex];
	var _TM = RegionTiles_Tilemap(UPPER);
	var _W = _BW * 2, _H = _BH * 2;
	for(var j = 0; j < _H; j++){
		for(var i = 0; i < _W; i++){
			var _Data = _Tiles.blocks[_Blocks[((j div 2) * _BW + (i div 2)) mod array_length(_Blocks)]][(j mod 2) * 2 + (i mod 2)];
			var _Value = tile_get_index(_Data) | (((tile_get_mirror(_Data) ? 1 : 0) | (tile_get_flip(_Data) ? 2 : 0)) << 16);
			var _Cell = RegionTiles_TransformCell(i, j, _W, _H, _Transform);
			var _New = (_Value & 0xFFFF) | (RegionTiles_TransformFlags(_Value >> 16, _Transform) << 16);
			tilemap_set_at_pixel(_TM, RegionTiles_TileData(_New), _PR.x + _X + _Cell[0] * 8, _PR.y + _Y + _Cell[1] * 8);
		}
	}
	Test_Log("paint transform=" + TransformationStr(_Transform) + " blocks=" + string(_BW * _BH));
}

/// Moves Link into the room of the main exit (_Extra false) or of the extra exit (roadmap F4b), 40 px in front of the
/// exit door. Returns the verb that walks into it ("up" or "down"), or "" when the level has no such exit.
function Test_GotoExit(_Extra){
	var _Exits = global.Level.Exits;
	var _RoomIndex = _Extra ? _Exits.ExtraRoom : global.Level.RoomIndex_BossAdjacent;
	if(_RoomIndex == -1) return "";
	var _R = global.Level.Rooms[_RoomIndex];
	for(var i = 0; i < array_length(_R.Doors); i++){
		var _Door = _R.Doors[i];
		if(_Door.Status != DoorStatus.Exit || (_Door.Location != "Top" && _Door.Location != "Bottom") || (_Extra && _Door.Position != _Exits.ExtraPosition)) continue;
		var _Top = (_Door.Location == "Top");
		//below a gate's doorway (solid until he pushes it; GateDY under the door cell, 64 px in the rooms painted from a frame)
		var _Front = (_Top && RegionGate_Get(_RoomIndex, _Door.x, _Door.y) != undefined) ? _R.RegionGrid.GateDY + 48 : 40;
		Test_PlaceLink(_RoomIndex, [_R.x + _Door.x + 16, _R.y + _Door.y + 16 + (_Top ? _Front : -40)]);
		global.TestExitDest = _Extra ? _Door.ExitDest : (global.SaveLevel ? Level_NextIndex() : _Exits.Dest);
		Test_Log("exit " + (_Extra ? "extra" : "main") + " room=" + string(_RoomIndex) + " " + _Door.Location + " -> level " + string(global.TestExitDest));
		return _Top ? "up" : "down";
	}
	return "";
}

/// A spot just inside one of the room's doors: [x, y]
function Test_RoomEntryPoint(_RoomIndex){
	var _R = global.Level.Rooms[_RoomIndex];
	var _RSI = global.RoomSizeIndex[_R.GridW][_R.GridH];
	for(var i = 0; i < array_length(_R.Doors); i++){
		var _Door = _R.Doors[i];
		if(_Door.Status == DoorStatus.Unused) continue;
		var _Coord = global.DoorCoordinates[_RSI][_Door.Position];
		var _X = _R.x + _Coord.x + 16;
		var _Y = _R.y + _Coord.y + 16;
		switch(_Coord.Location){
			case "Top":		_Y += 32; break;
			case "Bottom":	_Y -= 32; break;
			case "Left":	_X += 32; break;
			case "Right":	_X -= 32; break;
		}
		return [_X, _Y];
	}
	return [_R.x + _R.width / 2, _R.y + _R.height / 2];
}

/// Creates an enemy (object name) _Dist pixels in front of Link. Returns the instance or noone.
function Test_SpawnEnemy(_ObjName, _Dist = 48){
	var _Obj = asset_get_index(_ObjName);
	if(_Obj == -1 || !object_exists(_Obj)) return noone;
	var _DX = 0;
	var _DY = 0;
	switch(oLink.Facing){
		case UP:	_DY = -1; break;
		case DOWN:	_DY = 1; break;
		case LEFT:	_DX = -1; break;
		case RIGHT:	_DX = 1; break;
	}
	var _RoomIndex = global.CurrentRoomIndex;
	return instance_create_layer(oLink.x + _DX * _Dist, oLink.y + _DY * _Dist, "Objs_" + GetFloorLevelString(oLink.FloorLevel), _Obj,
		{FloorLevel: oLink.FloorLevel, ItemHolding: -1, SectionID: global.Level.Rooms[_RoomIndex].Section_ID, RoomIndex: _RoomIndex});
}

/// Gives Link an item like a pickup would: Test_GiveItem(ItemClass.Sword, Swords.Master)
function Test_GiveItem(_ItemClass, _Index = 0, _Amount = 1){
	var _Got = Item_Get(_ItemClass, _Index, _Amount);
	Inventory_Update();
	Link_UpdateAttackDefence();
	return _Got;
}

#endregion

#region Steps (run by oTest in its End Step)

/// Logs level and room changes, damage and death
function Test_Watch(){
	if(global.Level != LastLevel){
		LastLevel = global.Level;
		LastRoom = -1;
		Test_Log("level " + Test_LevelName() + " rooms=" + string(global.Level.RoomCount) + " dungeon=" + string(global.Level.DungeonTemplate_Index));
		if(!global.HubLevel && !global.SaveLevel && LevelDef.RoomSet != "") Test_Log("roomset " + LevelDef.RoomSet + " rooms=" + string(Test_SetRooms()) + "/" + string(global.Level.RoomCount));
	}
	if(global.CurrentRoomIndex >= 0 && global.CurrentRoomIndex != LastRoom){
		LastRoom = global.CurrentRoomIndex;
		Test_Log("room " + Test_RoomStr(LastRoom));
	}
	var _Health = LinkHealth;
	if(LastHealth >= 0 && _Health < LastHealth) Test_Log("damage " + string(LastHealth - _Health) + " hp=" + string(_Health));
	LastHealth = _Health;
	if(global.LinkDead && !Dead){
		Dead = true;
		Test_Log("dead room=" + string(global.CurrentRoomIndex));
	}
}

function Test_HoldVerbs(_Verbs){
	if(!is_array(_Verbs)) _Verbs = [_Verbs];
	for(var i = 0; i < array_length(_Verbs); i++){
		if(array_contains(global.TestVerbs, _Verbs[i])) input_verb_set(_Verbs[i], 1);
	}
}

/// Runs the current step; returns true when it is done
function Test_DoStep(_S){
	var _Do = _S[$ "do"] ?? "";
	switch(_Do){

		case "wait":
			return StepFrames >= (_S[$ "frames"] ?? 1);

		case "hold":	// keys held together for "frames", then one frame released
		case "press":	// one key held for "frames" (default 8), then 4 frames released
			var _Keys = _S[$ "keys"] ?? [_S[$ "key"] ?? ""];
			var _Frames = _S[$ "frames"] ?? (_Do == "press" ? 8 : 1);
			if(StepFrames == 1){
				for(var i = 0; i < array_length(_Keys); i++){
					if(!array_contains(global.TestVerbs, _Keys[i])) Test_Fail("unknown key " + string(_Keys[i]));
				}
			}
			if(StepFrames <= _Frames) Test_HoldVerbs(_Keys);
			return StepFrames >= _Frames + (_Do == "press" ? 4 : 1);

		case "shot":
			ShotName = string(_S[$ "name"] ?? ("shot" + string(Step)));
			return true;

		case "room":
			if(!Test_GotoRoom(_S[$ "x"] ?? -1, _S[$ "y"] ?? -1)) Test_Fail("no room at " + string(_S[$ "x"]) + "," + string(_S[$ "y"]));
			return true;

		case "exit":	// Link in front of the main or the extra exit, then walking into it ("frames", default 60)
			if(StepFrames == 1){
				ExitVerb = Test_GotoExit((_S[$ "which"] ?? "main") == "extra");
				if(ExitVerb == ""){
					Test_Fail("no " + string(_S[$ "which"] ?? "main") + " exit");
					return true;
				}
			}
			if(ExitVerb == "" || StepFrames > (_S[$ "frames"] ?? 60)) return true;
			Test_HoldVerbs([ExitVerb]);
			return false;

		case "level":
			// Dungeon_Clear only removes active instances: wake every room first (oTest Step), build in the next End Step
			if(StepFrames == 1){
				ActivateAll = true;
				return false;
			}
			Test_BuildLevel(_S[$ "level"] ?? global.Level.Index, _S[$ "seed"] ?? global.Test.Seed);
			return true;

		case "spawn":
			var _Inst = Test_SpawnEnemy(_S[$ "enemy"] ?? "", _S[$ "dist"] ?? 48);
			if(_Inst == noone) Test_Fail("unknown object " + string(_S[$ "enemy"]));
			else Test_Log("spawned " + object_get_name(_Inst.object_index) + " x=" + string(round(_Inst.x)) + " y=" + string(round(_Inst.y)));
			return true;

		case "give":
			if(!is_real(_S[$ "item"])) Test_Fail("bad item " + string(_S[$ "item"]));
			else Test_GiveItem(_S.item, _S[$ "index"] ?? 0, _S[$ "amount"] ?? 1);
			return true;

		case "state":
			Test_LogState();
			return true;

		case "rooms":	// one "layout" line per room of the level: template class, size, doors in use (position:status), special object
			for(var _RI = 0; _RI < global.Level.RoomCount; _RI++){
				var _LR = global.Level.Rooms[_RI];
				var _LD = "";
				for(var _DI = 0; _DI < array_length(_LR.Doors); _DI++){
					var _LDoor = _LR.Doors[_DI];
					if(_LDoor.Status != DoorStatus.Unused) _LD += (_LD == "" ? "" : ",") + string(_LDoor.Position) + ":" + string(_LDoor.Status);
				}
				Test_Log("layout " + Test_RoomStr(_RI) + " doors=" + _LD + " special=" + string(_LR.SpecialObject) + " section=" + string(_LR.Section_ID));
			}
			return true;

		case "log":
			Test_Log("note " + string(_S[$ "text"] ?? ""));
			return true;

		case "expect":
			var _Bad = "";
			if(variable_struct_exists(_S, "alive") && _S.alive == global.LinkDead) _Bad += " alive";
			if(variable_struct_exists(_S, "level") && _S.level != global.Level.Index) _Bad += " level(" + string(global.Level.Index) + ")";
			if(variable_struct_exists(_S, "room")){
				var _GX = _S.room[0];
				var _GY = _S.room[1];
				if(global.Level.Map_RoomIndex[_GY][_GX] != global.CurrentRoomIndex) _Bad += " room(" + string(global.CurrentRoomIndex) + ")";
			}
			if(variable_struct_exists(_S, "enemies") && instance_number(oEnemy) != _S.enemies) _Bad += " enemies(" + string(instance_number(oEnemy)) + ")";
			if(variable_struct_exists(_S, "kills_min") && global.TestKills < _S.kills_min) _Bad += " kills(" + string(global.TestKills) + ")";
			if(variable_struct_exists(_S, "set_rooms_min") && Test_SetRooms() < _S.set_rooms_min) _Bad += " set_rooms(" + string(Test_SetRooms()) + ")";
			if((_S[$ "free"] ?? false) && Test_LinkInWall()) _Bad += " free(" + string(round(oLink.x)) + "," + string(round(oLink.y)) + ")";
			if((_S[$ "exit_level"] ?? false) && (global.SaveLevel || global.Level.Index != global.TestExitDest)) _Bad += " exit_level(" + string(global.Level.Index) + (global.SaveLevel ? " rest stop" : "") + ")";
			if(_Bad == "") Test_Log("expect ok");
			else Test_Fail("expect" + _Bad);
			return true;

		case "trace":	// every enemy's position, state and sprite every "every" frames (default 10) for "frames" (default 120)
			if((StepFrames - 1) mod (_S[$ "every"] ?? 10) == 0) Test_LogEnemies(StepFrames - 1);
			return StepFrames >= (_S[$ "frames"] ?? 120);

		case "arch":	// changes a state of an archetype enemy for this test (scripts/__EnemyArch): "move", "time" [min, max]
			var _Arch = EnemyArch_Get(asset_get_index(_S[$ "enemy"] ?? ""));
			var _ArchState = _Arch == undefined ? undefined : EnemyArch_State(_Arch, _S[$ "state"] ?? 0);
			if(_ArchState == undefined){
				Test_Fail("no archetype state " + string(_S[$ "enemy"]) + " " + string(_S[$ "state"]));
				return true;
			}
			if(variable_struct_exists(_S, "move")) _ArchState.Move = _S.move;
			if(variable_struct_exists(_S, "time")) _ArchState.Time = _S.time;
			Test_Log("arch " + _Arch.Name + " state=" + string(_S.state) + " move=" + _ArchState.Move + " time=" + string(_ArchState.Time));
			return true;

		case "probe":	// creates each enemy in front of Link, logs its variables and removes it
			var _Enemies = _S[$ "enemies"] ?? [];
			for(var i = 0; i < array_length(_Enemies); i++){
				var _Probe = Test_SpawnEnemy(_Enemies[i], _S[$ "dist"] ?? 48);
				if(_Probe == noone){
					Test_Fail("unknown object " + string(_Enemies[i]));
					continue;
				}
				Test_Log("probe " + Test_InstLine(_Probe));
				instance_destroy(_Probe);	// with its Destroy event, which removes what it made (weapons, lights, lists)
			}
			return true;

		case "paint":	// region tileset (roadmap F6b): "blocks" painted in turn over a "w" x "h" grid of 16x16 at "x", "y" of Link's room
			var _Blocks = _S[$ "blocks"] ?? [0];
			if(variable_struct_exists(_S, "transform")){	// the grid turned like a painted room (roadmap F12b)
				Test_PaintTransformed(_Blocks, _S[$ "x"] ?? 0, _S[$ "y"] ?? 0, _S[$ "w"] ?? 1, _S[$ "h"] ?? 1, _S.transform);
				return true;
			}
			var _PR = global.Level.Rooms[global.CurrentRoomIndex];
			var _PX = _PR.x + (_S[$ "x"] ?? 0);
			var _PY = _PR.y + (_S[$ "y"] ?? 0);
			var _PW = _S[$ "w"] ?? 1;
			var _PH = _S[$ "h"] ?? 1;
			var _Painted = 0;
			for(var _j = 0; _j < _PH; _j++){
				for(var _i = 0; _i < _PW; _i++){
					var _Block = _Blocks[(_j * _PW + _i) mod array_length(_Blocks)];
					if(RegionTiles_PaintBlock(_Block, _PX + (_i * 16), _PY + (_j * 16), UPPER, _S[$ "mirror"] ?? false, _S[$ "flip"] ?? false)) _Painted++;
				}
			}
			var _Classes = "";
			for(var _j = 0; _j < _PH * 2; _j++){
				for(var _i = 0; _i < _PW * 2; _i++){
					var _C = RegionTiles_ClassAt(_PX + (_i * 8) + 4, _PY + (_j * 8) + 4);
					if(string_pos("," + _C + ",", "," + _Classes + ",") == 0) _Classes += (_Classes == "" ? "" : ",") + _C;
				}
			}
			var _PTiles = RegionTiles_Get(LevelDef.RegionTiles);
			Test_Log("paint tileset=" + (_PTiles == undefined ? "none" : _PTiles.tileset) + " blocks=" + string(_Painted) + " of " + string(_PW * _PH) + " classes=" + _Classes);
			if(_Painted != _PW * _PH) Test_Fail("paint: " + string(_PW * _PH - _Painted) + " blocks not painted");
			return true;

		case "painted":	// painted room (roadmap F12b): Link to the first one of the level (or "index"), then its walls checked tile by tile; "remake" makes its walls again first
			if(StepFrames == 1){
				PaintedRoom = _S[$ "index"] ?? -1;
				for(var i = 0; PaintedRoom == -1 && i < global.Level.RoomCount; i++) if(RegionRoom_Is(i)) PaintedRoom = i;
				if(PaintedRoom == -1 || !RegionRoom_Is(PaintedRoom)){
					Test_Fail("no painted room in the level");
					return true;
				}
				if(_S[$ "remake"] ?? false) RegionRoom_Walls(PaintedRoom);	//while the room sleeps, as a bombed secret door does to the room behind it
				var _GotoPainted = global.Level.Rooms[PaintedRoom];
				Test_PlaceLink(PaintedRoom, (_S[$ "at"] ?? "") == "center" ? [_GotoPainted.x + 128, _GotoPainted.y + (_GotoPainted.GridH * 128) + 8] : Test_RoomEntryPoint(PaintedRoom));
				return false;
			}
			if(StepFrames < 10) return false;	// the room wakes up
			Test_CheckPainted(PaintedRoom);
			return true;

		case "at":	// Link to "x", "y" px of room "index" (a photo of that spot; camera follows him)
			if(StepFrames == 1){
				//mid camera transition the game would put the new room to sleep when it ends, with Link in it
				if(oCamera.RoomTransition != NONE){
					Test_Fail("at: a room transition is under way (wait for it to end)");
					return true;
				}
				var _AR = _S[$ "index"] ?? global.CurrentRoomIndex;
				if(_AR < 0 || _AR >= global.Level.RoomCount){
					Test_Fail("no room " + string(_AR));
					return true;
				}
				Test_PlaceLink(_AR, [global.Level.Rooms[_AR].x + (_S[$ "x"] ?? 128), global.Level.Rooms[_AR].y + (_S[$ "y"] ?? 128)]);
				Test_Log("at room=" + string(_AR) + " " + Test_RoomStr(_AR));
				return false;
			}
			return StepFrames >= 10;	// the room wakes up and the camera gets there

		case "tour":	// a photo of every room of the level ("name", default "tour": <name>_<room>_<n>.png; "sections": only the rooms with a section): Link at the top of each 256 px cell of the room, and at the bottom of its last row, 12 frames for the room to wake and the camera to get there (the agreed photo set of a visual task, R1 sixth round)
			if(StepFrames == 1){
				TourShots = [];
				for(var _TR = 0; _TR < global.Level.RoomCount; _TR++){
					var _TRm = global.Level.Rooms[_TR];
					if((_S[$ "sections"] ?? false) && _TRm.Section_ID == 0) continue;	//only the rooms with a section (R1 seventh round)
					for(var _TY = 0; _TY < _TRm.GridH; _TY++){
						for(var _TX = 0; _TX < _TRm.GridW; _TX++){
							array_push(TourShots, [_TR, _TRm.x + _TX * 256 + 128, _TRm.y + _TY * 256 + 96]);
							if(_TY == _TRm.GridH - 1) array_push(TourShots, [_TR, _TRm.x + _TX * 256 + 128, _TRm.y + _TY * 256 + 160]);
						}
					}
				}
				Test_Log("tour shots=" + string(array_length(TourShots)));
			}
			var _TK = (StepFrames - 1) div 12;
			if(_TK >= array_length(TourShots)) return true;
			var _TS = TourShots[_TK];
			switch((StepFrames - 1) mod 12){
				case 0:
					if(oCamera.RoomTransition != NONE){
						Test_Fail("tour: a room transition is under way");
						return true;
					}
					Test_PlaceLink(_TS[0], [_TS[1], _TS[2]]);
					break;
				case 11:
					ShotName = string(_S[$ "name"] ?? "tour") + "_" + string(_TS[0]) + "_" + string(_TK);
					break;
			}
			return false;

		case "doorshots":	// a photo of every door of every painted room in use ("name", default "door": <name>_r<room>_p<position>.png), Link "in" px inside in front of it (default 40); the camera stops following him and is put against the door's edge of the room (the bottom 16 px of a room the game's camera never shows but in a transition, and a big room's camera was still scrolling: R1 eighth round), across it centered on the door, inside the room; each logs "doorshot" with the door cell in the level and "doorcam" with the camera, so tools/test/seam_sheet.py puts the two sides of a seam together where they are in the level (R1 seventh round)
			if(StepFrames == 1){
				TourShots = [];
				for(var _DR = 0; _DR < global.Level.RoomCount; _DR++){
					if(!RegionRoom_Is(_DR)) continue;
					var _DRm = global.Level.Rooms[_DR];
					for(var _DD = 0; _DD < array_length(_DRm.Doors); _DD++){
						var _DDr = _DRm.Doors[_DD];
						if(_DDr.Status == DoorStatus.Unused) continue;
						var _DIn = _S[$ "in"] ?? 40;
						var _DSX = _DRm.x + _DDr.x + 16, _DSY = _DRm.y + _DDr.y + 16;
						switch(_DDr.Location){
							case "Top":		_DSY += _DIn; break;
							case "Bottom":	_DSY -= _DIn; break;
							case "Left":	_DSX += _DIn; break;
							default:		_DSX -= _DIn; break;
						}
						array_push(TourShots, [_DR, _DSX, _DSY, _DDr.Position, _DRm.x + _DDr.x, _DRm.y + _DDr.y, _DDr.Location]);
						Test_Log("doorshot name=" + string(_S[$ "name"] ?? "door") + " room=" + string(_DR) + " pos=" + string(_DDr.Position) + " " + _DDr.Location + " status=" + string(_DDr.Status)
							+ " to=" + string(_DDr.ConnectedRoomIndex) + " cell=" + string(_DRm.x + _DDr.x) + "," + string(_DRm.y + _DDr.y) + " room_at=" + string(_DRm.x) + "," + string(_DRm.y) + " size=" + string(_DRm.width) + "x" + string(_DRm.height));
					}
				}
				Test_Log("doorshots shots=" + string(array_length(TourShots)));
			}
			var _DK = (StepFrames - 1) div 16;
			if(_DK >= array_length(TourShots)){
				oCamera.Override = false;
				return true;
			}
			var _DS = TourShots[_DK];
			switch((StepFrames - 1) mod 16){
				case 0:
					oCamera.Override = false;
					if(oCamera.RoomTransition != NONE){
						Test_Fail("doorshots: a room transition is under way");
						return true;
					}
					Test_PlaceLink(_DS[0], [_DS[1], _DS[2]]);
					break;
				case 9:
					with(oEnemy) instance_destroy(id);	//the room is awake: its enemies out of the photo
					break;
				case 10:
					//the camera against the door's edge of the room, centered on the door across it, inside the room
					var _DCR = global.Level.Rooms[_DS[0]];
					var _DCX = clamp(_DS[4] + 16 - CAM_W / 2, _DCR.x, _DCR.x + _DCR.width - CAM_W);
					var _DCY = clamp(_DS[5] + 16 - CAM_H / 2, _DCR.y, _DCR.y + _DCR.height - CAM_H);
					switch(_DS[6]){
						case "Top":		_DCY = _DCR.y; break;
						case "Bottom":	_DCY = _DCR.y + _DCR.height - CAM_H; break;
						case "Left":	_DCX = _DCR.x; break;
						default:		_DCX = _DCR.x + _DCR.width - CAM_W; break;
					}
					oCamera.Override = true;
					oCamera.X = _DCX;
					oCamera.Y = _DCY;
					break;
				case 15:
					ShotName = string(_S[$ "name"] ?? "door") + "_r" + string(_DS[0]) + "_p" + string(_DS[3]);
					Test_Log("doorcam name=" + string(_S[$ "name"] ?? "door") + " room=" + string(_DS[0]) + " pos=" + string(_DS[3]) + " cam=" + string(oCamera.X) + "," + string(oCamera.Y));
					break;
			}
			return false;

		case "grid":	// a preview painted over Link's room (R1): "cells" block * 2 + mirror, "w" x "h" blocks of 16x16 at "x", "y"; pictures only, the walls stay
			var _GR = global.Level.Rooms[global.CurrentRoomIndex];
			var _GCells = _S[$ "cells"] ?? [];
			var _GW = _S[$ "w"] ?? 16;
			var _GPainted = 0;
			for(var _k = 0; _k < array_length(_GCells); _k++){
				if(_GCells[_k] < 0) continue;	// left as it is
				if(RegionTiles_PaintBlock(_GCells[_k] div 2, _GR.x + (_S[$ "x"] ?? 0) + (_k mod _GW) * 16, _GR.y + (_S[$ "y"] ?? 0) + (_k div _GW) * 16, UPPER, (_GCells[_k] mod 2) == 1, false)) _GPainted++;
			}
			Test_Log("grid " + string(_S[$ "name"] ?? "") + " blocks=" + string(_GPainted));
			return true;

		case "pass":	// an open door of a painted room at one of "positions" (default any): Link 16 px inside (in its passage, past a lamp tower's foot), in the middle of it, walks through it for "frames" (default 90); he must end up in another room, out of the walls (R1 sixth round: the side doors by the top corner run under the top wall)
			if(StepFrames == 1){
				LockRoom = -1;
				LockVerb = "";
				var _PPos = _S[$ "positions"] ?? [];
				for(var _Pi = 0; LockVerb == "" && _Pi < global.Level.RoomCount; _Pi++){
					if(!RegionRoom_Is(_Pi)) continue;
					var _PsR = global.Level.Rooms[_Pi];
					for(var _Pd = 0; _Pd < array_length(_PsR.Doors); _Pd++){
						var _PsD = _PsR.Doors[_Pd];
						if(_PsD.Status != DoorStatus.Open || (array_length(_PPos) > 0 && !array_contains(_PPos, _PsD.Position))) continue;
						var _PsX = _PsR.x + _PsD.x + 16, _PsY = _PsR.y + _PsD.y + 16;
						switch(_PsD.Location){
							case "Top":		_PsY += 16; LockVerb = "up"; break;
							case "Bottom":	_PsY -= 16; LockVerb = "down"; break;
							case "Left":	_PsX += 16; LockVerb = "left"; break;
							default:		_PsX -= 16; LockVerb = "right"; break;
						}
						LockRoom = _Pi;
						Test_PlaceLink(_Pi, [_PsX, _PsY]);
						//Link's box is the 10 px above his feet: a side door by the top corner runs under the wall's face, so he
						//starts lower, where a player walks in
						for(var _Pk = 0; _Pk < 4 && Test_LinkInWall(); _Pk++){
							if(_PsD.Location == "Left" || _PsD.Location == "Right") _PsY += 4; else _PsY += (_PsD.Location == "Top") ? 8 : -8;
							Test_PlaceLink(_Pi, [_PsX, _PsY]);
						}
						Test_Log("pass room=" + string(_Pi) + " door=" + string(_PsD.Position) + " " + _PsD.Location);
						break;
					}
				}
				if(LockVerb == ""){
					if(_S[$ "optional"] ?? false) Test_Log("pass none");
					else Test_Fail("no open door of a painted room at " + string(_PPos));
				}
				return LockVerb == "";
			}
			if(StepFrames <= (_S[$ "frames"] ?? 90)){
				Test_HoldVerbs([LockVerb]);
				if(StepFrames mod 15 == 0 && instance_exists(oLink)) Test_Log("pass at " + string(round(oLink.x)) + "," + string(round(oLink.y)) + " room=" + string(global.CurrentRoomIndex) + " transition=" + string(oCamera.RoomTransition));
				return false;
			}
			if(oCamera.RoomTransition != NONE) return false;	// let the camera end its transition
			if(!instance_exists(oLink)) Test_Fail("pass: no_link");
			else if(global.CurrentRoomIndex == LockRoom) Test_Fail("pass: still in room " + string(LockRoom) + " at " + string(round(oLink.x)) + "," + string(round(oLink.y)));
			else if(Test_LinkInWall()) Test_Fail("pass: in_wall in room " + string(global.CurrentRoomIndex));
			else Test_Log("pass went to room=" + string(global.CurrentRoomIndex));
			return true;

		case "passall":	// every open or locked door of every room of the level (R1 seventh round; give Link keys for the locked ones): Link at the mouth of its passage, "in" px inside (default 24; another spot 16 to 56 px in where that is a wall), walks through it for at most "frames" (default 240); he must reach the room behind it, out of the walls. The room's enemies die first (they would push him back)
		case "bomb":	// every secret door of the level, the top ones (with the crack) first: Link "in" px inside in front of it, walks into the wall for 20 frames and puts a lit bomb down in front of him (as the bomb item does); the door must open and he walks through it to the room behind; "optional": a level without one is not a failure
		case "walkall":	// like passall, but Link starts on the floor nearest the middle of the room from which the door can be reached (the section's middle for a door of a section) and walks to the mouth of its passage along the shortest way between the walls (8 px steps), then through it; at most "frames" (default 600) per door (R1 eighth round: passall starts at the mouth and never walks into the wall beside a passage)
			var _Bomb = (_Do == "bomb");
			var _Walk = (_Do == "walkall");
			if(StepFrames == 1){
				PassList = [];
				for(var _PLi = 0; _PLi < global.Level.RoomCount; _PLi++){
					var _PLR = global.Level.Rooms[_PLi];
					for(var _PD = 0; _PD < array_length(_PLR.Doors); _PD++){
						var _PSt = _PLR.Doors[_PD].Status;
						if(_Bomb ? (_PSt == DoorStatus.Secret_Closed) : (_PSt == DoorStatus.Open || _PSt == DoorStatus.Secret_Open || _PSt == DoorStatus.Locked)){
							if(_Bomb && _PLR.Doors[_PD].Location == "Top") array_insert(PassList, 0, [_PLi, _PD]);
							else array_push(PassList, [_PLi, _PD]);
						}
					}
				}
				PassK = 0;
				PassT = 0;
				PassOk = 0;
				PassBad = 0;
				Test_Log(_Do + " doors=" + string(array_length(PassList)));
				if(_Bomb && array_length(PassList) == 0 && !(_S[$ "optional"] ?? false)) Test_Fail("bomb: no secret door in the level");
			}
			//the camera transition pauses the game until Link has walked in: moving him before that leaves it paused
			var _PSettled = (oCamera.RoomTransition == NONE && !global.Paused && instance_exists(oLink) && oLink.State != LinkState.AutoMove);
			if(PassK >= array_length(PassList)){
				if(!_PSettled) return false;
				Test_Log(_Do + " ok=" + string(PassOk) + " failed=" + string(PassBad));
				return true;
			}
			var _PE = PassList[PassK];
			var _PRm = global.Level.Rooms[_PE[0]];
			var _PDr = _PRm.Doors[_PE[1]];
			var _PWhere = "room=" + string(_PE[0]) + " door=" + string(_PDr.Position) + " " + _PDr.Location;
			PassT++;
			if(PassT == 1){
				//a bombed secret door opens the one behind it too: nothing left to do there
				var _PDone = false;
				with(oDoor) if(RoomIndex == _PDr.ConnectedRoomIndex && ConnectedRoomIndex == _PE[0] && Status == DoorStatus.Secret_Open) _PDone = true;
				if(_Bomb && (_PDr.Status != DoorStatus.Secret_Closed || _PDone)){
					Test_Log("bomb " + _PWhere + " opened from the other side");
					PassK++;
					PassT = 0;
					return false;
				}
				if(!_PSettled){
					PassT = 0;
					return false;
				}
				switch(_PDr.Location){
					case "Top":		PassVerb = "up"; break;
					case "Bottom":	PassVerb = "down"; break;
					case "Left":	PassVerb = "left"; break;
					default:		PassVerb = "right"; break;
				}
				Test_PlaceAtPassage(_PE[0], _PDr, _S[$ "in"] ?? 24);
				return false;
			}
			if(PassT < 10){
				//the room's enemies would push him back: they die as the sword kills them (their Destroy event cleans up
				//what they made), once the room is awake (the other rooms sleep, so with() only finds this one's)
				if(PassT == 9) with(oEnemy) instance_destroy(id);
				return false;
			}
			if(_Walk && PassT == 10){
				//the way from the middle: from the mouth of the passage (where he stands) over every spot 8 px apart
				//where he fits between the walls, the one nearest the middle of the room is the start
				WalkPath = Test_WalkFromMiddle(_PRm);
				WalkI = 0;
				var _WS = (array_length(WalkPath) > 0) ? WalkPath[0] : [oLink.x, oLink.y];
				Test_Log("walkall " + _PWhere + " from " + string(round(_WS[0] - _PRm.x)) + "," + string(round(_WS[1] - _PRm.y)) + " steps=" + string(array_length(WalkPath)));
				Test_PlaceLink(_PE[0], _WS);
				return false;
			}
			if(_Walk && WalkI < array_length(WalkPath) && PassT < (_S[$ "frames"] ?? 600)){
				var _WT = WalkPath[WalkI];
				var _WDX = _WT[0] - oLink.x, _WDY = _WT[1] - oLink.y;
				if(abs(_WDX) <= 1 && abs(_WDY) <= 1){
					WalkI++;
					return false;
				}
				var _WV = [];
				if(_WDX > 1) array_push(_WV, "right");
				if(_WDX < -1) array_push(_WV, "left");
				if(_WDY > 1) array_push(_WV, "down");
				if(_WDY < -1) array_push(_WV, "up");
				Test_HoldVerbs(_WV);
				return false;
			}
			if(_Bomb){
				var _PInst = noone;
				with(oDoor) if(RoomIndex == _PE[0] && Position == _PDr.Position) _PInst = id;
				if(PassT < 30){
					Test_HoldVerbs([PassVerb]);
					if(PassT == 29) ShotName = "bomb_" + string(PassK) + "_before";	//the wall with its crack (photos of the round)
					return false;
				}
				if(PassT == 30){
					PassOpened = false;
					var _BX = oLink.x, _BY = oLink.y;
					switch(PassVerb){
						case "up":		_BY -= 12; break;
						case "down":	_BY += 12; break;
						case "left":	_BX -= 14; break;
						default:		_BX += 14; break;
					}
					var _BInst = instance_create_layer(_BX, _BY, oLink.layer, oBomb, {From : ItemFrom.Inventory, FloorLevel : oLink.FloorLevel});
					_BInst.Index = 0;
					_BInst.visible = true;
					_BInst.alarm[0] = Bomb_IgniteDelay;
					Test_Log("bomb " + _PWhere + " door_cell=" + string(_PDr.x) + "," + string(_PDr.y) + " bomb=" + string(round(_BX - _PRm.x)) + "," + string(round(_BY - _PRm.y)));
					return false;
				}
				//kept once seen: after he walks through, the room (and the door) is put to sleep
				if(_PInst != noone && _PInst.Status == DoorStatus.Secret_Open) PassOpened = true;
				if(!PassOpened && PassT < 220) return false;
				if(!PassOpened){
					PassBad++;
					ShotName = _Do + "_fail_" + string(PassK);
					Test_Fail("bomb: the wall stayed shut " + _PWhere);
					PassK++;
					PassT = 0;
					return false;
				}
				if(PassT < 240) return false;	// the blast is over (Link may have been knocked back)
				//back to the mouth of the passage: the way across the room is the player's (the chest of the large
				//treasure room stands right under its secret door)
				if(PassT == 240){
					Test_PlaceAtPassage(_PE[0], _PDr, _S[$ "in"] ?? 24);
					ShotName = "bomb_" + string(PassK) + "_after";
					Test_Log("bomb " + _PWhere + " opened, Link at the passage " + string(round(oLink.x - _PRm.x)) + "," + string(round(oLink.y - _PRm.y)) + (Test_LinkInWall() ? " (in a wall)" : ""));
				}
			}
			var _PFrames = (_S[$ "frames"] ?? (_Walk ? 600 : 240)) + (_Bomb ? 240 : 0);
			//there once the camera has stopped and Link has walked in (the transition pauses the game until his steps end)
			var _PThere = (global.CurrentRoomIndex != _PE[0] && oCamera.RoomTransition == NONE && instance_exists(oLink) && oLink.State != LinkState.AutoMove && !global.Paused);
			if(!_PThere && PassT < _PFrames){
				Test_HoldVerbs([PassVerb]);
				return false;
			}
			var _PTarget = _PDr.ConnectedRoomIndex;
			if(_PThere && instance_exists(oLink) && !Test_LinkInWall() && (_PTarget < 0 || global.CurrentRoomIndex == _PTarget)){
				PassOk++;
				Test_Log(_Do + " " + _PWhere + " -> " + string(global.CurrentRoomIndex) + " ok");
			}else{
				PassBad++;
				ShotName = _Do + "_fail_" + string(PassK);
				//the walls right in front of him, to tell a painted wall from a door's blocker or another object
				var _PWalls = "";
				if(instance_exists(oLink)){
					var _PLX = oLink.x, _PLY = oLink.y, _PRX = _PRm.x, _PRY = _PRm.y;
					with(oWall) if(BlockLink && bbox_right >= _PLX - 10 && bbox_left <= _PLX + 10 && bbox_bottom >= _PLY - 20 && bbox_top <= _PLY + 4) _PWalls += " [" + object_get_name(object_index) + " " + string(bbox_left - _PRX) + "," + string(bbox_top - _PRY) + "-" + string(bbox_right - _PRX) + "," + string(bbox_bottom - _PRY) + (variable_instance_exists(id, "RegionRoom") ? " painted" : "") + (IsDoorEntrance ? " door_blocker" : "") + " " + string(id) + "]";
				}
				Test_Log(_Do + " walls by Link:" + _PWalls + (instance_exists(oLink) ? " (Link state " + string(oLink.State) + ")" : ""));
				var _PDoors = "";
				with(oDoor) if(RoomIndex == global.CurrentRoomIndex) _PDoors += " [" + string(id) + " pos=" + string(Position) + " status=" + string(Status) + " upd=" + string(UpdateStatus) + " wall=" + (instance_exists(WallInst) ? string(WallInst.id) + " block=" + string(WallInst.BlockLink) : string(WallInst)) + "]";
				Test_Log(_Do + " doors here:" + _PDoors);
				Test_Fail(_Do + " " + _PWhere + " blocked at " + (instance_exists(oLink) ? string(round(oLink.x - _PRm.x)) + "," + string(round(oLink.y - _PRm.y)) : "no_link")
					+ " (in room " + string(global.CurrentRoomIndex) + ", want " + string(_PTarget) + (Test_LinkInWall() ? ", in a wall" : "") + ")");
			}
			PassK++;
			PassT = 0;
			return false;

		case "cut":	// one bush of every painted room with bushes (Nature/bushes, RegionRoom_Bushes, R1 eighth round): Link right under its lowest bush, walks up into it and swings the sword; the bush and its wall must be gone ("cut room= ok", photos cut_<n>.png just before the swing and cut_<n>_after.png), otherwise a failure
			if(StepFrames == 1){
				CutList = [];
				for(var _CI = 0; _CI < global.Level.RoomCount; _CI++){
					var _CRS = global.Level.Rooms[_CI];
					var _CReg = is_struct(_CRS[$ "Template"]) ? _CRS.Template[$ "Region"] : undefined;
					if(is_struct(_CReg) && _CReg[$ "bushes"] != undefined) array_push(CutList, _CI);
				}
				CutK = 0;
				CutT = 0;
				CutOk = 0;
				Test_Log("cut rooms=" + string(array_length(CutList)));
			}
			var _CSettled = (oCamera.RoomTransition == NONE && !global.Paused && instance_exists(oLink) && oLink.State != LinkState.AutoMove);
			if(CutK >= array_length(CutList)){
				Test_Log("cut ok=" + string(CutOk) + " of " + string(array_length(CutList)));
				return true;
			}
			var _CRm = CutList[CutK];
			CutT++;
			if(CutT == 1){
				if(!_CSettled){
					CutT = 0;
					return false;
				}
				Test_PlaceLink(_CRm, Test_RoomEntryPoint(_CRm));
				return false;
			}
			if(CutT < 10) return false;
			if(CutT == 10){
				with(oEnemy) instance_destroy(id);
				var _CB = noone;
				with(oBush) if(RoomIndex == _CRm && State == PickupObjState.Idle && (_CB == noone || y > _CB.y)) _CB = id;
				CutBush = _CB;
				CutWall = (_CB == noone) ? noone : _CB.WallObj;
				var _CPlaced = false;
				if(_CB != noone){
					for(var _CDY = 10; _CDY <= 22 && !_CPlaced; _CDY += 4){
						Test_PlaceLink(_CRm, [_CB.x, _CB.y + _CDY]);
						_CPlaced = !Test_LinkInWall();
					}
				}
				if(!_CPlaced){
					Test_Fail("cut room=" + string(_CRm) + ": " + (_CB == noone ? "no bush" : "no room under its lowest bush"));
					CutK++;
					CutT = 0;
				}
				return false;
			}
			if(CutT < 20){
				Test_HoldVerbs(["up"]);
				if(CutT == 19) ShotName = "cut_" + string(CutK);
				return false;
			}
			if(CutT < 28){
				Test_HoldVerbs(["sword"]);
				return false;
			}
			if(CutT < 70){
				if(CutT == 60) ShotName = "cut_" + string(CutK) + "_after";
				return false;
			}
			var _CGone = !instance_exists(CutBush) && !instance_exists(CutWall);
			if(_CGone) CutOk++;
			else Test_Fail("cut room=" + string(_CRm) + ": the bush " + (instance_exists(CutBush) ? "is still there" : "is gone but its wall is not"));
			Test_Log("cut room=" + string(_CRm) + (_CGone ? " ok" : " failed"));
			CutK++;
			CutT = 0;
			return false;

		case "lock":	// a locked door of a painted room (R1): Link "side" px across from its middle, 32 px inside, walks into it for "frames" (default 120); he must stay in the room, out of the walls, with no camera transition
			if(StepFrames == 1){
				LockRoom = -1;
				LockVerb = "";
				for(var i = 0; LockVerb == "" && i < global.Level.RoomCount; i++){
					if(!RegionRoom_Is(i)) continue;
					var _LR = global.Level.Rooms[i];
					for(var d = 0; d < array_length(_LR.Doors); d++){
						var _LD = _LR.Doors[d];
						if(_LD.Status != DoorStatus.Locked) continue;
						var _Side = _S[$ "side"] ?? 0;
						var _LX = _LR.x + _LD.x + 16, _LY = _LR.y + _LD.y + 16;
						switch(_LD.Location){
							case "Top":		_LX += _Side; _LY += 32; LockVerb = "up"; break;
							case "Bottom":	_LX += _Side; _LY -= 32; LockVerb = "down"; break;
							case "Left":	_LY += _Side; _LX += 32; LockVerb = "left"; break;
							default:		_LY += _Side; _LX -= 32; LockVerb = "right"; break;
						}
						LockRoom = i;
						Test_PlaceLink(i, [_LX, _LY]);
						//a spot beside the passage may be the wall's foot (the posts under a third round wall): he starts further in
						var _LIn = (_LD.Location == "Top") ? [0, 8] : ((_LD.Location == "Bottom") ? [0, -8] : ((_LD.Location == "Left") ? [8, 0] : [-8, 0]));
						for(var _Lk = 0; _Lk < 6 && Test_LinkInWall(); _Lk++){
							_LX += _LIn[0];
							_LY += _LIn[1];
							Test_PlaceLink(i, [_LX, _LY]);
						}
						Test_Log("lock room=" + string(i) + " door=" + string(_LD.Position) + " " + _LD.Location + " side=" + string(_Side));
						break;
					}
				}
				if(LockVerb == ""){
					if(_S[$ "optional"] ?? false) Test_Log("lock none");
					else Test_Fail("no locked door in a painted room");
				}
				return LockVerb == "";
			}
			if(StepFrames <= (_S[$ "frames"] ?? 120)){
				Test_HoldVerbs([LockVerb]);
				return false;
			}
			var _LBad = "";
			if(!instance_exists(oLink)) _LBad += " no_link";
			else{
				if(Test_LinkInWall()) _LBad += " in_wall";
				var _LRm = global.Level.Rooms[LockRoom];
				if(oLink.x < _LRm.x || oLink.x >= _LRm.x + _LRm.width || oLink.y < _LRm.y || oLink.y >= _LRm.y + _LRm.height) _LBad += " outside(" + string(round(oLink.x)) + "," + string(round(oLink.y)) + ")";
			}
			if(global.CurrentRoomIndex != LockRoom) _LBad += " room(" + string(global.CurrentRoomIndex) + ")";
			if(oCamera.RoomTransition != NONE) _LBad += " transition";
			if(_LBad == "") Test_Log("lock held x=" + string(round(oLink.x)) + " y=" + string(round(oLink.y)));
			else Test_Fail("lock passed:" + _LBad);
			return true;

		case "seams":	// the seams between neighbouring painted rooms (roadmap F12b-2): every 2x2 window of blocks across the edge of two of them fits the set's rules (sets/<Set>/Fit.json)
			Test_CheckSeams();
			return true;

		case "sheet":
			Test_SheetStart(_S[$ "level"] ?? global.Level.Index, _S[$ "seeds"] ?? [global.Test.Seed]);
			return true;

		case "end":
			Test_Finish("ok");
			return true;

		default:
			Test_Fail("unknown step " + string(_Do));
			return true;
	}
}

#endregion

#region Level dumps (reference scenarios, tools/test/baseline.py)

/// Called from Dungeon_InitLevel once every room is built and before the rooms are put to sleep. With "dump": true
/// in the scenario, writes everything the generator produced to dump_<n>_<level>_s<seed>.txt: the level and room
/// structs, every instance with its variables and an MD5 of each tile layer per room. Two versions of the code that
/// build the same level give the same file. Test_DumpGlobals adds the global variables once the build is over.
function Test_OnLevelBuilt(){
	if(!global.TestMode || !global.Test.Dump) exit;
	global.TestDumps++;
	global.TestDumpFile = "dump_" + string(global.TestDumps) + "_" + LevelDef.Name + "_s" + string(global.TestBuildSeed) + ".txt";
	var _B = buffer_create(1 << 16, buffer_grow, 1);
	buffer_write(_B, buffer_text, "level " + string(global.Level.Index) + " seed=" + string(global.TestBuildSeed) + "\n");
	buffer_write(_B, buffer_text, "levelstruct " + Test_VarsLine(global.Level) + "\n");
	for(var _RoomIndex = 0; _RoomIndex < global.Level.RoomCount; _RoomIndex++){
		buffer_write(_B, buffer_text, "room " + Test_RoomStr(_RoomIndex) + "\n");
		buffer_write(_B, buffer_text, "roomstruct " + string(_RoomIndex) + " " + Test_VarsLine(global.Level.Rooms[_RoomIndex]) + "\n");
	}

	// Tile layers: one MD5 per room and layer
	var _Layers = layer_get_all();
	var _Tiles = buffer_create(4096, buffer_grow, 4);
	for(var i = 0; i < array_length(_Layers); i++){
		var _Layer = _Layers[i];
		buffer_write(_B, buffer_text, "layer " + layer_get_name(_Layer) + " depth=" + string(layer_get_depth(_Layer)) + " visible=" + string(layer_get_visible(_Layer)) + "\n");
		var _TM = layer_tilemap_get_id(_Layer);
		if(_TM == -1) continue;
		var _TW = tilemap_get_tile_width(_TM);
		var _TH = tilemap_get_tile_height(_TM);
		buffer_write(_B, buffer_text, "tilemap " + layer_get_name(_Layer) + " tileset=" + tileset_get_name(tilemap_get_tileset(_TM)) + " x=" + string(tilemap_get_x(_TM)) + " y=" + string(tilemap_get_y(_TM)) + "\n");
		for(var _RoomIndex = 0; _RoomIndex < global.Level.RoomCount; _RoomIndex++){
			var _R = global.Level.Rooms[_RoomIndex];
			buffer_seek(_Tiles, buffer_seek_start, 0);
			var _Used = 0;
			for(var _Y = _R.y; _Y < _R.y + _R.height; _Y += _TH){
				for(var _X = _R.x; _X < _R.x + _R.width; _X += _TW){
					var _T = tilemap_get_at_pixel(_TM, _X, _Y);
					if(_T > 0) _Used++;
					buffer_write(_Tiles, buffer_u32, _T == -1 ? 0 : _T);
				}
			}
			if(_Used > 0) buffer_write(_B, buffer_text, "tiles " + layer_get_name(_Layer) + " room=" + string(_RoomIndex) + " used=" + string(_Used) + " md5=" + buffer_md5(_Tiles, 0, buffer_tell(_Tiles)) + "\n");
		}
	}
	buffer_delete(_Tiles);

	with(all){
		if(object_index == oTest) continue;
		buffer_write(_B, buffer_text, "inst " + Test_InstLine(id) + "\n");
	}
	buffer_save_ext(_B, TEST_OUT + global.TestDumpFile, 0, buffer_tell(_B));
	buffer_delete(_B);
}

/// Called after Dungeon_InitLevel (Test_BuildLevel): adds the global variables to the level dump
function Test_DumpGlobals(){
	if(!global.TestMode || !global.Test.Dump || global.TestDumpFile == "") exit;
	var _Names = variable_instance_get_names(global);
	array_sort(_Names, true);
	var _Text = "";
	for(var i = 0; i < array_length(_Names); i++){
		var _Name = _Names[i];
		if(string_char_at(_Name, 1) == "_" || string_pos("Test", _Name) == 1 || string_pos("Time_", _Name) == 1) continue;	// libraries, test mode, clocks
		var _Value = Test_ValueStr(variable_global_get(_Name));
		if(_Value != undefined) _Text += "global " + _Name + "=" + _Value + "\n";
	}
	var _File = file_text_open_append(TEST_OUT + global.TestDumpFile);
	if(_File == -1) exit;
	file_text_write_string(_File, _Text);
	file_text_close(_File);
	Test_Log("dump " + global.TestDumpFile);
	global.TestDumpFile = "";
}

/// Text of a plain value, or of an array of plain values (up to 256 items, two levels deep); undefined for anything else
/// (structs, methods)
function Test_ValueStr(_V, _Depth = 0){
	if(is_real(_V) || is_bool(_V) || is_int64(_V) || is_int32(_V)) return string(_V);
	if(is_string(_V)) return "\"" + string_replace_all(_V, "\n", "\\n") + "\"";
	if(is_undefined(_V)) return "undefined";
	if(typeof(_V) == "ref") return string(_V);
	if(is_array(_V)){
		var _N = array_length(_V);
		if(_N > 256 || _Depth >= 2) return "[" + string(_N) + " items]";
		var _Out = "[";
		for(var i = 0; i < _N; i++){
			var _Item = Test_ValueStr(_V[i], _Depth + 1);
			_Out += (i > 0 ? "," : "") + (_Item ?? "?");
		}
		return _Out + "]";
	}
	return undefined;
}

/// name=value for every plain variable of a struct or instance, sorted by name
function Test_VarsLine(_Owner){
	var _Names = is_struct(_Owner) ? variable_struct_get_names(_Owner) : variable_instance_get_names(_Owner);
	array_sort(_Names, true);
	var _Out = "";
	for(var i = 0; i < array_length(_Names); i++){
		var _Value = Test_ValueStr(is_struct(_Owner) ? _Owner[$ _Names[i]] : variable_instance_get(_Owner, _Names[i]));
		if(_Value != undefined) _Out += " " + _Names[i] + "=" + _Value;
	}
	return _Out;
}

/// One line about an instance: object, position, sprite, layer and its own variables
function Test_InstLine(_Inst){
	with(_Inst){
		return object_get_name(object_index) + " x=" + string(x) + " y=" + string(y) + " depth=" + string(depth)
			+ " layer=" + (layer == -1 ? "-" : layer_get_name(layer)) + " sprite=" + (sprite_index == -1 ? "-" : sprite_get_name(sprite_index))
			+ " image=" + string(image_index) + " xs=" + string(image_xscale) + " ys=" + string(image_yscale) + " visible=" + string(visible)
			+ " |" + Test_VarsLine(id);
	}
}

#endregion

#region Screenshots and contact sheets

/// Copies what the game view shows (view 1, drawn at 4x into application_surface) into _Surface at 1x. Post Draw only.
function Test_CaptureView(_Surface, _X, _Y){
	var _VX = view_get_xport(1);
	var _VY = view_get_yport(1);
	var _VW = view_get_wport(1);
	var _VH = view_get_hport(1);
	surface_set_target(_Surface);
	gpu_set_colorwriteenable(true, true, true, false);	// keep the target opaque
	draw_surface_part_ext(application_surface, _VX, _VY, _VW, _VH, _X, _Y, CAM_W / _VW, CAM_H / _VH, c_white, 1);
	gpu_set_colorwriteenable(true, true, true, true);
	surface_reset_target();
}

function Test_SaveShot(_Name){
	var _Surface = surface_create(CAM_W, CAM_H);
	surface_set_target(_Surface);
	draw_clear(c_black);
	surface_reset_target();
	Test_CaptureView(_Surface, 0, 0);
	surface_save(_Surface, TEST_OUT + _Name + ".png");
	surface_free(_Surface);
	Test_Log("shot " + _Name + ".png room=" + string(global.CurrentRoomIndex));
}

/// Contact sheet: builds the level once per seed and pictures every room. Saves sheet_<level>_<seed>.png per seed
/// and sheet_<level>.png with all of them side by side at half size, in seed order.
function Test_SheetStart(_Level, _Seeds){
	Sheet = {Level: _Level, Seeds: _Seeds, SeedIndex: -1, Shots: [], ShotIndex: 0, Wait: 0, Ready: false, NextSeed: true, Activated: false, Surface: -1, MinX: 0, MinY: 0, Done: []};
	oCamera.Override = true;
}

function Test_SheetNextSeed(){
	Sheet.SeedIndex++;
	if(Sheet.SeedIndex >= array_length(Sheet.Seeds)){
		Test_SheetFinish();
		exit;
	}
	var _Seed = Sheet.Seeds[Sheet.SeedIndex];
	Test_BuildLevel(Sheet.Level, _Seed);
	global.Paused = true;
	oLink.visible = false;
	oHUD.ShowLevelName = false;	// the level name banner is drawn in the view

	// Bounding box of the level and the camera positions that cover every room (the view is 256x224, rooms are 256 multiples)
	var _MinX = 99999;
	var _MinY = 99999;
	var _MaxX = 0;
	var _MaxY = 0;
	Sheet.Shots = [];
	for(var _RoomIndex = 0; _RoomIndex < global.Level.RoomCount; _RoomIndex++){
		var _R = global.Level.Rooms[_RoomIndex];
		_MinX = min(_MinX, _R.x);
		_MinY = min(_MinY, _R.y);
		_MaxX = max(_MaxX, _R.x + _R.width);
		_MaxY = max(_MaxY, _R.y + _R.height);
		for(var _X = _R.x; _X < _R.x + _R.width; _X += CAM_W){
			var _Y = _R.y;
			while(true){
				array_push(Sheet.Shots, [_RoomIndex, _X, min(_Y, _R.y + _R.height - CAM_H)]);
				if(_Y + CAM_H >= _R.y + _R.height) break;
				_Y += CAM_H;
			}
		}
		Test_Log("sheet seed=" + string(_Seed) + " room " + Test_RoomStr(_RoomIndex));
	}
	Sheet.MinX = _MinX;
	Sheet.MinY = _MinY;
	Sheet.Surface = surface_create(_MaxX - _MinX, _MaxY - _MinY);
	surface_set_target(Sheet.Surface);
	draw_clear(c_black);
	surface_reset_target();
	Sheet.ShotIndex = 0;
	Sheet.Ready = false;
	for(var _RoomIndex = 0; _RoomIndex < global.Level.RoomCount; _RoomIndex++) Dungeon_RoomDeActivate(_RoomIndex);
	instance_activate_object(oLink);	// oCamera and oTest need him, even hidden
}

/// End Step: builds the next level or points the camera at the next shot
function Test_SheetStep(){
	if(Sheet.NextSeed){
		if(!Sheet.Activated){	// same as the "level" step: every room active before the next level is built
			Sheet.Activated = true;
			ActivateAll = true;
			exit;
		}
		Sheet.Activated = false;
		Sheet.NextSeed = false;
		Test_SheetNextSeed();
		exit;
	}
	if(Sheet.Ready){
		if(Sheet.Wait > 0) Sheet.Wait--;
		exit;
	}
	var _Shot = Sheet.Shots[Sheet.ShotIndex];
	var _RoomIndex = _Shot[0];
	if(_RoomIndex != global.CurrentRoomIndex){
		if(global.CurrentRoomIndex >= 0) Dungeon_RoomDeActivate(global.CurrentRoomIndex);
		Dungeon_RoomActivate(_RoomIndex);
		instance_activate_object(oLink);
		with(oCamera) SetCurrentRoom(_RoomIndex);
	}
	oCamera.X = _Shot[1];
	oCamera.Y = _Shot[2];
	Sheet.Wait = TEST_SHEET_WAIT;
	Sheet.Ready = true;
}

/// Post Draw: takes the shot once the camera has settled
function Test_SheetCapture(){
	if(!Sheet.Ready || Sheet.Wait > 0 || !surface_exists(Sheet.Surface)) exit;
	var _Shot = Sheet.Shots[Sheet.ShotIndex];
	Test_CaptureView(Sheet.Surface, _Shot[1] - Sheet.MinX, _Shot[2] - Sheet.MinY);
	Sheet.Ready = false;
	Sheet.ShotIndex++;
	if(Sheet.ShotIndex < array_length(Sheet.Shots)) exit;

	var _Name = "sheet_" + string(Sheet.Level) + "_" + string(Sheet.Seeds[Sheet.SeedIndex]) + ".png";
	surface_save(Sheet.Surface, TEST_OUT + _Name);
	Test_Log("shot " + _Name + " rooms=" + string(global.Level.RoomCount));
	array_push(Sheet.Done, Sheet.Surface);
	Sheet.Surface = -1;
	Sheet.NextSeed = true;
}

function Test_SheetFinish(){
	// All seeds side by side at half size
	var _Gap = 8;
	var _W = 0;
	var _H = 0;
	for(var i = 0; i < array_length(Sheet.Done); i++){
		_W += surface_get_width(Sheet.Done[i]) / 2 + _Gap;
		_H = max(_H, surface_get_height(Sheet.Done[i]) / 2);
	}
	var _All = surface_create(max(1, _W - _Gap), max(1, _H));
	surface_set_target(_All);
	draw_clear(c_dkgray);
	var _X = 0;
	for(var i = 0; i < array_length(Sheet.Done); i++){
		draw_surface_ext(Sheet.Done[i], _X, 0, 0.5, 0.5, 0, c_white, 1);
		_X += surface_get_width(Sheet.Done[i]) / 2 + _Gap;
		surface_free(Sheet.Done[i]);
	}
	surface_reset_target();
	var _Name = "sheet_" + string(Sheet.Level) + ".png";
	surface_save(_All, TEST_OUT + _Name);
	surface_free(_All);
	Test_Log("shot " + _Name + " seeds=" + string(array_length(Sheet.Done)));

	Sheet = undefined;
	global.Paused = false;
	oLink.visible = true;
	oCamera.Override = false;
	Link_SetStartingPos();
}

#endregion

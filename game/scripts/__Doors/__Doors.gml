enum DoorStatus{
	Open,
	Closed,
	Locked,
	Entrance,
	Exit,
	MainEntrance,
	ClosedHalf,
	LockedHalf,
	Secret_Closed,
	Secret_Open,
	Curtain,
	Unused
}

enum SecretDoor{
	Crack,
	Blank,
	Illusion	
}

enum OpenDoorSprite{
	LightCurrentLightNext,
	LightCurrentDarkNext,
	DarkCurrentLightNext,
	DarkCurrentDarkNext
}


#region Exit looks (roadmap F4b)

/// How exit doors look. The level sheet of the level an exit leads to names its look (ExitLook = "StairsDown"), so the
/// player can read where a stairway goes. A new look is a new entry here and a level pointing at it; the generator
/// does not change. Each look has:
///   Draw(_Door, _Tiles)	draws the door beam and the doorway of an exit oDoor (x, y, Location "Top" or "Bottom",
///							FloorLevel); _Tiles = {Decor, Beam, Y}: its decor and beam tilemaps and its tile row
///							(Door_DrawTiles draws the door sides)
///   Sound					played when Link goes through it
///   LinkAnim				Link's animation through it: global.LinkSpr_<LinkAnim>_Top1/_Bottom1 to leave by a stairway
///							in the top or bottom wall, _Top2/_Bottom2 to arrive at the next level (LinkSprites_Construct)
///   ArriveSound			played when Link arrives at the next level (oLink Alarm 9)
///   Entrance				[top, bottom] decor tile column of the doorway Link arrives through at the next level (oLink
///							End Step): the stairway of the other way, as in ALttP
///   MapIcon				its icon on the large map (with the compass)
function ExitLooks_Init(){
	global.ExitLooks = {
		// the usual exit
		StairsDown: {Draw: ExitLook_DrawStairsDown, Sound: Sound_StairsFloorDown, LinkAnim: "Descending", ArriveSound: Sound_StairsDown, Entrance: [58, 60], MapIcon: sLargeMap_Down},
		// the stairway a level's entrance shows; Link climbs it
		StairsUp: {Draw: ExitLook_DrawStairsUp, Sound: Sound_StairsUp, LinkAnim: "Ascending", ArriveSound: Sound_StairsUp, Entrance: [60, 58], MapIcon: sLargeMap_Down},
		// outdoor levels (OwnExitLooks, ArriveLook): the palace door of ALttP's area 0x1B in the top wall, painted with the
		// room (RegionGate). Link walks in as it opens (Leave) and out as it closes behind him (Arrive); at the next level
		// he arrives by the usual stairway (ArriveAnim, Entrance)
		Gate: {Draw: ExitLook_DrawPainted, Sound: Sound_DoorOpen, LinkAnim: "Walk", ArriveAnim: "Walk", ArriveSound: Sound_DoorOpen, Entrance: [58, 60], MapIcon: sLargeMap_Down, Leave: ExitLook_GateLeave, Arrive: ExitLook_GateArrive},
		// the stairs down out of the castle's front gate, painted in a bottom wall passage (an exit that cannot be a gate)
		GateStairs: {Draw: ExitLook_DrawPainted, Sound: Sound_StairsFloorDown, LinkAnim: "Descending", ArriveSound: Sound_StairsDown, Entrance: [58, 60], MapIcon: sLargeMap_Down}
	};
}

/// A look painted with the room (RegionGate): nothing to draw on the dungeon tile layers
function ExitLook_DrawPainted(_Door, _Tiles){
}

/// Link leaves through a gate (ExitLook.Leave, from the Descending state): he pushed it open already (RegionGate_Push)
function ExitLook_GateLeave(_DoorInst){
	RegionGate_Open(_DoorInst);
}

/// The exit gate opens in front of Link, as ALttP's palace door: half open, then open, and its doorway lets him in
function RegionGate_Open(_DoorInst){
	var _Room = _DoorInst.RoomIndex;
	var _X = _DoorInst.x - global.Level.Rooms[_Room].x;
	var _Y = _DoorInst.y - global.Level.Rooms[_Room].y;
	var _Gt = RegionGate_Get(_Room, _X, _Y);
	if(_Gt == undefined || _Gt[$ "Opening"] == true) return;
	_Gt.Opening = true;
	RegionGate_Frame(_Room, _X, _Y, 1);
	audio_play_sound(Sound_DoorOpen, 1, false);
	var _Ctx = {R : _Room, X : _X, Y : _Y, G : global.Level.Rooms[_Room].RegionGrid};
	call_later(8, time_source_units_frames, method(_Ctx, function(){
		if(!RegionGate_Same(R, G)) return;
		RegionGate_Frame(R, X, Y, 2);
		RegionGate_SetOpen(R, X, Y, true);
	}));
}

/// oDoor Step of an exit with a gate: Link facing it at its foot pushes it open; once it is open, he leaves as soon as
/// he is in its doorway (the stairs wait for him at the door cell, above it: through a gate he would cross the wall)
function RegionGate_Push(_DoorInst){
	if(!instance_exists(oLink) || global.Paused) return;
	var _Gt = RegionGate_Get(_DoorInst.RoomIndex, _DoorInst.x - global.Level.Rooms[_DoorInst.RoomIndex].x, _DoorInst.y - global.Level.Rooms[_DoorInst.RoomIndex].y);
	if(_Gt == undefined) return;
	var _DY = RegionGate_DY(_DoorInst);
	with(oLink){
		if(Facing != UP || (State != LinkState.Standing && State != LinkState.Walking && State != LinkState.Pushing)) return;
		if(abs(x - (_DoorInst.x + 16)) > 8 || y > _DoorInst.y + _DY + 58) return;
		if(!_Gt.Open){
			if(y >= _DoorInst.y + _DY + 40) RegionGate_Open(_DoorInst);
		}else if(y < _DoorInst.y + _DY + 44){
			Link_TakeExit(_DoorInst, TOP);
		}
	}
}

/// How far below a gate door's cell its doorway is (RegionGrid.GateDY; 16 where the room has no grid)
function RegionGate_DY(_DoorInst){
	var _G = global.Level.Rooms[_DoorInst.RoomIndex][$ "RegionGrid"];
	return (_G == undefined) ? 16 : _G.GateDY;
}

/// Where a secret door of a painted room shows its crack: the block of the face of the room's top wall in front of
/// the door cell (40 px down: below the roof's cream and the rivets), only when all of it is wall ("rachadura só em mureta", roadmap
/// F12b-2). The other walls of a painted room are a rim with the cream of the roof behind it, where a crack would lie
/// on the roof (R1, sixth round): their secret doors, and a top one with no face there, are a blank wall (undefined).
/// Px in the room.
function RegionRoom_CrackSpot(_DoorInst){
	var _R = global.Level.Rooms[_DoorInst.RoomIndex];
	var _G = _R[$ "RegionGrid"];
	if(_G == undefined || _DoorInst.Location != "Top") return undefined;
	var _PX = _DoorInst.x - _R.x + 8;
	var _PY = 40;
	_PX = _PX div 16 * 16;
	var _Solid = RegionTiles_Get(LevelDef.RegionTiles).solid;
	for(var t = 0; t < 4; t++){
		if(!RegionRoom_SolidAt(_G, _Solid, _PX div 8 + (t mod 2), _PY div 8 + (t div 2))) return undefined;
	}
	return [_PX, _PY];
}

/// Adds to _List the secret doors of painted rooms a blast at _X, _Y (radius _Radius, floor level _FloorLevel) reaches:
/// it has to touch the wall the door's passage opens (its open tiles), not the door cell. A painted room's walls are
/// thicker than a dungeon's (64 px on top, with the crack 40 px down), so a bomb at the wall's foot never reached the
/// 24 px mask of the door (R1, seventh round)
function RegionRoom_BlastDoors(_List, _X, _Y, _Radius, _FloorLevel){
	with(oDoor){
		if(Status == DoorStatus.Secret_Closed && ds_list_find_index(_List, id) == -1 && Collision_CheckFloorLevel(_FloorLevel, id)){
			var _R = global.Level.Rooms[RoomIndex];
			var _G = _R[$ "RegionGrid"];
			if(_G != undefined){
				var _DX = x - _R.x, _DY = y - _R.y;
				var _BX = _X - _R.x, _BY = _Y - _R.y;
				var _Hit = false;
				//the open tiles in the 64x64 box of the passage (RegionRoom_OpenPassage)
				for(var j = max(0, (_DY - 24) div 8); j < min(_G.H, (_DY + 56) div 8) && !_Hit; j++){
					for(var i = max(0, (_DX - 24) div 8); i < min(_G.W, (_DX + 56) div 8) && !_Hit; i++){
						if(_G.Open[j * _G.W + i] == 0) continue;
						_Hit = (point_distance(_BX, _BY, clamp(_BX, i * 8, i * 8 + 8), clamp(_BY, j * 8, j * 8 + 8)) <= _Radius);
					}
				}
				if(_Hit) ds_list_add(_List, id);
			}
		}
	}
}

#macro GATE_SHUT_FRAMES 64	// a gate Link arrives through shuts this long after the level is built: his stair frames and 24 walking

/// Link arrives through a gate: it is open, and shuts behind him once he has walked out (ExitLook.Arrive)
function ExitLook_GateArrive(_DoorInst){
	var _Room = _DoorInst.RoomIndex;
	var _X = _DoorInst.x - global.Level.Rooms[_Room].x;
	var _Y = _DoorInst.y - global.Level.Rooms[_Room].y;
	RegionGate_Frame(_Room, _X, _Y, 2);
	//the calls check that the room is still the one painted (Link may leave the level before they run)
	var _Ctx = {R : _Room, X : _X, Y : _Y, G : global.Level.Rooms[_Room].RegionGrid, D : _DoorInst};
	call_later(GATE_SHUT_FRAMES - 6, time_source_units_frames, method(_Ctx, function(){ if(RegionGate_Same(R, G)) RegionGate_Frame(R, X, Y, 1); }));
	call_later(GATE_SHUT_FRAMES, time_source_units_frames, method(_Ctx, function(){
		if(!RegionGate_Same(R, G)) return;
		RegionGate_Frame(R, X, Y, 0);
		RegionGate_SetOpen(R, X, Y, false);
		audio_play_sound(Sound_DoorClose, 1, false);
		//the way back is shut like a dungeon entrance behind Link (no dungeon door is drawn over a gate, Door_DrawTiles)
		if(instance_exists(D) && D.Status == DoorStatus.Entrance){
			D.Status = DoorStatus.Closed;
			D.UpdateStatus = true;
		}
	}));
}

/// Whether room _Room of the current level is still painted with grid _G (a delayed gate frame after a level change)
function RegionGate_Same(_Room, _G){
	return _Room < array_length(global.Level.Rooms) && global.Level.Rooms[_Room][$ "RegionGrid"] == _G;
}

function ExitLook_DrawStairsDown(_Door, _Tiles){
	with(_Door){
		if(Location == "Top"){
			DrawTileBlock(_Tiles.Beam, x, y, 58, _Tiles.Y, 4, 1);
			DrawTileBlock(_Tiles.Decor, x + 8, y + 8, 60, _Tiles.Y + 2, 2, 2);
		}else{
			DrawTileBlock(_Tiles.Beam, x, y + 16, 58, _Tiles.Y, 4, 1);
			DrawTileBlock(_Tiles.Decor, x + 8, y, 58, _Tiles.Y + 4, 2, 2);
		}
	}
}

/// The stairway Link comes down at the entrance of every level (oLink End Step), with an ordinary door beam
function ExitLook_DrawStairsUp(_Door, _Tiles){
	with(_Door){
		var _BeamX = 50 + (FloorLevel == LOWER ? 4 : 0);
		if(Location == "Top"){
			DrawTileBlock(_Tiles.Beam, x, y, _BeamX, _Tiles.Y, 4, 1);
			DrawTileBlock(_Tiles.Decor, x + 8, y + 8, 58, _Tiles.Y + 2, 2, 2);
		}else{
			DrawTileBlock(_Tiles.Beam, x, y + 16, _BeamX, _Tiles.Y + 1, 4, 1);
			DrawTileBlock(_Tiles.Decor, x + 8, y, 60, _Tiles.Y + 4, 2, 2);
		}
	}
}

/// Link's sprite going through an exit with look _Look: _Phase 1 leaving, 2 arriving; _Location TOP or BOTTOM, the wall
/// of the stairway
function ExitLook_LinkSprite(_Look, _Phase, _Location){
	var _Anim = (_Phase == 2) ? (_Look[$ "ArriveAnim"] ?? _Look.LinkAnim) : _Look.LinkAnim;
	//through a door Link just walks: in, facing the wall; out, facing away from it
	if(_Anim == "Walk") return ((_Location == TOP) == (_Phase == 1)) ? global.LinkSpr_Walk_Up : global.LinkSpr_Walk_Down;
	return variable_global_get("LinkSpr_" + _Anim + (_Location == TOP ? "_Top" : "_Bottom") + string(_Phase));
}

/// Level an exit door leads to
function Door_ExitDest(_DoorInst){
	if(global.SaveLevel) return Level_NextIndex();	//the rest stop leads where the exit taken before it led
	var _Doors = global.Level.Rooms[_DoorInst.RoomIndex].Doors;
	for(var i = 0; i < array_length(_Doors); i++){
		if(_Doors[i].Position == _DoorInst.Position && _Doors[i].ExitDest != -1) return _Doors[i].ExitDest;
	}
	return global.Level.Exits.Dest;
}

/// Look of an exit door: the ExitLook of the level it leads to, or the level's own look for that wall where the room
/// has it painted (OwnExitLooks: the gate out of the rooftops)
function Door_ExitLook(_DoorInst){
	if(LevelDef.OwnExitLooks != undefined && Door_HasGate(_DoorInst)){
		var _Own = global.ExitLooks[$ LevelDef.OwnExitLooks[$ _DoorInst.Location] ?? ""];
		if(_Own != undefined) return _Own;
	}
	var _Def = Level_Get(Door_ExitDest(_DoorInst));
	var _Look = (_Def == undefined) ? undefined : global.ExitLooks[$ _Def.ExitLook];
	return _Look ?? global.ExitLooks.StairsDown;
}

/// Whether a door instance has the gate of its painted room (RegionRoom_Paint keeps the doors that took one)
function Door_HasGate(_DoorInst){
	var _R = global.Level.Rooms[_DoorInst.RoomIndex];
	var _G = _R[$ "RegionGrid"];
	if(_G == undefined) return false;
	for(var g = 0; g < array_length(_G.Gates); g++){
		if(_G.Gates[g].X == _DoorInst.x - _R.x && _G.Gates[g].Y == _DoorInst.y - _R.y) return true;
	}
	return false;
}

#endregion

function Dungeon_CreateDoors(_RoomIndex){

	if(LevelDef.Special == LevelSpecial.Intro) exit;
	
	
	//To draw sprite of all doors for oMapRoom
	var DoorsSprSurface = surface_create(Room.width / 8, Room.height / 8);
	surface_set_target(DoorsSprSurface);
	draw_clear_alpha(c_black, 0);
	
	var TMID_Walls, WallObjInst, WallX, WallY, WallGID, ScaleX, ScaleY, Position, Dx, Dy, Dw, Dh;
	for(var DoorIndex = 0; DoorIndex < Room.DoorCount; DoorIndex++){
		
		//var DungeonDoor = DungeonRoom.Doors[DoorIndex];
		var _Door = Room.Doors[DoorIndex];
		
		if(_Door.Status == DoorStatus.Unused){
			continue;
		}
		
		var TLCornerX = Room.x + _Door.x;
		var TLCornerY = Room.y + _Door.y;

		var FloorLevelStr = GetFloorLevelString(_Door.Level);
		
		var _DoorInst = instance_create_layer(TLCornerX, TLCornerY, "ObjsDoors_" + FloorLevelStr, oDoor);
		_DoorInst.RoomIndex = _RoomIndex;
		_DoorInst.FloorLevel = _Door.Level;		
		_DoorInst.Location = _Door.Location;
		_DoorInst.Position = _Door.Position;
		_DoorInst.Status = _Door.Status;
		
		
		if(_DoorInst.Status == DoorStatus.Entrance) _DoorInst.Entrance = true;
		_DoorInst.ConnectedRoomIndex = _Door.ConnectedRoomIndex;
		

		if(_DoorInst.Status == DoorStatus.Secret_Closed){
			
			//Secret door types for specific cases/levels
			_DoorInst.SecretType = LevelDef.SecretDoorType;
			
			if(	TemplateCheck(_DoorInst.ConnectedRoomIndex, RoomTemplateClass.Other, RoomTemplateClass_Other.Unique, "TMNT") || 
				TemplateCheck(_RoomIndex, RoomTemplateClass.Other, RoomTemplateClass_Other.Unique, "TMNT")){
					_DoorInst.SecretType = SecretDoor.Crack;
			}

			if(_DoorInst.SecretType == -1){
				
				if(TemplateCheck(_DoorInst.ConnectedRoomIndex, RoomTemplateClass.Special, RoomTemplateClass_Special.TreasureLarge) || 
					TemplateCheck(_RoomIndex, RoomTemplateClass.Special, RoomTemplateClass_Special.TreasureLarge)){
						_DoorInst.SecretType = choose(SecretDoor.Blank, SecretDoor.Illusion);
				}else{
					_DoorInst.SecretType = Prob(Chance_SecretDoorCrack) ? SecretDoor.Crack : choose(SecretDoor.Blank, SecretDoor.Illusion);
				}

			}

			//the secret room of an extra exit always opens with a bomb, never walking through an illusion (roadmap F4b)
			var _ExitRoom = global.Level.Exits.ExtraSecret ? global.Level.Exits.ExtraRoom : -1;
			if(_DoorInst.SecretType == SecretDoor.Illusion && _ExitRoom != -1 && (_RoomIndex == _ExitRoom || _DoorInst.ConnectedRoomIndex == _ExitRoom)){
				_DoorInst.SecretType = SecretDoor.Crack;
			}

		}
		
		if(LevelDef.Special == LevelSpecial.Mines){
			if(	global.MainTemplates_Mine[Room.GridY][Room.GridX] == 1 || global.MainTemplates_Mine[Room.GridY][Room.GridX] >= 7){
				_DoorInst.Status = DoorStatus.Secret_Closed;
				_DoorInst.SecretType = SecretDoor.Blank;
			}
		}
		
		//If we're on a boss level, make the inside doors of the boss Room closed. Otherwise, the outside doors of the boss Room are turned into stairwells, bypassing the boss Room
		if(global.Level.IsBossLevel && _RoomIndex == global.Level.RoomIndex_Boss){
			_DoorInst.Status = DoorStatus.Closed; //close all doors if we're in the boss Room
		}	
		
		if(_DoorInst.Status == DoorStatus.Locked || _DoorInst.Status == DoorStatus.Exit) ds_list_add(global.LargeMapItems, _DoorInst); //certain doors to large map items so we can draw the icon if Link has a compass

		//Clear walls for pathway

		if(_DoorInst.FloorLevel == UPPER){
			//var TMID_Floors_Common = global.TMID2_Upper;
			TMID_Walls = global.TMID_Walls_Upper;	
			var TMID_Decor = global.TMID_Decor_Upper;
		}else{
			//var TMID_Floors_Common = global.TMID2_Lower;
			TMID_Walls = global.TMID_Walls_Lower;
			var TMID_Decor = global.TMID_Decor_Lower;
		}

		//a painted room's walls already leave the passage open (RegionRoom_Paint)
		if(!RegionRoom_Is(_RoomIndex)) switch(_DoorInst.Location){
			case "Top":
				if(LevelDef.Special == LevelSpecial.FinalBoss){
					//clear larger area for the large door frames
					ClearTileBlock(TMID_Walls, TLCornerX, TLCornerY - 16, 4, 5);
					//draw back ceiling on top left/right corners
					//DrawTileBlock(global.TMID_Tiles_Ceiling, TLCornerX, TLCornerY, 8, LevelTilesY + 2, 1, 1);
					//DrawTileBlock(global.TMID_Tiles_Ceiling, TLCornerX + 24, TLCornerY, 8, LevelTilesY + 2, 1, 1);
				}else
					ClearTileBlock(TMID_Walls, TLCornerX + 8, TLCornerY + 8, 2, 2);

				WallObjInst = collision_point(TLCornerX + 4, TLCornerY + 4, oWall, false, true);
				if(WallObjInst != noone) WallObj_Cutout_H(WallObjInst, TLCornerX + 8, TLCornerX + 23);
				
				break;
				
			case "Bottom":	
				ClearTileBlock(TMID_Walls, TLCornerX + 8, TLCornerY, 2, 2);
				
				WallObjInst = collision_point(TLCornerX + 4, TLCornerY + 4, oWall, false, true);
				if(WallObjInst != noone) WallObj_Cutout_H(WallObjInst, TLCornerX + 8, TLCornerX + 23);

				break;
		
			case "Left":
			case "Right":
				ClearTileBlock(TMID_Walls, TLCornerX + (_DoorInst.Location == "Left" ? 8 : 0), TLCornerY + 8, 2, 2);
				WallObjInst = collision_point(TLCornerX + 4, TLCornerY + 4, oWall, false, true);
				if(WallObjInst != noone) WallObj_Cutout_V(WallObjInst, TLCornerY + 8, TLCornerY + 23);
				break;
		}
		
		Door_SetPassageArea(_DoorInst);
	
		//Place an enemy door blocker at every door to prevent enemies from going through them
		switch(_DoorInst.Location){
			case "Top":
				WallX = TLCornerX + 8;
				WallY = TLCornerY;
				WallGID = _DoorInst.FloorLevel == UPPER ? TemplateObjGID.WallSideT : TemplateObjGID.WallLowerSideT;
				ScaleX = 2;
				ScaleY = 3;
				Position = TOP;
				break;
				
			case "Left":
				WallX = TLCornerX;
				WallY = TLCornerY + 8;
				WallGID = _DoorInst.FloorLevel == UPPER ? TemplateObjGID.WallSideL : TemplateObjGID.WallLowerSideL;
				ScaleX = 3;
				ScaleY = 2;
				Position = LEFT;
				break;
			
			case "Bottom":
				WallX = TLCornerX + 8;
				WallY = TLCornerY;
				WallGID = _DoorInst.FloorLevel == UPPER ? TemplateObjGID.WallSideB : TemplateObjGID.WallLowerSideB;
				ScaleX = 2;
				ScaleY = 3;
				Position = BOTTOM;
				break;
			
			case "Right":
				WallX = TLCornerX;
				WallY = TLCornerY + 8;
				WallGID = _DoorInst.FloorLevel == UPPER ? TemplateObjGID.WallSideR : TemplateObjGID.WallLowerSideR;
				ScaleX = 3;
				ScaleY = 2;
				Position = RIGHT;
				break;
			
		}
		//a painted room has no door frame beside the blocker: it covers the whole 32 px of the door cell, so a lock
		//closes all of the passage (RegionRoom_OffLane walls the room's edge beside the door cell)
		if(global.Level.Rooms[_RoomIndex].Template[$ "Region"] != undefined){
			if(Position == TOP || Position == BOTTOM){
				WallX = TLCornerX;
				ScaleX = 4;
			}else{
				WallY = TLCornerY;
				ScaleY = 4;
			}
		}
		var inst = WallObj_Create("Objs_" + FloorLevelStr, WallX, WallY, ScaleX, ScaleY, _DoorInst.Location, WallGID);
		inst.FloorLevel = _DoorInst.FloorLevel;
		inst.BlockLink = false;
		inst.BlockLinkCarry = (_DoorInst.Status == DoorStatus.Exit);
		inst.BlockItems = true;
		inst.IsDoorEntrance = true;
		inst.Position = Position;
		_DoorInst.WallInst = inst;
		

		//Draw Map Doors onto MapRoomInst spr
		if(_DoorInst.SecretType != -1) continue; //don't draw the door on the map if it connects to a secret Room
		
		if(LevelDef.Special == LevelSpecial.Mines){
			if(Room.GridX == 4 && Room.GridY == 4 && _DoorInst.Location != "Top" && _DoorInst.Location != "Right") continue; //secret doors in the mine caves entrance
			if(Room.GridX == 6 && Room.GridY == 0 && _DoorInst.Location == "Left") continue; //secret door at the entrance to the treasure map
		}
		
		var MapDoorX = (TLCornerX - Room.x) / 8;
		var MapDoorY = (TLCornerY - Room.y) / 8;
		switch(_DoorInst.Location){
			case "Top":
				Dx = MapDoorX;	Dy = MapDoorY - 5; Dw = 4; Dh = 8;
				break;
			case "Bottom":
				Dx = MapDoorX;	Dy = MapDoorY; Dw = 4; Dh = 8;
				break;
			case "Left":
				Dx = MapDoorX - 5;	Dy = MapDoorY; Dw = 8; Dh = 4;
				break;
			case "Right":
				Dx = MapDoorX;	Dy = MapDoorY; Dw = 8; Dh = 4;
				break;
		}
						
		draw_sprite_ext(sPixel, 0, Dx, Dy, Dw, Dh, 0, make_color_rgb(110,110,110), 1);
		
	}
	
	surface_reset_target();
	
	Room.MapSpr_Doors = sprite_create_from_surface(DoorsSprSurface, 0, 0, Room.MapW, Room.MapH, false, false, 0, 0);	
		
	surface_free(DoorsSprSurface);
		
			
}

function Door_DrawTiles(Inst){

	
	with(Inst){
		
		var TMID_Decor = (FloorLevel == UPPER ? global.TMID_Decor_Upper : global.TMID_Decor_Lower);
		var TMID_Walls = (FloorLevel == UPPER ? global.TMID_Walls_Upper : global.TMID_Walls_Lower);
		var TMID_Floor = (FloorLevel == UPPER ? global.TMID_Floor_Upper : global.TMID_Floor_Lower);
		var WallLevel = (FloorLevel == UPPER ? 0 : 1);
		var TilesY = global.Level.Rooms[RoomIndex].ForcedTheme != -1 && global.Level.Rooms[RoomIndex].ForcedTheme <= 11 ? 4 + (global.Level.Rooms[RoomIndex].ForcedTheme * 6) : LevelTilesY_Base;
		var TMID_Beam = (FloorLevel == UPPER ? global.TMID_Tiles_Highest : global.TMID_Walls_Upper);
		
		//outdoor levels (roadmap F12b): no dungeon doors in a painted room (a room of the shared templates keeps them,
		//since its walls are the dungeon's). An open door is the passage it leaves in the walls; a locked one is that
		//passage with the key blocks in it (oDoor Draw); a secret one is the wall, cracked or not, until it is bombed;
		//the entrance and the exit are the gate painted with the room (RegionGate)
		if(LevelDef.Layout == LevelLayout.Outdoor && RegionRoom_Is(RoomIndex)){
			var _Painted = false;
			switch(Status){
				case DoorStatus.Open:
				case DoorStatus.Curtain:
				case DoorStatus.Locked:
				case DoorStatus.LockedHalf:
				case DoorStatus.Secret_Open:
					_Painted = true;
					break;
				case DoorStatus.Entrance:
				case DoorStatus.Exit:
				case DoorStatus.Closed:			//the entrance once its gate has shut behind Link (ExitLook_GateArrive)
				case DoorStatus.ClosedHalf:
					_Painted = Door_HasGate(id);
					break;
				case DoorStatus.Secret_Closed:
					_Painted = true;
					ClearTileBlock(TMID_Decor, x, y, 4, 4);
					ClearTileBlock(TMID_Beam, x, y, 4, 4);
					if(SecretType == SecretDoor.Crack){
						//on the block of the border in front of the door, only where it is all wall
						var _Spot = RegionRoom_CrackSpot(id);
						if(_Spot != undefined) DrawTileBlock(TMID_Decor, global.Level.Rooms[RoomIndex].x + _Spot[0], global.Level.Rooms[RoomIndex].y + _Spot[1], 94, TilesY + 4, 2, 2);
					}
					exit;
			}
			if(_Painted){
				ClearTileBlock(TMID_Decor, x, y, 4, 4);
				ClearTileBlock(TMID_Beam, x, y, 4, 4);
				exit;
			}
		}
		
		switch(Location){
		
			case "Top":

				//draw boss Room entrance
				if(!global.SaveLevel && (global.Level.IsBossLevel && LevelDef.Special != LevelSpecial.FinalBoss) && ConnectedRoomIndex == global.Level.RoomIndex_Boss){ 
					

					DrawTileBlock(TMID_Floor, x, y + 32, 52, 2, 2, 2);
					DrawTileBlock(TMID_Floor, x + 16, y + 32, 52, 2, 2, 2);
					DrawTileBlock(TMID_Floor, x, y + 48, 52, 2, 2, 2);
					DrawTileBlock(TMID_Floor, x + 16, y + 48, 52, 2, 2, 2);
					DrawTileBlock(TMID_Floor, x - 16, y + 32, 52, 2, 2, 2);
					DrawTileBlock(TMID_Floor, x - 16, y + 48, 52, 2, 2, 2);
					DrawTileBlock(TMID_Floor, x + 32, y + 32, 52, 2, 2, 2);
					DrawTileBlock(TMID_Floor, x + 32, y + 48, 52, 2, 2, 2);						

					//Skull emblem
					DrawTileBlock(TMID_Decor, x, y + 40, 52, 0, 4, 2);
						
					//add door frames
					var TileX = LevelDef.BossDoorFrame;
					DrawTileBlock(TMID_Decor, x - 16, y, TileX, 0, 2, 4);		
					DrawTileBlock(TMID_Decor, x + 32, y, TileX + 2, 0, 2, 4);	
						
				}
				
				if(Status != DoorStatus.Secret_Closed && Status != DoorStatus.Secret_Open){

					//Sides
					DrawTileBlock(TMID_Decor, x, y + 8, 70, TilesY, 1, 2);
					DrawTileBlock(TMID_Decor, x + 24, y + 8, 71, TilesY, 1, 2);
					
					//Door beam
					switch(Status){
						case DoorStatus.Exit:
							break; //drawn by the exit look, below
						default:
							if(RoomIndex == global.Level.RoomIndex_Boss){
								DrawTileBlock(TMID_Decor, x, y, 50 + (FloorLevel == LOWER ? 4 : 0), TilesY, 4, 1); //because bosses jump higher and the beams are above them. Link doesn't go through these doors anyways
							}else{
								DrawTileBlock(TMID_Beam, x, y, 50 + (FloorLevel == LOWER ? 4 : 0), TilesY, 4, 1);
							}
					}
				

				}
				
				switch(Status){
		
					case DoorStatus.Open:
					case DoorStatus.Curtain:
						if(AddTracks){ //for mine level only
							DrawTileBlock(TMID_Decor, x + 8, y + 8, 128, VillageTilesY, 2, 2); break;
						}else{
							switch(LightingFrame){
								case OpenDoorSprite.LightCurrentLightNext:
								case OpenDoorSprite.DarkCurrentLightNext:
									DrawTileBlock(TMID_Decor, x + 8, y + 8, 72, 2, 2, 2); break;
								case OpenDoorSprite.LightCurrentDarkNext: DrawTileBlock(TMID_Decor, x + 8, y + 8, 70, 0, 2, 2); break;							
								case OpenDoorSprite.DarkCurrentDarkNext: DrawTileBlock(TMID_Decor, x + 8, y + 8, 74, TilesY, 2, 2); break;
							}
						}
						break;

					case DoorStatus.Closed:
						DrawTileBlock(TMID_Decor, x, y + 8, 70, TilesY + 4, 4, 2);
						break;
					
					case DoorStatus.ClosedHalf:
						DrawTileBlock(TMID_Decor, x, y + 8, 74, TilesY + 4, 4, 2);
						break;

					case DoorStatus.Locked:
						DrawTileBlock(TMID_Decor, x, y + 8, 86, TilesY, 4, 2);
						break;

					case DoorStatus.LockedHalf:
						DrawTileBlock(TMID_Decor, x, y + 8, 86, TilesY + 2, 4, 2);
						break;

					case DoorStatus.Secret_Closed:
						
						switch(Inst.SecretType){
							case SecretDoor.Crack:
						
								//Draw back wall
								DrawTileBlock(TMID_Walls, x + 8, y, 6 + (WallLevel * 17), TilesY, 2, 3); 
								
								//Crack
								DrawTileBlock(TMID_Decor, x + 8, y + 8, 94, TilesY + 4, 2, 2);
								break;
							
							case SecretDoor.Blank:
								//draw back wall
								DrawTileBlock(TMID_Walls, x + 8, y, 6 + (WallLevel * 17), TilesY, 2, 3); 
								break;
								
						}
						break;

					case DoorStatus.Secret_Open:
						
						switch(Inst.SecretType){
							case SecretDoor.Blank:
							case SecretDoor.Crack:

								ClearTileBlock(TMID_Walls, x + 8, y + 8, 2, 2);
								ClearTileBlock(TMID_Decor, x + 8, y + 8, 2, 2);
								
								switch(Inst.FloorLevel){
									case UPPER:

										//Sides
										DrawTileBlock(TMID_Decor, x, y + 8, 98, TilesY, 1, 2);
										DrawTileBlock(TMID_Decor, x + 24, y + 8, 99, TilesY, 1, 2);

										//Top
										DrawTileBlock(TMID_Beam, x, y, 62, TilesY + 4, 4, 1);

										break;
										
									case LOWER:
								
										//Sides
										DrawTileBlock(TMID_Decor, x, y + 8, 102, TilesY, 1, 2);
										DrawTileBlock(TMID_Decor, x + 24, y + 8, 103, TilesY, 1, 2);

										//Top
										DrawTileBlock(TMID_Beam, x, y, 66, TilesY + 4, 4, 1);
										
										break;
						
								}

								switch(LightingFrame){
									case OpenDoorSprite.LightCurrentLightNext:
									case OpenDoorSprite.DarkCurrentLightNext:
										DrawTileBlock(TMID_Decor, x + 8, y + 8, 72, 2, 2, 2); break;
									case OpenDoorSprite.LightCurrentDarkNext: DrawTileBlock(TMID_Decor, x + 8, y + 8, 70, 0, 2, 2); break;							
									case OpenDoorSprite.DarkCurrentDarkNext: DrawTileBlock(TMID_Decor, x + 8, y + 8, 106, TilesY, 2, 2); break;
								}
								break;
							
							case SecretDoor.Illusion:
								//Draw back wall
								for(var i = 0; i < 4; i++){
									var _x = x + (i * 8);
									var _TileX =  6 + (_x mod 16 == 0 ? 1 : 0) + (WallLevel * 17);
									DrawTileBlock(TMID_Beam, _x, y, _TileX, TilesY, 1, 1); 
									DrawTileBlock(TMID_Walls, _x, y + 8, _TileX, TilesY + 1, 1, 2); 
								}
								break;
						}
						break;
						
					case DoorStatus.Exit:
						Door_ExitLook(Inst).Draw(Inst, {Decor: TMID_Decor, Beam: TMID_Beam, Y: TilesY});
						break;

					
				}
				
				break;
		
			case "Bottom":
				
				if(Status == DoorStatus.Entrance && LevelDef.RunStart && !global.HubLevel){
					
					//draw entrance
					
					//floor
					DrawTileBlock(TMID_Floor, x + 8, y, 63, 1, 2, 2);
					
					//Sides
					DrawTileBlock(TMID_Decor, x, y, 62, 1, 1, 2);
					DrawTileBlock(TMID_Decor, x + 24, y, 65, 1, 1, 2);
					
					//top
					DrawTileBlock(TMID_Beam, x + 8, y + 16, 9, 8, 2, 1);
					
					oLink.Castle_EntranceWallInst = WallObj_Create("Objs_Upper", x, y + 24, 4, 2);
					oLink.Castle_EntranceWallInst.IsDoorEntrance = true;
					
						
				}else{

					if(Status != DoorStatus.Secret_Closed && Status != DoorStatus.Secret_Open){
						//Door beam
						switch(Status){
							case DoorStatus.Exit:
								break; //drawn by the exit look, below
							default:
								DrawTileBlock(TMID_Beam, x, y + 16, 50 + (FloorLevel == LOWER ? 4 : 0), TilesY + 1 , 4, 1);
						}	
				
						//Sides
						DrawTileBlock(TMID_Decor, x, y, 72, TilesY + 2, 1, 2);
						DrawTileBlock(TMID_Decor, x + 24, y, 73, TilesY + 2, 1, 2);
					}
				
					switch(Status){
		
						case DoorStatus.Open:
						case DoorStatus.Curtain:
							if(AddTracks){ //for mine level only
								DrawTileBlock(TMID_Decor, x + 8, y, 130, VillageTilesY + 2, 2, 2); break;
							}else{
								switch(LightingFrame){
									case OpenDoorSprite.LightCurrentLightNext: 
									case OpenDoorSprite.DarkCurrentLightNext:
										DrawTileBlock(TMID_Decor, x + 8, y, 70, 0, 2, 2); break;
									case OpenDoorSprite.LightCurrentDarkNext: DrawTileBlock(TMID_Decor, x + 8, y, 72, 2, 2, 2); break;
									case OpenDoorSprite.DarkCurrentDarkNext: DrawTileBlock(TMID_Decor, x + 8, y, 76, TilesY + 2, 2, 2); break;
								}
							}
							break;

						case DoorStatus.Closed:
							DrawTileBlock(TMID_Decor, x, y, 78, TilesY + 4, 4, 2);
							break;
					
						case DoorStatus.ClosedHalf:
							DrawTileBlock(TMID_Decor, x, y, 82, TilesY + 4, 4, 2);
							break;

						case DoorStatus.Locked:
							DrawTileBlock(TMID_Decor, x, y, 86, TilesY + 4, 4, 2);
							break;

						case DoorStatus.LockedHalf:
							DrawTileBlock(TMID_Decor, x, y, 90, TilesY + 4, 4, 2);
							break;

						case DoorStatus.Secret_Closed:
						
							switch(Inst.SecretType){
								case SecretDoor.Crack:
						
									//draw back wall
									DrawTileBlock(TMID_Walls, x + 8, y, 9 + (WallLevel * 17), TilesY + 2, 2, 3); 
								
									//Crack
									DrawTileBlock(TMID_Decor, x + 8, y, 96, TilesY + 4, 2, 2);
								
									break;
							
								case SecretDoor.Blank:
									//draw back wall
									DrawTileBlock(TMID_Walls, x + 8, y, 9 + (WallLevel * 17), TilesY + 2, 2, 3); 
									break;
							}
						break;

					case DoorStatus.Secret_Open:
						
						switch(Inst.SecretType){
							case SecretDoor.Blank:
							case SecretDoor.Crack:
						
								ClearTileBlock(TMID_Walls, x + 8, y, 2, 2);
								ClearTileBlock(TMID_Decor, x + 8, y, 2, 2);


								switch(Inst.FloorLevel){
									case UPPER:

										//Sides
										DrawTileBlock(TMID_Decor, x, y, 100, TilesY + 2, 1, 2);
										DrawTileBlock(TMID_Decor, x + 24, y, 101, TilesY + 2, 1, 2);
						
										//Top
										DrawTileBlock(TMID_Beam, x, y + 16, 62, TilesY + 5, 4, 1);
								
										break;
										
									case LOWER:
								
										//Sides
										DrawTileBlock(TMID_Decor, x, y, 104, TilesY + 2, 1, 2);
										DrawTileBlock(TMID_Decor, x + 24, y, 105, TilesY + 2, 1, 2);
						
										//Top
										DrawTileBlock(TMID_Beam, x, y + 16, 66, TilesY + 5, 4, 1);
										
										break;
						
								}
								


								switch(LightingFrame){
									case OpenDoorSprite.LightCurrentLightNext:
									case OpenDoorSprite.DarkCurrentLightNext:
										DrawTileBlock(TMID_Decor, x + 8, y, 70, 0, 2, 2); break;
									case OpenDoorSprite.LightCurrentDarkNext: DrawTileBlock(TMID_Decor, x + 8, y, 72, 2, 2, 2); break;							
									case OpenDoorSprite.DarkCurrentDarkNext: DrawTileBlock(TMID_Decor, x + 8, y, 108, TilesY + 2, 2, 2); break;
								}
								break;
							
							case SecretDoor.Illusion:
								//draw back wall
								for(var i = 0; i < 4; i++){
									var _x = x + (i * 8);
									var _TileX =  9 + (_x mod 16 == 0 ? 1 : 0) + (WallLevel * 17);
									DrawTileBlock(TMID_Walls, _x, y, _TileX, TilesY + 2, 1, 2); 
									DrawTileBlock(TMID_Beam, _x, y + 16, _TileX, TilesY + 4, 1, 1); 
								}
								
								break;
						}
						break;
						
						case DoorStatus.Exit:
							Door_ExitLook(Inst).Draw(Inst, {Decor: TMID_Decor, Beam: TMID_Beam, Y: TilesY});
							break;

					
					}
				}
						
				break;
		
			case "Left":

				if(Status != DoorStatus.Secret_Closed && Status != DoorStatus.Secret_Open){
						
					//Door beam
					DrawTileBlock(TMID_Beam, x, y, 62 + (FloorLevel == LOWER ? 2 : 0), TilesY, 1, 4);
				
					//Sides
					DrawTileBlock(TMID_Decor, x + 8, y, 70, TilesY + 2, 2, 1);
					DrawTileBlock(TMID_Decor, x + 8, y + 24, 70, TilesY + 3, 2, 1);
					
				}
				
				switch(Status){
		
					case DoorStatus.Open:
					case DoorStatus.Curtain:
						if(AddTracks){ //for mine level only
							DrawTileBlock(TMID_Decor, x + 8, y + 8, 128, VillageTilesY + 2, 2, 2); break;
						}else{
							switch(LightingFrame){
								case OpenDoorSprite.LightCurrentLightNext: 
								case OpenDoorSprite.DarkCurrentLightNext:
									DrawTileBlock(TMID_Decor, x + 8, y + 8, 72, 0, 2, 2); break;
								case OpenDoorSprite.LightCurrentDarkNext: DrawTileBlock(TMID_Decor, x + 8, y + 8, 70, 2, 2, 2); break;
								case OpenDoorSprite.DarkCurrentDarkNext: DrawTileBlock(TMID_Decor, x + 8, y + 8, 74, TilesY + 2, 2, 2); break;
							}
						}
						break;

					case DoorStatus.Closed:
						DrawTileBlock(TMID_Decor, x + 8, y, 78, TilesY, 2, 4);
						break;
					
					case DoorStatus.ClosedHalf:
						DrawTileBlock(TMID_Decor, x + 8, y, 80, TilesY, 2, 4);
						break;

					case DoorStatus.Locked:
						DrawTileBlock(TMID_Decor, x + 8, y, 90, TilesY, 2, 4);
						break;

					case DoorStatus.LockedHalf:
						DrawTileBlock(TMID_Decor, x + 8, y, 92, TilesY, 2, 4);
						break;

					case DoorStatus.Secret_Closed:
						
						switch(Inst.SecretType){
							case SecretDoor.Crack:
						
								//draw back wall
								DrawTileBlock(TMID_Walls, x, y + 8, 6 + (WallLevel * 17), TilesY + 3, 3, 2);  
								
								//Crack
								DrawTileBlock(TMID_Decor, x + 8, y + 8, 98, TilesY + 4, 2, 2);
								break;
								
							case SecretDoor.Blank:
								//draw back wall
								DrawTileBlock(TMID_Walls, x, y + 8, 6 + (WallLevel * 17), TilesY + 3, 3, 2);  

								break;
								
						}
						break;

					case DoorStatus.Secret_Open:
						
						switch(Inst.SecretType){
							case SecretDoor.Blank:
							case SecretDoor.Crack:
						
								ClearTileBlock(TMID_Walls, x + 8, y + 8, 2, 2);
								ClearTileBlock(TMID_Decor, x + 8, y + 8, 2, 2);

								switch(Inst.FloorLevel){
									case UPPER:

										//Sides
										DrawTileBlock(TMID_Decor, x + 8, y, 98, TilesY + 2, 2, 1);
										DrawTileBlock(TMID_Decor, x + 8, y + 24, 98, TilesY + 3, 2, 1);
						
										//Top
										DrawTileBlock(TMID_Beam, x, y, 66, TilesY, 1, 4);
								
										break;
										
									case LOWER:
								
										//Sides
										DrawTileBlock(TMID_Decor, x + 8, y, 102, TilesY + 2, 2, 1);
										DrawTileBlock(TMID_Decor, x + 8, y + 24, 102, TilesY + 3, 2, 1);
						
										//Top
										DrawTileBlock(TMID_Beam, x, y, 68, TilesY, 1, 4);
										
										break;
						
								}

								switch(LightingFrame){
									case OpenDoorSprite.LightCurrentLightNext:
									case OpenDoorSprite.DarkCurrentLightNext:
										DrawTileBlock(TMID_Decor, x + 8, y + 8, 72, 0, 2, 2); break;
									case OpenDoorSprite.LightCurrentDarkNext: DrawTileBlock(TMID_Decor, x + 8, y + 8, 70, 2, 2, 2); break;							
									case OpenDoorSprite.DarkCurrentDarkNext: DrawTileBlock(TMID_Decor, x + 8, y + 8, 106, TilesY + 2, 2, 2); break;
								}
								break;
							
							case SecretDoor.Illusion:
								//draw back wall								
								for(var i = 0; i < 4; i++){
									var _y = y + (i * 8);
									var _TileY =  TilesY + 3 + (_y mod 16 == 0 ? 1 : 0);
									DrawTileBlock(TMID_Beam, x, _y, 6 + (WallLevel * 17), _TileY, 1, 1); 									
								}
								for(var i = 0; i < 2; i++){
									var _y = y + 8 + (i * 8);
									var _TileY =  TilesY + 3 + (_y mod 16 == 0 ? 1 : 0);
									DrawTileBlock(TMID_Walls, x + 8, _y, 7 + (WallLevel * 17), _TileY, 2, 1); 
								}
								
								break;

						}
						break;
						

				}
				
				//draw back ceilings above to cover any items Link is carrying while walking through
				for(var i = 0; i < 2; i++){
					var _TileY = y - 16 + (i * 8);
					DrawTileBlock(TMID_Beam, x, _TileY, 6 + (WallLevel * 17), TilesY + 3 + (_TileY mod 16 == 0 ? 1 : 0), 1, 1);  
				}
				
				break;
		
			case "Right":

				if(Status != DoorStatus.Secret_Closed && Status != DoorStatus.Secret_Open){
					
					//Door beam
					DrawTileBlock(TMID_Beam, x + 16, y,  63 + (FloorLevel == LOWER ? 2 : 0), TilesY, 1, 4);
				
					//Sides
					DrawTileBlock(TMID_Decor, x, y, 72, TilesY, 2, 1);
					DrawTileBlock(TMID_Decor, x, y + 24, 72, TilesY + 1, 2, 1);
				
				}
				
				switch(Status){
		
					case DoorStatus.Open:
					case DoorStatus.Curtain:
						if(AddTracks){ //for mine level only
							DrawTileBlock(TMID_Decor, x, y + 8, 130, VillageTilesY, 2, 2); break;
						}else{
							switch(LightingFrame){
								case OpenDoorSprite.LightCurrentLightNext: 
								case OpenDoorSprite.DarkCurrentLightNext:
									DrawTileBlock(TMID_Decor, x, y + 8, 70, 2, 2, 2); break;
								case OpenDoorSprite.LightCurrentDarkNext: DrawTileBlock(TMID_Decor, x, y + 8, 72, 0, 2, 2); break;
								case OpenDoorSprite.DarkCurrentDarkNext: DrawTileBlock(TMID_Decor, x, y + 8, 76, TilesY, 2, 2); break;
							}
						}
						break;

					case DoorStatus.Closed:
						DrawTileBlock(TMID_Decor, x, y, 82, TilesY, 2, 4);
						break;
					
					case DoorStatus.ClosedHalf:
						DrawTileBlock(TMID_Decor, x, y, 84, TilesY, 2, 4);
						break;

					case DoorStatus.Locked:
						DrawTileBlock(TMID_Decor, x, y, 94, TilesY, 2, 4);
						break;

					case DoorStatus.LockedHalf:
						DrawTileBlock(TMID_Decor, x, y, 96, TilesY, 2, 4);
						break;

					case DoorStatus.Secret_Closed:
						
						switch(Inst.SecretType){
							case SecretDoor.Crack:
						
								//draw back wall
								DrawTileBlock(TMID_Walls, x, y + 8, 8 + (WallLevel * 17), TilesY, 3, 2); 
								
								//Crack
								DrawTileBlock(TMID_Decor, x, y + 8, 100, TilesY + 4, 2, 2);
								break;
								
							case SecretDoor.Blank:
								//draw back wall
								DrawTileBlock(TMID_Walls, x, y + 8, 8 + (WallLevel * 17), TilesY, 3, 2); 	
								break;
								
															
						}
						break;

					case DoorStatus.Secret_Open:
						
						switch(Inst.SecretType){
							case SecretDoor.Blank:
							case SecretDoor.Crack:
						
								ClearTileBlock(TMID_Walls, x, y + 8, 2, 2);
								ClearTileBlock(TMID_Decor, x, y + 8, 2, 2);

								switch(Inst.FloorLevel){
									case UPPER:

										//Sides
										DrawTileBlock(TMID_Decor, x, y, 100, TilesY, 2, 1);
										DrawTileBlock(TMID_Decor, x, y + 24, 100, TilesY + 1, 2, 1);
						
										//Top
										DrawTileBlock(TMID_Beam, x + 16, y, 67, TilesY, 1, 4);
								
										break;
										
									case LOWER:
								
										//Sides
										DrawTileBlock(TMID_Decor, x, y, 104, TilesY, 2, 1);
										DrawTileBlock(TMID_Decor, x, y + 24, 104, TilesY + 1, 2, 1);
						
										//Top
										DrawTileBlock(TMID_Beam, x + 16, y, 69, TilesY, 1, 4);
										
										break;
						
								}

								switch(LightingFrame){
									case OpenDoorSprite.LightCurrentLightNext:
									case OpenDoorSprite.DarkCurrentLightNext:
										DrawTileBlock(TMID_Decor, x, y + 8, 70, 2, 2, 2); break;
									case OpenDoorSprite.LightCurrentDarkNext: DrawTileBlock(TMID_Decor, x, y + 8, 72, 0, 2, 2); break;							
									case OpenDoorSprite.DarkCurrentDarkNext: DrawTileBlock(TMID_Decor, x, y + 8, 108, TilesY, 2, 2); break;
								}
								break;
							
							case SecretDoor.Illusion:
								//draw back wall
								for(var i = 0; i < 2; i++){
									var _y = y + 8 + (i * 8);
									var _TileY =  TilesY + (_y mod 16 == 0 ? 1 : 0);
									DrawTileBlock(TMID_Walls, x, _y, 8 + (WallLevel * 17), _TileY, 2, 1); 
								}
								for(var i = 0; i < 4; i++){
									var _y = y + (i * 8);
									var _TileY =  TilesY + (_y mod 16 == 0 ? 1 : 0);
									DrawTileBlock(TMID_Beam, x + 16, _y, 10 + (WallLevel * 17), _TileY, 1, 1); 									
								}

								
								break;

						}
						break;
						

				}
				
				//draw back ceilings above to cover any items Link is carrying while walking through
				for(var i = 0; i < 2; i++){
					var _TileY = y - 16 + (i * 8);
					DrawTileBlock(TMID_Beam, x + 16, _TileY, 10 + (WallLevel * 17), TilesY + (_TileY mod 16 == 0 ? 1 : 0), 1, 1); 
				}				
				break;
		}
		
	}
	
}

function Dungeon_InitDoors(){


	with(oDoor){
		
		var RoomGridX = floor(x / 256);
		var RoomGridY = floor(y / 256);

		var DoorDist = (FloorLevel == UPPER ? 56 : 104);
		var DirX = 0;	
		var DirY = 0;
		
		switch(Location){
			case "Top": DirY = -1;	break;
			case "Bottom": DirY = 1; break;				
			case "Left": DirX = -1; break;
			case "Right": DirX = 1; break;
		}

		LinkedDoor = instance_place(x + (DirX * DoorDist), y + (DirY * DoorDist), oDoor);
		
		var ConnectedRoomGridX = RoomGridX + DirX;
		var ConnectedRoomGridY = RoomGridY + DirY;
				
		//Make sure the door and linked door is the same secret type
		if(SecretType != -1 && LinkedDoor.SecretType != SecretType){
			LinkedDoor.Status = DoorStatus.Secret_Closed;
			LinkedDoor.SecretType = SecretType;
		}
		
		if(global.Level.Rooms[RoomIndex].TemplateName == "Arcade") continue;
		
		if(ConnectedRoomGridX >= 0 && ConnectedRoomGridX <= 7 && ConnectedRoomGridY >= 0 && ConnectedRoomGridY <= 7){
			var ConnectedRoomIndex = global.Level.Map_RoomIndex[ConnectedRoomGridY][ConnectedRoomGridX];
			if(ConnectedRoomIndex != -1 && ConnectedRoomIndex != undefined && !Entrance && Status != DoorStatus.Entrance && Status != DoorStatus.Exit){
				var ConnectedLightingStatus = global.Level.Rooms[ConnectedRoomIndex].Lighting;
				if(global.Level.Rooms[RoomIndex].Lighting == 0.0){
					if(ConnectedLightingStatus == 0.0)
						LightingFrame = OpenDoorSprite.LightCurrentLightNext;
					else
						LightingFrame = OpenDoorSprite.LightCurrentDarkNext;
				}else{
					if(ConnectedLightingStatus == 0.0){
						LightingFrame = OpenDoorSprite.DarkCurrentLightNext;
						var C = 0.6;
						var E = 0.47;
						var S = 0.7;
						switch(Location){
							case "Top":
								EntranceLight = Lighting_CreateLight(RoomIndex, x + 16, y + 16, E, [C, C, C]);	
								FloorLight = Lighting_CreateLight(RoomIndex, x + 16, y + 16, S, [C, C,C]);	
								break;
							case "Bottom":
								EntranceLight = Lighting_CreateLight(RoomIndex, x + 16, y + 11, E, [C, C, C]);	
								FloorLight = Lighting_CreateLight(RoomIndex, x + 16, y + 10, S, [C, C, C]);	
								break;							
							case "Left":
								EntranceLight = Lighting_CreateLight(RoomIndex, x + 16, y + 16, E, [C, C, C]);	
								FloorLight = Lighting_CreateLight(RoomIndex, x + 16, y + 16, S, [C, C, C]);
								break;							
							case "Right":
								EntranceLight = Lighting_CreateLight(RoomIndex, x + 9, y + 16, E, [C, C, C]);
								FloorLight = Lighting_CreateLight(RoomIndex, x + 8, y + 16, S, [C, C, C]);
								break;							
						}
						
					}else LightingFrame = OpenDoorSprite.DarkCurrentDarkNext;
				}
			}
		}

		Door_UpdateLights();
	
	}
	
	with(oDoor){

		Door_DrawTiles(id);
		if(SecretType == SecretDoor.Illusion){
			if(global.Level.Rooms[LinkedDoor.RoomIndex].Secret == 1) global.Level.Rooms[LinkedDoor.RoomIndex].Secret = 2; //to notify the camera to play sound when transitioning. 
			Status = DoorStatus.Secret_Open;
			EntranceLight = Lighting_DestroyLight(RoomIndex, EntranceLight);
			FloorLight = Lighting_DestroyLight(RoomIndex, FloorLight);
		}

	}
	
}

function Door_OpenSecretDoor(_Inst){
	
	with(_Inst){
		Status = DoorStatus.Secret_Open;
		UpdateStatus = true;
		RegionRoom_OpenPassage(RoomIndex, x - global.Level.Rooms[RoomIndex].x, y - global.Level.Rooms[RoomIndex].y);
		RegionRoom_OpenPassage(LinkedDoor.RoomIndex, LinkedDoor.x - global.Level.Rooms[LinkedDoor.RoomIndex].x, LinkedDoor.y - global.Level.Rooms[LinkedDoor.RoomIndex].y);
		LinkedDoor.Status = DoorStatus.Secret_Open;
		LinkedDoor.SecretType = SecretType;
		LinkedDoor.UpdateStatus = true;	
	}
	
}

function Door_SetPassageArea(_DoorInst){
	
	with(_DoorInst){
		switch(Location){
		
			case "Top":
				
				sprite_index = sDoorMaskH;
				PassageArea[0] = x - 4;
				PassageArea[1] = y - 48 - (FloorLevel == LOWER ? 48 : 0);
				PassageArea[2] = x + 35;
				PassageArea[3] = y + 7;
					
				break;
			
			case "Bottom":

				sprite_index = sDoorMaskH;
				PassageArea[0] = x - 4;
				PassageArea[1] = y + 15;
				PassageArea[2] = x + 35;
				PassageArea[3] = y + 63 + (FloorLevel == LOWER ? 48 : 0);
				
				break;
			
			case "Left":

				sprite_index = sDoorMaskV;
				PassageArea[0] = x - 48 - (FloorLevel == LOWER ? 48 : 0);
				PassageArea[1] = y - 12;
				PassageArea[2] = x + 8;
				PassageArea[3] = y + 35;

				break;
			
			case "Right":

				sprite_index = sDoorMaskV;
				PassageArea[0] = x + 16;
				PassageArea[1] = y - 12;
				PassageArea[2] = x + 63 + (FloorLevel == LOWER ? 48 : 0);
				PassageArea[3] = y + 35;

				break;
	
		}
	}
		
}

function Door_GetConnectedPos(ARGridX, ARGridY, ARSize, CRGridX, CRGridY, CRSize, ARDoorPos){
	
	//AR = Active Room
	//CR = Connected Room
	
	var A = (ARDoorPos > 12 ? 12 : 0); //A stands for 'Add 12'
	
	switch(ARSize){
		case RoomSize._1x1:
			
			switch(CRSize){
				case RoomSize._1x1:
						
					switch(ARDoorPos){
						case 1: case 13: return 5 + A;
						case 2: case 14: return 10 + A;
						case 3: case 15: return 9 + A;
						case 4: case 16: return 8 + A;
						case 5: case 17: return 1 + A;
						case 6: case 18: return 12 + A;
						case 7: case 19: return 11 + A;
						case 8: case 20: return 4 + A;
						case 9: case 21: return 3 + A;
						case 10: case 22: return 2 + A;
						case 11: case 23: return 7 + A;
						case 12: case 24: return 6 + A;
						default: return -1;
								
					}
						
				case RoomSize._1x2:
				
					switch(ARDoorPos){
						case 1: case 13: return 5 + A;
						case 3: case 15: if(ARGridY == CRGridY) return 10 + A; else return 8 + A;
						case 5: case 17: return 1 + A;
						case 6: case 18: return 12 + A;
						case 7: case 19: return 11 + A;
						case 9: case 21: if(ARGridY == CRGridY) return 2 + A; else return 4 + A;
						case 11: case 23: return 7 + A;
						case 12: case 24: return 6 + A;
						default: return -1;
								
					}
					
				case RoomSize._2x1:

					switch(ARDoorPos){
						case 2: case 14: return 10 + A;
						case 3: case 15: return 9 + A;
						case 4: case 16: return 8 + A;
						case 6: case 18: if(ARGridX == CRGridX) return 11 + A; else return 1 + A;
						case 8: case 20: return 4 + A;
						case 9: case 21: return 3 + A;
						case 10: case 22: return 2 + A;
						case 12: case 24: if(ARGridX == CRGridX) return 7 + A; else return 5 + A;
						default: return -1;
								
					}
						
				case RoomSize._2x2:
				
					switch(ARDoorPos){
						case 3: case 15: if(ARGridY == CRGridY) return 10 + A; else return 8 + A;
						case 6: case 18: if(ARGridX == CRGridX) return 11 + A; else return 1 + A;
						case 9: case 21: if(ARGridY == CRGridY) return 2 + A; else return 4 + A;
						case 12: case 24: if(ARGridX == CRGridX) return 7 + A; else return 5 + A;
						default: return -1;
								
					}
			}
				
			break;
		
		case RoomSize._1x2:

			switch(CRSize){
				case RoomSize._1x1:
						
					switch(ARDoorPos){
						case 1: case 13: return 5 + A;
						case 2: case 14: return 9 + A;
						case 4: case 16: return 9 + A;
						case 5: case 17: return 1 + A;
						case 6: case 18: return 12 + A;
						case 7: case 19: return 11 + A;
						case 8: case 20: return 3 + A;
						case 10: case 22: return 3 + A;
						case 11: case 23: return 7 + A;
						case 12: case 24: return 6 + A;
						default: return -1;
								
					}
						
				case RoomSize._1x2:
				
					switch(ARDoorPos){
						case 1: case 13: return 5 + A;
						case 2: case 14: if(ARGridY == CRGridY) return 10 + A; else return 8 + A;
						case 3: case 15: if(ARGridY == CRGridY) return 9 + A; else return -1;
						case 4: case 16: if(ARGridY == CRGridY) return 8 + A; else return 10 + A;
						case 5: case 17: return 1 + A;
						case 6: case 18: return 12 + A;
						case 7: case 19: return 11 + A;
						case 8: case 20: if(ARGridY == CRGridY) return 4 + A; else return 2 + A;
						case 9: case 21: if(ARGridY == CRGridY) return 3 + A; else return -1;
						case 10: case 22: if(ARGridY == CRGridY) return 2 + A; else return 4 + A;
						case 11: case 23: return 7 + A;
						case 12: case 24: return 6 + A;
						default: return -1;
								
					}
					
				case RoomSize._2x1:

					switch(ARDoorPos){
						case 2: case 14: return 9 + A;
						case 4: case 16: return 9 + A;
						case 6: case 18: if(ARGridX == CRGridX) return 11 + A; else return 1 + A;
						case 8: case 20: return 3 + A;
						case 10: case 22: return 3 + A;
						case 12: case 24: if(ARGridX == CRGridX) return 7 + A; else return 5 + A;
						default: return -1;
								
					}
						
				case RoomSize._2x2:
				
					switch(ARDoorPos){
						case 2: case 14: if(ARGridY == CRGridY) return 10 + A; else return 8 + A;
						case 3: case 15: if(ARGridY == CRGridY) return 9 + A; else return -1;
						case 4: case 16: if(ARGridY == CRGridY) return 8 + A; else return 10 + A;
						case 6: case 18: if(ARGridX == CRGridX) return 11 + A; else return 1 + A;
						case 8: case 20: if(ARGridY == CRGridY) return 4 + A; else return 2 + A;
						case 9: case 21: if(ARGridY == CRGridY) return 3 + A; else return -1;
						case 10: case 22: if(ARGridY == CRGridY) return 2 + A; else return 4 + A;
						case 12: case 24: if(ARGridX == CRGridX) return 7 + A; else return 5 + A;
						default: return -1;
								
					}
			}
			
			break;
			
			
		case RoomSize._2x1:

			switch(CRSize){
				case RoomSize._1x1:
						
					switch(ARDoorPos){
						case 1: case 13: return 6 + A;
						case 2: case 14: return 10 + A;
						case 3: case 15: return 9 + A;
						case 4: case 16: return 8 + A;
						case 5: case 17: return 12 + A;
						case 7: case 19: return 12 + A;
						case 8: case 20: return 4 + A;
						case 9: case 21: return 3 + A;
						case 10: case 22: return 2 + A;
						case 11: case 23: return 6 + A;
						default: return -1;
								
					}
						
				case RoomSize._1x2:
				
					switch(ARDoorPos){
						case 1: case 13: return 6 + A;
						case 3: case 15: if(ARGridY == CRGridY) return 10 + A; else return 8 + A;
						case 5: case 17: return 12 + A;
						case 7: case 19: return 12 + A;
						case 9: case 21: if(ARGridY == CRGridY) return 2 + A; else return 4 + A;
						case 11: case 23: return 6 + A;
						default: return -1;
								
					}
					
				case RoomSize._2x1:

					switch(ARDoorPos){
						case 1: case 13: if(ARGridX == CRGridX) return 5 + A; else return 7 + A;
						case 2: case 14: return 10 + A;
						case 3: case 15: return 9 + A;
						case 4: case 16: return 8 + A;
						case 5: case 17: if(ARGridX == CRGridX) return 1 + A; else return 11 + A;
						case 6: case 18: return 12 + A;
						case 7: case 19: if(ARGridX == CRGridX) return 11 + A; else return 1 + A;
						case 8: case 20: return 4 + A;
						case 9: case 21: return 3 + A;
						case 10: case 22: return 2 + A;
						case 11: case 23: if(ARGridX == CRGridX) return 7 + A; else return 5 + A;
						case 12: case 24: return 6 + A;
						default: return -1;
								
					}
						
				case RoomSize._2x2:
				
					switch(ARDoorPos){
						case 1: case 13: if(ARGridX == CRGridX) return 5 + A; else return 7 + A;
						case 3: case 15: if(ARGridY == CRGridY) return 10 + A; else return 8 + A;
						case 5: case 17: if(ARGridX == CRGridX) return 1 + A; else return 11 + A;
						case 6: case 18: if(ARGridX == CRGridX) return 12 + A; else return -1;
						case 7: case 19: if(ARGridX == CRGridX) return 11 + A; else return 1 + A;
						case 9: case 21: if(ARGridY == CRGridY) return 2 + A; else return 4 + A;
						case 11: case 23: if(ARGridX == CRGridX) return 7 + A; else return 5 + A;
						case 12: case 24: if(ARGridX == CRGridX) return 6 + A; else return -1;
						default: return -1;
								
					}
			}
			
			break;
			
		case RoomSize._2x2:

			switch(CRSize){
				case RoomSize._1x1:
						
					switch(ARDoorPos){
						case 1: case 13: return 6 + A;
						case 2: case 14: return 9 + A;
						case 4: case 16: return 9 + A;
						case 5: case 17: return 12 + A;
						case 7: case 19: return 12 + A;
						case 8: case 20: return 3 + A;
						case 10: case 22: return 3 + A;
						case 11: case 23: return 6 + A;
						default: return -1;
								
					}
						
				case RoomSize._1x2:
				
					switch(ARDoorPos){
						case 1: case 13: return 6 + A;
						case 2: case 14: if(ARGridY == CRGridY) return 10 + A; else return 8 + A;
						case 3: case 15:  if(ARGridY == CRGridY) return 9 + A; else return -1;
						case 4: case 16: if(ARGridY == CRGridY) return 8 + A; else return 10 + A;
						case 5: case 17: return 12 + A;
						case 7: case 19: return 12 + A;
						case 8: case 20: if(ARGridY == CRGridY) return 4 + A; else return 2 + A;
						case 9: case 21: if(ARGridY == CRGridY) return 3 + A; else return -1;
						case 10: case 22: if(ARGridY == CRGridY) return 2 + A; else return 4 + A;
						case 11: case 23: return 6 + A;
						default: return -1;
								
					}
					
				case RoomSize._2x1:

					switch(ARDoorPos){
						case 1: case 13: if(ARGridX == CRGridX) return 5 + A; else return 7 + A;
						case 2: case 14: return 9 + A;
						case 4: case 16: return 9 + A;
						case 5: case 17: if(ARGridX == CRGridX) return 1 + A; else return 11 + A;
						case 6: case 18: if(ARGridX == CRGridX) return 12 + A; else return -1;
						case 7: case 19: if(ARGridX == CRGridX) return 11 + A; else return 1 + A;
						case 8: case 20: return 3 + A;
						case 10: case 22: return 3 + A;
						case 11: case 23: if(ARGridX == CRGridX) return 7 + A; else return 5 + A;
						case 12: case 24: if(ARGridX == CRGridX) return 6 + A; else return -1;
						default: return -1;
								
					}
						
				case RoomSize._2x2:
				
					switch(ARDoorPos){
						case 1: case 13: if(ARGridX == CRGridX) return 5 + A; else return 7 + A;
						case 2: case 14: if(ARGridY == CRGridY) return 10 + A; else return 8 + A;
						case 3: case 15: if(ARGridY == CRGridY) return 9 + A; else return -1;
						case 4: case 16: if(ARGridY == CRGridY) return 8 + A; else return 10 + A;
						case 5: case 17: if(ARGridX == CRGridX) return 1 + A; else return 11 + A;
						case 6: case 18: if(ARGridX == CRGridX) return 12 + A; else return -1;
						case 7: case 19: if(ARGridX == CRGridX) return 11 + A; else return 1 + A;
						case 8: case 20: if(ARGridY == CRGridY) return 4 + A; else return 2 + A;
						case 9: case 21: if(ARGridY == CRGridY) return 3 + A; else return -1;
						case 10: case 22: if(ARGridY == CRGridY) return 2 + A; else return 4 + A;
						case 11: case 23: if(ARGridX == CRGridX) return 7 + A; else return 5 + A;
						case 12: case 24: if(ARGridX == CRGridX) return 6 + A; else return -1;
						default: return -1;
								
					}
			}
			
			break;
			
	}
		
	
}

function Door_UpdateLights(){
	
	var LightStatus = (Status != DoorStatus.Closed && Status != DoorStatus.Locked && Status != DoorStatus.Secret_Closed && Status != DoorStatus.Curtain);
	Lighting_UpdateLight_Visible(RoomIndex, FloorLight, LightStatus);
	Lighting_UpdateLight_Visible(RoomIndex, EntranceLight, LightStatus);
	
}

function Door_LocationToDir(_Location){
	switch(_Location){
		case "Top": return UP
		case "Bottom": return DOWN
		case "Left": return LEFT
		case "Right": return RIGHT
		
	}
	
	return -1;
	
}
function Door_LocationToOppositeDir(_Location){
	switch(_Location){
		case "Top": return DOWN
		case "Bottom": return UP
		case "Left": return RIGHT
		case "Right": return LEFT
		
	}
	
	return -1;
	
}
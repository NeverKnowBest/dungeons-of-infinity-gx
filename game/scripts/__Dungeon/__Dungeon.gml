// Feather disable GM2064
#macro Room global.Level.Rooms[_RoomIndex]
#macro DungeonRoom global.Level.DungeonTemplate.Rooms[_RoomIndex]
#macro StartingRoom (LevelDef.RunStart && _RoomIndex == global.Level.RoomIndex_Entrance)
#macro DungeonGridW 8
#macro DungeonW (256 * DungeonGridW)
#macro SectionIndex (Room.TemplateClass == RoomTemplateClass.Main_Upper ? Room.Section_ID : 0)

enum DungeonClass{
	Castle,				//no crystals, no warps
	CastleBasement,		//no crystals, no warps
	CastleJails,		//no crystals, no warps
	CatacombsSewers,	//Catacombs, Sewers, crystals, no warps
	BossesRuins,		//crystals, warps
	Aghanim,			//crystals, warps
	Special				//Village, start, etc
}
#macro DungeonClasses 7

#macro TileLayers 15
enum TileLayer{
	Lava,
	Pit,
	Floor_Lower,
	FloorFringe_Lower,
	Water_Lower,
	Walls_Lower,
	Decor_Lower,
	Floor_Upper,
	FloorFringe_Upper,
	Water_Upper,
	StairMonuments,
	StairMonumentsDecor,
	Walls_Upper,
	Decor_Upper,
	Higher,
	Highest,
	Ceiling,
}

#macro DungeonLevels 15
enum DungeonLevel{
	Start,
	Castle,
	CastleBasement,
	CastleJails,
	Catacombs,
	Sewers,
	Village,
	LanmolasLair,
	Ruins,
	WaterTemple,
	Mines,
	MoldormsLair,
	Aghanim1,
	Aghanim2,
	CastleTop		// chapter 2 variant (docs/regioes/topo-do-castelo.md)
}

enum RoomSize{
	_1x1,
	_1x2,
	_2x1,
	_2x2
}

global.Level = 0;


function Dungeon_Clear(){

	for(var i = 0; i < array_length(global.TMID); i++){
		tilemap_clear(global.TMID[i], 0);
	}
	RegionTiles_Clear();

	//destroy items from previous dungeon.
	with(oEnemy) instance_destroy(id);
	with(oItem) instance_destroy(id);
	with(oProjectile) instance_destroy(id);
	with(oPickupObj) instance_destroy(id);
	with(oSwitch) instance_destroy(id);
	with(oSwitchBlock) instance_destroy(id);
	with(oWallLight) instance_destroy(id);
	with(oLampFlame) instance_destroy(id);
	with(oDoor) instance_destroy(id);
	with(oSign) instance_destroy(id);
	with(oEffects) instance_destroy(id);
	with(oMovingFloor) instance_destroy(id);
	with(oWall) instance_destroy(id);
	with(oCurtain) instance_destroy(id);
	with(oShop) instance_destroy(id);
	with(oHeartGuy) instance_destroy(id);
	with(oArcades) instance_destroy(id);
	with(oPoolTable) instance_destroy(id);
	with(oPopMachine) instance_destroy(id);
	with(oClawMachine) instance_destroy(id);
	with(oBoss_Armos_C) instance_destroy(id);
	with(oBoss_Lanmola_C) instance_destroy(id);
	with(oBoss_Lanmola_Dirt1) instance_destroy(id);
	with(oBoss_Lanmola_Dirt2) instance_destroy(id);
	with(oBoss_Lanmola_DirtSplash) instance_destroy(id);
	with(oBossHeartCrystal) instance_destroy(id);
	with(oFinalBossGate) instance_destroy(id);
	with(oStarfield) instance_destroy(id);
	with(oAghanim_End) instance_destroy(id);
	with(oCrystalEnd) instance_destroy(id);
	with(oItem_Kinstone_Main) instance_destroy(id);
	with(oRodCharger) instance_destroy(id);
	with(oWarp) instance_destroy(id);
	with(oWeather) instance_destroy(id);
	with(oCursed) instance_destroy(id);
	with(oDeadHungryGuy) instance_destroy(id);
	with(oMap) instance_destroy(id);
	with(oCape) instance_destroy(id);
	with(oInventory) instance_destroy(id);
	with(oPrisoner) instance_destroy(id);
	with(oTreasureLarge) instance_destroy(id);
	with(oFairy_Health) instance_destroy(id);
	with(oFairy_Queen) instance_destroy(id);
	with(oHouseDoor) instance_destroy(id);
	with(oCastleWallDoor) instance_destroy(id);	
	with(oWaterfall) instance_destroy(id);
	with(oNPC) instance_destroy(id);
	with(oNPC_OldLady) instance_destroy(id);
	with(oChessBoard) instance_destroy(id);
	with(oBook) instance_destroy(id);
	with(oEnemy_Guru_Bar) instance_destroy(id);
	with(oEnemy_Guru) instance_destroy(id);
	with(oLinkDeath) instance_destroy(id);
	with(oLinkRevive) instance_destroy(id);
	with(oEnemyTrap) instance_destroy(id);
	with(oGemPondWater) instance_destroy(id);
	with(oZora) instance_destroy(id);
	with(oMineCart) instance_destroy(id);
	with(oMineCartDirSwitch) instance_destroy(id);
	with(oMineCartAction) instance_destroy(id);
	with(oCoal) instance_destroy(id);
	with(oCoalLight) instance_destroy(id);
	with(oDwarfWorker) instance_destroy(id);
	with(oGemRock) instance_destroy(id);
	with(oDrawBridgeArea) instance_destroy(id);
	with(oStoreSign) instance_destroy(id);
	with(oSaveTent) instance_destroy(id);
	with(oSaveTentFire) instance_destroy(id);
	with(oTombSkeleton) instance_destroy(id);
	with(oLeaf_Inside) instance_destroy(id);
	with(oSimonFrogs) instance_destroy(id);
	
	Inventory_DeleteItemClass(ItemClass.Map);
	Inventory_DeleteItemClass(ItemClass.Compass);
	oHUD.DrawMap = false;
	oHUD.DrawCompass = false;

	
	ds_grid_resize(global.NonDuplicatableItemsThatExist, 2, 0);
	
	Map_Clear();
	
	ResetUnusedPrisonerList();
	ResetUnusedShopKeeperList();
	
	global.TorchGroupIndex = 0; //When adding torches to Rooms, set them all to the same group index, and increment this index for each Room. This way when checking to see if all torches are lit in the same Room, we can check only those that have the same group index
	global.LinkDead = false;
	Dungeon_DestroyLevel();
	
	gc_collect();
	
}

function Dungeon_CreateStruct_Level(_LevelIndex) constructor{
	
	
	Index = _LevelIndex;
	
	Class = Dungeon_PickClass(_LevelIndex);
	
	if(DEBUG){
		
		//if(Index == DungeonLevel.MoldormsLair && !global.SaveLevel){
			//Transformation = ObjTransformation.None;
			//DungeonTemplate_Index = 41;
		//}else{
			Transformation = Dungeon_PickTemplateTransformation(Index);
			DungeonTemplate_Index = Dungeon_PickTemplateIndex(Index, Class, Transformation);
		//}
		
	}else{
		Transformation = Dungeon_PickTemplateTransformation(Index);
		DungeonTemplate_Index = Dungeon_PickTemplateIndex(Index, Class, Transformation);
	}
	
	DungeonTemplate = global.Templates_Dungeon[Class][Transformation][DungeonTemplate_Index];
	//rooms painted from one frame share their border (roadmap F12b-2): a layout with a seam the frame cannot paint is
	//drawn again (Dungeon_LayoutSeamsOk), only in levels with a region tileset
	for(var _Try = 0; _Try < 12 && Class != DungeonClass.Special && global.LevelDefs[_LevelIndex].RegionTiles != ""
		&& !Dungeon_LayoutSeamsOk(DungeonTemplate, _LevelIndex); _Try++){
		Test_Event("layout " + string(DungeonTemplate_Index) + " drawn again (a seam the painted rooms cannot meet)");
		Transformation = Dungeon_PickTemplateTransformation(Index);
		DungeonTemplate_Index = Dungeon_PickTemplateIndex(Index, Class, Transformation);
		DungeonTemplate = global.Templates_Dungeon[Class][Transformation][DungeonTemplate_Index];
	}
	
	RoomCount = array_length(DungeonTemplate.Rooms);
	
	Rooms = array_create(RoomCount);
	RoomsVisted = 0;
	RoomsVistedPercent = 0;
	
	RoomIndex_Entrance = 0;
	RoomIndex_Boss = -1;
	RoomIndex_BossAdjacent = -1;

	// Exits (roadmap F4b, Dungeon_PlanExits): where the main exit leads, and the extra exit when the level has one
	Exits = {Dest: global.LevelDefs[_LevelIndex].Next, ExtraRoom: -1, ExtraPosition: -1, ExtraSecret: false};
	
	Map_RoomIndex = Array_Create2D(DungeonGridW, DungeonGridW, -1);
	

	Map_Sprite_All = 0;				//all Rooms(grey versions)
	Map_Sprite_Explored = 0;		//only explored Rooms  (blue versions)
	Map_Sprite_Doors_All = 0;		//All Doors
	Map_Sprite_Doors_Explored = 0;	//only explored Doors
	
	
	
	StartDir = Dungeon_StartDir(Index);
	IsBossLevel = Dungeon_IsBossLevel(Index);
	
	SwitchBlock_Colors = 2;
	SwitchBlock_ActiveColor = SwitchBlockColor.Red; //color that the crystal is showing, SBs with this color are lowered/active
	
	if(DEBUG){ //Often I edit these, make sure I don't forget to reset them by only modifying the debug versions
		MaxBonusTreasures = 99;//ceil(RoomCount / 14);
		MaxShops = ceil(RoomCount / 14);
	}else{
		MaxBonusTreasures = ceil(RoomCount / 14);
		MaxShops = ceil(RoomCount / 14);		
	}
	
	BonusTreasureCount = 0;
	ShopCount = 0;
	
	MaxNoEnemyRooms = max(2, ceil(RoomCount / 8));
	NoEnemyRoomCount = 0;
	
	AltarCount = 0;
	
	RodCharger = false; //only allow 1 per level
	
	JailMonumentItem_DeadMale = false; //only allow 1 of each for the level
	JailMonumentItem_DeadFemale = false;
	
	CatacombGrave = false; //only allow 1 grave per catacomb level, those are the ones with the headings you can read. The headings cycle and I want only 1 per game to be read
	
	//keep track if certain rooms were generated that only allow 1 per level
	FairyRoom = false; 
	GemPondRoom = false; 
	TMNTRoom = false; 
	LargeTreasureRoom = false;
	
	var _Depth = global.LevelDefs[Index].Depth;
	
	Stars = Prob(Chance_LevelHasStar) && _Depth > Level_Depth(DungeonLevel.Castle);
	MinEnemiesForStars = 6 + floor(_Depth / 3);
	
	MaxRollingSpikes = irandom_range(1 + floor(_Depth / 6), 2 + floor(_Depth / 4));
	MaxGuruBars = irandom_range(1 + floor(_Depth / 6), 2 + floor(_Depth / 4));
	
	//keep track of items that should only be created once on a level for shops
	ShopBagSlotsCreated = 0;
	ShopHeartPiecesCreated = 0;
	ShopKeysCreated = 0;
	ShopLargeMagicCreated = 0;
	ShopArrowsCreated = 0;
	ShopBombsCreated = 0;
	ShopOrbsCreated = 0;
	ShopPopsCreated = 0;

	PotStyle = global.LevelDefs[Index].PotStyle;
	
	
}

function Dungeon_CreateStruct_Room(_RoomIndex) constructor{
	
	x = DungeonRoom.x;
	y = DungeonRoom.y;
	width = DungeonRoom.width;
	height = DungeonRoom.height;
	x2 = x + width - 1;
	y2 = y + height - 1;
	TileX = x / 8;
	TileY = y / 8;
	TileW = width / 8;
	TileH = height / 8;
	GridX = DungeonRoom.GridX;
	GridY = DungeonRoom.GridY;
	GridW = DungeonRoom.GridW;
	GridH = DungeonRoom.GridH;
	
	//create all tile layers for each Room
	Tiles = array_create(TileLayers);
	for(var _TileLayerIndex = 0; _TileLayerIndex < TileLayers; _TileLayerIndex++){
		Tiles[_TileLayerIndex] = Array_Create2D(DungeonRoom.GridW * 32, DungeonRoom.GridH * 32);
	}


	Visited = false;
	Secret = -1;
	
	FairyOrGemPond = false;
	Water = false;
	Sand = false;
	Heat = false;
	
	ForcedTheme = -1;
	ForcedTheme_Floor = -1;
	ForcedTheme_Floor_Upper = -1;
	ForcedTheme_Floor_Lower = -1;
	
	Section_ID = DungeonRoom.Section_ID;
	Section_WallType = DungeonRoom.Section_WallType;
	
	SizeIndex = global.RoomSizeIndex[GridW][GridH];
	
	UnusedZone = -1;
	
	UsedSpace = [];
	
	SpecialObject = DungeonRoom.SpecialObj;
	SpecialObject_InSection = (DungeonRoom.SpecialObjSection > 0);
	SpecialObject_SectionType = (SpecialObject_InSection ? Section.Other : Section.Main);

	StarEnemyCount = 0; //keep track of enemy count for star, only place star if count is > a certain number
	
	BonusTreasure = Prob(Chance_BonusTreasure);
	
	ShopPriceMultiplier = random_range(1, min(1.4 + (LevelDef.Depth * 0.1), 2)); //for each room, pick a multiplier for the base prices
	
	WetBandits = false;
	
	Switch = {Inst : noone, Action: SwitchAction.None, HiddenObjType : Switch_HiddenObjType.None, HiddenObjInst : noone, TreasureItemClass : -1};
	
	Warp_DestGridPosition = DungeonRoom.Warp_DestGridPosition;
	Warp_DestRoomIndex = DungeonRoom.Warp_DestRoomIndex;

	WarpDest_WarpRoomIndex = DungeonRoom.WarpDest_WarpRoomIndex;
	WarpDest = WarpDest_WarpRoomIndex != -1;
	WarpDest_Created = false;
	WarpDest_X = 0;
	WarpDest_Y = 0;

	RoomSongIndex = LevelDef.Song;
	
	DoorCode = 0;
	
	DoorCount = array_length(DungeonRoom[$ "Doors"]);
	Doors = array_create(DoorCount);
	UpperDoors = false;
	LowerDoors = false;
	for(var _DoorIndex = 0; _DoorIndex < DoorCount; _DoorIndex++){	
		
		Doors[_DoorIndex] = new Dungeon_CreateStruct_Door();
		Doors[_DoorIndex].Position = DungeonRoom.Doors[_DoorIndex].Position;
		Doors[_DoorIndex].Location = DungeonRoom.Doors[_DoorIndex].Location;
		Doors[_DoorIndex].ConnectedRoomIndex = DungeonRoom.Doors[_DoorIndex].ConnectedRoomIndex;
		
		//special case where boss room exit door touches another room, so boss room not being generated, the dungeon editon is setting the connectedroomindex to not be -1, that's a bug in map editor, can't find it, this fixes this.
		if(SpecialObject == SpecialDungeonObj.Boss && Doors[_DoorIndex].ConnectedRoomIndex != global.Level.RoomIndex_BossAdjacent) Doors[_DoorIndex].ConnectedRoomIndex = -1;
		
		Doors[_DoorIndex].x = DungeonRoom.Doors[_DoorIndex].x;
		Doors[_DoorIndex].y = DungeonRoom.Doors[_DoorIndex].y;
		
		Doors[_DoorIndex].Level = RoomTemplates_GetDoorLevel(Doors[_DoorIndex].x, Doors[_DoorIndex].y);
		if(Doors[_DoorIndex].Level == UPPER) UpperDoors = true;
		if(Doors[_DoorIndex].Level == LOWER) LowerDoors = true;
		
		Doors[_DoorIndex].Status = DungeonRoom.Doors[_DoorIndex].Status;		
		//outdoors there is no door that shuts until the enemies die: it is the open passage (docs/design/direcao.md)
		if(LevelDef.Layout == LevelLayout.Outdoor && (Doors[_DoorIndex].Status == DoorStatus.Closed || Doors[_DoorIndex].Status == DoorStatus.ClosedHalf)){
			Doors[_DoorIndex].Status = DoorStatus.Open;
		}
		switch(Doors[_DoorIndex].Status){
			case DoorStatus.Entrance:
				global.Level.RoomIndex_Entrance = _RoomIndex;
				//RoomEntrance = _RoomIndex;				
				break;
				
			case DoorStatus.Exit:
				global.Level.RoomIndex_BossAdjacent = _RoomIndex;
				break;
			
		}

	}
	
	Lighting = false;
	Lights_Pos = array_create(MAXROOMLIGHTS * 3);
	Lights_RGB = array_create(MAXROOMLIGHTS * 3);
	Lights_RGBOld = array_create(MAXROOMLIGHTS * 3);
	Lights_UnusedIndexes = [];
	Lights_LastIndex = -1;	
	
	Obstacle = -1;
	
	Template = -1;
	TemplateClass = -1;
	TemplateSubClass = -1;
	TemplateIndex = 0;
	TemplateName = "";

	MapSpr = -1;
	MapSpr_Visited = -1;
	MapSpr_Doors = -1;
	MapX = GridX * 32;
	MapY = GridY * 32;
	MapW = GridW * 32;
	MapH = GridH * 32;

	TemplateObjGrid = {WallsUpper : Array_Create2D(MapW, MapH, false), OutOfBounds : Array_Create2D(MapW, MapH, false), ExtraCeilings : Array_Create2D(MapW, MapH, false)};
	
	switch(LevelDef.Special){
		case LevelSpecial.Intro:
			TemplateClass = RoomTemplateClass.Other;
			TemplateSubClass = RoomTemplateClass_Other.Start;
			break;
		case LevelSpecial.Village:
			
			if(_RoomIndex >= 0 && _RoomIndex <= 5){
				TemplateClass = RoomTemplateClass.Village;
				TemplateSubClass = RoomTemplateClass_Village.Main;
			}
			
			if(GridX == 0 && GridY == 0){
				TemplateClass = RoomTemplateClass.Village;
				TemplateSubClass = RoomTemplateClass_Village.Maze;	
				TemplateName = "0";
			}
			if(GridX == 2 && GridY == 0){
				TemplateClass = RoomTemplateClass.Village;
				TemplateSubClass = RoomTemplateClass_Village.Maze;	
				TemplateName = "1";
			}
			if(GridX == 2 && GridY == 1){
				TemplateClass = RoomTemplateClass.Village;
				TemplateSubClass = RoomTemplateClass_Village.Maze;	
				TemplateName = "2";
			}
			if(GridX == 0 && GridY == 2){
				TemplateClass = RoomTemplateClass.Village;
				TemplateSubClass = RoomTemplateClass_Village.Maze;	
				TemplateName = "3";
			}
			if(GridX == 0 && GridY == 4){
				TemplateClass = RoomTemplateClass.Village;
				TemplateSubClass = RoomTemplateClass_Village.Maze;	
				TemplateName = "4";
			}
			if(GridX == 7 && GridY == 2){
				TemplateClass = RoomTemplateClass.Village;
				TemplateSubClass = RoomTemplateClass_Village.Exit;	
				TemplateName = "Exit";
			}
			break;
		
		case LevelSpecial.Mines:
			
			if(global.MainTemplates_Mine[GridY][GridX] != -1){
				TemplateClass = RoomTemplateClass.Mines;
				TemplateSubClass = RoomTemplateClass_Mines.Main;
			}
			break;
			
		case LevelSpecial.FinalBoss:
			TemplateClass = RoomTemplateClass.Other;
			TemplateSubClass = RoomTemplateClass_Other.Unique;
			if(GridX == 3 && GridY == 4) TemplateName = "FinalBossHall";
			if(GridX == 3 && GridY == 3) TemplateName = "FinalBoss";
			break;
	}
	
	if(global.SaveLevel){
		TemplateClass = RoomTemplateClass.Other;
		TemplateSubClass = RoomTemplateClass_Other.Save;
	}
	
	if(global.HubLevel){
		TemplateClass = RoomTemplateClass.Other;
		TemplateSubClass = RoomTemplateClass_Other.Unique;
		TemplateName = Hub_RoomTemplateName(GridX, GridY);
		exit;
	}
	
	switch(SpecialObject){
		
		case SpecialDungeonObj.SpecialRoom:
		
			if(LevelDef.Special == LevelSpecial.Village && GridX == 3 && GridY == 0){
				TemplateClass = RoomTemplateClass.Other;
				TemplateSubClass = RoomTemplateClass_Other.Unique;
				TemplateName = "TreasureRoom";
				break;
			}
			
			if(LevelDef.Special == LevelSpecial.Mines && GridX == 3 && GridY == 0){
				TemplateClass = RoomTemplateClass.Other;
				TemplateSubClass = RoomTemplateClass_Other.Unique;
				TemplateName = "WishRoom";
				break;
			}
			
			TemplateClass = RoomTemplateClass.Special;
			
			break;
		
		case SpecialDungeonObj.Jail:
		case SpecialDungeonObj.JailKey:
			TemplateClass = RoomTemplateClass.Jails;
			TemplateSubClass = global.RoomSizeIndex[GridW][GridH];
			break;
			
		case SpecialDungeonObj.House:
			
			switch(LevelDef.Special){
				case LevelSpecial.Village:
					TemplateClass = RoomTemplateClass.Village;
					TemplateSubClass = RoomTemplateClass_Village.House;					
					break;
					
				case LevelSpecial.Mines:
					TemplateClass = RoomTemplateClass.Mines;
					TemplateSubClass = RoomTemplateClass_Mines.House;							
					break;
				
			}

			break;
		
		case SpecialDungeonObj.Boss:
			TemplateClass = RoomTemplateClass.Other;
			TemplateSubClass = RoomTemplateClass_Other.Boss;
			break;
			
	}
	
	
	if(TemplateClass != -1) exit;
	
	
	
	//an outdoor level paints its sections on its own rooms (paint_sections.py): never the dungeon's Sections templates,
	//not even the built-in sections over 20 (R1 eighth round: a 1x1 room with section 21 or 22 was the castle's room)
	if(SizeIndex == RoomSize._1x1 && ((Section_ID > 20 && LevelDef.Layout != LevelLayout.Outdoor) || (Section_ID > 0 && Section_ID <= 20 && Section_WallType == SectionWallType.Rail && Prob(Chance_SectionTemplate) && LevelDef.Layout != LevelLayout.Outdoor)) ){
		TemplateClass = RoomTemplateClass.Sections;
	}else if(UpperDoors && !LowerDoors){
		
		//eventually remove the SizeIndex == RoomSize._1x1 condition and make sure there are 1x2 and 2x1 obstacle templates
		TemplateClass = (LevelDef.ObstacleRooms && Section_ID == 0 && SizeIndex == RoomSize._1x1 && _RoomIndex != global.Level.RoomIndex_BossAdjacent && _RoomIndex != global.Level.RoomIndex_Entrance && Prob(Chance_ObstacleTemplate) ? RoomTemplateClass.Obstacles : RoomTemplateClass.Main_Upper);
		
	}else if(!UpperDoors && LowerDoors){
		TemplateClass = RoomTemplateClass.Main_Lower;
	}else if(UpperDoors && LowerDoors){
		TemplateClass = RoomTemplateClass.Stairs
	}
	
	switch(TemplateClass){
		case RoomTemplateClass.Main_Upper:
		case RoomTemplateClass.Main_Lower:
			if(GridW == 1 && GridH == 1)
				TemplateSubClass = RoomSize._1x1;
			else //even if room is 2x1, use 1x2 since templates only exist in either 1x1 or 1x2, which will be rotated if needed for 2x1
				TemplateSubClass = RoomSize._1x2;			
			break;
		
		case RoomTemplateClass.Obstacles:
			
			var _ObstacleList = ds_list_create();

			
			var _AllowMovingFloors = (SpecialObject == SpecialDungeonObj.None && !WarpDest);
			for(var i = 0; i < array_length(LevelDef.Obstacles); i++) ds_list_add(_ObstacleList, LevelDef.Obstacles[i]);
			if(_AllowMovingFloors){
				for(var i = 0; i < array_length(LevelDef.MovingFloors); i++) ds_list_add(_ObstacleList, LevelDef.MovingFloors[i]);
			}
			
			ds_list_shuffle(_ObstacleList);
			Obstacle = _ObstacleList[| 0];
			ds_list_destroy(_ObstacleList);
			
			switch(Obstacle){
				case RoomObstacle.Blocks:
					TemplateSubClass = RoomTemplateClass_Obstacles.Blocks;
					BonusTreasure = Prob(0.9);
					break;
				
				case RoomObstacle.Holes:
				case RoomObstacle.Spikes:
				case RoomObstacle.MovingFloorsHoles:
				case RoomObstacle.MovingFloorsSpikes:
				case RoomObstacle.MovingFloorsSpikeBlocks:
					TemplateSubClass = RoomTemplateClass_Obstacles.MovingFloors;
					break;
				
				case RoomObstacle.SpikeBlocks:
					TemplateSubClass = choose(RoomTemplateClass_Obstacles.Blocks, RoomTemplateClass_Obstacles.MovingFloors, RoomTemplateClass_Obstacles.SpikeBlocks);
					break;
				
			}

	
			break;
			
		default:
			TemplateSubClass = global.RoomSizeIndex[GridW][GridH];
			break;		
		
	}

	
}

function Dungeon_CreateStruct_Door() constructor{
	x = 0;
	y = 0;
	ExitDest = -1;	//level an extra exit leads to (roadmap F4b); -1 for every other door, the main exit uses global.Level.Exits.Dest
	Level = 0;
	Status = DoorStatus.Open;
	Position = 0;
	Location = "";
	ConnectedRoomIndex = -1;
}

function Dungeon_InitLevel(_LevelIndex){
	
	Dungeon_Clear();
	
	if(global.Continue){
		Dungeon_LoadLevel();
		Map_Init();
		Dungeon_InitDoors();
		Link_SetStartingPos();
		global.Continue = false;
		exit;
	}else{
		global.Level = new Dungeon_CreateStruct_Level(_LevelIndex);
		global.RunPath.Next = -1;	// the exit taken to get here is used up
	}
	
	
	//Init Room data
	
	//keep track of which boss room is highest, that's the room to use
	var _LowestBossRoomGridY = 7;
	
	for(var _RoomIndex = 0; _RoomIndex < global.Level.RoomCount; _RoomIndex++){

		//var _DungeonRoom = global.Level.DungeonTemplate[$ "Rooms"][_RoomIndex];

		//pre-set all Room indexes in global.DungeonGrid_RoomIndex
		global.Level.Map_RoomIndex[DungeonRoom.GridY][DungeonRoom.GridX] = _RoomIndex;
		if(DungeonRoom.GridW == 2) global.Level.Map_RoomIndex[DungeonRoom.GridY][DungeonRoom.GridX + 1] = _RoomIndex;
		if(DungeonRoom.GridH == 2) global.Level.Map_RoomIndex[DungeonRoom.GridY + 1][DungeonRoom.GridX] = _RoomIndex;
		if(DungeonRoom.GridW == 2 && DungeonRoom.GridH == 2) global.Level.Map_RoomIndex[DungeonRoom.GridY + 1][DungeonRoom.GridX + 1] = _RoomIndex;

		Room = new Dungeon_CreateStruct_Room(_RoomIndex);
		
		for(var _DoorIndex = 0; _DoorIndex < Room.DoorCount; _DoorIndex++){	
			
			var _Door = Room.Doors[_DoorIndex];
			
			//Set any doors to unsed that are entrances and exits that are not needed for this dungeon transformation
			
			switch(_Door.Status){
				case DoorStatus.Entrance:
					if((global.Level.StartDir == UP && _Door.Location != "Bottom") || (global.Level.StartDir == DOWN && _Door.Location != "Top")){
						_Door.Status = DoorStatus.Unused;
					}
					break;
					
				case DoorStatus.Exit:
					if(global.Level.IsBossLevel && _Door.Location == "Top"){
						_Door.Status = DoorStatus.Open;
					}else if((global.Level.StartDir == UP && _Door.Location != "Top") || (global.Level.StartDir == DOWN && _Door.Location != "Bottom")){
						_Door.Status = DoorStatus.Unused;
					}
					break;
			}

			if(_Door.Status == DoorStatus.Unused) continue;
			
			Room.DoorCode = Room.DoorCode | power(2, _Door.Position - 1);


		}		
		
		if(DungeonRoom.SpecialObj == SpecialDungeonObj.Boss){
			if(DungeonRoom.GridY <= _LowestBossRoomGridY){
				_LowestBossRoomGridY = DungeonRoom.GridY;
				//set the boss Room index
				global.Level.RoomIndex_Boss = _RoomIndex;		
			}
		}
		
		//special case for Aghanim's lair
		if(LevelDef.Special == LevelSpecial.FinalBoss && DungeonRoom.GridW == 1 && DungeonRoom.GridH == 1){
			global.Level.RoomIndex_Boss = _RoomIndex;
		}
		
	}

	Dungeon_ExitToTop();
	Dungeon_PlanExits();

	//set up secret room. This has to be done in a seperate loop after all the rooms have been initialised
	for(var _RoomIndex = 0; _RoomIndex < global.Level.RoomCount; _RoomIndex++){
		
		if(Room.Secret != -1) continue; //continue if this Room has already been flagged as secret
						
		if(Room.TemplateClass == RoomTemplateClass.Special){ //secret Rooms will only have 1 door

			var _DoorPos = DungeonRoom.Doors[0].Position;

			if(LevelDef.TMNTRoom && _DoorPos == 18 && Prob(Chance_TMNT)){
				Room.TemplateClass = RoomTemplateClass.Other;
				Room.TemplateSubClass = RoomTemplateClass_Other.Unique;
				Room.TemplateName = "TMNT";
				global.Level.TMNTRoom = true;
			}else if(LevelDef.Special == LevelSpecial.Village && Room.GridX == 6 && Room.GridY == 1){
				Room.TemplateClass = RoomTemplateClass.Other;
				Room.TemplateSubClass = RoomTemplateClass_Other.Unique;
				Room.TemplateName = "Zora";
				continue;
			}else if(LevelDef.Special == LevelSpecial.Mines && Room.GridX == 7 && Room.GridY == 1){
				Room.TemplateClass = RoomTemplateClass.Other;
				Room.TemplateSubClass = RoomTemplateClass_Other.Unique;
				Room.TemplateName = "Zora";
				continue;				
			}else if((!global.Level.FairyRoom || !global.Level.GemPondRoom) && LevelDef.FairyRooms && (_DoorPos == 6 || _DoorPos == 18)){
				if(Prob(Chance_SpecialRoomFairyOrGemPond)){
					Room.FairyOrGemPond = true;
					continue;
				}
			}


			
			//This is the prob that a Special Room will be hidden with secret doors. Otherwise the special Room will have regular doors
			//Use only secret_closed doors for village
			
			if(Prob(Chance_SecretDoor) || LevelDef.Special == LevelSpecial.Village || LevelDef.Special == LevelSpecial.Mines || Room.TemplateName = "TMNT"){ 
				
				Room.Secret = 1;
				
				if(LevelDef.Special == LevelSpecial.Village && Room.GridX == 3 && Room.GridY == 0) continue; //special locked door with special Room, so don't make door secret

				Dungeon_HideSpecialRoom(_RoomIndex);

			}

		}

				
				
	}

	
	global.CarpetTileBase = GetTileID(111, LevelTilesY + 2); 
	global.CarpetTileTrim = GetTileID(110, LevelTilesY + 4); 	

	
	//Add 0 to Rooms-1 to list, then shuffle. Pick Rooms from the list instead of doing them sequencially.
	//This prevents things like shops to be bunched up in Rooms by the entrance, it spreads them out
	
	var ShuffledRoomIndexesList = ds_list_create_sequence_shuffled(0, global.Level.RoomCount - 1);
	var _SetMisses = array_create(global.Level.RoomCount, 0);	//templates of the level's room set that fit a room but could not hold its special objects


	for(var _RoomListIndex = 0; _RoomListIndex < global.Level.RoomCount; _RoomListIndex++){
		
		var _RoomIndex = ShuffledRoomIndexesList[| _RoomListIndex];


		//check if this room's template is a boss room. There may be  up to 3 possible boss rooms, any that don't have the door at pos 6 or 12 should be ignored since those should not be used based on dungeon rotation
		if(TemplateCheck(_RoomIndex, RoomTemplateClass.Other, RoomTemplateClass_Other.Boss)){
			
			if(!global.Level.IsBossLevel) continue;	
			
			if(_RoomIndex != global.Level.RoomIndex_Boss) continue;
		
		}

		global.SpawnedBlocks = false;
							
		var _UseSet = (_SetMisses[_RoomIndex] < ROOMSET_MAXMISSES);	//a set template is picked again after a miss; after a few, the shared ones
		Room.Template = RoomTemplates_Pick(_RoomIndex, _UseSet);

		if(Room.Template == -1 && _RoomIndex == global.Level.Exits.ExtraRoom){
			Dungeon_DropExtraExit(_RoomIndex);	//no template fits the extra exit door: the level keeps only the main exit
			Room.Template = RoomTemplates_Pick(_RoomIndex, _UseSet);
		}

		if(Room.Template == -1){
			//continue;
			
			if(DEBUG){
				Error("Room index " + string(_RoomIndex) + " doesn't have a suitable template for dungeon index " + string(global.Level.DungeonTemplate_Index) + "  with transformation " + TransformationStr(global.Level.Transformation), true);
			}else{
				Error("Error: Cannot generate level", true);
			}
			exit;
				
		}	

		Map_GenerateRoomSprite(_RoomIndex);
			
		Room.TemplateName = Room.Template[$ "name"];	
		Room.Lighting = Lighting_GetRoomStatus(_RoomIndex);	
		
		var RoomTemplateProperties = Room.Template[$"properties"];
		
		Room.ForcedTheme = GetPropertyValue(RoomTemplateProperties, "ForceWallTheme");
		Room.ForcedTheme_Floor = GetPropertyValue(RoomTemplateProperties, "ForceFloorTheme");
		Room.ForcedTheme_Floor_Upper = GetPropertyValue(RoomTemplateProperties, "ForceFloorTheme_Upper");
		Room.ForcedTheme_Floor_Lower = GetPropertyValue(RoomTemplateProperties, "ForceFloorTheme_Lower");
			
		if(TemplateCheck(_RoomIndex, RoomTemplateClass.Other, RoomTemplateClass_Other.Boss)) Room.RoomSongIndex = SongIndex.Boss;
		if(TemplateCheck(_RoomIndex, RoomTemplateClass.Other, RoomTemplateClass_Other.Unique, "FinalBoss")) Room.RoomSongIndex = SongIndex.Boss_Final;
		if(TemplateCheck(_RoomIndex, RoomTemplateClass.Special, RoomTemplateClass_Special.Fairy)) Room.RoomSongIndex = SongIndex.Fairy;
		if(TemplateCheck(_RoomIndex, RoomTemplateClass.Other, RoomTemplateClass_Other.Unique, "WishRoom")) Room.RoomSongIndex = SongIndex.WishRoom;			
		if(TemplateCheck(_RoomIndex, RoomTemplateClass.Special, RoomTemplateClass_Special.GemPond) || TemplateCheck(_RoomIndex, RoomTemplateClass.Other, RoomTemplateClass_Other.Unique, "Zora")) Room.RoomSongIndex = SongIndex.GemPond;
		if(TemplateCheck(_RoomIndex, RoomTemplateClass.Other, RoomTemplateClass_Other.Unique, "TMNT")) Room.RoomSongIndex = SongIndex.TMNT;

		switch(LevelDef.Special){
			case LevelSpecial.Village:
				if(TemplateCheck(_RoomIndex, RoomTemplateClass.Village, RoomTemplateClass_Village.Main) || TemplateCheck(_RoomIndex, RoomTemplateClass.Village, RoomTemplateClass_Village.House)) Room.RoomSongIndex = SongIndex.Village;
				if(TemplateCheck(_RoomIndex, RoomTemplateClass.Village, RoomTemplateClass_Village.Exit, "Exit")) Room.RoomSongIndex = SongIndex.Village_Cave;
				if(TemplateCheck(_RoomIndex, RoomTemplateClass.Village, RoomTemplateClass_Village.House, "Arcade")) Room.RoomSongIndex = SongIndex.Village_Arcade;
				if(TemplateCheck(_RoomIndex, RoomTemplateClass.Village, RoomTemplateClass_Village.House, "Store")) Room.RoomSongIndex = SongIndex.Village_Store;	
				if(TemplateCheck(_RoomIndex, RoomTemplateClass.Village, RoomTemplateClass_Village.House, "Pub")) Room.RoomSongIndex = SongIndex.Village_Pub;
				break;
					
			case LevelSpecial.Mines:
				if(TemplateCheck(_RoomIndex, RoomTemplateClass.Mines, RoomTemplateClass_Mines.House, "Store")) Room.RoomSongIndex = SongIndex.Village_Store;
				if(global.MainTemplates_Mine[Room.GridY][Room.GridX] == 1 || global.MainTemplates_Mine[Room.GridY][Room.GridX] == 5 || global.MainTemplates_Mine[Room.GridY][Room.GridX] >= 8) Room.RoomSongIndex = SongIndex.Village_Cave;
				break;
		}

			
		Dungeon_Draw_Floors(_RoomIndex);
		
		Dungeon_Draw_Walls(_RoomIndex);
		
		var _Painted = RegionRoom_Paint(_RoomIndex);	//a room painted with the region tileset, walls from its tiles (roadmap F12b)
		if(_Painted) Map_GenerateRoomSprite(_RoomIndex);	//again, now with the painted walls
		
		if(LevelDef.Ceiling && !_Painted && !TemplateCheck(_RoomIndex, RoomTemplateClass.Village, RoomTemplateClass_Village.Main)){
			Dungeon_Draw_Ceiling(GetTileID(8, LevelTilesY + 2), Room.TileX, Room.TileY, Room.TileX, Room.TileY, Room.TileX + Room.TileW, Room.TileY + Room.TileH);
		}
		
		Dungeon_Draw_ExtraCeilings(_RoomIndex);		
		
		Dungeon_CreateDoors(_RoomIndex);
			
		Dungeon_Draw_Carpets(_RoomIndex);
		Dungeon_Draw_CarpetsFull(_RoomIndex);
		
		Dungeon_Draw_Pit(_RoomIndex);
		
		Dungeon_Draw_Holes(_RoomIndex);
			
		global.SpawnedWater = false;
		Dungeon_Draw_Water(_RoomIndex);
				
		Dungeon_Draw_Stairs(_RoomIndex);
			
		global.SpawnedMovingFloors = false;
		Dungeon_Draw_FloorObjs(_RoomIndex); 		

		global.Switch_Add = false;
		global.Switch_Spawned = false;

		Dungeon_Draw_SpecialObjs_Forced(_RoomIndex);
		
		if(DEBUG){
			SpawnBoss(_RoomIndex);
		}else{
			SpawnBoss(_RoomIndex);
		}
			
		var SpawnedSpecialObs = Dungeon_Draw_SpecialObjs(_RoomIndex);
					
		if(!DEBUG && !SpawnedSpecialObs){
						
			//important special objects couldn't spawn, so clear room and try another template
			if(Room.Template[$ "RoomSet"] != undefined) _SetMisses[_RoomIndex]++;

			//items that may have spawned in Dungeon_Draw_SpecialObjs before exiting
			var ObjsToDestroyList = ds_list_create();						
			ds_list_add(ObjsToDestroyList, oWall, oDoor, oSwitch, oSwitchBlock, oMovingFloor, oWarp, oShop, oPrisoner, oItem, oPickupObj, oEnemy, oDeadHungryGuy, oHeartGuy, oTombSkeleton);
			var ObjsToDestroy = ds_list_size(ObjsToDestroyList);
						
			var ObjCollisionList = ds_list_create();						
			for(var i = 0; i < ObjsToDestroy; i++){
				ds_list_clear(ObjCollisionList); 
				var _Obj = ObjsToDestroyList[| i];
				var _Objs = collision_rectangle_list(Room.x + 0.5, Room.y + 0.5, Room.x + (Room.GridW * 256) - 1, Room.y + (Room.GridH * 256) - 1, _Obj, false, true, ObjCollisionList, false);
				for(var j = 0; j < _Objs; j++){
					instance_destroy(ObjCollisionList[| j]);
				}
			}
						
			ds_list_destroy(ObjCollisionList);
			ds_list_destroy(ObjsToDestroyList);

			for(var i = 0; i < array_length(global.TMID); i++){
				ClearTileBlock(global.TMID[i], Room.x, Room.y, Room.TileW, Room.TileH);
			}
			if(RegionRoom_Is(_RoomIndex)){
				ClearTileBlock(RegionTiles_Tilemap(UPPER), Room.x, Room.y, Room.TileW, Room.TileH);
				variable_struct_remove(Room, "RegionGrid");
			}
									
			_RoomListIndex--;
			
			Room.UsedSpace = [];
			delete Room.RoomTemplate;
			
			continue;
						
		} 

		
		if(DEBUG){
			if(!SpawnedSpecialObs){
				Error("No suitable room template for special objs for dungeon index " + string(global.Level.DungeonTemplate_Index) + ", Room index " + string(_RoomIndex) + ", template id " + string(Room.Template[$ "id"]), true);
				exit;
			}			
		}
		
		Dungeon_Draw_WallDecor(_RoomIndex);
		
		if(LevelDef.Special == LevelSpecial.FinalBoss){

			switch(_RoomIndex){
				case 0:	
				
					if(DEBUG){
						instance_create_layer(Room.x + 93, Room.y + 60, "Objs_Upper", oFinalBossGate);
						instance_create_layer(Room.x, Room.y, "ObjsFloor_Upper", oCrystalEnd);	
						DrawTileBlock(global.TMID_Decor_Upper, Room.x + 88, Room.y + 16, 74, 0, 3, 4);
						DrawTileBlock(global.TMID_Decor_Upper, Room.x + 144, Room.y + 16, 77, 0, 3, 4);
					}else{
						instance_create_layer(Room.x + 93, Room.y + 60, "Objs_Upper", oFinalBossGate);
						instance_create_layer(Room.x, Room.y, "ObjsFloor_Upper", oCrystalEnd);	
						DrawTileBlock(global.TMID_Decor_Upper, Room.x + 88, Room.y + 16, 74, 0, 3, 4);
						DrawTileBlock(global.TMID_Decor_Upper, Room.x + 144, Room.y + 16, 77, 0, 3, 4);
					}

					
					break;
			
				case 1:
					DrawTileBlock(global.TMID_Decor_Upper, Room.x + 88, Room.y + 208, 80, 0, 3, 4);
					DrawTileBlock(global.TMID_Decor_Upper, Room.x + 144, Room.y + 208, 83, 0, 3, 4);
					
					var VarStruct = {FloorLevel : UPPER, ItemHolding : -1, SectionID: 0, RoomIndex : _RoomIndex};
					instance_create_layer(Room.x + 128, Room.y + 74, "ObjsHigher_Upper", oBoss_Aghanim, VarStruct);						
					break;
			
			}

			instance_create_layer(Room.x, Room.y, "Starfield", oStarfield, {RoomH : Room.height});
			layer_set_visible(global.LayerID_Starfield, true);
			
		}

		
	}
	

	//temp
	//with(oItem_Treasure){
	//	if(collision_rectangle(x - 16, y, x + 16, y + 32, oSign, false, true) != noone){
	//		oGame.alarm[0] = -1;
	//		var a = 0;
	//	}		
	//}
	
	
	Map_Init();
	
	Dungeon_InitDoors();

	ds_list_destroy(ShuffledRoomIndexesList);

	Test_OnLevelBuilt();	// test mode only: dump of the level while every room is still awake

	Link_SetStartingPos();

	Achievements_OnLevelStart(global.Level.Index);

	
	if(LevelDef.Special == LevelSpecial.Intro){
		var _inst = instance_create_layer(-100, -100, "System", oIntro);		
	}
	Weather_Start();	// the level's rain and lightning (the intro's is already there, made by oIntro)
	
	if(LevelDef.RunStart){
		if(audio_is_playing(global.RainSound)){
			audio_sound_gain(global.RainSound, 0.3, 200)
		}
		global.StatsToAdd[Stat.GamesPlayed]++;
		oRender.FadeIn();
	}
	
	input_clear_momentary(true);
	
	if(DEBUG) InitPreviewCam();
	
	if(DEBUG){
		if(LevelDef.Special == LevelSpecial.Village){
			Music_Play(SongIndex.Village);	
		}else{
			if(LevelDef.Special != LevelSpecial.Intro) Music_Play(LevelDef.Song);	
		}
	}else{
		if(LevelDef.Special != LevelSpecial.Intro) Music_Play(LevelDef.Song);	
	}
	
}

/// Exits of the level (roadmap F4b), drawn from the pools of the level sheet: where the main exit leads and, sometimes,
/// an extra exit far from it, maybe in a secret room behind a bombable wall. Runs after every room struct exists and
/// before the secret rooms and the templates are picked. A level whose exits can only lead to one level draws nothing
/// and gets no extra exit, so today's levels are built exactly as before. The main exit is the layout's and never hidden.
function Dungeon_PlanExits(){
	var _Exits = global.Level.Exits;
	if(array_length(LevelDef.NextPool) == 0) exit;
	_Exits.Dest = Level_PoolPick(LevelDef.NextPool);
	if(!Level_Branches(LevelDef)) exit;

	var _Log = "exits main->" + string(_Exits.Dest);

	//fixed layouts keep their exit; boss levels leave through the boss room, an extra exit would skip the boss
	if(LevelDef.Special != LevelSpecial.None || global.Level.IsBossLevel || Level_PoolPick(LevelDef.ExitCount) < 2){
		Test_Event(_Log + " count=1");
		exit;
	}
	var _Secret = Level_PoolPick(LevelDef.ExitHidden);

	//the main exit: its room and where that room is across the map (columns doubled, so the middle is a whole number)
	var _MainRoom = global.Level.RoomIndex_BossAdjacent;
	if(_MainRoom == -1) exit;
	var _MinX = DungeonGridW;
	var _MaxX = 0;
	var _RoomIndex;
	for(_RoomIndex = 0; _RoomIndex < global.Level.RoomCount; _RoomIndex++){
		_MinX = min(_MinX, Room.GridX);
		_MaxX = max(_MaxX, Room.GridX + Room.GridW - 1);
	}
	var _Middle2 = _MinX + _MaxX + 1;
	var _Main2 = 2 * global.Level.Rooms[_MainRoom].GridX + global.Level.Rooms[_MainRoom].GridW;

	//rooms where the extra exit fits: a stairway in the middle of the top or bottom wall (upper floor), with no room
	//behind that wall, at least ExitMinDistance columns from the main exit and across the middle of the map.
	//Hidden: a special room with one door, which then gets a bombable secret door. Otherwise an ordinary room.
	var _Candidates = [[], []];	//[ordinary, secret], each [room, position, location]
	for(_RoomIndex = 0; _RoomIndex < global.Level.RoomCount; _RoomIndex++){
		if(_RoomIndex == _MainRoom || _RoomIndex == global.Level.RoomIndex_Entrance) continue;
		if(Room.GridW != 1 || Room.Section_ID != 0 || Room.LowerDoors) continue;

		var _Kind = -1;
		if(Room.SpecialObject == SpecialDungeonObj.None && Room.TemplateClass != RoomTemplateClass.Special) _Kind = 0;
		if(Room.SpecialObject == SpecialDungeonObj.SpecialRoom && Room.TemplateClass == RoomTemplateClass.Special && Room.DoorCount == 1) _Kind = 1;
		if(_Kind == -1) continue;

		var _Room2 = 2 * Room.GridX + Room.GridW;
		if(abs(_Room2 - _Main2) < 2 * LevelDef.ExitMinDistance) continue;
		if(_Main2 != _Middle2 && sign(_Room2 - _Middle2) != -sign(_Main2 - _Middle2)) continue;

		var _Walls = [["Top", 12, Room.GridY - 1], ["Bottom", 6, Room.GridY + Room.GridH]];
		for(var w = 0; w < (LevelDef.ExitWall == "Top" ? 1 : 2); w++){
			var _BehindY = _Walls[w][2];
			if(_BehindY >= 0 && _BehindY < DungeonGridW && global.Level.Map_RoomIndex[_BehindY][Room.GridX] != -1) continue;
			var _Free = true;
			for(var d = 0; d < Room.DoorCount; d++){
				if(Room.Doors[d].Position == _Walls[w][1]) _Free = false;
			}
			if(_Free) array_push(_Candidates[_Kind], [_RoomIndex, _Walls[w][1], _Walls[w][0]]);
		}
	}

	//no special room for a hidden exit: it stays in sight; no room at all: one exit
	if(_Secret && array_length(_Candidates[1]) == 0) _Secret = false;
	var _List = _Candidates[_Secret ? 1 : 0];
	if(array_length(_List) == 0){
		Test_Event(_Log + " count=1 (no room for the extra exit)");
		exit;
	}
	var _Pick = _List[irandom(array_length(_List) - 1)];
	_RoomIndex = _Pick[0];

	var _Door = new Dungeon_CreateStruct_Door();
	_Door.Position = _Pick[1];
	_Door.Location = _Pick[2];
	_Door.ConnectedRoomIndex = -1;
	_Door.x = global.DoorCoordinates[Room.SizeIndex][_Door.Position].x;
	_Door.y = global.DoorCoordinates[Room.SizeIndex][_Door.Position].y;
	_Door.Level = RoomTemplates_GetDoorLevel(_Door.x, _Door.y);
	_Door.Status = DoorStatus.Exit;
	_Door.ExitDest = Level_PoolPick(LevelDef.NextPool);
	array_push(Room.Doors, _Door);
	Room.DoorCount++;
	Room.UpperDoors = true;
	Room.DoorCode = Room.DoorCode | power(2, _Door.Position - 1);

	_Exits.ExtraRoom = _RoomIndex;
	_Exits.ExtraPosition = _Door.Position;
	_Exits.ExtraSecret = _Secret;
	if(_Secret){
		Room.Secret = 1;
		Dungeon_HideSpecialRoom(_RoomIndex);
	}

	Test_Event(_Log + " count=2 extra=room " + string(_RoomIndex) + " grid=" + string(Room.GridX) + "," + string(Room.GridY) + " " + _Door.Location
		+ (_Secret ? " secret" : "") + "->" + string(_Door.ExitDest) + " main=room " + string(_MainRoom) + " grid=" + string(global.Level.Rooms[_MainRoom].GridX) + "," + string(global.Level.Rooms[_MainRoom].GridY));
}

/// Takes the extra exit out of its room again, when no room template has a door where it is
function Dungeon_DropExtraExit(_RoomIndex){
	var _Exits = global.Level.Exits;
	array_pop(Room.Doors);	//the extra exit is always the room's last door
	Room.DoorCount--;
	Room.DoorCode = Room.DoorCode & ~power(2, _Exits.ExtraPosition - 1);
	Test_Event("exits extra dropped room=" + string(_RoomIndex) + " (no template with that door)");
	_Exits.ExtraRoom = -1;
	_Exits.ExtraPosition = -1;
	_Exits.ExtraSecret = false;
}

/// ExitWall "Top" (the castle rooftops, painted rooms that share their border, roadmap F12b-2): the level's entrance and
/// main exit are doors of the layout, and their passage (or the stairs) would meet the closed border of a room behind
/// that wall. The main exit moves to the middle of the top wall of a room one column wide, where the frame has the gate,
/// which leaves the border as it is (whatever is behind); a top entrance with a room behind it does the same. Where
/// that is taken, an exit with a room behind takes a top or bottom position with nothing behind, and an entrance a
/// position of its own wall with nothing behind. A bottom exit with nothing behind only moves to the gate.
/// A new position takes no door beside a door in use (their passages would touch). Where no position is free the door
/// stays (Test_CheckSeams then reports the seam).
function Dungeon_ExitToTop(){
	if(LevelDef.ExitWall != "Top") exit;
	for(var _RoomIndex = 0; _RoomIndex < global.Level.RoomCount; _RoomIndex++){
		for(var d = 0; d < Room.DoorCount; d++){
			var _Door = Room.Doors[d];
			var _Exit = (_Door.Status == DoorStatus.Exit);
			if(!_Exit && _Door.Status != DoorStatus.Entrance) continue;
			var _Gate = (Room.GridW == 1);
			var _Behind = Dungeon_DoorBehind(_RoomIndex, _Door.Position);
			if(_Door.Location == "Top" && (_Gate ? _Door.Position == 12 : !_Behind)) continue;
			if(!_Exit && !_Behind) continue;
			//the positions to try, in order: the gate, then (where something is behind) the walls the door may take
			var _Try = [];
			if(_Gate && (_Exit || _Door.Location == "Top")) array_push(_Try, 12);
			var _Walls = !_Behind ? [] : (_Exit ? ["Top", "Bottom"] : [_Door.Location]);
			for(var w = 0; w < array_length(_Walls); w++){
				var _Ps = (_Walls[w] == "Top") ? [12, 11, 1] : ((_Walls[w] == "Bottom") ? [6, 7, 5] : ((_Walls[w] == "Left") ? [9, 8, 10] : [3, 2, 4]));
				for(var k = 0; k < 3; k++) array_push(_Try, _Ps[k]);
			}
			var _To = -1;
			for(var t = 0; t < array_length(_Try) && _To == -1; t++){
				var _P = _Try[t];
				if(_P == _Door.Position || (Dungeon_DoorBehind(_RoomIndex, _P) && !(_Gate && _P == 12))) continue;
				var _Free = true;
				for(var e = 0; e < Room.DoorCount; e++){
					if(e == d || Room.Doors[e].Status == DoorStatus.Unused) continue;
					var _Q = Room.Doors[e].Position;
					if(_Q == _P || _Q == (_P mod 12) + 1 || _P == (_Q mod 12) + 1) _Free = false;
				}
				if(_Free) _To = _P;
			}
			if(_To == -1){
				Test_Event((_Exit ? "exits main" : "entrance") + " stays in the " + string_lower(_Door.Location) + " wall room=" + string(_RoomIndex));
				continue;
			}
			Room.DoorCode = Room.DoorCode & ~power(2, _Door.Position - 1);
			_Door.Position = _To;
			_Door.Location = (_To == 11 || _To == 12 || _To == 1) ? "Top" : ((_To >= 5 && _To <= 7) ? "Bottom" : ((_To >= 2 && _To <= 4) ? "Right" : "Left"));
			_Door.x = global.DoorCoordinates[Room.SizeIndex][_To].x;
			_Door.y = global.DoorCoordinates[Room.SizeIndex][_To].y;
			_Door.Level = RoomTemplates_GetDoorLevel(_Door.x, _Door.y);
			Room.DoorCode = Room.DoorCode | power(2, _To - 1);
			Test_Event((_Exit ? "exits main" : "entrance") + " moved to the " + string_lower(_Door.Location) + " wall room=" + string(_RoomIndex) + " position=" + string(_To));
		}
	}
}

/// Whether a layout's seams can all be painted by a set of rooms that share a frame (roadmap F12b-2). Two rooms of two
/// cells along the same long wall (2x1 above 2x1, 1x2 beside 1x2) would show where the frame's four corners meet,
/// which no map shows and Guilherme refused as a join. With ExitWall "Top", the entrance must also find a place that
/// meets nothing (Dungeon_ExitToTop): the gate (top wall of a room one column wide, positions 11 and 1 not in use) or
/// a position of its own wall with nothing behind.
function Dungeon_LayoutSeamsOk(_Template, _LevelIndex){
	var _Rooms = _Template.Rooms;
	var _N = array_length(_Rooms);
	for(var a = 0; a < _N; a++){
		var _A = _Rooms[a];
		for(var b = 0; b < _N; b++){
			var _B = _Rooms[b];
			if(_A.GridW == 2 && _B.GridW == 2 && _A.GridX == _B.GridX && _B.GridY == _A.GridY + _A.GridH) return false;
			if(_A.GridH == 2 && _B.GridH == 2 && _A.GridY == _B.GridY && _B.GridX == _A.GridX + _A.GridW) return false;
		}
	}
	var _Def = global.LevelDefs[_LevelIndex];
	if(_Def.ExitWall != "Top") return true;
	var _Wall = (Dungeon_StartDir(_LevelIndex) == UP) ? "Bottom" : "Top";
	var _Occupied = function(_Rooms, _X, _Y){
		for(var r = 0; r < array_length(_Rooms); r++){
			var _R = _Rooms[r];
			if(_X >= _R.GridX && _X < _R.GridX + _R.GridW && _Y >= _R.GridY && _Y < _R.GridY + _R.GridH) return true;
		}
		return false;
	};
	for(var r = 0; r < _N; r++){
		var _R = _Rooms[r];
		for(var d = 0; d < array_length(_R.Doors); d++){
			var _Door = _R.Doors[d];
			if(_Door.Status != DoorStatus.Entrance || _Door.Location != _Wall) continue;
			//the doors of the room in use: the other entrances go unused, and so do the exits not in the wall across
			//from the entrance (Dungeon_InitLevel)
			var _Used = [];
			for(var e = 0; e < array_length(_R.Doors); e++){
				var _St = _R.Doors[e].Status;
				if(e == d || _St == DoorStatus.Unused || _St == DoorStatus.Entrance) continue;
				if(_St == DoorStatus.Exit && _R.Doors[e].Location == _Wall) continue;
				array_push(_Used, _R.Doors[e].Position);
			}
			var _Ps = (_Wall == "Top") ? [_Door.Position, 12, 11, 1] : [_Door.Position, 6, 7, 5];
			for(var k = 0; k < array_length(_Ps); k++){
				var _P = _Ps[k];
				var _Free = true;
				for(var u = 0; u < array_length(_Used); u++){
					var _Q = _Used[u];
					if(_Q == _P || _Q == (_P mod 12) + 1 || _P == (_Q mod 12) + 1) _Free = false;
				}
				if(!_Free) continue;
				if(_Wall == "Top" && _R.GridW == 1 && _P == 12) return true;
				var _X = global.DoorCoordinates[global.RoomSizeIndex[_R.GridW][_R.GridH]][_P].x;
				var _Y = (_Wall == "Top") ? _R.GridY - 1 : _R.GridY + _R.GridH;
				if(!_Occupied(_Rooms, _R.GridX + (_X div 256), _Y) && !_Occupied(_Rooms, _R.GridX + ((_X + 31) div 256), _Y)) return true;
			}
			return false;
		}
	}
	return true;
}

/// Whether a room of the level is behind the wall of door position _Position (1 to 12) of the room: the grid cells its
/// 32 px door spans, one step out of the room
function Dungeon_DoorBehind(_RoomIndex, _Position){
	var _X = global.DoorCoordinates[Room.SizeIndex][_Position].x;
	var _Y = global.DoorCoordinates[Room.SizeIndex][_Position].y;
	var _Cells = [];
	switch(_Position){
		case 11: case 12: case 1:	array_push(_Cells, [Room.GridX + (_X div 256), Room.GridY - 1], [Room.GridX + ((_X + 31) div 256), Room.GridY - 1]); break;
		case 5: case 6: case 7:		array_push(_Cells, [Room.GridX + (_X div 256), Room.GridY + Room.GridH], [Room.GridX + ((_X + 31) div 256), Room.GridY + Room.GridH]); break;
		case 8: case 9: case 10:	array_push(_Cells, [Room.GridX - 1, Room.GridY + (_Y div 256)], [Room.GridX - 1, Room.GridY + ((_Y + 31) div 256)]); break;
		default:					array_push(_Cells, [Room.GridX + Room.GridW, Room.GridY + (_Y div 256)], [Room.GridX + Room.GridW, Room.GridY + ((_Y + 31) div 256)]); break;
	}
	for(var c = 0; c < 2; c++){
		var _CX = _Cells[c][0], _CY = _Cells[c][1];
		if(_CY >= 0 && _CY < array_length(global.Level.Map_RoomIndex) && _CX >= 0 && _CX < array_length(global.Level.Map_RoomIndex[_CY])
			&& global.Level.Map_RoomIndex[_CY][_CX] != -1) return true;
	}
	return false;
}

/// Makes the only door of a special room, and the door on the other side, secret doors
function Dungeon_HideSpecialRoom(_RoomIndex){

	Room.Doors[0].Status = DoorStatus.Secret_Closed; //special Rooms should always only have 1 door into them, so we can index at 0

	var _ConnectedRoomTemplateIndex = Room.Doors[0].ConnectedRoomIndex;
	var _ConnectedRoomTemplate = global.Level.DungeonTemplate.Rooms[_ConnectedRoomTemplateIndex];
	var _ConnectedRoomTemplateRSI = global.RoomSizeIndex[_ConnectedRoomTemplate.GridW][_ConnectedRoomTemplate.GridH];
	var _ConnectedDoorPos = Door_GetConnectedPos(Room.GridX, Room.GridY, Room.SizeIndex, _ConnectedRoomTemplate.GridX, _ConnectedRoomTemplate.GridY, _ConnectedRoomTemplateRSI, Room.Doors[0].Position);

	var _ConnectedRoom = global.Level.Rooms[_ConnectedRoomTemplateIndex];

	var _ConnectedRoomTemplateDoorsArray = _ConnectedRoomTemplate.Doors;
	var ConnectedRoomTemplateDoors = array_length(_ConnectedRoomTemplateDoorsArray);
	for(var i = 0; i < ConnectedRoomTemplateDoors; i++){
		var _ConnectedDoor = _ConnectedRoomTemplateDoorsArray[i];
		if(_ConnectedDoor.Position == _ConnectedDoorPos){
			_ConnectedRoom.Doors[i].Status = DoorStatus.Secret_Closed;
			break;
		}
	}

}

function Dungeon_InitSaveLevel(_LevelIndex){
	
	Dungeon_Clear();
	
	global.Level = new Dungeon_CreateStruct_Level(_LevelIndex);
	
	var _RoomIndex = 0;
	
	var _DungeonRoom = global.Level.DungeonTemplate[$ "Rooms"][_RoomIndex];
	global.Level.Map_RoomIndex[_DungeonRoom.GridY][_DungeonRoom.GridX] = 0;		
	
	Room = new Dungeon_CreateStruct_Room(_RoomIndex);
	
	Room.Template = RoomTemplates_Pick(_RoomIndex);
	
	Room.TemplateName = Room.Template[$ "name"];	
	Room.Lighting = Lighting_GetRoomStatus(_RoomIndex);	
	
	Map_GenerateRoomSprite(_RoomIndex);
	
	Dungeon_Draw_Floors(_RoomIndex);
		
	Dungeon_Draw_Walls(_RoomIndex);
		
	Dungeon_Draw_Ceiling(GetTileID(8, LevelTilesY + 2), Room.TileX, Room.TileY, Room.TileX, Room.TileY, Room.TileX + Room.TileW, Room.TileY + Room.TileH);
		
	Dungeon_Draw_ExtraCeilings(_RoomIndex);		
		
	Dungeon_CreateDoors(_RoomIndex);

	//Dungeon_Draw_FloorObjs(_RoomIndex); 		

	Dungeon_Draw_SpecialObjs_Forced(_RoomIndex);

	Map_Init();
	
	Dungeon_InitDoors();
	
	Link_SetStartingPos();
	
	input_clear_momentary(true);
	
	if(DEBUG) InitPreviewCam();
	
}

function Dungeon_LoadTemplates(){
	
	var _TemplateBuffer = buffer_load(GAMEFILE_DUNGEONTEMPLATES);
	
	var Templates_Dungeon_Temp = json_parse(buffer_read(_TemplateBuffer, buffer_string));
	buffer_delete(_TemplateBuffer);
	_TemplateBuffer = -1;
	
	global.Templates_Dungeon = array_create(DungeonClasses);
	for(var _ClassType = 0; _ClassType < DungeonClasses; _ClassType++){
		
		if(_ClassType != DungeonClass.Special) global.Templates_Dungeon[_ClassType] = array_create(TransformTypes);	
		
		global.Templates_Dungeon[_ClassType][ObjTransformation.None] = StructCopy(Templates_Dungeon_Temp[_ClassType]);
		
		if(_ClassType == DungeonClass.Special) continue; //special templates don't need the extra transformations added
		
		var _DungeonCount = array_length(global.Templates_Dungeon[_ClassType][ObjTransformation.None]);		
		
		for(var _TransformType = 1; _TransformType < TransformTypes; _TransformType++){
			
			for(var _DungeonIndex = 0; _DungeonIndex < _DungeonCount; _DungeonIndex++){				
			
				global.Templates_Dungeon[_ClassType][_TransformType][_DungeonIndex] = StructCopy(Templates_Dungeon_Temp[_ClassType][_DungeonIndex]);
				
				var _Dungeon = global.Templates_Dungeon[_ClassType][_TransformType][_DungeonIndex];
				
				var _RoomArray = _Dungeon[$ "Rooms"];
				var _Rooms = array_length(_RoomArray);					
				
				for(var _RoomIndex = 0; _RoomIndex < _Rooms; _RoomIndex++){
			
					var _Room = _RoomArray[_RoomIndex];

					var NewData = GetTransformedDungeonGrid(_Room.GridX, _Room.GridY, _Room.GridW, _Room.GridH, _TransformType);

					_Room.GridX = NewData[0];
					_Room.GridY = NewData[1];
					_Room.GridW = NewData[2];
					_Room.GridH = NewData[3];
			
					_Room.x = _Room.GridX * 256;
					_Room.y = _Room.GridY * 256;
					_Room.width = _Room.GridW * 256;
					_Room.height = _Room.GridH * 256;
				
					var _RoomSizeIndex = global.RoomSizeIndex[_Room.GridW][_Room.GridH];
			
					//transform Doors
					var _DoorArray = _Room.Doors;
					var _Doors = array_length(_DoorArray);
					for(var _DoorIndex = 0; _DoorIndex < _Doors; _DoorIndex++){
				
						var _Door = _DoorArray[_DoorIndex];
					
						_Door.Position = GetTransformedDoorPosition(_Door.Position, _TransformType);
						_Door.ConnectedDoorPos = GetTransformedDoorPosition(_Door.ConnectedDoorPos, _TransformType);
						_Door.x = global.DoorCoordinates[_RoomSizeIndex][_Door.Position].x;
						_Door.y = global.DoorCoordinates[_RoomSizeIndex][_Door.Position].y;
						_Door.Location = GetTransformedDoorLocation(_Door.Location, _TransformType);

						if(_Door.Status == DoorStatus.Entrance){
							_Dungeon.EntranceRoomIndex = _RoomIndex;						
						}
					
					}
			
					//Flip Section
					if(_Room[$ "Section_ID"] > 0) _Room[$ "Section_ID"] = GetTransformedSectionID(_Room[$ "Section_ID"], _TransformType);

					
				}
			}

		}
	
	}
	

	////set entrance index for all rooms in all dungeon templates
	
	//for(var _TransformType = 0; _TransformType < TransformTypes; _TransformType++){
		
	//	for(var _DungeonIndex = 0; _DungeonIndex < array_length(global.Templates_Dungeon[_TransformType]); _DungeonIndex++){
			
	//		var _Dungeon = global.Templates_Dungeon[_TransformType][_DungeonIndex];
	//		var _RoomArray = _Dungeon.Rooms;
	//		var _Rooms = array_length(_RoomArray);
			
	//		for(var _RoomIndex = 0; _RoomIndex < _Rooms; _RoomIndex++){
				
	//			var _Room = _RoomArray[_RoomIndex];
	//			variable_struct_set(_Room, "DoorCode", 0);
				
	//			var _DoorArray = _Room.Doors;
				
	//			var _Doors = array_length(_DoorArray);
	//			if(_Doors == 0) continue;
				
	//			for(var _DoorIndex = 0; _DoorIndex < _Doors; _DoorIndex++){
					
	//				var _Door = _DoorArray[_DoorIndex];
					
	//				_Room.DoorCode = _Room.DoorCode | power(2, _Door.Position - 1);
					

					
	//			}
				
	//		}
	//	}
	//}
	
	Templates_Dungeon_Temp = -1;
	gc_collect();
	
}

function Dungeon_DestroyLevel(){
	
	if(is_struct(global.Level)){
		for(var _RoomIndex = 0; _RoomIndex < global.Level.RoomCount; _RoomIndex++){
			var _Room = global.Level.Rooms[_RoomIndex];
			var _DoorCount = array_length(_Room.Doors);
			for(var _DoorIndex = 0; _DoorIndex < _DoorCount; _DoorIndex++){
				delete _Room.Doors[_DoorIndex];
			}
			delete _Room.Template;
			delete _Room
		}
		delete global.Level.SaveData;
		delete global.Level;
	}	
	
	global.Level = 0;
	
}

function Dungeon_RoomActivate(_RoomIndex){
	
	if(DEBUG){
		if(!global.DeactivateObjs) exit;
	}
	
	instance_activate_region(Room.x + 0.25, Room.y + 0.25, Room.width - 0.5, Room.height - 0.5, true);

	
}

function Dungeon_RoomDeActivate(_RoomIndex){
	
	if(DEBUG){
		if(!global.DeactivateObjs) exit;
	}
	
	Dungeon_DestroyUnimportantObjs();
	
	instance_deactivate_region(Room.x + 0.25, Room.y + 0.25, Room.width - 0.5, Room.height - 0.5, true, true);	
	
	//make sure important objects are kept activated
	
	instance_activate_object(oSwitchBlock); //these should remain active in the entire dungeon so they can still toggle even in a deactivated Room
	instance_activate_object(oStarfield);
	instance_activate_object(oEnemy_Wallmaster);
	
	if(instance_exists(oLink)){
		if(oLink.ItemHolding != noone) instance_activate_object(oLink.ItemHolding);
	}

}

function Dungeon_DestroyUnimportantObjs(_RoomIndex = -1){

		
	with(oPickupObj){
			
		if(id == oLink.ItemHolding) continue;
			
		if(_RoomIndex != -1 && RoomIndex != _RoomIndex) continue;

		switch(object_index){
			case oBush:
			case oPot:
				if(State == PickupObjState.Idle) continue;
				break;
					
			case oWishStone: //set certain pickup objs back down and reset them back to items
				z = 0;
				ObjSetY(y_base);
				PickupObj_ResetToItem(oItem_WishStone);
				break;
					
			case oGem:
				z = 0;
				ObjSetY(y_base);
				PickupObj_ResetToItem(oItem_Gem);
				break;

		}
			
		instance_destroy(id);
			
	}
	
	with(oProjectile){
		instance_destroy(id);
	}
	
	with(oEffects){
		instance_destroy(id);
	}
	
	
	//destroy enemies that are on fire, but also make sure to spawn any item they're carrying
	with(oEnemy){
		if(_RoomIndex != -1 && RoomIndex != _RoomIndex) continue;
		if(State == EnemyState.OnFire){
			Enemy_Destroy();
			if(ItemHolding != -1) Enemy_DestroySpawnItem(ItemHolding, Size, ItemSpawnType.None, false);			
		}
		
	}
	
}

function Dungeon_IsBossLevel(_Level){
	
	if(global.SaveLevel || global.HubLevel) return false
	
	return global.LevelDefs[_Level].Boss
}

function Dungeon_StartDir(_Level){
	
	if(global.HubLevel) return UP
	
	if(global.SaveLevel) return DOWN
	
	return global.LevelDefs[_Level].StartDir
}

function Dungeon_GetRoomIndex(_x, _y){
	
	//returns room index based on x/y position

	_x = clamp(_x, 0, DungeonW - 1);
	_y = clamp(_y, 0, DungeonW - 1);
	
	return global.Level.Map_RoomIndex[floor(_y / 256)][floor(_x / 256)];
}

function Dungeon_PickClass(_Level){
	
	if(global.SaveLevel || global.HubLevel) return DungeonClass.Special
	
	return global.LevelDefs[_Level].Class
	
}

function Dungeon_PickTemplateIndex(_LevelIndex, _Class, _Transformation){
	
	if(_Class == DungeonClass.Special){
		
		if(global.HubLevel) return HUB_DUNGEON_TEMPLATE
		
		if(global.SaveLevel) return 4
		
		return global.LevelDefs[_LevelIndex].Template
	}
	
	var _Templates = array_length(global.Templates_Dungeon[_Class][0]);
	
	var _Seq = global.Users[global.UserIndex].DungeonSeq[_Class];
	
	var _SeqLen = array_length(_Seq);

	
	if(_Templates < _SeqLen){
		//find any indexes that are larger than template count and delete them, some may not be there anymore after an update
		for(var i = 0; i < array_length(_Seq); i++){
			if(_Seq[i] >= _Templates){
				array_delete(_Seq, i, 1);
				if(i < global.Users[global.UserIndex].DungeonSeqIndex[_Class]) global.Users[global.UserIndex].DungeonSeqIndex[_Class]--;
				i--;
			}
		}
		
		_SeqLen = array_length(_Seq);
		
	}else if(_Templates > _SeqLen){
		//find any template indexes that are not in the seq and add them at the current seqindex
		var _Diff = _Templates - _SeqLen;
		for(var i = 0; i < _Diff; i++){
			array_insert(_Seq, global.Users[global.UserIndex].DungeonSeqIndex[_Class] + i, _Templates - _Diff + i);
		}		
		_SeqLen = array_length(_Seq);
	}


	if(global.Users[global.UserIndex].DungeonSeqIndex[_Class] >= _SeqLen){
		DungeonSeq_Randomize(_Class);
		global.Users[global.UserIndex].DungeonSeqIndex[_Class] = 0;
	}
	
	var _SeqIndex = global.Users[global.UserIndex].DungeonSeqIndex[_Class];
	var _TemplateIndex = _Seq[_SeqIndex];	
	
	global.Users[global.UserIndex].DungeonSeqIndex[_Class]++;

	User_Save();
	
	//show_debug_message(_Seq);
	//show_debug_message(global.Users[global.UserIndex].DungeonSeqIndex[_Class]);
	
	return _TemplateIndex;
	
}

function Dungeon_PickTemplateTransformation(_Level){
	
	if(global.SaveLevel || global.HubLevel) return ObjTransformation.None
	
	if(!global.LevelDefs[_Level].Transform) return ObjTransformation.None
	
	var _StartDir = Dungeon_StartDir(_Level);
	
	if(_StartDir == UP){
		return choose(ObjTransformation.None, ObjTransformation.FlipH, ObjTransformation.RotateCW, ObjTransformation.RotateCCW, ObjTransformation.FlipHRotateCW, ObjTransformation.FlipHRotateCCW)

	}else{
		return choose(ObjTransformation.FlipV, ObjTransformation.FlipHV, ObjTransformation.RotateCW, ObjTransformation.RotateCCW, ObjTransformation.FlipHRotateCW, ObjTransformation.FlipHRotateCCW)
	}

}

function Dungeon_IsSaveLevel(_LevelIndex){
	
	//true when a save level comes before this level
	var _Def = Level_Get(_LevelIndex);
	return _Def != undefined && _Def.SaveBefore
	
}
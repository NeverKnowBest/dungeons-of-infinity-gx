// Feather disable GM2064
enum LinkState{
	Idle,
	Standing,
	Walking,
	Hit,
	Dead,
	AutoMove,
	PickUp,
	PutDown,
	TreasureOpening,
	HoldingItem,
	Throwing,
	Pushing,
	Sword,
	SwordSpin,
	SwordPoke,
	Bow,
	Boomerang,
	Hookshot,
	Rod,
	Powder,
	Shocked,
	Star,
	Falling,
	FallingOverEdge,
	Descending,
	Warping,
	Inventory,
	Dialogue,
	VideoGame
	
}

enum ActionKey{
	Up,
	Down,
	Left,
	Right,
	Sword,
	Interact,
	Run,
	Item,
	Jump,
	Strafe
}

enum LinkWeaponClass{
	Sword,
	Pot,
	Arrow,	
	Boomerang,
	Hookshot,
	Bomb,
	Fire,
	Ice,
	SwordBeam,
	Stone,
	Transform
}
#macro LinkWeapons 11

#macro LinkHealth global.Inventory.ItemData[ItemClass.Heart].Amount

function Link_SetStartingItems(){
	if(DEBUG){

		global.Inventory.ItemData[ItemClass.Rupee].Amount = 200;
		global.Inventory.ItemData[ItemClass.HeartPiece].Amount = 12;//ChallengeMax_StartingHearts;
		global.Inventory.ItemData[ItemClass.Magic].Amount = MAGICAMOUNT_MAX;
		global.Inventory.ItemData[ItemClass.Key].Amount = 0;

		//repeat(ChallengeMax_Inventory){
		repeat(10){
			Item_Get(ItemClass.BagSlot);
		}

		Item_Get(ItemClass.Sword, Swords.Steel);
		Item_Get(ItemClass.Tunic, 0);
		Item_Get(ItemClass.Lamp, 0);
		
		switch(global.StartingGear){
			case StartingGear.Rupees:
				global.Inventory.ItemData[ItemClass.Rupee].Amount = StartingGear_Rupees;
				break;
			case StartingGear.Inventory:
				Item_Get(ItemClass.BagSlot);
				break;
			case StartingGear.Heart:
				global.Inventory.ItemData[ItemClass.HeartPiece].Amount++;
				break;
			case StartingGear.Shield:
				Item_Get(ItemClass.Shield, 0);
				break;
			case StartingGear.Rod:
				Item_Get(ItemClass.Rod, Rod.Stone, global.MaxRodCharge[Rod.Stone]);
				break;
			case StartingGear.Orbs:
				Item_Get(ItemClass.Orb, Orb.Fire, StartingGear_Orbs);
				break;
			case StartingGear.Antidotes:
				Item_Get(ItemClass.Potion, Potion.Antidote, StartingGear_Antidotes);
				break;
		
		}
	
		LinkHealth = global.Inventory.ItemData[ItemClass.HeartPiece].Amount;

		
		//global.Cursed = true;
		//global.CurseEffect = CurseEffects.ShopsMaxPrice;
		//global.CurseEffectStr = global.CurseEffectStrArray[global.CurseEffect];
		//global.CurseTask = CurseTasks.Kill;
		//global.CurseTaskItem = ItemClass.Rupee;
		//global.CurseTaskCount = 20;
		//oLink.alarm[3] = global.CurseHealthDrainDelay;
		
		//global.Challenges[Challenges.WallMaster] = true;
		//global.ChallengeOptions[ChallengeOption.MaxRupees] = 3;

		//Item_Get(ItemClass.Gloves, 0);
		//Item_Get(ItemClass.Shield, 0);
		
		Item_Get(ItemClass.ArrowQuiver);
		
		Item_Get(ItemClass.BombBag);
		Item_Get(ItemClass.FoodBag);
		Item_Get(ItemClass.PendantBag);
		Item_Get(ItemClass.GemBag);
		
		//Item_Get(ItemClass.Arrows, 0, 24);
		//Item_Get(ItemClass.Bombs, 0, 6);

		
		
		//Item_Get(ItemClass.Food, Food.Broth);
		//Item_Get(ItemClass.Arrows, 0, 80);
		//Item_Get(ItemClass.Gem, Gem.Diamond);
		//Item_Get(ItemClass.Gem, Gem.Quartz);
		//Item_Get(ItemClass.Pop, 0, 2);
		//Item_Get(ItemClass.Potion, Potion.Milk);
		//Item_Get(ItemClass.Bombs, 0, 6);
		
		//Item_Get(ItemClass.Bow, 0);
		
		//Item_Get(ItemClass.Boomerang);
		//Item_Get(ItemClass.Hookshot);
		
		
		//Item_Get(ItemClass.Pendant, Pendant.Health);
		//Item_Get(ItemClass.Pendant, Pendant.Magic);
		//Item_Get(ItemClass.Pendant, Pendant.Wealth);
		//Item_Get(ItemClass.Pendant, Pendant.Direction);
		//Item_Get(ItemClass.Pendant, Pendant.Immunity);
		//Item_Get(ItemClass.Pendant, Pendant.Revival);
		//Item_Get(ItemClass.Pendant, Pendant.Protection);		
		//Item_Get(ItemClass.Pendant, Pendant.Secrets);

		//Item_Get(ItemClass.Rod, Rod.Stone, 0);//global.MaxRodCharge[Rod.Stone]);
		//Item_Get(ItemClass.Rod, Rod.Ice, 0);//global.MaxRodCharge[Rod.Ice]);
		//Item_Get(ItemClass.Rod, Rod.Fire, 0);//global.MaxRodCharge[Rod.Fire]);
		//Item_Get(ItemClass.Rod, Rod.Bomb, 0);//global.MaxRodCharge[Rod.Bomb]);
		//Item_Get(ItemClass.Rod, Rod.Heart, 0);//global.MaxRodCharge[Rod.Heart]);		
		//Item_Get(ItemClass.Rod, Rod.Wealth, 0);//global.MaxRodCharge[Rod.Wealth]);
		
	
		//Item_Get(ItemClass.Ring, Ring.Health);
		//Item_Get(ItemClass.Ring, Ring.Arrows);
		//Item_Get(ItemClass.Ring, Ring.Bombs);
		//Item_Get(ItemClass.Ring, Ring.Rupees);
		
		//repeat(2){
			//Item_Get(ItemClass.Coupon, Coupon.Blue, 1);
			//Item_Get(ItemClass.Coupon, Coupon.Silver, 2);
			//Item_Get(ItemClass.Coupon, Coupon.Gold, 1);
			//Item_Get(ItemClass.Coupon, Coupon.Green, 1);
			//Item_Get(ItemClass.Coupon, Coupon.Red, 2);
			//Item_Get(ItemClass.Coupon, Coupon.Pink);
		//}
		
		//Item_Get(ItemClass.MoonPearl);
		//Item_Get(ItemClass.MasterKey);
		//Item_Get(ItemClass.Cape);

	
		//Item_Get(ItemClass.Book);
		//Item_Get(ItemClass.SpecialKey);
		//Item_Get(ItemClass.WishStone,,2);
		//Item_Get(ItemClass.Medallion);
		//Item_Get(ItemClass.Letter);
		//Item_Get(ItemClass.Mirror);
		//Item_Get(ItemClass.Mushroom);
		//Item_Get(ItemClass.Powder);
		
		//Item_Get(ItemClass.MagicLarge,0,2);
		
		//Item_Get(ItemClass.Map);
		//Item_Get(ItemClass.Compass);
		
		//Item_Get(ItemClass.Food, Food.GoldenEgg);
		
		//repeat(30){
		//Item_Get(ItemClass.Potion, Potion.Antidote);
		//Item_Get(ItemClass.Potion, Potion.Antidote);
		//Item_Get(ItemClass.Potion, Potion.Antidote);
		//Item_Get(ItemClass.Potion, Potion.Antidote);
		//Item_Get(ItemClass.Potion, Potion.Magic);
		//Item_Get(ItemClass.Potion, Potion.Magic);
		//Item_Get(ItemClass.Potion, Potion.Magic);
		//Item_Get(ItemClass.Potion, Potion.Magic);
		//Item_Get(ItemClass.Potion, Potion.Health);
		//Item_Get(ItemClass.Potion, Potion.Health);
		//Item_Get(ItemClass.Potion, Potion.Health);
		//Item_Get(ItemClass.Potion, Potion.Milk);
		//Item_Get(ItemClass.Potion, Potion.Milk);
		//}
		//repeat(30){
			//Item_Get(ItemClass.Pop, irandom(global.PopFlavors - 1), 1);			
		//}
		//Item_Get(ItemClass.Pendant, Pendant.Secrets);
		//repeat(10){
		//	Item_Get(ItemClass.Kinstone, irandom(3));
			//Item_Get(ItemClass.Kinstone, KinstoneColor.Red);
			//Item_Get(ItemClass.Orb, Orb.Fire);
		//	Item_Get(ItemClass.Orb, Orb.Fire, 5);
			//Item_Get(ItemClass.Orb, Orb.Ice, 5);
			//Item_Get(ItemClass.Orb, Orb.Fairy);
			//Item_Get(ItemClass.WishStone);
		//	Item_Get(ItemClass.Gem, Gem_PickIndex());
		//}
		//Item_Get(ItemClass.Kinstone, irandom(3));
		//Item_Get(ItemClass.Kinstone, irandom(3));
		//Item_Get(ItemClass.Kinstone, irandom(3));
		//Item_Get(ItemClass.Kinstone, irandom(3));
		

		//Item_Get(ItemClass.Pop, irandom(global.PopFlavors - 1), 3);

		//Item_Get(ItemClass.Food, Food.Apple);
		
		//Item_Get(ItemClass.Crystal);
		
		//repeat(16){
		//	Item_Get(ItemClass.Food, irandom(sprite_get_number(sItem_Food) - 1), 1);
		//}
		
		

		//Item_Get(ItemClass.Food, Food.Burger, 2);
		//Item_Get(ItemClass.Food, Food.CakeSlicePink, 2);
		//Item_Get(ItemClass.Food, Food.Apple, 2);
		//Item_Get(ItemClass.Food, Food.Egg, 2);
		//Item_Get(ItemClass.Food, Food.Blueberries, 1);

		//Inventory_Add(ItemClass.Star, 0);
		
		//oHUD.BossesDefeated = 0;
		
	}
	else{
		global.Inventory.ItemData[ItemClass.Rupee].Amount = 0;
		global.Inventory.ItemData[ItemClass.HeartPiece].Amount = ChallengeMax_StartingHearts;
		global.Inventory.ItemData[ItemClass.Magic].Amount = 0;

		repeat(ChallengeMax_Inventory){
			Item_Get(ItemClass.BagSlot);
		}
		
		Item_Get(ItemClass.Sword, Swords.Basic);
		Item_Get(ItemClass.Tunic, 0);
		Item_Get(ItemClass.Lamp, 0);

		switch(global.StartingGear){
			case StartingGear.Rupees:
				global.Inventory.ItemData[ItemClass.Rupee].Amount = StartingGear_Rupees;
				break;
			case StartingGear.Inventory:
				Item_Get(ItemClass.BagSlot);
				break;
			case StartingGear.Heart:
				global.Inventory.ItemData[ItemClass.HeartPiece].Amount++;
				break;
			case StartingGear.Shield:
				Item_Get(ItemClass.Shield, 0);
				break;
			case StartingGear.Rod:
				Item_Get(ItemClass.Rod, Rod.Stone, global.MaxRodCharge[Rod.Stone]);
				break;
			case StartingGear.Orbs:
				Item_Get(ItemClass.Orb, Orb.Fire, StartingGear_Orbs);
				break;
			case StartingGear.Antidotes:
				Item_Get(ItemClass.Potion, Potion.Antidote, StartingGear_Antidotes);
				break;
		
		}
		
		LinkHealth = global.Inventory.ItemData[ItemClass.HeartPiece].Amount;
		
	}
	
	Init_Gameplay_Cheats();
	
	Inventory_Update();	

}

function Link_SetStartingPos(){
	
	// Check if cheats are enabled or not
	global.CheatsEnabled = Cheats_Enabled(false);
	show_debug_message(global.CheatsEnabled == true ? "[Log] CHEATS ARE ON" : "[Log] CHEATS ARE OFF");
	
	oCamera.SetCurrentRoom(global.Level.RoomIndex_Entrance);
	
	global.TransitionRoom = -1;
	global.TransitionRoomIndex = -1;
	
	var EntranceRoom = global.Level.Rooms[global.Level.RoomIndex_Entrance];
	//var TemplateRoom = global.Level.DungeonTemplate.Rooms[global.Level.RoomIndex_Entrance];
	
	var RoomX = EntranceRoom.x;
	var RoomY = EntranceRoom.y;
	var RoomGridW = EntranceRoom.GridW;
	var RoomGridH = EntranceRoom.GridH;
	var _RSI = global.RoomSizeIndex[RoomGridW][RoomGridH];
	
	//determine entrance door position
	var _EntranceDoorPos = 6;
	for(var _DoorIndex = 0; _DoorIndex < array_length(EntranceRoom.Doors); _DoorIndex++){
		var _RoomDoor = EntranceRoom.Doors[_DoorIndex];
		if(_RoomDoor.Status == DoorStatus.Entrance){
			_EntranceDoorPos = _RoomDoor.Position;
			break;
		}
	}
	
	oLink.Facing = global.Level.StartDir;
	
	var EntranceDoorX = RoomX + global.DoorCoordinates[_RSI][_EntranceDoorPos].x;
	var EntranceDoorY = RoomY + global.DoorCoordinates[_RSI][_EntranceDoorPos].y;
		
	oLink.x = EntranceDoorX + 16;
	oLink.y = EntranceDoorY + 16;
	
	if(global.HubLevel) Hub_SetStartingPos(RoomX, RoomY, EntranceDoorX, EntranceDoorY);
	
	oLink.HitBox.x = oLink.x;
	oLink.HitBox.y = oLink.y;
	
	oLink.image_index = 0;
	oLink.image_speed = 1;
	oLink.FloorLevel = GetFloorLevelID(EntranceDoorX, EntranceDoorY);
	oLink.layer = (oLink.FloorLevel == UPPER ? global.LayerID_Objs_Upper : global.LayerID_Objs_Lower);
	oLink.LampDim = oLink.FloorLevel;
	oLink.GoingThruClosedDoorID = noone;
	oLink.MoveAssist = false;
	oLink.MoveAssistDir = NONE;
	oLink.Cape = false;
	oLink.ItemHolding = noone;
	
	var _Radius = (global.Inventory.ItemData[ItemClass.Lamp].Index == -1 ? 0 : 1 + (global.Inventory.ItemData[ItemClass.Lamp].Index * 0.5));
	Lighting_UpdateLinkLight([oLink.x, oLink.y], _Radius, [oLink.LampLightR, oLink.LampLightG, oLink.LampLightB]);

	
	with(oHUD){
		DungeonLinkY = HUD_DungeonLinkY();
		if(!global.SaveLevel && !global.HubLevel) ShowLevelName = true;
	}
	

	global.Level.Rooms[global.CurrentRoomIndex].Visited = true;
	Map_UpdateExploredRooms();
	
	global.InWaterSprite = Link_GetInWaterSprite();	
	
	if(LevelDef.Special == LevelSpecial.Intro) exit;

	oLink.FallSpawnX = oLink.x;
	oLink.FallSpawnY = oLink.y;
	oLink.FallSpawnFloorLevel = oLink.FloorLevel;
	oLink.FallSpawnFacing = oLink.Facing;
	
	//precalculate hole tiles to speed up collision check
	var _LevelTilesY = LevelTilesY_Base;
	global.HoleTileID_TL = GetTileID(102, _LevelTilesY + 4); 
	global.HoleTileID_TM = GetTileID(104, _LevelTilesY + 4); 					
	global.HoleTileID_TR = GetTileID(103, _LevelTilesY + 4); 
	global.HoleTileID_ML = GetTileID(104, _LevelTilesY + 5); 
	global.HoleTileID_MR = GetTileID(105, _LevelTilesY + 4); 
	global.HoleTileID_BL = GetTileID(102, _LevelTilesY + 5); 
	global.HoleTileID_BM = GetTileID(105, _LevelTilesY + 5); 
	global.HoleTileID_BR = GetTileID(103, _LevelTilesY + 5); 
	global.HoleTileID_ITL = GetTileID(106, _LevelTilesY + 4);
	global.HoleTileID_ITR = GetTileID(107, _LevelTilesY + 4);
	global.HoleTileID_IBL = GetTileID(106, _LevelTilesY + 5);
	global.HoleTileID_IBR = GetTileID(107, _LevelTilesY + 5); 

	
	for(var _RoomIndex = 0; _RoomIndex < global.Level.RoomCount; _RoomIndex++){
		Dungeon_RoomDeActivate(_RoomIndex);		
	}
	
	Dungeon_RoomActivate(global.CurrentRoomIndex);
	
	if(LevelDef.RunStart && !global.HubLevel){
		with(oLink){
			Link_SetAutoMove(0, global.Level.StartDir == UP ? -1 : 1, 0.5, 28);
			var _Leaves = irandom_range(6,7);
			repeat(_Leaves){
				instance_create_layer(x + irandom_range(-3, 3), y + 8, "ObjsHigher_Upper", oLeaf_Inside);
			}
		}
		
		
	}
	
	if(global.Continue){
		with(oLink){
			x = 912;
			y = 830;
			Facing = DOWN;
			UpdateSprites();
		}
		with(oDoor){
			if(Status == DoorStatus.Entrance){
				Status = DoorStatus.Closed;
				UpdateStatus = true;
				break;
			}
		}
		global.Continue = false;	
	}

	if(global.Challenges[Challenges.WallMaster]){
			
		switch(LevelDef.Special){
				
			case LevelSpecial.Intro:
			case LevelSpecial.Village:
			case LevelSpecial.Mines:
			case LevelSpecial.FinalBoss:
				break;
				
			default:
					
				if(global.SaveLevel || global.HubLevel) break;
					
				var _PosY = (oLink.Facing == UP ? oLink.y + 16 : oLink.y - 16);
			
				instance_create_layer(oLink.x, _PosY, "Objs_Upper", oEnemy_Wallmaster, {FloorLevel : UPPERLOWER, 
																						ItemHolding : -1, 
																						SectionID: 0,
																						RoomIndex: oLink.RoomIndex,
																						Dir_Init: (oLink.Facing == UP ? 90 : 270)});
		}
			
	}
		
	oCamera.Cam_UpdatePos();
	camera_set_view_pos(view_camera[1], oCamera.X, oCamera.Y);
	
}

function UpdateState(NewState, var1 = undefined){
	
	if(StarActive) exit;
	
	State = NewState;
	
	image_index = 0;
	
	UpdateSprites();	
	
	alarm[1] = -1; //reset pushing timer
	
	switch(NewState){
		
		case LinkState.SwordPoke:
		case LinkState.SwordSpin:
			Sword_ResetCharge(false);
			break;
			
		//don't destroy sword if new state is one of these and there's a sword charge
		case LinkState.Standing:
		case LinkState.Walking:
		case LinkState.AutoMove:
		case LinkState.Inventory:
			if(SwordCharge > 0) break;
		
		case LinkState.Idle:
			if(SwordCharge > 0 && oCamera.RoomTransition != NONE) break; //only allow sword charge if idle between rooms
			
		default:
			if(instance_exists(oSword)){
				Sword_ResetCharge();
			}
	}
	
	if(instance_exists(oRod_Cane)) instance_destroy(oRod_Cane);
	if(instance_exists(oHookshot)) instance_destroy(oHookshot);
	
	var PowderInst, _FloorLevelStr, SwordInst;
	switch(State){
		
		case LinkState.Standing:
			AutoMoveFrames = 0;	
			BounceBack = false;
			vx = 0;
			vy = 0;			
			image_index = (ItemHolding != noone && instance_exists(ItemHolding) ? 1 : 0);
			if(UncurseAfterStar){
				UncurseAfterStar = false;
				MsgBox("Task completed!\\You are now uncursed.",,, Curse_Done);
			}
			break;
		
		case LinkState.Sword:
			
			_FloorLevelStr = GetFloorLevelString(FloorLevel);
			SwordInst = instance_create_layer(x, y, "Objs_" + _FloorLevelStr, oSword);
			SwordInst.FloorLevel = FloorLevel;
			audio_play_sound(global.SwordSound[global.Inventory.ItemData[ItemClass.Sword].Index], 1, false);
			
			if(SwordLevel(Swords.Master)){
				if(LinkHealth == global.Inventory.ItemData[ItemClass.HeartPiece].Amount){
					if(!instance_exists(oSwordBeam)) instance_create_layer(x, y, "ObjsHigher_" + _FloorLevelStr, oSwordBeam, {FloorLevel : FloorLevel});
				}
			}
			
			break;

		//case LinkState.SwordPoke:
		//	alarm[4] = -1;
		//	Invincible = true;
		//	break;
		
		case LinkState.SwordSpin:
			Invincible = true;
			HitFlashingStatus = false;
			alarm[4] = -1;
			alarm[5] = -1;
			break;
			
		case LinkState.Bow:
			var _ConsumedArrowAmount = -1;
			
			// Inf. Arrows Cheat
			if (Cheat_On("Cheat_Inf_Arrows"))
				_ConsumedArrowAmount = 0;
			
			ObjSetImageSpeed(1);
			if(global.Inventory.ItemData[ItemClass.ArrowQuiver].Owns[0])
				Item_Consume(ItemClass.Arrows, 0, _ConsumedArrowAmount);
			else
				Inventory_Add(ItemClass.Arrows, 0, _ConsumedArrowAmount, Inventory_FindItem(ItemClass.Arrows));
			
			Bow_Set();

			break;
		
		case LinkState.Boomerang:
			instance_create_layer(x, y, "ObjsHigher_" + GetFloorLevelString(FloorLevel), oBoomerang);
			break;
		
		case LinkState.Rod:
			Rod_Shoot();
			audio_play_sound(Sound_Rod, 1, false);				
			
			break;
		
		case LinkState.Hookshot:
			instance_create_layer(x, y - 5, "ObjsHigher_" + GetFloorLevelString(FloorLevel), oHookshot);
			break;
			
		case LinkState.Powder:
			var FloorLevelStr = GetFloorLevelString(FloorLevel);
			switch(Facing){
				case LEFT: 
					PowderInst = instance_create_layer(x - 12, y - 6, "ObjsHigher_" + FloorLevelStr, oPowder);
					PowderInst.sprite_index = sPowder_Left;
					break;
				case RIGHT: 
					PowderInst = instance_create_layer(x + 12, y - 6, "ObjsHigher_" + FloorLevelStr, oPowder); 
					PowderInst.sprite_index = sPowder_Right;
					break;
				case UP: 
					PowderInst = instance_create_layer(x, y - 29, "ObjsHigher_" + FloorLevelStr, oPowder); 
					PowderInst.sprite_index = sPowder_Up;
					break;
				case DOWN: 
					PowderInst = instance_create_layer(x, y + 2, "ObjsHigher_" + FloorLevelStr, oPowder); 
					PowderInst.sprite_index = sPowder_Down;
					break;
			}
			audio_play_sound(Sound_Powder, 1, false);
			audio_play_sound(Sound_FairySprinkle, 1, false);			
			break;

			
		case LinkState.Star:
			_FloorLevelStr = GetFloorLevelString(FloorLevel);
			SwordInst = instance_create_layer(x, y, "Objs_" + _FloorLevelStr, oSword);
			SwordInst.FloorLevel = FloorLevel;
			if(ItemHolding != noone){
				LinkThrow();
				//if(object_index == oPot){ //he may be holding something valuable like an orb. Deal with other items differently
				//	instance_destroy(ItemHolding) 
				//	ItemHolding = noone;
				//}
			}
			instance_destroy(oCape);
			Invincible = true;
			HitFlashingStatus = false;
			StarActive = true;
			alarm[4] = -1;
			alarm[5] = -1;
			alarm[7] = StarColorDelay;
			alarm[8] = StarTimer;
			Music_Play(SongIndex.Star);
			break;
		
		case LinkState.PickUp:
			
			ItemHolding = var1;
			
			switch(ItemHolding.object_index){
					
				case oEnemy_Chicken:
					with(ItemHolding){
						PickedUp = true;
						vx = 0;
						vy = 0;
						Chicken_SetScared();
						if(Egg){
							ItemDrop(x, y, ItemClass.Food, GoldenEgg ? Food.GoldenEgg : Food.Egg, 1, ItemFrom.Pot);
							Egg = false;
							GoldenEgg = false;
						}
					}
					break;
				
				case oItem_Orb:
				case oItem_Gem:
				case oItem_Bombs:
				case oItem_WishStone:

					var _Inst = instance_create_layer(ItemHolding.x, ItemHolding.y, ItemHolding.layer, ObjFromItem(ItemHolding.object_index));
					_Inst.Index = ItemHolding.Index;
					_Inst.FloorLevel = ItemHolding.FloorLevel;
					_Inst.From = ItemHolding.From;
					
					if(ItemHolding.object_index == oItem_Bombs){
						if(ItemHolding.Red) _Inst.Red = true;
					}
					
					ItemHolding.Amount--;
					if(ItemHolding.Amount <= 0){
						instance_destroy(ItemHolding);
					}
					ItemHolding = _Inst;

					
				default:
					
					ItemHolding.State = PickupObjState.PickUp;
					ItemHolding.DrawShadow = false;

					if(variable_instance_exists(ItemHolding, "Amount")){
						if(ItemHolding.Amount > 1){
							ItemHolding.Amount--;
						}else{
							instance_destroy(ItemHolding);
						}				
					}
			
					break;
		
			}

			break;
		
		case LinkState.PutDown:
			audio_play_sound(Sound_Throw, 1, false);
			break;
			
		case LinkState.Throwing:
			LinkThrow();					
			break;
		
		case LinkState.Hit:
			LinkEnableFlashing();
			alarm[6] = HitSoundDelay;
			break;
		
		case LinkState.Dead:
			if(!instance_exists(oLinkDeath)){
				instance_create_layer(0, 0, "System", oLinkDeath);
				
			}
			break;
			
		case LinkState.Descending:
			DescendingPhase = 1;
			x = floor(x); y = floor(y);
			var snd = audio_play_sound(ExitLook.Sound, 1, false);	//ExitLook: set by CheckDoors
			audio_sound_gain(snd, 0, 2000);
			if(ExitLook[$ "Leave"] != undefined && instance_exists(ExitDoor)) ExitLook.Leave(ExitDoor);	//a gate opens in front of him
			var NextLevelSongIndex = global.LevelDefs[Level_NextIndex()].Song;
			if(oMusic.SongPlaying_Index != NextLevelSongIndex) Music_Fade(0, SongFadeLen_NextLevel, SongIndex.None);

			if(audio_is_playing(global.RainSound)) audio_sound_gain(global.RainSound, 0, 1000);
			Weather_StopLightning();
			
			with(oCape) instance_destroy(id);
			
			break;
		
		case LinkState.Shocked:
			alarm[2] = 30;
			Invincible = false;
			audio_play_sound(Sound_Hurt, 1, false);
			audio_play_sound(Sound_Shock, 1, false);			
			break;
		
		case LinkState.FallingOverEdge:
			alarm[2] = -1;
			break;
			
		case LinkState.Falling:
			alarm[2] = -1;
			audio_play_sound(Sound_LinkFall, 1, false);
			break;
			
	}	
	
}

function UpdateSprites(){
	
	var _HoldingItem = (ItemHolding != noone && instance_exists(ItemHolding));
	var _SwordCharge = (SwordCharge > 0);
	
	image_speed = 1; 
	
	switch(State){
		
		case LinkState.Standing:
		case LinkState.Inventory:
		
			if(_SwordCharge){
				switch(Facing){
					case LEFT: sprite_index = global.LinkSpr_Stand_SwordCharge_Left; break;
					case RIGHT: sprite_index = global.LinkSpr_Stand_SwordCharge_Right; break;
					case UP: sprite_index = global.LinkSpr_Stand_SwordCharge_Up; break;
					case DOWN: sprite_index = global.LinkSpr_Stand_SwordCharge_Down; break;
				}
				image_index = 0;						
				
			}else{
				switch(Facing){
					case LEFT: sprite_index = global.LinkSpr_Stand_Left; break;
					case RIGHT: sprite_index = global.LinkSpr_Stand_Right; break;
					case UP: sprite_index = global.LinkSpr_Stand_Up; break;
					case DOWN: sprite_index = global.LinkSpr_Stand_Down; break;
				}
				image_index = _HoldingItem ? 1 : 0;					
			}
			break;
			
		//case LinkState.BounceBack:
		case LinkState.Dialogue:
		case LinkState.TreasureOpening:
		case LinkState.Warping:
		case LinkState.Idle:
			switch(Facing){
				case LEFT: sprite_index = global.LinkSpr_Stand_Left; break;
				case RIGHT: sprite_index = global.LinkSpr_Stand_Right; break;
				case UP: sprite_index = global.LinkSpr_Stand_Up; break;
				case DOWN: sprite_index = global.LinkSpr_Stand_Down; break;
			}
			image_index = _HoldingItem ? 1 : 0;
			break;
		
		case LinkState.Walking:
		case LinkState.AutoMove:
			
			if(_SwordCharge){
				switch(Facing){
					case LEFT: sprite_index = global.LinkSpr_Walk_SwordCharge_Left; break;
					case RIGHT: sprite_index = global.LinkSpr_Walk_SwordCharge_Right; break;
					case UP: sprite_index = global.LinkSpr_Walk_SwordCharge_Up; break;
					case DOWN: sprite_index = global.LinkSpr_Walk_SwordCharge_Down; break;
				}					
				
			}else{
				
				switch(Facing){
					case LEFT: sprite_index = (_HoldingItem ? global.LinkSpr_Carrying_Left : global.LinkSpr_Walk_Left); break;
					case RIGHT: sprite_index = (_HoldingItem ? global.LinkSpr_Carrying_Right : global.LinkSpr_Walk_Right); break;
					case UP: sprite_index = (_HoldingItem ? global.LinkSpr_Carrying_Up : global.LinkSpr_Walk_Up); break;
					case DOWN: sprite_index = (_HoldingItem ? global.LinkSpr_Carrying_Down: global.LinkSpr_Walk_Down); break;
				}
			}
			break;

		case LinkState.Hit:
		case LinkState.Dead:
			switch(Facing){
				case LEFT: sprite_index = global.LinkSpr_Hurt_Left; break;
				case RIGHT: sprite_index = global.LinkSpr_Hurt_Right; break;
				case UP: sprite_index = global.LinkSpr_Hurt_Up; break;
				case DOWN: sprite_index = global.LinkSpr_Hurt_Down; break;
			}
			break;

		case LinkState.Pushing:
			switch(Facing){
				case LEFT: sprite_index = global.LinkSpr_Push_Left; break;
				case RIGHT: sprite_index = global.LinkSpr_Push_Right; break;
				case UP: sprite_index = global.LinkSpr_Push_Up; break;
				case DOWN: sprite_index = global.LinkSpr_Push_Down; break;
			}
			break;
		
		case LinkState.Falling:
			sprite_index = global.LinkSpr_Falling;
			break;
			
		case LinkState.Sword:

			switch(Facing){
				case LEFT: sprite_index = global.LinkSpr_Sword_Left; break;
				case RIGHT: sprite_index = global.LinkSpr_Sword_Right; break;
				case UP: sprite_index = global.LinkSpr_Sword_Up; break;
				case DOWN: sprite_index = global.LinkSpr_Sword_Down; break;
			}
			break;
		
		case LinkState.SwordPoke:

			switch(Facing){
				case LEFT: sprite_index = global.LinkSpr_SwordPoke_Left; break;
				case RIGHT: sprite_index = global.LinkSpr_SwordPoke_Right; break;
				case UP: sprite_index = global.LinkSpr_SwordPoke_Up; break;
				case DOWN: sprite_index = global.LinkSpr_SwordPoke_Down; break;
			}
			break;
		
		case LinkState.SwordSpin:
			switch(Facing){
				case LEFT: sprite_index = global.LinkSpr_SwordSpin_Left; break;
				case RIGHT: sprite_index = global.LinkSpr_SwordSpin_Right; break;
				case UP: sprite_index = global.LinkSpr_SwordSpin_Up; break;
				case DOWN: sprite_index = global.LinkSpr_SwordSpin_Down; break;
			}			
			break;
			
		case LinkState.Bow:
			switch(Facing){
				case LEFT: sprite_index = global.LinkSpr_Bow_Left; break;
				case RIGHT: sprite_index = global.LinkSpr_Bow_Right; break;
				case UP: sprite_index = global.LinkSpr_Bow_Up; break;
				case DOWN: sprite_index = global.LinkSpr_Bow_Down; break;
			}
			break;
		
		case LinkState.Boomerang:
			switch(Facing){
				case LEFT: sprite_index = global.LinkSpr_Boomerang_Left; break;
				case RIGHT: sprite_index = global.LinkSpr_Boomerang_Right; break;
				case UP: sprite_index = global.LinkSpr_Boomerang_Up; break;
				case DOWN: sprite_index = global.LinkSpr_Boomerang_Down; break;
			}
			break;
		
		case LinkState.Hookshot:
			switch(Facing){
				case LEFT: sprite_index = global.LinkSpr_Hookshot_Left; break;
				case RIGHT: sprite_index = global.LinkSpr_Hookshot_Right; break;
				case UP: sprite_index = global.LinkSpr_Hookshot_Up; break;
				case DOWN: sprite_index = global.LinkSpr_Hookshot_Down; break;
			}
			break;
			
		case LinkState.Rod:
			switch(Facing){
				case LEFT: sprite_index = global.LinkSpr_Rod_Left; break;
				case RIGHT: sprite_index = global.LinkSpr_Rod_Right; break;
				case UP: sprite_index = global.LinkSpr_Rod_Up; break;
				case DOWN: sprite_index = global.LinkSpr_Rod_Down; break;
			}
			break;
		
		case LinkState.Powder:
			switch(Facing){
				case LEFT: sprite_index = global.LinkSpr_Powder_Left; break;
				case RIGHT: sprite_index = global.LinkSpr_Powder_Right; break;
				case UP: sprite_index = global.LinkSpr_Powder_Up; break;
				case DOWN: sprite_index = global.LinkSpr_Powder_Down; break; 
			}
			break;
		
		case LinkState.PickUp:
		case LinkState.PutDown:
			switch(Facing){
				case LEFT: sprite_index = global.LinkSpr_PickUp_Left; break;		
				case RIGHT: sprite_index = global.LinkSpr_PickUp_Right; break;
				case UP: sprite_index = global.LinkSpr_PickUp_Up; break;
				case DOWN: sprite_index = global.LinkSpr_PickUp_Down; break;
			}
			if(State == LinkState.PutDown){
				image_index = sprite_get_number(sprite_index) - 0.01;
				image_speed = -1.25;
			}
			break;
			
		case LinkState.Throwing:
			switch(Facing){
				case LEFT: sprite_index = global.LinkSpr_Throwing_Left;	break;		
				case RIGHT:	sprite_index = global.LinkSpr_Throwing_Right; break;
				case UP: sprite_index = global.LinkSpr_Throwing_Up;	break;
				case DOWN: sprite_index = global.LinkSpr_Throwing_Down; break;	
			}
			break;
			
		case LinkState.HoldingItem:
			sprite_index = global.LinkSpr_HoldingItem;
			break;
		
		case LinkState.Descending:
			sprite_index = ExitLook_LinkSprite(ExitLook, 1, DescendingLocation);
			break;
		
		case LinkState.Shocked:
			sprite_index = global.LinkSpr_Shock;
			break;
		
		case LinkState.Star:
			sprite_index = global.LinkSpr_Star;
			break;
			
	}
	
}

function Facing_Check(){
	
	if(MoveAssistDir != NONE || BounceBack || Action[ActionKey.Strafe]) exit;
	
	if(vx == 0){
		if(vy < 0) {Facing = UP; exit;}
		if(vy > 0) {Facing = DOWN; exit;}
	}
	if(vy == 0){
		if(vx < 0) {Facing = LEFT; exit;}
		if(vx > 0) {Facing = RIGHT;	exit;}
	}
	if(Facing == LEFT && vx > 0){
		if(vy > 0) {Facing = choose(RIGHT, DOWN); exit;}
		if(vy < 0) {Facing = choose(RIGHT, UP); exit;}
	}
	if(Facing == RIGHT && vx < 0){
		if(vy > 0) {Facing = choose(LEFT, DOWN); exit;}
		if(vy < 0) {Facing = choose(LEFT, UP); exit;}
	}
	if(Facing == UP && vy > 0){
		if(vx > 0) {Facing = choose(LEFT, DOWN); exit;}
		if(vx < 0) {Facing = choose(RIGHT, DOWN); exit;}
	}
	if(Facing == DOWN && vy < 0){
		if(vx > 0) {Facing = choose(LEFT, UP); exit;}
		if(vx < 0) {Facing = choose(RIGHT, UP); exit;}
	}
	
}

function CheckMoveAssist(){
	
	MoveAssistDir = NONE;
	var WallInst, _Walls;
	if(MoveAssist){ 
		
		MoveAssist = false;
		var _WallList = ds_list_create();
		
		//check move assist with wall objects
	
		if(!keyLeft && !keyRight){
		
			KeyState[0] = keyUp; KeyState[1] = keyDown;
			Position1[0] = bbox_top - 1; Position1[1] = bbox_bottom + 1;
			for(var i = 0; i <= 1; i++){
				if(KeyState[i] && vy == 0){
					
					
					//var WallInst = ObjCollision_Position (x, Position1[i], oWall, FloorLevel); 
					
					//make sure to check collisions on all posible walls at point, and only pass the ones that are on the correct floor level
					//===============Put this in seperate function, it is repeated 4 times==============================
					WallInst = noone;
					_Walls = instance_position_list(x, Position1[i], oWall, _WallList, false);					
					for(var _WallIndex = 0; _WallIndex < _Walls; _WallIndex++){
						
						if(_WallList[| _WallIndex].FloorLevel == FloorLevel || _WallList[| _WallIndex].FloorLevel == UPPERLOWER){
							WallInst = _WallList[| _WallIndex];
							break;
						}						
					}
					//==================================================================================================
					
					var WallCollide = false;
					if(WallInst != noone && (WallInst.BlockLink || (WallInst.BlockLinkCarry && ItemHolding != noone))) WallCollide = true;
					if(!WallCollide){
						Position2[0] = bbox_left; Position2[1] = bbox_right;
						for(var j = 0; j <= 1; j++){
							//WallInst = ObjCollision_Position(Position2[j], Position1[i], oWall, FloorLevel);
							
							ds_list_clear(_WallList);
							WallInst = noone;
							_Walls = instance_position_list(Position2[j], Position1[i], oWall, _WallList, false);				
							for(var _WallIndex = 0; _WallIndex < _Walls; _WallIndex++){
						
								if(_WallList[| _WallIndex].FloorLevel == FloorLevel || _WallList[| _WallIndex].FloorLevel == UPPERLOWER){
									WallInst = _WallList[| _WallIndex];
									break;
								}						
							}							
							
							WallCollide = false;
							if(WallInst != noone && WallInst.BlockLink) WallCollide = true;
							if(WallCollide){
								MoveAssistDir = (j == 0 ? RIGHT : LEFT);
								break;
							}
						}
						if(MoveAssistDir != NONE) break;
					}
					
				}

				
			}

		}
		
		if(MoveAssistDir != NONE){
			ds_list_destroy(_WallList);
			exit;
		}
		
		if(!keyDown && !keyUp){
		
			KeyState[0] = keyLeft; KeyState[1] = keyRight;
			Position1[0] = bbox_left - 1; Position1[1] = bbox_right + 1;
			for(var i = 0; i <= 1; i++){
				if(KeyState[i] && vx == 0){
					//var WallInst = ObjCollision_Position(Position1[i], y - 6, oWall, FloorLevel);
					
					ds_list_clear(_WallList);
					WallInst = noone;
					_Walls = instance_position_list(Position1[i], y - 6, oWall, _WallList, false);				
					for(var _WallIndex = 0; _WallIndex < _Walls; _WallIndex++){
						
						if(_WallList[| _WallIndex].FloorLevel == FloorLevel || _WallList[| _WallIndex].FloorLevel == UPPERLOWER){
							WallInst = _WallList[| _WallIndex];
							break;
						}						
					}	
							
					var WallCollide = false;
					if(WallInst != noone && (WallInst.BlockLink || (WallInst.BlockLinkCarry && ItemHolding != noone))) WallCollide = true;
					if(!WallCollide){
						Position2[0] = bbox_bottom; Position2[1] = bbox_top;
						for(var j = 0; j <= 1; j++){
							//WallInst = ObjCollision_Position(Position1[i], Position2[j], oWall, FloorLevel);

							ds_list_clear(_WallList);
							WallInst = noone;
							_Walls = instance_position_list(Position1[i], Position2[j], oWall, _WallList, false);				
							for(var _WallIndex = 0; _WallIndex < _Walls; _WallIndex++){
						
								if(_WallList[| _WallIndex].FloorLevel == FloorLevel || _WallList[| _WallIndex].FloorLevel == UPPERLOWER){
									WallInst = _WallList[| _WallIndex];
									break;
								}						
							}
							
							WallCollide = false;
							if(WallInst != noone && WallInst.BlockLink) WallCollide = true;
							if(WallCollide){
								MoveAssistDir = (j == 0 ? UP : DOWN);
								break;
							}
						}
						if(MoveAssistDir == UP || MoveAssistDir == DOWN) break;
					}
				}
			}

		}
		
		ds_list_destroy(_WallList);
		
	}
}

function CheckRoomTransition(){
	
	if(DEBUG){
		if(global.Clip) exit;
	}
	
	//Check for Room edges while going thru doors
	//FloorLevel adjustments are because lower level doors are at different positions than upper floor doors
	
	if(oCamera.RoomTransition == NONE){		

		var DoorInst = instance_place(x, y, oDoor);
		
		if(DoorInst != noone){
			
			if(House_Inside){
				if (vy > 0 && y > global.CurrentRoom.y + global.CurrentRoom.height - 30 + (FloorLevel * 24)){
					
					Sword_ResetCharge();
					
					Link_SetAutoMove(0, 1, 0.4);
					//HouseDoorInst.alarm[0] = 70;
					//HouseDoorInst.Warp = true;
					var NextRoomSongIndex = global.Level.Rooms[House_OldRoomIndex].RoomSongIndex;
					if(oMusic.SongPlaying_Index != NextRoomSongIndex){
						Music_Fade(0, SongFadeLen_House, NextRoomSongIndex);
					}else{
						Music_Fade(1, SongFadeLen_House);
					}
					
					House_Leaving = true;
					oRender.FadeOut();
		
				}
			}else{
				
				AutoMoveSpeed = (FloorLevel == UPPER ? 0.5 : 1.25);
				if(vx < 0 && x < global.CurrentRoom.x + 40 - (FloorLevel * 24)) oCamera.Cam_InitTransitionRoom(LEFT);
				else if (vx > 0 && x > global.CurrentRoom.x + global.CurrentRoom.width - 40 + (FloorLevel * 24)) oCamera.Cam_InitTransitionRoom(RIGHT);
				else if (vy < 0 && y < global.CurrentRoom.y + 52 - (FloorLevel * 24)){
					AutoMoveSpeed = (FloorLevel == UPPER ? 0.55 : 1.32);
					oCamera.Cam_InitTransitionRoom(UP);					
				}else if (vy > 0 && y > global.CurrentRoom.y + global.CurrentRoom.height - 30 + (FloorLevel * 24)) oCamera.Cam_InitTransitionRoom(DOWN);

			}
		}else{
			//if no door is detected it means we're walking off the edge of an open Room with no wall (village)
			//a painted room is walled all round: it is left only through a door (RegionRoom_OffLane); this transition
			//would put to sleep the room Link is still standing in. Outdoor levels have no open rooms at all, painted
			//or not (R1 eighth round: Link walked off a room of the shared templates into the wall of the room below)
			if(RegionRoom_Is(global.CurrentRoomIndex) || LevelDef.Layout == LevelLayout.Outdoor) exit;

			
			if(vx < 0 && x < global.CurrentRoom.x + 16){
				AutoMoveSpeed = 0.8;
				oCamera.Cam_InitTransitionRoom(LEFT, true);
			}else if (vx > 0 && x > global.CurrentRoom.x + global.CurrentRoom.width - 16){
				AutoMoveSpeed = 0.8;
				oCamera.Cam_InitTransitionRoom(RIGHT, true);
			}else if (vy < 0 && y < global.CurrentRoom.y + 28){
				AutoMoveSpeed = 1.4;
				oCamera.Cam_InitTransitionRoom(UP, true);
			}else if (vy > 0 && y > global.CurrentRoom.y + global.CurrentRoom.height - 28){
				AutoMoveSpeed = 1.4;
				oCamera.Cam_InitTransitionRoom(DOWN, true);
			}
			
		}
		
	}

	if(oCamera.RoomTransition != NONE){
		
		if(LastDoorID == noone) exit;
		
		if(LastDoorID.LinkedDoor == noone){
			exit;
		}
		
		if(!oCamera.OpenTransition){
			if(LastDoorID.LinkedDoor.Status = DoorStatus.Closed){
				GoingThruClosedDoor = true;
				GoingThruClosedDoorID = LastDoorID.LinkedDoor;
				LastDoorID.LinkedDoor.Status = DoorStatus.Open;
				LastDoorID.LinkedDoor.UpdateStatus = true;
				LastDoorID.LinkedDoor.WallInst.BlockLink = true;
				LastDoorID.LinkedDoor.WallInst.BlockProjectiles = true;
			}
			//open any curtain if going through one
			if(LastDoorID.LinkedDoor.CurtainInst != noone){
				LastDoorID.LinkedDoor.CurtainInst.Revealed = true;
			}
		}
				
	}		
}

/// Link goes through exit _DoorInst in the wall at _Location (TOP or BOTTOM): CheckDoors, or a gate he walked into
/// (RegionGate_Push)
function Link_TakeExit(_DoorInst, _Location){
	//its animation and sounds, leaving and arriving (roadmap F4b); before UpdateState, which sets the sprite first
	ExitLook = Door_ExitLook(_DoorInst);
	ExitDoor = _DoorInst;
	global.RunPath.Next = Door_ExitDest(_DoorInst);	//this exit's branch of the run (roadmap F4b)
	DescendingLocation = _Location;
	UpdateState(LinkState.Descending);
}

function CheckDoors(){
	
	var DoorInst = instance_place(x + vx, y + vy, oDoor);
	
	if(!oCamera.RoomTransition) InDoorPassage = 0;
	
	if(DoorInst != noone){
	
		LastDoorID = DoorInst;

		//Check for locked doors					
		if(DoorInst.Status == DoorStatus.Locked){
			if(LevelDef.Special == LevelSpecial.Village && oCamera.DungeonGridX == 3 && oCamera.DungeonGridY == 2){
				if(Inventory_ItemExists(ItemClass.SpecialKey)) 
					UnlockDoor(DoorInst, ItemClass.SpecialKey);
			}else{
				if(global.Inventory.ItemData[ItemClass.MasterKey].Owns[0]){
					UnlockDoor(DoorInst, ItemClass.MasterKey);
				}else if(global.Inventory.ItemData[ItemClass.Key].Amount > 0) 
					UnlockDoor(DoorInst);
			}			
		}
		
		if(DoorInst.Status == DoorStatus.Exit){
			if(DoorInst.Location == "Top" && y < DoorInst.y + 24){
				Link_TakeExit(DoorInst, TOP);
				return 1;
			}
			else if(DoorInst.Location == "Bottom" && y > DoorInst.y + 4){
				Link_TakeExit(DoorInst, BOTTOM);
				return 1;
			}		
		}

		DoorPassage = DoorInst.PassageArea;	
		InDoorPassage = rectangle_in_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, DoorPassage[0], DoorPassage[1], DoorPassage[2], DoorPassage[3]);
		
		switch(DoorInst.Location){
			case "Top":
			case "Bottom":
				PassageOrientation = TOP_BOTTOM;
				break;
			case "Left":
			case "Right":
				PassageOrientation = LEFT_RIGHT;
				break;
		}


	}

	//Check for House doors
	var HouseDoorInst = instance_place(x, y + 6, oHouseDoor);
	if(HouseDoorInst != noone){
		if(State != LinkState.AutoMove && vy < 0 && !InDoor_BlockItem && (ItemHolding == noone || !instance_exists(ItemHolding))){
			
			House_DoorInst = HouseDoorInst; //keep the inst for later
		
			DoorPassage = House_DoorInst.PassageArea;
			InDoorPassage = rectangle_in_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, DoorPassage[0], DoorPassage[1], DoorPassage[2], DoorPassage[3]);
			
			if(House_DoorInst.image_index != 2){
				House_DoorInst.image_index = 2;
				audio_play_sound(Sound_DoorOpen, 1, false);
			}
			
			Sword_ResetCharge();
			
			Link_SetAutoMove(0, -1, 0.4);

			House_RoomIndex = House_DoorInst.House_RoomIndex;
			House_OldRoomIndex = global.CurrentRoomIndex;
			House_X = House_DoorInst.House_X;
			House_Y = House_DoorInst.House_Y;
			House_Entering = true;
			
			var NextRoomSongIndex = global.Level.Rooms[House_RoomIndex].RoomSongIndex;
			if(oMusic.SongPlaying_Index != NextRoomSongIndex)
				Music_Fade(0, SongFadeLen_House, NextRoomSongIndex);
			else
				Music_Fade(0.25, SongFadeLen_House);
			
			oRender.FadeOut();
		}

	}

	
	
	
	//Check for locked key blocks
	var KeyBlockInst = instance_place(x + vx, y + vy, oKeyBlock);
	if(KeyBlockInst != noone){
		if( global.Inventory.ItemData[ItemClass.Key].Amount > 0 || global.Inventory.ItemData[ItemClass.MasterKey].Owns[0]){
			if(!KeyBlockInst.Unlocked){
				if(!global.Inventory.ItemData[ItemClass.MasterKey].Owns[0]) Item_Consume(ItemClass.Key, 0, -1);
				KeyBlockInst.alarm[0] = 6; //destroy timer, so it doesn't destroy instantly
				audio_play_sound(Sound_DoorUnlock, 1, false);
				KeyBlockInst.Unlocked = true;
			}
		}
	}


	
	//Check for Castle Wall doors
	if(!Castle_Entering){

		var CastleWallDoorInst = instance_place(x, y + 6, oCastleWallDoor);
		if(CastleWallDoorInst != noone){
			
			DoorPassage = CastleWallDoorInst.PassageArea;
			InDoorPassage = rectangle_in_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, DoorPassage[0], DoorPassage[1], DoorPassage[2], DoorPassage[3]);
			
			if(y <= CastleWallDoorInst.y + 4){
				
				Castle_Entering = true;
				
				//swordless quest enabled if entering without a sword
				if(!global.Swordless){
					if(!Inventory_ItemExists(ItemClass.Sword)){
						MsgBox("Swordless quest enabled! No swords will be generated during the game. Good Luck!");
						global.Swordless = true;
						exit;
					}
				}
				
			}

		}
				
	}
	
}

function UnlockDoor(_DoorInst, _KeyItemClass = ItemClass.Key){
	
	_DoorInst.Unlock = true;
	
	Item_Consume(_KeyItemClass, 0, -1);

	audio_play_sound(Sound_DoorUnlock, 1, false);
	
}

function CheckStairs(){
	
	var _OnStairs = NONE;
	if(vy != 0){
		_OnStairs = OnStairs(x, y);
	}
	
	if(StairsAutoMove){
	
		var LampDimInc = (1 - LampDimMin) / 55;
		switch(StairsFloorLevelDir){
			case UPPER:
				LampDim += LampDimInc;
				if(LampDim > 1) LampDim = 1;
				break;
			case LOWER:
				LampDim -= LampDimInc;
				if(LampDim < LampDimMin) LampDim = LampDimMin;
				break;
		}
		
		if(_OnStairs == NONE){
		
			StairsAutoMove = false;
			AutoMoveDirX = 0;
			AutoMoveDirY = sign(vy);
			AutoMoveSpeed = WalkSpeed;
			if(vy > 0) AutoMoveFrames = 9;
			if(vy < 0) AutoMoveFrames = 2;
			if(vy == 0) AutoMoveFrames = 6;
			UpdateState(LinkState.AutoMove);
			
			//if we're on floor 1 and there's not an upper floor after stairs, we went down(switched to 1 earlier), so switch to FloorLevel 0 now
			if(FloorLevel == 1 && tilemap_get_at_pixel(global.TMID_Floor_Upper, x, y) == 0) FloorLevel = 0;
			FloorLevelStr = GetFloorLevelString(FloorLevel);
			
			audio_stop_sound(Sound_StairsDown);
			audio_stop_sound(Sound_StairsFloorDown);
			audio_stop_sound(Sound_StairsUp);
			
			if(global.StairPause) global.Paused = false;
		
		}
	}else{
		
		if(_OnStairs != NONE){
			
			Link_SetAutoMove (0, sign(vy), StairSpeed);
			
			StairsAutoMove = true;
			MoveAssist = false;
		
			//always switch to level 1 first thing if starting from lovel 0 to prevent top floors from covering head before reaching top
			if(FloorLevel == 0)	FloorLevel = 1;	
		

			if( (_OnStairs == TOP && Facing == UP) || (_OnStairs == BOTTOM && Facing == DOWN)){
				//Going Up
				StairsFloorLevelDir = UPPER;
				audio_play_sound(Sound_StairsUp, 1, false)
			}else if( (_OnStairs == TOP && Facing == DOWN) || (_OnStairs == BOTTOM && Facing == UP)){
				//Going Down
				StairsFloorLevelDir = LOWER;
				audio_play_sound(Sound_StairsDown, 1, false);
			}
		
			if(global.StairPause) global.Paused = true;
		
		}
		
	}		
	
}

function Link_SetAutoMove (_DirX, _DirY, _Speed, _Frames = -1){

	AutoMoveDirX = _DirX;
	AutoMoveDirY = _DirY;
	AutoMoveSpeed = _Speed;	
	AutoMoveFrames = _Frames; //-1 = infinite

	if(AutoMoveDirX < 0) Facing = LEFT;
	if(AutoMoveDirX > 0) Facing = RIGHT;
	if(AutoMoveDirY < 0) Facing = UP;
	if(AutoMoveDirY > 0) Facing = DOWN; 
	
	UpdateState(LinkState.AutoMove);			
	
}

function CheckMovingFloor(){
	
	if(State == LinkState.AutoMove || State == LinkState.Hookshot || MoveAssistDir != NONE) exit;

	var MovingFloorInst = instance_position(x, y, oMovingFloor);
	if(MovingFloorInst != noone){
		vx += (MovingFloorInst.DirX * 0.5);	
		vy += (MovingFloorInst.DirY * 0.5);
	}

}

function CheckHoles(){
	
	if(RoomIndex == -1 && LevelDef.Special != LevelSpecial.FinalBoss) return false
	
	var _TileUpper = tilemap_get_at_pixel(global.TMID_Floor_Upper, x, y);
	var _TileLower = tilemap_get_at_pixel(global.TMID_Floor_Lower, x, y);
	
	if(_TileUpper == 0 && _TileLower == 0){
		
		if(House_Leaving) return false; //if exiting house and there's no tiles on the outside (mine houses), then it causes Link to fall
		
		if(FloorLevel == UPPER && position_meeting(x, y, oDrawBridgeArea)) return false;				
		
		UpdateState(LinkState.Falling);
		
		return true;
		
	}
	
	//var TMID = (FloorLevel = UPPER ? global.TMID_Floor_Upper : global.TMID_Floor_Lower);
	
	var HoleEdgeID = FloorLevel = UPPER ? _TileUpper : _TileLower;
		
	var FallDir, FallPointX, FallPointY;
	switch(HoleEdgeID){
		case global.HoleTileID_TL: 
		case global.HoleTileID_ITL:
			FallDir = 315;
			FallPointX = 8; FallPointY = 8;
			break;

		case global.HoleTileID_TM:
			FallDir = 270;
			FallPointX = 0; FallPointY = 8;
			break;

		case global.HoleTileID_TR:
		case global.HoleTileID_ITR:
			FallDir = 225;
			FallPointX = -8; FallPointY = 8;
			break;

		case global.HoleTileID_ML:
			FallDir = 0;
			FallPointX = 8; FallPointY = 0;
			break;

		case global.HoleTileID_MR:
			FallDir = 180;
			FallPointX = -8; FallPointY = 0;
			break;

		case global.HoleTileID_BL:
		case global.HoleTileID_IBL:
			FallDir = 45;
			FallPointX = 8; FallPointY = -8;
			break;

		case global.HoleTileID_BM:
			FallDir = 90;
			FallPointX = 0; FallPointY = -8;
			break;

		case global.HoleTileID_BR:
		case global.HoleTileID_IBR:
			FallDir = 135;
			FallPointX = -8; FallPointY = -8;
			break;

		
		default: return false;
			
	}
	
	LinkThrow();
	
	UpdateState(LinkState.FallingOverEdge);
	//calculate vx and vy based on FallPoint from HoleEdge
	//FallPointX = x + FallPointX;
	//FallPointY = y + FallPointY;
	//var Dir = point_direction(x, y, FallPointX, FallPointY);
	//var Dist = point_distance(x, y, FallPointX, FallPointY);
	var LenDirX = lengthdir_x(8, FallDir);
	var LenDirY = lengthdir_y(8, FallDir);
	var time = 10;
	vx = LenDirX / time;
	vy = LenDirY / time;
	FallOverEdgeDelay = time;
		
	return true;

}

function Interact(){
	
	switch(State){
		case LinkState.SwordSpin:
		case LinkState.SwordPoke:
		case LinkState.Star:
		case LinkState.Hit:
			exit;
		
	}
	
	//if(instance_exists(oCursed)) exit;
	
	if(global.SaveLevel){
		if(oLink.Facing == RIGHT){
			var SaveTentInst = instance_position(bbox_right, y, oSaveTent); 
			if(SaveTentInst != noone){
				MsgBox("Take a break? Save and quit?", true);
				SaveTentInst.DB_Started = true;
			}
		}
	}	
	
	var _HoldingItem = (ItemHolding != noone && instance_exists(ItemHolding));
	
	if(_HoldingItem && !InDoor_Facing && InDoor_Aligned){
		UpdateState(LinkState.Throwing);
		exit;
	}
	
	//Treasure Small
	var TreasureInst = instance_position(x, bbox_top - 3, oItem_Treasure); 
	if(TreasureInst != noone && Facing == UP && TreasureInst.visible && TreasureInst.sprite_index != sItem_TreasureBlock && TreasureInst.image_index == 0){
		UpdateState(LinkState.TreasureOpening);
		Treasure_Open(TreasureInst);
		exit;		
	}	

	//Treasure Large
	TreasureInst = instance_position(x, bbox_top - 3, oTreasureLarge); 
	if(TreasureInst != noone && Facing == UP && TreasureInst.visible && TreasureInst.image_index == 0){
		UpdateState(LinkState.TreasureOpening);
		TreasureLarge_Open(TreasureInst);
		exit;		
	}	

	//Store
	if(oLink.Facing == UP && !_HoldingItem){
		var WallInst = instance_place(x, y - 6, oShopWall);
		if(WallInst != noone){

			if(WallInst.FloorLevel == oLink.FloorLevel){
				
				var ShopInst = WallInst.ShopInst;
				
				if(ShopInst != noone){
					
					//we have to check all items in front of shop and make sure they are FromShop, since other dropped items may be sitting in front also.
					ds_list_clear(CollidedShopItemList);
					
					var _ShopItems = collision_rectangle_list(x - 4, y - 30, x + 4, y - 16, oItem, false, true, CollidedShopItemList, false);
					
					for(var i = 0; i < _ShopItems; i++){
						ShopItemLook = CollidedShopItemList[| i];
						if(ShopItemLook != noone){
							if(ShopItemLook.ShopItem && FromAnyStore(ShopItemLook.From)){
								UpdateState(LinkState.Standing);
								ShopInst.DB_Init = true;	
								exit;
							}
						}
					}
					
				}
				
			}
		}
	}
	
	//Kinstones
	if(Facing == DOWN){
		
		var KinstoneInst = instance_position(x, bbox_bottom - 9, oItem_Kinstone_Main); 

		if(KinstoneInst != noone){
			if(KinstoneInst.State == KinstoneState.Idle){
				KinstoneInst.DB_Init = true;
				exit;
			}
		}
	
	}

	
	//Sign
	if(Facing == UP){
		var SignInst = instance_position(x, bbox_top - 3, oSign); 
		if(SignInst != noone){
			if(SignInst.Active){
				SignInst.DB_Init = true;
				exit;
			}
		}
	}
	
	
	
	//consume/pickup inventory full item
	
	var CanPickupInst = noone;
	if(InventoryFullInst != noone){
		if(InventoryFullInst.CanConsume){
			var _ItemInst = InventoryFullInst.ItemInst;
			Item_Consume(_ItemInst.Class, _ItemInst.Index);
			if(_ItemInst.Class == ItemClass.Potion && _ItemInst.Index == Potion.Antidote) _ItemInst.Get_Sound = noone;
			if(_ItemInst.Get_Sound != noone) audio_play_sound(_ItemInst.Get_Sound, 1, false);
			_ItemInst.Amount--;
			if(_ItemInst.Amount <= 0){
				instance_destroy(_ItemInst);
				instance_destroy(InventoryFullInst);
				InventoryFullInst = noone;
			}
			exit;
		}
		
		if(InventoryFullInst.CanPickup){
			CanPickupInst = CheckPickupItem(InventoryFullInst.ItemInst);
			if(CanPickupInst != noone) exit;
		}
	}
	
	if(CanPickupInst == noone){
		if(CheckPickupItem(oItem_Orb) != noone) exit;	
		if(CheckPickupItem(oItem_Bombs) != noone) exit;	
		if(CheckPickupItem(oItem_Gem) != noone) exit;	
		if(CheckPickupItem(oItem_WishStone) != noone) exit;	
	}

	
	var Inst;
	switch(Facing){
		case LEFT: Inst = instance_place(bbox_left, y, oPickupObj); break
		case RIGHT: Inst = instance_place(bbox_right, y, oPickupObj); break
		case UP: Inst = instance_place(x, bbox_top + 9, oPickupObj); break
		case DOWN: Inst = instance_place(x, bbox_bottom + 2, oPickupObj); break
	}
	if(Inst != noone){
		
		var _Pickup = true;
		
		switch(Inst.object_index){
			case oOrb: //there's never a need to pick up these objs, anytime you would need to pick them up they would be in their oItem_ form
			case oGem:	
			case oWishStone:	
				_Pickup = false;
				break;
				
			default:
				if(Inst.Hidden || Inst.State == PickupObjState.Destroyed) _Pickup = false;
				if(Inst.State == PickupObjState.Travelling && Inst.z > 2 && Inst.Bounces > 1) _Pickup = false;
				break;
		}
		
		if(_Pickup){
			UpdateState(LinkState.PickUp, Inst);
			if(Inst.object_index == oBomb){
				if(LevelDef.Special != LevelSpecial.FinalBoss && !Inst.Red){ //for Aghanim fight, bombs must ignite even when picking up
					Inst.alarm[0] = -1; //don't ignite it if picking up bomb item, it'll be ignited when thrown. This also cancels igniting a bomb if it wasn't ignited yet
				}
			}
			exit;	
		}
		
	}	

	
	//Light Torch
	if(global.Inventory.ItemData[ItemClass.Lamp].Index > -1 && !instance_exists(oLampFlame)){
		
		Inst = noone;
		switch(Facing){
			case LEFT: Inst = instance_place(bbox_left, y, oTorch); break;
			case RIGHT: Inst = instance_place(bbox_right, y, oTorch); break;
			case UP: Inst = instance_place(x, bbox_top + 9, oTorch); break;
			case DOWN: Inst = instance_place(x, bbox_bottom + 2, oTorch); break;
		}
		if(Inst != noone){
			if(!Inst.Lit){
				Inst.Lighting = true;
				exit;
			}
		}
		
	}
		

	//Dead/Hungry Guy
	var DeadGuyInst;
	switch(Facing){
		case LEFT: DeadGuyInst = instance_position(bbox_left - 5, y - 6, oDeadHungryGuy); break
		case RIGHT: DeadGuyInst = instance_position(bbox_right + 5, y - 6, oDeadHungryGuy); break
		case UP: DeadGuyInst = instance_position(x, bbox_top - 3, oDeadHungryGuy); break;
		case DOWN: DeadGuyInst = instance_position(x, bbox_bottom + 3, oDeadHungryGuy); break
	}
	if(DeadGuyInst != noone){
		DeadGuyInst.DB_Init = true;
		exit;
	}

	//HeartGuy
	var HeartGuyInst;
	switch(Facing){
		case LEFT: HeartGuyInst = instance_position(bbox_left - 5, y - 6, oHeartGuy); break
		case RIGHT: HeartGuyInst = instance_position(bbox_right + 5, y - 6, oHeartGuy); break
		case UP: HeartGuyInst = instance_position(x, bbox_top - 3, oHeartGuy); break;
		case DOWN: HeartGuyInst = instance_position(x, bbox_bottom + 3, oHeartGuy); break
	}
	if(HeartGuyInst != noone){
		HeartGuyInst.DB_Init = true;
		exit;
	}
	
	//NPC		
	var NPCInst;
	switch(Facing){
		case LEFT: NPCInst = instance_position(bbox_left - 5, y - 6, oNPC); break
		case RIGHT: NPCInst = instance_position(bbox_right + 5, y - 6, oNPC); break
		case UP: NPCInst = instance_position(x, bbox_top - 5, oNPC); break;
		case DOWN: NPCInst = instance_position(x, bbox_bottom + 5, oNPC); break
	}

	if(NPCInst != noone){
		NPCInst.DB_Init = true;
		exit;
	}

	//curtain
	Inst = noone;
	switch(Facing){
		case LEFT: Inst = instance_place(bbox_left, y, oCurtain); break;
		case RIGHT: Inst = instance_place(bbox_right, y, oCurtain); break;
		case UP: Inst = instance_place(x, bbox_top + 9, oCurtain); break;
		case DOWN: Inst = instance_place(x, bbox_bottom + 2, oCurtain); break;
	}
	if(Inst != noone){
		if(!Inst.Revealed && Inst.FloorLevel == FloorLevel && Door_LocationToDir(Inst.Location) == Facing){
			Curtain_Reveal(Inst);
			exit;
		}
	}

	
	if(LevelDef.Special == LevelSpecial.Village){
			
		//Old Lady NPC
			
		if(Facing == LEFT){
			var OldLadyInst = instance_position(bbox_left - 9, y - 6, oNPC_OldLady); 
			if(OldLadyInst != noone){
				if(OldLadyInst.State == NPCState_OldLady.Sleeping){
					OldLadyInst.Wake_Init = true;
					global.Paused = true;
					UpdateState(LinkState.Idle);
					exit;
				}
			}
		}
			
		switch(Facing){
			case LEFT: Inst = instance_place(bbox_left, y, oEnemy_Chicken); break
			case RIGHT: Inst = instance_place(bbox_right, y, oEnemy_Chicken); break
			case UP: Inst = instance_place(x, bbox_top - 5, oEnemy_Chicken); break
			case DOWN: Inst = instance_place(x, bbox_bottom + 2, oEnemy_Chicken); break
		}
		if(Inst != noone){
			if(Inst.State != EnemyState.OnFire && Inst.State != EnemyState.Stone && Inst.State != EnemyState.Frozen && !oLink.InDoor && !oLink.InDoor_House){
				UpdateState(LinkState.PickUp, Inst);
				exit;
			}
		}	

		//switch(Facing){
		//	case UP: var Inst = instance_place(x, bbox_top - 32, oVillager_ChessPlayer); break
		//}
		//if(Inst != noone){
		//	Inst.OfferGame = true;
		//	exit;
		//}	

		//PopMachine
		//if(global.Level.Rooms[global.CurrentRoomIndex].TemplateName == "Arcade"){
			if(oLink.Facing == UP){
				var PopMachineInst = instance_position(x, bbox_top + 6, oPopMachine);
				if(PopMachineInst != noone){
					if(global.Challenges[Challenges.NoFood]){
						MsgBox("\\Out of Order",,,,,true);
					}else{
						PopMachineInst.DB_Init = true;
					}
					exit;
				}
				var ClawMachineInst = instance_position(x, bbox_top + 6, oClawMachine);
				if(ClawMachineInst != noone){
					ClawMachineInst.DB_Init = true;
					exit;
				}
			}
		//}
		
		//Frogs
		if(Facing == UP){
			Inst = instance_place(x, bbox_top - 5, oSimonFrogs);
			if(Inst != noone){
				if(!Inst.PlayNote){
					Inst.Index = floor((x - Inst.x) / 18);				
					Inst.PlayNoteInit = true;
				}
			}
		}
	}

	//Prisoners
	if(LevelDef.Jails){
		if(Facing == UP){
			var PrisonerInst = collision_rectangle(x - 16, y - 48, x + 16, y, oPrisoner, false, true);
			if(PrisonerInst != noone){
				PrisonerInst.DB_Init = true;
				exit;
			}			
		
		}
	}

}

function CheckPickupItem(_ItemObj, _Inst = noone){
	
	if(_Inst == noone){
		switch(Facing){
			case LEFT: _Inst = instance_place(bbox_left, y, _ItemObj); break
			case RIGHT: _Inst = instance_place(bbox_right, y, _ItemObj); break
			case UP: _Inst = instance_place(x, bbox_top + 9, _ItemObj); break
			case DOWN: _Inst = instance_place(x, bbox_bottom + 2, _ItemObj); break
		}
	}
	if(_Inst != noone){
		if(!_Inst.ShopItem && _Inst.FloorLevel == FloorLevel){
			UpdateState(LinkState.PickUp, _Inst);	
		}
	}	
	
	return _Inst;
}

function CheckGravityBall(){
	
	var _GravityBall = false;
	
	with(oAghanim_GravityBall){
		var _Dir = point_direction(x, y, oLink.x, oLink.y);
		oLink.vx += lengthdir_x(1.75, _Dir);
		oLink.vy += lengthdir_y(1.75, _Dir);
		_GravityBall = true;
	}
	
	return _GravityBall;
	
}

function LinkThrow(){
	
	if(ItemHolding == noone || !instance_exists(ItemHolding)){
		ItemHolding = noone;
		exit;
	}
	
	switch(ItemHolding.object_index){

		case oEnemy_Chicken:
			with(ItemHolding){
				Enemy_UpdateState(EnemyState.Jumping);
			}

			break;
		
		case oBomb:
			if(InDoor){
				ItemHolding.CheckWallCollide = false; //it'll collide with the door so wait to check, alarm will reset the check
				ItemHolding.alarm[2] = 20;
			}
		default:
			ItemHolding.State = PickupObjState.Throw;
			break;
	}
			
	ItemHolding = noone;
			
}

function LinkBounceBack(_BounceDir, _Speed, _Time, _Sound = true){

	BounceBack = true;

	alarm[2] = _Time;	
	
	if(_Sound) audio_play_sound_stopall(Sound_Bounce);

	with(oWall){		
		if(IsStairs){ 
			//if link is standing on a stair wall, exit and don't bounce back
			if(place_meeting(x, y, oLink)){
				exit;
			}
			BlockLink = true;
		}
	}

	if(InDoorPassage == 0){ //only send Link bouncing if not in a door passage, otherwise it may crash
		vx = lengthdir_x(_Speed, _BounceDir);
		vy = lengthdir_y(_Speed, _BounceDir);
	}		
	
}

function CheckEnemies(){
	
	HitBox.x = x + vx;
	HitBox.y = y + vy;
	
	if(Cape) exit;
	
	var Inst = noone;
	
	with(HitBox){
		Inst = instance_place(x, y, oEnemy);
	}
	if(Inst != noone){
		if(EnemyCanHurtLink(Inst)){
			switch(Inst.object_index){
				case oEnemy_RollingSpike:
					LinkHit(point_direction(Inst.x, Inst.y, Inst.x + Inst.vx, Inst.y + Inst.vy), 1.75, 12, Inst.Attack);
					break;
					
				case oEnemy_Bubble:
					LinkHit(point_direction(Inst.x, Inst.y, x, y), 1.25, 12, Inst.Attack, MAGICAMOUNT_BASEUNIT * 2);
					break;
				
				case oEnemy_MovingSpikeBlock:
					LinkHit(point_direction(Inst.x, Inst.y, x, y), 2, 12, Inst.Attack);
					break;
					
				case oBoss_Aghanim:
					LinkHit(point_direction(Inst.x, Inst.y, x, y), 3.5, 12, Inst.Attack);
					break;
				
				case oEnemy_Guru:					
					LinkHit(point_direction(Inst.x, Inst.y, x, y), 1.5, 12, Inst.Attack, MAGICAMOUNT_BASEUNIT * Inst.Type * 2);
					break;
					
				default:
					
					if(Inst.object_index == oEnemy_Bari && Inst.CanShock){ //special case for Bari, shock Link if he touches them while electric
						ShockLink(Inst);
					}else{
						LinkHit(point_direction(Inst.x, Inst.y, x, y), 1.25, 12, Inst.Attack);
					}
					break;
			}
			exit;
		}
	}
		

	with(HitBox){
		Inst = instance_place(x, y, oSoldierWeapon);
	}
	var _Dir;
	if(Inst != noone){
		
		if(Inst.FloorLevel == FloorLevel && (Inst.CanHurtLinkWhenSoldierHurt || EnemyCanHurtLink(Inst.SoldierInst))){
			switch(Inst.object_index){
				default: _Dir = point_direction(Inst.x, Inst.y, x, y); break;
				case oSoldierWeapon_Mace: _Dir = AngleCheck(Inst.SpinAngle + 90); break;
			}
			LinkHit(_Dir, 1.25, 12, Inst.SoldierInst.Attack);
			exit;
		}
	}
				

	Inst = instance_place(x, y, oProjectile);
	if(Inst != noone){
		if(Inst.Enemy && Inst.FloorLevel == FloorLevel){
			
			var _ShieldHit = Shield_Hit(Inst, Inst.x, Inst.y);
			
			if(_ShieldHit){
				switch(Inst.object_index){
					default:
						instance_create_layer(Inst.x, Inst.y, "ObjsHigher_" + GetFloorLevelString(FloorLevel), oWallHit, {PlaySound: false});
						audio_play_sound(Sound_Shield, 1, false);
						break;
					case oBone:
						break;
				}				
			}else{
				LinkHit(point_direction(Inst.x, Inst.y, x, y), Inst.HitV, Inst.HitTime, Inst.Damage); 
			}
			
			with(Inst){
				if(LinkTouchDestroy){
					switch(object_index){
						default:
							instance_destroy(id);
							break;
						case oBone:
							Destroyed = true;
							break;
					}
				
				}
			}
			
		}
	}
		

}

function ShockLink(_EnemyInst, _ShowSword = false){
	
	with(oLink){
		
		if(State == LinkState.Shocked || Invincible) exit;
		
		UpdateState(LinkState.Shocked);
		
		ShockEnemyX = _EnemyInst.x;
		ShockEnemyY = _EnemyInst.y;
		ShockEnemyAttack = _EnemyInst.Attack;
		ShockDrawSword = _ShowSword;
		
	}
	
	Mosaic(MosaicType.Shock);
						
}

function EnemyCanHurtLink(_Inst){
	return !global.Paused && _Inst.CanHurtLink && (_Inst.FloorLevel == FloorLevel || _Inst.FloorLevel == UPPERLOWER) && _Inst.State != EnemyState.KnockBack && _Inst.State != EnemyState.PushBack && _Inst.State != EnemyState.Idle && _Inst.State != EnemyState.Wake && _Inst.State != EnemyState.Sleep && _Inst.State != EnemyState.Stunned && _Inst.State != EnemyState.Frozen && _Inst.State != EnemyState.OnFire && _Inst.State != EnemyState.Stone
}

function LinkHit(_Dir, _Speed, _Time, _MaxAttackPoints, _Magic = 0){
	
	if(State == LinkState.Hit || State == LinkState.Descending || State == LinkState.AutoMove || State == LinkState.FallingOverEdge || State == LinkState.Falling || Invincible || (Cape && State != LinkState.Shocked)) exit;
	
	var _Damage = Enemy_Attack(_MaxAttackPoints);
	HealthAdd(-_Damage);
	
	if(LinkHealth <= 0) exit;
	
	if(_Magic > 0 && global.Inventory.ItemData[ItemClass.Magic].Amount > 0){
		MagicUse(_Magic);
		audio_play_sound(Sound_MagicMeter, 1, false);
	}
	
	LinkThrow();
	UpdateState(LinkState.Hit);
		
	LinkBounceBack(_Dir, _Speed, _Time, false);	
	
}

function LinkEnableFlashing(){
	Invincible = true;
	HitFlashingStatus = true;
	alarm[4] = HitFlashingLength; //Stay invincible/flashing for this long
	alarm[5] = HitFlashingDelay; //flashing alarm	
}

function CheckSpikes(){
	
	if(Invincible || Cape) exit;
	
	var SpikeBlockInst = instance_place(x + vx, y + vy, oSpikeBlock);
	if(SpikeBlockInst != noone){
		LinkHit(point_direction(SpikeBlockInst.x + 8, SpikeBlockInst.y + 8, x, y), CarryingSpeed, 12, SpikeBlockInst.Damage);
		exit;
	}
	
	if(Pendant_Check(Pendant.Protection)) exit;
	
	
	if(OnSpikeTile(GetFloorLevelTMID("Tiles_Floor", x, y), x, y)){
		LinkHit(0, 0, 1, 1.5);
	}	
	
}

function CheckItems(){
	
	if(instance_exists(oInventory)) exit;
	
	var _InventoryFull = false;
	
	ObjCollision_List(CollidedObjList, x, y, oItem, FloorLevel);
	
	var _PickedWithSword = false;
	
	if(ds_list_size(CollidedObjList) == 0 && instance_exists(oSword)){
		
		with(oSword){
			var img_index = floor(oLink.image_index);
			if( (img_index >= 2 && img_index <= 9) || oLink.State == LinkState.Star || oLink.State == LinkState.SwordSpin){
				SwordCollision(oItem, other.CollidedObjList)	//	ObjCollision_List(other.CollidedObjList, x, y, oItem, other.FloorLevel);
			}
		}
		_PickedWithSword = ds_list_size(CollidedObjList) > 0;
	}
	
	var _PlayingGetSound = false; //only allow 1 get sound per group pickup, otherwise it can get too loud if multiple sounds play at once
	
	for(var i = 0; i < ds_list_size(CollidedObjList); i++){
		
		if(global.DB_Inst != noone) break;
		
		var ItemInst = CollidedObjList[| i];
		
		StandingOnMap = (ItemInst.Class == ItemClass.Map);
		StandingOnCompass = (ItemInst.Class == ItemClass.Compass);
		
		if((!ItemInst.Spawning || ItemInst.Get_Allowed) && !ItemInst.ShopItem && ItemInst.Get_WhenLinkCollides){
			
			switch(ItemInst.object_index){
				
				//case oItem_Star:
				//	if(_PickedWithSword) break; //don't allow pick-up with sword for star
					
				default:

					var _Amount = global.ItemData[ItemInst.Class].Type == ItemType.Inv_Chrg ? ItemInst.Amount : max(ItemInst.Amount, 1);
					var _GetDialogue = ItemInst.Get_ShowDialogue && Item_GetDialogueClass(ItemInst.Class) && ItemInst.From != ItemFrom.Inventory && State != LinkState.Star && State != LinkState.SwordSpin;

					var ItemGot = Item_Get(ItemInst.Class, ItemInst.Index, _Amount);
					
					if(ItemGot){
						
						if(_GetDialogue){
							Item_GetDialogue(ItemInst.Class, ItemInst.Index, ItemInst.Amount);
						}

						Curse_GetItemUncurseMsg(ItemInst.Class, ItemInst.Index);
	
						if(ItemInst.Get_Sound != noone && !_PlayingGetSound && !audio_is_playing(Sound_Antidote)){
							audio_play_sound(ItemInst.Get_Sound, 1, false);
							_PlayingGetSound = true;
						}
						instance_destroy(ItemInst);
						
					}else{
						
						if(_PickedWithSword){
							switch(ItemInst.Class){
								case ItemClass.Map:
									StandingOnMap = false;
									break;
								case ItemClass.Compass:
									StandingOnCompass = false;
									break;
							}
							break;
						}
						
						_InventoryFull = true;
						
						if(InventoryFullInst == noone){
							InventoryFullInst = instance_create_layer(0, 0, "System", oInventoryFull);
						}
						
						//determine if Maxed Out message should show
						switch(ItemInst.Class){
							case ItemClass.Bombs:
							case ItemClass.Arrows:

								var _ItemAmount = global.Inventory.ItemData[ItemInst.Class].Amount[0];
								var _MaxAmount = Inventory_MaxAmount(ItemInst.Class);
								
								InventoryFullInst.MaxedOut = (_ItemAmount >= _MaxAmount);
								
								break;
						}

						InventoryFullInst.ItemInst = ItemInst;
						
					}					
					
					break;

				case oItem_Crystal:
					ItemInst.SpawnAnimation = false;
					ItemInst.SpawnAnimationFinish = true;
					if(instance_exists(ItemHolding)){
						var _DropPos = Item_DropPos();
						var _Class = ItemClassFromObjIndex(ItemFromObj(ItemHolding.object_index));
						var _DroppedItemInst = ItemDrop(_DropPos[0], _DropPos[1], _Class, ItemHolding.Index, 1, ItemFrom.Inventory);
						instance_destroy(ItemHolding);
						ItemHolding = noone;
					}
					with(oCape){
						instance_destroy(id);
					}
					Music_Stop();
					audio_play_sound(Music_Boss_Defeated, 1, false);
					HoldUpItem(ItemInst,, false, false);
					HoldBossCrystal = true;
					var _MusicLen = audio_sound_length(Music_Boss_Defeated);
					alarm[10] = global.MusicVol > 0 && _MusicLen != -1? _MusicLen * 60 : 180; //hold delay
					break;
			}
			
		}
	}
	
	if(!_InventoryFull && instance_exists(InventoryFullInst)){
		instance_destroy(InventoryFullInst);
		InventoryFullInst = noone;
	}
	
}

function CheckSpecialItems(){
	
	//1st level Entrance Wall
	if(LevelDef.Depth <= Level_Depth(DungeonLevel.Castle)){
		if(AllowCastleEntranceWallCollide){
			var EntranceWallInst = instance_position(x, y + 4, Castle_EntranceWallInst);
			if(EntranceWallInst != noone){
				AllowCastleEntranceWallCollide = false;
				MsgBox("Where are you going? The action is the other way!");
			}
		}else{
			if(!instance_position(x, y + 4, Castle_EntranceWallInst)) AllowCastleEntranceWallCollide = true;
		
		}
	}
	
	if(global.CurrentRoomIndex == -1) exit;
	
	
	//Fairy_Health
	
	if(TemplateCheck(global.CurrentRoomIndex, RoomTemplateClass.Special, RoomTemplateClass_Special.Fairy)){
		var FairyInst = collision_circle(x, y, 50, oFairy_Health, false, true);

		if(FairyInst != noone){
			if(AllowFairy){
				FairyInst.DB_Init = true;
				AllowFairy = false;
			}
		}else AllowFairy = true;
	}

	
	//Floor Switches
	var SwitchInst = instance_position(x, y - 2, oFloorSwitch);
	if(SwitchInst != noone && SwitchInst.FloorLevel == FloorLevel){
		SwitchInst.Activated = true;
	}
	
	//Warps
	var WarpInst = instance_position(x, y - 2, oWarp);
	if(WarpInst != noone){
		if(WarpInst.FloorLevel == FloorLevel && WarpInst.visible){

			StopStar();
			
			with(oCape) instance_destroy(id);
			
			Warp_RoomIndex_From = global.CurrentRoomIndex;
			Warp_RoomIndex_To = global.Level.Rooms[WarpInst.RoomIndex].Warp_DestRoomIndex;
		
			Mosaic(MosaicType.Warp);		
			
			UpdateState(LinkState.Warping);
			
			Dungeon_RoomActivate(Warp_RoomIndex_To);
		
			audio_play_sound(Sound_Warp, 1, false);
		}
		
	}

}

function UpdateCarryItem(){

	if(!instance_exists(ItemHolding) || ItemHolding == noone || State == LinkState.PickUp || State == LinkState.PutDown || State == LinkState.HoldingItem) exit;
	
	ItemHolding.x = x;
	//var NewY = y - 18 + (vx != 0 || vy != 0 ? floor(image_index mod 3) : 0); //if moving, make the item go up and down relative to link's head	
	var NewY = y - 18 + ((State == LinkState.Walking || State == LinkState.AutoMove) ? floor(image_index mod 3) : 0); //if moving, make the item go up and down relative to link's head	
	
	ItemHolding.FloorLevel = FloorLevel;

	ItemHolding.layer = (FloorLevel == UPPER || OnStairs(ItemHolding.x, ItemHolding.y) != NONE ? global.LayerID_ObjsHigher_Upper : global.LayerID_ObjsHigher_Lower);
	
	switch(ItemHolding.id){
		case oEnemy_Chicken:
			ObjSetY(NewY);
			break;
		default:
			ItemHolding.y = NewY; 
			break;
	}
	

}

function HoldUpItem(_Inst, _From = ItemFrom.Treasure, _PlayFanfare = true, _Alarm = true){

	with(oLink){
		UpdateState(LinkState.HoldingItem);
		ItemHolding = _Inst
		ItemHolding.visible = true;
		ItemHolding.layer = (_Inst.Class == ItemClass.Treasure && _From == ItemFrom.Shop ? global.LayerID_ObjsHigher_Upper : global.LayerID_ObjsHighest);
		ItemHolding.From = _From;	
		ItemHolding.FloorLevel = UPPER;
		ItemHolding.ShowShadow = false;
		ItemHolding.ShowPrice = false;
		ItemHolding.Get_Sound = noone;
		ItemHolding.Lighting = false;
		ItemHolding.x = x + 6;
		ItemHolding.y = y - 19;
		if(_Alarm) alarm[0] = 92; //how long for the obj to disappear from Link's hands. 92 since that's how long items from treasures spawn so it has to be the same
	}
	
	if(_PlayFanfare) audio_play_sound(Sound_ItemGetFanfare, 1, false);
	
}

function ATTACK(){
	
	//returns total attack points from items that link owns and factoring modifiers like curses
	
	var AttackPoints = Attack_GearPoints();
	
	if(Curse_Check(CurseEffects.AttackReduced)) AttackPoints -= Curse_AttDefReduction;
	
	return max(AttackPoints, 0);
	
}

function Attack_GearPoints(){

	var SwordPoints = global.Inventory.ItemData[ItemClass.Sword].Index + 1;
	var GlovePoints = max(global.Inventory.ItemData[ItemClass.Gloves].Index, 0);
	
	return SwordPoints + GlovePoints;
	
}

function DEFENSE(){
	
	//return total defense points from items that Link owns and factoring modifiers like curses
		
	var DefensePoints = Defense_GearPoints();	
	
	if(Curse_Check(CurseEffects.DefenseReduced)) DefensePoints -= Curse_AttDefReduction;
	
	return max(DefensePoints, 0);
	
}

function Defense_GearPoints(){

	var TunicPoints = max(global.Inventory.ItemData[ItemClass.Tunic].Index, 0);
	var ShieldPoints = global.Inventory.ItemData[ItemClass.Shield].Index + 1;
	var GlovePoints = global.Inventory.ItemData[ItemClass.Gloves].Index >= 0 ? 1 : 0; 
		
	return TunicPoints + ShieldPoints + GlovePoints;	
	
}

function AttackOrDefenseTooHigh(_AttackOrDefense){
	
	if(LevelDef.Special == LevelSpecial.Village) return false; //ignore village level as Link can upgrade all he wants, he would just be denied upgrades in later levels if he's too high
	
	//checks if attack or defense value is too higher too early.
	if( (_AttackOrDefense >= 3 && LevelDef.Depth <= Level_Depth(DungeonLevel.CastleJails))	||
		(_AttackOrDefense >= 4 && LevelDef.Depth <= Level_Depth(DungeonLevel.Sewers))		||
		(_AttackOrDefense >= 5 && LevelDef.Depth <= Level_Depth(DungeonLevel.LanmolasLair))	||
		(_AttackOrDefense >= 6 && LevelDef.Depth <= Level_Depth(DungeonLevel.WaterTemple)) )	{
			return true;
	}	
}

function MaxAttackPointsThatExist(){
	
	//returns maximum attack points Link can achieve from the items he owns and items that exist. This is for checking if his possible attack is too high for the level he's on.
	//Another way to put it is if he were to collect all the existing attack items in the level, what would his attack points then be
	
	var LinkSwordIndex = global.Inventory.ItemData[ItemClass.Sword].Index;
	var LinkGloveIndex = global.Inventory.ItemData[ItemClass.Gloves].Index;
	
	var HighestSwordIndexThatExists = LinkSwordIndex;
	var HighestGloveIndexThatExists = LinkGloveIndex;
	
	var GridH = ds_grid_height(global.NonDuplicatableItemsThatExist);
		
	for(var i = 0; i < GridH; i++){

		var _ItemClass = global.NonDuplicatableItemsThatExist[# 0, i];
		var _ItemIndex = global.NonDuplicatableItemsThatExist[# 1, i];
		
		switch(_ItemClass){
			case ItemClass.Sword:
				HighestSwordIndexThatExists = max(HighestSwordIndexThatExists, _ItemIndex);
				break;
			case ItemClass.Gloves:
				HighestGloveIndexThatExists = max(HighestGloveIndexThatExists, _ItemIndex);
				break;
		}
		
	}	
	
	var SwordPoints = HighestSwordIndexThatExists + 1;
	var GlovePoints = max(HighestGloveIndexThatExists, 0);
	
	return SwordPoints + GlovePoints;	
	
}

function MaxDefensePointsThatExist(){
	
	//returns maximum defense points Link can achieve from the items he owns and items that exist. This is for checking if his possible defense is too high for the level he's on
	//Another way to put it is if he were to collect all the existing defense items in the level, what would his defense points then be
	
	var LinkGloveIndex = global.Inventory.ItemData[ItemClass.Gloves].Index;
	var LinkShieldIndex = global.Inventory.ItemData[ItemClass.Shield].Index;
	var LinkTunicIndex = max(global.Inventory.ItemData[ItemClass.Tunic].Index, 0);
	
	
	var HighestGloveIndexThatExists = LinkGloveIndex;
	var HighestShieldIndexThatExists = LinkShieldIndex;
	var HighestTunicIndexThatExists = LinkTunicIndex;
	
	var GridH = ds_grid_height(global.NonDuplicatableItemsThatExist);
		
	for(var i = 0; i < GridH; i++){
		
		var _ItemClass = global.NonDuplicatableItemsThatExist[# 0, i];
		var _ItemIndex = global.NonDuplicatableItemsThatExist[# 1, i];
		
		switch(_ItemClass){
			case ItemClass.Gloves:
				HighestGloveIndexThatExists = max(HighestGloveIndexThatExists, _ItemIndex);
				break;
			case ItemClass.Shield:
				HighestShieldIndexThatExists = max(HighestShieldIndexThatExists, _ItemIndex);
				break;
			case ItemClass.Tunic:
				HighestTunicIndexThatExists = max(HighestTunicIndexThatExists, _ItemIndex);
				break;
		}
		
	}	
	
	var GlovePoints = HighestGloveIndexThatExists >= 0 ? 1 : 0; 
	var ShieldPoints = HighestShieldIndexThatExists + 1;
	var TunicPoints = HighestTunicIndexThatExists;	
		
	return TunicPoints + ShieldPoints + GlovePoints;	
	
}

function Link_UpdateAttackDefence(){
	oLink.AttackPoints = ATTACK();
	oLink.DefensePoints = DEFENSE();
}

function InFrontOfLink(_x, _y){
	
	switch(oLink.Facing){
		case UP:
			if(_y <= oLink.y) return true; 
			break;
		case DOWN:  
			if(_y >= oLink.y) return true;
			break; 
		case LEFT:  
			if(_x <= oLink.x) return true;
			break;
		case RIGHT: 
			if(_x >= oLink.x) return true;
			break; 		
	}
	return false;
}

function Link_PickupObjPos(img_index){
	
	switch(Facing){
		case LEFT:
			if(img_index >= 0 && img_index <= 2) { ItemHolding.x = x - 13; ItemHolding.y = y - 10;}
			if(img_index == 3) { ItemHolding.x = x - 10; ItemHolding.y = y - 13;}
			if(img_index >= 4) { ItemHolding.x = x - 5; ItemHolding.y = y - 16;}
			break;		
		case RIGHT:
			if(img_index >= 0 && img_index <= 2) { ItemHolding.x = x + 13; ItemHolding.y = y - 10;}
			if(img_index == 3) { ItemHolding.x = x + 10; ItemHolding.y = y - 13;}
			if(img_index >= 4) { ItemHolding.x = x + 5; ItemHolding.y = y - 16;}
			break;
		case UP:
			if(img_index >= 0 && img_index <= 2) { ItemHolding.x = x; ItemHolding.y = y - 15;}
			if(img_index == 3) { ItemHolding.x = x; ItemHolding.y = y - 16;}
			if(img_index >= 4) { ItemHolding.x = x; ItemHolding.y = y - 17;}
			break;
		case DOWN:
			if(img_index >= 0 && img_index <= 2) { ItemHolding.x = x; ItemHolding.y = y - 2;}
			if(img_index == 3) { ItemHolding.x = x; ItemHolding.y = y - 12;}
			if(img_index >= 4) { ItemHolding.x = x; ItemHolding.y = y - 16;}
			break;				
	}	
	
}

function Link_PauseHitFlashingTimer(){
	with(oLink){
		if(Invincible && alarm[4] != -1){
			alarm[4]++;
			alarm[5]++;
			HitFlashingStatus = false;
		}	
	}
}

function Link_PixelRender(){

	if(LevelDef.Special == LevelSpecial.FinalBoss){ //once Aghanim grabs items, don't draw tunic. Tunic from inventory will eventually be destroyed, so this only applies during the taking phase
		with(oBoss_Aghanim){
			if(Intro && TakeItems && TakeItems_ShowBag){
				PixelRender(other.Lighting, other.Lighting, false, noone, 0, false, []);
				exit
			}
		}		
	}
	
	var _TunicIndex = max(global.Inventory.ItemData[ItemClass.Tunic].Index, 0);
	if (State == LinkState.Star)
		PixelRender(Lighting, Lighting, PaletteSpr != noone, PaletteSpr, _TunicIndex, true, StarColors[StarColorIndex]);
	else if(global.Cursed) 
		PixelRender(Lighting, Lighting, PaletteSpr != noone, PaletteSpr, _TunicIndex, true, KB_Gr);
	else
		PixelRender(Lighting, Lighting, PaletteSpr != noone, PaletteSpr, _TunicIndex, false, []);
	
}

function GetLinkWeaponClass(_Obj, _Index = 0){
	switch(_Obj){
		case oSword: return LinkWeaponClass.Sword;			
		case oArrow: return LinkWeaponClass.Arrow;
		case oBoomerang: return LinkWeaponClass.Boomerang;
		case oBombExplosion: return LinkWeaponClass.Bomb;
		case oHookshot: return LinkWeaponClass.Hookshot;
		case oRodBeam: 
		case oCaneBeam: 
			switch(_Index){
				case Rod.Stone:
					return LinkWeaponClass.Stone
				case Rod.Ice:
					return LinkWeaponClass.Ice
				case Rod.Fire:
					return LinkWeaponClass.Fire
				case Rod.Bomb:
				case Rod.Heart:
				case Rod.Wealth:
					return LinkWeaponClass.Transform
			}
			break;
		//case oCaneBeam: 
		////case oMagic:
		//	return LinkWeaponClass.Transform
		//	break;

		case oFireTower: 
			return LinkWeaponClass.Fire;
		case oIceTower: 
			return LinkWeaponClass.Ice;
		case oSwordBeam: return LinkWeaponClass.SwordBeam;
		//case oMagic: return LinkWeaponClass.Magic;

		case oPot:
		case oBush:
			return LinkWeaponClass.Pot;
			
	}
	
	return -1
	
}

function Link_GetInWaterSprite(){
	
	if(TemplateCheck(global.CurrentRoomIndex, RoomTemplateClass.Special, RoomTemplateClass_Special.Fairy)) return sInWater;
	
	return LevelDef.InWaterSprite;
	
}

function GetStateName(State){ //temp, only used for debug text in Render obj
	
	switch(State){
		case LinkState.Idle: return "Idle";	
		case LinkState.Standing: return "Standing";	
		case LinkState.Walking: return "Walking";	
		case LinkState.Hit: return "Hit";	
		case LinkState.Dead: return "Dead";	
		case LinkState.AutoMove: return "AutoMove";	
		case LinkState.Sword: return "Sword";	
		case LinkState.SwordSpin: return "Sword Spin";	
		case LinkState.Bow: return "Bow";	
		case LinkState.PickUp: return "PickUp";	
		case LinkState.PutDown: return "PutDown";	
		case LinkState.TreasureOpening: return "TreasureOpening";	
		case LinkState.HoldingItem: return "HoldingItem";	
		case LinkState.Throwing: return "Throwing";	
		case LinkState.Pushing: return "Pushing";	
		case LinkState.Boomerang: return "Boomerang";	
		case LinkState.Hookshot: return "Hookshot";	
		case LinkState.Rod: return "Rod";	
		case LinkState.Powder: return "Powder";	
		case LinkState.Shocked: return "Shocked";
		case LinkState.Warping: return "Warping";
		case LinkState.Falling: return "Falling";	
		case LinkState.FallingOverEdge: return "FallingOverEdge";	
		case LinkState.Descending: return "Descending";	
		case LinkState.Inventory: return "Inventory";
		case LinkState.Dialogue: return "Dialogue";
		case LinkState.VideoGame: return "VideoGame";	
	}
	
	return "unknown"
}

function Link_LoadCharacterIndex(){
	if(!variable_global_exists("LinkCharacterIndex")) global.LinkCharacterIndex = 0;
	PaletteSpr = global.LinkCharacterPal[global.LinkCharacterIndex];
	LinkSprites_Construct(global.LinkCharacterIndex);	
}
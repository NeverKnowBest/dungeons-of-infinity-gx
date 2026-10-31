with(ExplosionLightInst){
	if(global.Paused) ObjPause();	
}

PauseObj


if(image_index > 5) exit;

//enemies
	
ds_list_clear(CollisionList);
ObjCollision_Circle_List(CollisionList, x, y, BlastRadius_Enemies, oEnemy, FloorLevel);
var Enemies = ds_list_size(CollisionList);
if(Enemies > 0){
	for(var EnemyIndex = 0; EnemyIndex < Enemies; EnemyIndex++){
		var EnemyInst = CollisionList[| EnemyIndex];
		Enemy_LinkWeaponHit(LinkWeaponClass.Bomb, 0, EnemyInst, x, y, point_direction(x, y, EnemyInst.x, EnemyInst.y));
	}
}

//Link
Bomb_CheckLinkDamage(FloorLevel, , MaxDamage);

if(oLink.State == LinkState.Dead) exit;

//Pickup Objs
PickupObj_CheckExplosions(x, y, FloorLevel, BlastRadius_PickupObjs, CollisionList);


if(image_index > 3 && !Exploded_Curtains){
	ObjCollision_Circle_List(CollisionList, x, y, BlastRadius_Doors, oCurtain, FloorLevel);
	var Curtains = ds_list_size(CollisionList);
	if(Curtains > 0){
		for(var CurtainIndex = 0; CurtainIndex < Curtains; CurtainIndex++){
			
			var CurtainInst = CollisionList[| CurtainIndex];
			
			if(CurtainInst != noone) Curtain_Reveal(CurtainInst);
		
		}

		
	}
	
	Exploded_Curtains = true;
	
}

if(image_index > 4 && !Exploded_Doors){ //check a bit later in the animation for doors, otherwise they blow up too quick
	
	if(LevelDef.Special == LevelSpecial.Intro){
		//check for castle wall hidden door
		var CastleDoor = collision_circle(x, y, BlastRadius_Doors, oCastleWallDoor, false, true);
		if(CastleDoor != noone){
			CastleDoor.Opened = true;			
		}
	}else{		
		
		//check for hidden doors
		ObjCollision_Circle_List(CollisionList, x, y, BlastRadius_Doors, oDoor, FloorLevel);
		RegionRoom_BlastDoors(CollisionList, x, y, BlastRadius_Doors, FloorLevel);	//painted rooms: the wall of the passage
		var Doors = ds_list_size(CollisionList);
	
		var _SecretDoor = false;

		if(Doors > 0){
			for(var DoorIndex = 0; DoorIndex < Doors; DoorIndex++){
			
				var DoorInst = CollisionList[| DoorIndex];
			
				if(DoorInst.Status == DoorStatus.Secret_Closed && (DoorInst.SecretType == SecretDoor.Crack || DoorInst.SecretType == SecretDoor.Blank) ){
				
					Door_OpenSecretDoor(DoorInst);
				
					with(DoorInst){
						var LightInst = instance_place(x, y, oWallLight);
						if(LightInst != noone){
							instance_destroy(LightInst);
						}
					}
				
					_SecretDoor = true;
				}
		
			}
		
			if(_SecretDoor) audio_play_sound_stopall(Sound_Secret);
		
		}


	}

	
	Exploded_Doors = true;
	
}



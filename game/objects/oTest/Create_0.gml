// Test mode controller (see scripts/__Test). Created by Test_Init, lives through every room.
Step = 0;			// index in global.Test.Steps
StepFrames = 0;		// frames spent on the current step
Started = false;
ShotName = "";		// screenshot to save in the Post Draw of this frame
Sheet = undefined;	// contact sheet in progress (Test_SheetStart)
ActivateAll = false;	// set by steps that build a level: oTest's Step activates every instance, like oLink before the stairs

ExitVerb = "";		// verb the "exit" step holds to walk into the exit
PaintedRoom = -1;	// room the "painted" step checks
LockRoom = -1;		// room the "lock" step walks in, and the verb it holds
LockVerb = "";
TourShots = [];		// spots the "tour" step photographs: [room, x, y] (px in the level)
PassList = [];		// doors the "passall" and "bomb" steps go through: [room, door index]
PassK = 0;			// the door under way, its frames, the verb held and the count of doors done and failed
PassT = 0;
PassVerb = "";
PassOk = 0;
PassBad = 0;
PassOpened = false;	// the "bomb" step saw the wall open

LastLevel = undefined;
LastRoom = -1;
LastHealth = -1;
Dead = false;

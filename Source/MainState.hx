package;

import flixel.FlxState;
import flixel.FlxG;
import game.GameState;

class MainState extends FlxState
{

	public function new()
	{
		super();
	}

	override public function create():Void
	{
		var playerDefs:Array<PlayerDef> = [];
		playerDefs.push({ controllerNumber: -1, characterNumber: 2 });
		playerDefs.push({ controllerNumber: 0, characterNumber: 3 });
		//playerDefs.push({ controllerNumber: 1, characterNumber: 2 });
		//playerDefs.push({ controllerNumber: 2, characterNumber: 3 });

		//FlxG.fixedTimestep = false;
		//FlxG.drawFramerate = 120;
		//FlxG.updateFramerate = 120;

		FlxG.switchState(new GameState(playerDefs, "map1", 3));
	}
}
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
		playerDefs.push({
			playerNumber: 1, controllerNumber: -1, characterNumber: 0
			});

		FlxG.switchState(new GameState(playerDefs, "map1"));
	}
}
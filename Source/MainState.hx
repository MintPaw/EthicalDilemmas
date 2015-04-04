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
		playerDefs.push({ controllerNumber: -1, characterNumber: 0 });
		playerDefs.push({ controllerNumber: 0, characterNumber: 1 });

		FlxG.switchState(new GameState(playerDefs, "map1"));
	}
}
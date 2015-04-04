package game;

import flixel.FlxG;
import flixel.FlxSprite;
import game.GameState;

class Player extends FlxSprite
{
	private var _playerDef:PlayerDef;

	public function new(playerDef:PlayerDef)
	{
		super();

		_playerDef = playerDef;

		maxVelocity.set(150, 150);
		drag.set(maxVelocity.x * 8, maxVelocity.y * 8);

		makeGraphic(10, 10, 0xFF0000FF);
	}

	override public function update(elapsed:Float):Void
	{
		acceleration.set(0, 0);
		{ // Update input
			{ // Keyboard input
				if (_playerDef.controllerNumber == -1)
				{
					if (FlxG.keys.pressed.LEFT) move("left");
					if (FlxG.keys.pressed.RIGHT) move("right");
					if (FlxG.keys.pressed.UP) move("up");
					if (FlxG.keys.pressed.DOWN) move("down");
				}
			}
		}

		super.update(elapsed);
	}

	public function move(dir:String):Void
	{
		if (dir == "left") acceleration.x -= maxVelocity.x * 10;
		if (dir == "right") acceleration.x += maxVelocity.x * 10;
		if (dir == "up") acceleration.y -= maxVelocity.x * 10;
		if (dir == "down") acceleration.y += maxVelocity.x * 10;
	}
}
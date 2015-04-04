package game;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import game.GameState;

class Player extends FlxSprite
{
	public static var BASE_SPEED:Float = 150;
	public static var BULLET_SPEED:Float = 300;

	public var baseBulletTime:Float = .5;

	public var speedMod:Float = 1;
	public var shootCallback:Dynamic;

	private var _playerDef:PlayerDef;
	private var _bulletTime:Float = 0;
	private var _dirVector:FlxPoint = new FlxPoint();

	public function new(playerDef:PlayerDef)
	{
		super();

		_playerDef = playerDef;

		drag.set(maxVelocity.x * 8, maxVelocity.y * 8);

		makeGraphic(10, 10, 0xFF0000FF);
	}

	override public function update(elapsed:Float):Void
	{
		var left:Bool = false;
		var right:Bool = false;
		var up:Bool = false;
		var down:Bool = false;
		var shoot:Bool = false;

		{ // Update input
			{ // Keyboard input
				if (_playerDef.controllerNumber == -1)
				{
					if (FlxG.keys.pressed.LEFT) left = true;
					if (FlxG.keys.pressed.RIGHT) right = true;
					if (FlxG.keys.pressed.UP) up = true;
					if (FlxG.keys.pressed.DOWN) down = true;
					if (FlxG.keys.pressed.Z) shoot = true;
				}
			}
		}

		{ // Update movement
			maxVelocity.set(BASE_SPEED * speedMod, BASE_SPEED * speedMod);
			acceleration.set(0, 0);
			if (speedMod < 1) speedMod += .005;

			if (left) acceleration.x -= maxVelocity.x * 10;
			if (right) acceleration.x += maxVelocity.x * 10;
			if (up) acceleration.y -= maxVelocity.x * 10;
			if (down) acceleration.y += maxVelocity.x * 10;
		}

		{ // Update shooting
			_bulletTime -= elapsed;
			if (_bulletTime <= 0)
			{
				_bulletTime = baseBulletTime;
				if (up || down || left || right) _dirVector.set(0, 0);
				if (up) _dirVector.y = -1;
				if (down) _dirVector.y = 1;
				if (left) _dirVector.x = -1;
				if (right) _dirVector.x = 1;

				if (!(_dirVector.x == 0 && _dirVector.y == 0) && shoot)
				{
					var shootVector:FlxPoint = new FlxPoint();
					shootVector.copyFrom(_dirVector);
					shootVector.x *= BULLET_SPEED;
					shootVector.y *= BULLET_SPEED;

					shootCallback(getMidpoint(), shootVector);
				}
			}
		}

		super.update(elapsed);
	}

	override public function hurt(damage:Float):Void
	{
		speedMod /= 2.5;
		super.hurt(damage);
	}
}
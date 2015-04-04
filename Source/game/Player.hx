package game;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.particles.FlxParticle;
import flixel.effects.particles.FlxEmitter;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.XboxButtonID;
import flixel.math.FlxPoint;
import flixel.ui.FlxBar;
import flixel.text.FlxText;
import game.GameState;

class Player extends FlxSprite
{
	public static var BASE_SPEED:Float = 150;
	public static var BULLET_SPEED:Float = 500;
	public static var DEAD_ZONE:Float = .5;

	public var baseBulletTime:Float;
	public var baseBulletDamage:Float;

	public var mine:FlxSprite;
	public var emitter:FlxEmitter;

	public var adds:Array<Dynamic> = [];
	public var shootCallback:Dynamic;
	public var specialCallback:Dynamic;

	public var charges:Int;
	public var chargeTime:Float;
	public var baseChargeTime:Float;
	public var maxCharges:Float;

	private var _playerDef:PlayerDef;
	private var _healthBar:FlxBar;
	private var _chargeBar:FlxBar;
	private var _itemText:FlxText;

	private var _itemShowTime:Float;

	private var _bulletTime:Float = 0;
	private var _speedMod:Float = 1;
	private var _dirVector:FlxPoint = new FlxPoint(0, 1);

	public function new(playerDef:PlayerDef)
	{
		super();

		_playerDef = playerDef;

		drag.set(maxVelocity.x * 8, maxVelocity.y * 8);
		charges = 1; //TODO(jeru): Set to 0

		_healthBar = new FlxBar(0, 0, null, 20, 2, null, "", 0, 1);
		_healthBar.createFilledBar(0xFF147800, 0xFF2BFF00);
		adds.push(_healthBar);

		_chargeBar = new FlxBar(0, 0, null, 20, 2, null, "", 0, 1);
		_chargeBar.createFilledBar(0xFF02002E, 0xFF6666FF);
		adds.push(_chargeBar);

		_itemText = new FlxText(0, 0, 150, "99\nTHINGS", 16);
		_itemText.color = 0xFF000000;
		_itemText.alignment = "center";
		adds.push(_itemText);

		mine = new FlxSprite();
		mine.makeGraphic(5, 5, 0xFFFF8800);
		mine.visible = false;

		emitter = new FlxEmitter();
		emitter.lifespan.set(100, 100);
		emitter.drag.set(50, 50);

		_itemShowTime = 5;

		var colour:UInt = 0;

		// Medic
		if (_playerDef.characterNumber == 0)
		{
			colour = 0xFF0000FF;
			baseChargeTime = 10;
			maxCharges = 5;
			baseBulletTime = .4;
			baseBulletDamage = .2;
		}

		// Burst
		if (_playerDef.characterNumber == 1)
		{
			colour = 0xFFFF0000;
			baseChargeTime = 20;
			maxCharges = 3;
			baseBulletTime = .15;
			baseBulletDamage = .3;
		}

		// Demo
		if (_playerDef.characterNumber == 2)
		{
			colour = 0xFFFF00FF;
			baseChargeTime = 10;
			maxCharges = 10;
			baseBulletTime = .1;
			baseBulletDamage = .4;
		}

		// Bait
		if (_playerDef.characterNumber == 3)
		{
			colour = 0xFFFFFF00;
			baseChargeTime = 10;
			maxCharges = 10;
			baseBulletTime = .05;
			baseBulletDamage = .2;
		}

		chargeTime = baseChargeTime;
		makeGraphic(10, 10, colour);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var left:Bool = false;
		var right:Bool = false;
		var up:Bool = false;
		var down:Bool = false;
		var shoot:Bool = false;
		var special:Bool = false;

		{ // Update input
			{ // Keyboard
				if (_playerDef.controllerNumber == -1)
				{
					if (FlxG.keys.pressed.LEFT) left = true;
					if (FlxG.keys.pressed.RIGHT) right = true;
					if (FlxG.keys.pressed.UP) up = true;
					if (FlxG.keys.pressed.DOWN) down = true;
					if (FlxG.keys.pressed.Z) shoot = true;
					if (FlxG.keys.justPressed.X) special = true;
				}
			}

			{ // Gamepad
				if (_playerDef.controllerNumber >= 0)
				{
					var pad:FlxGamepad = FlxG.gamepads.getByID(_playerDef.controllerNumber);

					if (pad != null)
					{
						if (pad.getAxis(0) < -DEAD_ZONE) left = true;
						if (pad.getAxis(0) > DEAD_ZONE) right = true;
						if (pad.getAxis(1) < -DEAD_ZONE) up = true;
						if (pad.getAxis(1) > DEAD_ZONE) down = true;
						if (pad.pressed(XboxButtonID.A)) shoot = true;
						if (pad.justPressed(XboxButtonID.B)) special = true;
					}
				}
			}
		} 

		{ // Update movement
			maxVelocity.set(BASE_SPEED * _speedMod, BASE_SPEED * _speedMod);
			acceleration.set(0, 0);
			if (_speedMod < 1) _speedMod += .005;

			if (left) acceleration.x -= maxVelocity.x * 10;
			if (right) acceleration.x += maxVelocity.x * 10;
			if (up) acceleration.y -= maxVelocity.x * 10;
			if (down) acceleration.y += maxVelocity.x * 10;

			if (x < 0) x = 0;
			if (y < 0) y = 0;
			if (x > FlxG.width - width) x = FlxG.width - width;
			if (y > FlxG.height - height) y = FlxG.height - height;

			_bulletTime -= elapsed;
			if (up || down || left || right) _dirVector.set(0, 0);
			if (up) _dirVector.y = -1;
			if (down) _dirVector.y = 1;
			if (left) _dirVector.x = -1;
			if (right) _dirVector.x = 1;
		}

		{ // Update shooting
			if (_bulletTime <= 0 && shoot)
			{
				_bulletTime = baseBulletTime;

				var shootVector:FlxPoint = new FlxPoint();
				shootVector.copyFrom(_dirVector);
				shootVector.x *= BULLET_SPEED;
				shootVector.y *= BULLET_SPEED;

				shootCallback(getMidpoint(), shootVector, baseBulletDamage);
			}
		}

		{ // Update special use
			chargeTime -= elapsed;
			if (charges == maxCharges) chargeTime = baseChargeTime;

			if (chargeTime <= 0)
			{
				charges++;
				_itemShowTime = 2;
				chargeTime = baseChargeTime;
			}

			if (mine.visible && special) charges++;

			if (special && charges > 0)
			{
				charges--;
				_itemShowTime = 2;
				specialCallback(getMidpoint(), _dirVector, _playerDef.characterNumber, this);
			}
		}

		{ // Update ui
			_healthBar.x = x + width / 2 - _healthBar.width / 2;

			_healthBar.y = y + height + 4;
			_healthBar.value = health;

			_chargeBar.x = _healthBar.x;
			_chargeBar.y = _healthBar.y + 4;
			_chargeBar.value = 1 - chargeTime / baseChargeTime;

			if (_playerDef.characterNumber == 0) _itemText.text = "Medpacks:";
			if (_playerDef.characterNumber == 1) _itemText.text = "Explosions:";
			if (_playerDef.characterNumber == 2) _itemText.text = "Mines:";
			if (_playerDef.characterNumber == 3) _itemText.text = "Bait:";
			_itemText.text += "\n" + charges;
			_itemText.x = x + width / 2 - _itemText.width / 2;
			_itemText.y = y - 50;
			_itemText.visible = _itemShowTime > 0;
			_itemShowTime -= elapsed;
		}

		{ //Update misc specials
			var launchAngle:Float = 0;
			if (_dirVector.x == 1 && _dirVector.y == 0)		 launchAngle = 0;
			if (_dirVector.x == 1 && _dirVector.y == 1)		 launchAngle = 45;
			if (_dirVector.x == 0 && _dirVector.y == 1)		 launchAngle = 90;
			if (_dirVector.x == -1 && _dirVector.y == 1)	 launchAngle = 90 + 45;
			if (_dirVector.x == -1 && _dirVector.y == 0)	 launchAngle = 180;
			if (_dirVector.x == -1 && _dirVector.y == -1)	 launchAngle = 180 + 45;
			if (_dirVector.x == 0 && _dirVector.y == -1)	 launchAngle = 270;
			if (_dirVector.x == 0 && _dirVector.y == -1)	 launchAngle = 270 + 90;

			emitter.launchAngle.set(launchAngle - 45, launchAngle + 45);
			emitter.x = x;
			emitter.y = y;
		}
	}

	override public function hurt(damage:Float):Void
	{
		_speedMod /= 2.5;
		super.hurt(damage);
	}

	override public function kill():Void
	{
		for (item in adds) item.kill();
	}
}
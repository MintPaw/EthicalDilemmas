package game;

import flixel.FlxSprite;
import flixel.util.FlxPath;

class Zombie extends FlxSprite
{
	public static inline var TARGET_TIME:Float = .25;
	public static inline var ATTACK_TIME:Float = 1;
	public static inline var ATTACK_RANGE:Float = 10;
	public static inline var DAMAGE:Float = .02;

	public var targetTime:Float = 0;
	public var attackTime:Float = 0;
	public var currentTarget:FlxSprite;
	public var path:FlxPath = new FlxPath();

	public function new()
	{
		super();

		makeGraphic(10, 10, 0xFF00FF00);
	}

	override public function hurt(damage:Float):Void
	{
		path.cancel();
		super.hurt(damage);
	}
}
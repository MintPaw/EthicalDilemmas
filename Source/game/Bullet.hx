package game;

import flixel.FlxSprite;

class Bullet extends FlxSprite
{
	public var damage:Float;

	public function new()
	{
		super();

		makeGraphic(5, 5, 0xFF000000);
	}
}
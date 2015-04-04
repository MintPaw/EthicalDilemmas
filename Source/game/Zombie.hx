package game;

import flixel.FlxSprite;

class Zombie extends FlxSprite
{

	public var currentTarget:FlxSprite;

	public function new()
	{
		super();

		makeGraphic(10, 10, 0xFF00FF00);
	}
}
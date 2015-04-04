package;


import openfl.display.Sprite;
import flixel.FlxGame;

class Main extends Sprite
{	
	
	public function new()
	{	
		super();
		
		var flixel:FlxGame = new FlxGame(960, 512, MainState);
		addChild(flixel);
	}
}
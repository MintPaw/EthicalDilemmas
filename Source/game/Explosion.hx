package game;

import flixel.FlxSprite;

class Explosion extends FlxSprite
{
	private var _fadeTime:Float;
	private var _totalFadeTime:Float;

	public function new(smoke:Bool = false)
	{
		super();

		if (smoke)
		{
			makeGraphic(200, 200, 0xFFCCCCCC);
			_fadeTime = 10;
			_totalFadeTime = 20;
		} else {
			makeGraphic(200, 200, 0xFFCC3333);
			_fadeTime = 1;
			_totalFadeTime = 1;
		}
	}

	override public function update(elapsed:Float):Void
	{
		_fadeTime -= elapsed;

		alpha = _fadeTime / _totalFadeTime;

		if (_fadeTime < 0) kill();
	}
}
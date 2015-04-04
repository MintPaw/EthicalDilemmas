package game;

import flixel.FlxSprite;

class Explosion extends FlxSprite
{
	public var deadly:Bool;

	private var _fadeTime:Float;
	private var _totalFadeTime:Float;

	private var _deathTime:Float = .5;

	public function new(smoke:Bool = false)
	{
		super();

		if (smoke)
		{
			makeGraphic(200, 200, 0xFFCCCCCC);
			deadly = false;
			_fadeTime = 10;
			_totalFadeTime = 20;
		} else {
			makeGraphic(200, 200, 0xFFCC3333);
			deadly = true;
			_fadeTime = 1;
			_totalFadeTime = 1;
		}
	}

	override public function update(elapsed:Float):Void
	{
		_fadeTime -= elapsed;
		_deathTime -= elapsed;

		alpha = _fadeTime / _totalFadeTime;

		if (_fadeTime < 0) kill();
		if (_deathTime < 0) deadly = false;
	}
}
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
			loadGraphic("Assets/img/blackSmoke" + Math.round(Math.random() * 25) + ".png");
			scale.set(.75, .75);
			_fadeTime = 10;
			_totalFadeTime = 20;
		} else {
			loadGraphic("Assets/img/explosion" + Math.round(Math.random() * 9) + ".png");
			scale.set(.3, .3);
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
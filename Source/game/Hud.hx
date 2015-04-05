package game;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class Hud extends FlxSpriteGroup
{
	private var _texts:Array<FlxText>;

	public function new(players:Int)
	{
		super();

		_texts = [];

		for (i in 0...players)
		{
			var t:FlxText = new FlxText(0, 0, FlxG.width, "PLAYER NAME: XXXpt.", 8 * 1.5);
			t.y = (t.height + 3) * i;
			add(t);

			_texts.push(t);
		}
	}

	public function updateInfo(players:Array<Player>):Void
	{
		for (i in 0...players.length)
		{
			_texts[i].text = players[i].title + ": " + Math.round(players[i].score);
		}
	}

	public function enlage():Void
	{
		for (text in _texts)
		{
			FlxTween.tween(text.scale, { x: 3, y: 3 }, 1, { ease: FlxEase.elasticOut });
		}
	}

	public function shrink():Void
	{
		for (text in _texts)
		{
			FlxTween.tween(text.scale, { x: 1, y: 1 }, 1, { ease: FlxEase.elasticOut });
		}
	}
}
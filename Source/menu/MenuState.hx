package menu;

import flixel.FlxG;
import flixel.FlxState;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.XboxButtonID;
import flixel.text.FlxText;

class MenuState extends FlxState
{
	private var _playerSelects:Array<PlayerSelect>;

	private var _title:FlxText;
	private var _subtitle:FlxText;

	public function new()
	{
		super();
	}

	override public function create():Void
	{
		super.create();

		_title = new FlxText(0, 0, FlxG.width, "GAME", 8 * 4);
		_title.alignment = "center";
		_title.y = FlxG.height / 3;
		add(_title);

		_subtitle = new FlxText(0, 0, FlxG.width, "Press A or Space to join", 8 * 2);
		_subtitle.alignment = "center";
		_subtitle.y = _title.y + _title.height + 20;
		add(_subtitle);

		_playerSelects = [];
	}

	override public function update(elapsed:Float):Void
	{
		{ // Input
			if (FlxG.keys.justPressed.SPACE) addPlayer(-1);

			for (padNumber in 0...99)
			{
				var pad:FlxGamepad = FlxG.gamepads.getByID(padNumber);

				if (pad == null) continue;

				if (pad.justPressed(XboxButtonID.A)) addPlayer(padNumber);
			}
		}

		super.update(elapsed);
	}

	private function addPlayer(controller:Int):Void
	{
		for (selects in _playerSelects) if (selects.controllerNumber == controller) return;

		var p:PlayerSelect = new PlayerSelect(controller);
		add(p);
		_playerSelects.push(p);

		{ // Arrange
			for (i in 0..._playerSelects.length)
			{
				_playerSelects[i].x = (_playerSelects[i].width + 5) * i;
				_playerSelects[i].y = FlxG.height - _playerSelects[i].height - 5;
			}
		}
	}
}
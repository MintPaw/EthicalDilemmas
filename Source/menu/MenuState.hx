package menu;

import flixel.FlxG;
import flixel.FlxState;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.XboxButtonID;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import game.GameState;

class MenuState extends FlxState
{
	private var _playerSelects:Array<PlayerSelect>;

	private var _title:FlxText;
	private var _subtitle:FlxText;
	private var _infoText:FlxText;

	private var _countdown:Float = 6;
	private var _playerDefs:Array<PlayerDef> = [];
	private var _selectingMap:Bool = false;

	private var _oldStickPos:Float = 0;
	private var _mapSelection:Int = 1;

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

		_infoText = new FlxText(0, 0, FlxG.width, "", 8 * 2);
		_infoText.alignment = "center";
		_infoText.y = _subtitle.y + _subtitle.height + 20;
		add(_infoText);

		_playerSelects = [];
	}

	override public function update(elapsed:Float):Void
	{
		if (!_selectingMap)
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

			{ // Countdown
				var locks:Int = 0;
				var unlocked:Int = 0;
				for (select in _playerSelects)
				{
					if (select.selected) locks++ else unlocked++;
				}

				if (locks == 1) _infoText.text = "You need at least 2 players!";
				if (unlocked > 0) _countdown = 6;
				if (locks > 1 && _countdown == 6 && unlocked == 0) _countdown = 5;
				if (_countdown <= 5)
				{
					_countdown -= elapsed;
					_infoText.text = "Starting in " + Std.string(Math.round(_countdown * 10) / 10) + " seconds!";
				}

				if (_countdown <= 0)
				{
					_playerDefs = [];
					for (select in _playerSelects)
						_playerDefs.push({ controllerNumber: select.controllerNumber, characterNumber: select.selection });

					_subtitle.text = "<- Select Map ->";
					for (select in _playerSelects) select.kill();

					_selectingMap = true;
				}
			}
		} else {
			{ // Map select
				var left:Bool = false;
				var right:Bool = false;
				var select:Bool = false;

				if (_playerDefs[0].controllerNumber == -1)
				{
					if (FlxG.keys.justPressed.LEFT) left = true;
					if (FlxG.keys.justPressed.RIGHT) right = true;
					if (FlxG.keys.justPressed.SPACE) select = true;
				} else {
					var pad:FlxGamepad = FlxG.gamepads.getByID(_playerDefs[0].controllerNumber);
					if (pad != null)
					{
						if (pad.getAxis(0) < -.5 && _oldStickPos > -.5) left = true;
						if (pad.getAxis(0) > .5 && _oldStickPos < .5) right = true;
						if (pad.justPressed(XboxButtonID.A)) select = true;

						_oldStickPos = pad.getAxis(0);
					}
				}

				if (left) _mapSelection = 1;
				if (right) _mapSelection = 2;
				if (select) FlxG.switchState(new GameState(_playerDefs, "map" + _mapSelection, 3));

				if (_mapSelection == 1) _infoText.text = "Church" else _infoText.text = "Maze";
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
package menu;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.XboxButtonID;
import flixel.text.FlxText;

class PlayerSelect extends FlxSpriteGroup
{
	public static inline var DEAD_ZONE:Float = 0.5;

	public static var CLASSES:Array<String> =
		[
			"Medic",
			"Mr. Combustion",
			"C4",
			"Decoy"
		];

	public var controllerNumber:Int;
	public var selection:Int = 0;
	public var selected:Bool = false;

	private var _texts:Array<FlxText> = [];
	private var _oldStickPos:Float = 0;
	private var _frames:Int = 0;

	public function new(controllerNumber:Int)
	{
		super();

		for (classNumber in 0...CLASSES.length)
		{
			var t:FlxText = new FlxText(0, 0, 200, CLASSES[classNumber], 8 * 2);
			t.alignment = "center";
			t.y = (t.height + 10) * classNumber;
			add(t);
			_texts.push(t);
		}

		this.controllerNumber = controllerNumber;
	}

	override public function update(elapsed:Float):Void
	{
		_frames++;

		for (text in _texts) text.color = 0xFF555555;
		_texts[selection].color = 0xFFFFFFFF;

		if (!selected && _frames >= 2)
		{
			if (controllerNumber == -1)
			{
				if (FlxG.keys.justPressed.UP && selection > 0) selection--;
				if (FlxG.keys.justPressed.DOWN && selection < _texts.length - 1) selection++;
				if ((FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.Z) && selection < _texts.length) select();
			} else {
				var pad:FlxGamepad = FlxG.gamepads.getByID(controllerNumber);
				if (pad == null) return;

				if (pad.getAxis(1) < -DEAD_ZONE && _oldStickPos > -DEAD_ZONE && selection > 0) selection--;
				if (pad.getAxis(1) > DEAD_ZONE && _oldStickPos < DEAD_ZONE && selection < _texts.length - 1) selection++;
				if (pad.justPressed(XboxButtonID.A)) select();

				_oldStickPos = pad.getAxis(1);
			}
		}

		super.update(elapsed);
	}

	private function select():Void
	{
		for (i in 0..._texts.length) if (i != selection) _texts[i].kill();
		selected = true;
	}
}

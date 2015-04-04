package game;

import openfl.Assets;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.tile.FlxTilemap;

class GameState extends FlxState
{
	public static inline var TILE_WIDTH:Int = 32;
	public static inline var TILE_HEIGHT:Int = 32;

	private var _players:Array<Player>;
	private var _playerDefs:Array<PlayerDef>;
	private var _tilemaps:Array<FlxTilemap>;

	private var _mapName:String;

	public function new(playerDefs:Array<PlayerDef>, mapName:String)
	{
		super();

		_playerDefs = playerDefs;
		_mapName = mapName;
	}

	override public function create():Void
	{
		{ // Create Tilemap
			_tilemaps = [];

			var all:String = Assets.getText("Assets/map/" + _mapName + ".tmx");

			var bot:String = all.split("<data encoding=\"csv\">")[1];
			bot = bot.split("</data>")[0];

			var mid:String = all.split("<data encoding=\"csv\">")[2];
			mid = mid.split("</data>")[0];

			var top:String = all.split("<data encoding=\"csv\">")[3];
			top = top.split("</data>")[0];

			_tilemaps.push(new FlxTilemap());
			_tilemaps.push(new FlxTilemap());
			_tilemaps.push(new FlxTilemap());

			_tilemaps[0].loadMapFromCSV(bot, Assets.getBitmapData("Assets/img/tilemap.png"), 32, 32, null, 1);
			_tilemaps[1].loadMapFromCSV(mid, Assets.getBitmapData("Assets/img/tilemap.png"), 32, 32, null, 1);
			_tilemaps[2].loadMapFromCSV(top, Assets.getBitmapData("Assets/img/tilemap.png"), 32, 32, null, 1);

			for (i in 0...3) add(_tilemaps[i]);
		}

		{ // Create players
			_players = [];

			for (i in 0..._playerDefs.length)
			{
				var p:Player = new Player();
				//p.x = _tilemap.widthInTiles / 2 - 2 + i;
				//p.y =
			}
		}
	}
}


typedef PlayerDef = 
{
	playerNumber:Int,
	controllerNumber:Int,
	characterNumber:Int
}
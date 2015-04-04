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
	private var _tilemap:FlxTilemap;

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
			var tilemapString:String = Assets.getText("Assets/map/" + _mapName + ".tmx");
			tilemapString = tilemapString.split("<data encoding=\"csv\">")[1];
			tilemapString = tilemapString.split("</data>")[0];
			trace(tilemapString);

			_tilemap = new FlxTilemap();
			_tilemap.loadMapFromCSV(tilemapString, Assets.getBitmapData("Assets/img/tilemap.png"), 32, 32, null, 1);
			add(_tilemap);
		}

		{ // Create players
			_players = [];

			for (i in _playerDefs)
			{
				var p:Player = new Player();
				//p.x = 
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
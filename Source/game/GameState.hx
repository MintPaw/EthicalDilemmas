package game;

import openfl.Assets;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.tile.FlxTilemap;

class GameState extends FlxState
{
	public static inline var TILE_WIDTH:Int = 32;
	public static inline var TILE_HEIGHT:Int = 32;
	public static inline var ZOMBIE_TIMER:Int = 5;

	private var _rnd:FlxRandom = new FlxRandom();

	private var _tilemaps:Array<FlxTilemap>;
	private var _collisionMap:FlxTilemap;

	private var _playerDefs:Array<PlayerDef>;
	private var _mapName:String;

	private var _zombieSpawns:Array<FlxPoint>;
	private var _zombieSpawnTimer:Float;

	private var _playerGroup:FlxTypedSpriteGroup<Player>;
	private var _zombieGroup:FlxTypedSpriteGroup<Zombie>;

	public function new(playerDefs:Array<PlayerDef>, mapName:String)
	{
		super();

		_playerDefs = playerDefs;
		_mapName = mapName;
	}

	override public function create():Void
	{
		{ // Create misc vars
			_zombieGroup = new FlxTypedSpriteGroup<Zombie>();
			_zombieSpawnTimer = 0;
		}

		{ // Create tilemap
			_tilemaps = [];

			var all:String = Assets.getText("Assets/map/" + _mapName + ".tmx");

			var bot:String = all.split("<data encoding=\"csv\">")[1];
			bot = bot.split("</data>")[0];

			var mid:String = all.split("<data encoding=\"csv\">")[2];
			mid = mid.split("</data>")[0];

			var top:String = all.split("<data encoding=\"csv\">")[3];
			top = top.split("</data>")[0];

			var super_top:String = all.split("<data encoding=\"csv\">")[4];
			super_top = super_top.split("</data>")[0];

			_collisionMap = new FlxTilemap();
			_collisionMap.visible = false;

			for (i in 0...4) _tilemaps.push(new FlxTilemap());
			
			_collisionMap.loadMapFromCSV(top, Assets.getBitmapData("Assets/img/tilemap.png"), 32, 32, null, 1);

			_tilemaps[0].loadMapFromCSV(bot, Assets.getBitmapData("Assets/img/tilemap.png"), 32, 32, null, 1);
			_tilemaps[1].loadMapFromCSV(mid, Assets.getBitmapData("Assets/img/tilemap.png"), 32, 32, null, 1);
			_tilemaps[2].loadMapFromCSV(top, Assets.getBitmapData("Assets/img/tilemap.png"), 32, 32, null, 1);
			_tilemaps[3].loadMapFromCSV(super_top, Assets.getBitmapData("Assets/img/tilemap.png"), 32, 32, null, 1);

			for (tilemapNumber in 1...3)
			{
				var mapData:Array<Int> = _tilemaps[tilemapNumber].getData(true);
				for (tileNumber in 0...mapData.length)
				{
					if (mapData[tileNumber] == 1) _collisionMap.setTileByIndex(tileNumber, mapData[tileNumber]);
				}
			}
		}

		{ // Create players
			_playerGroup = new FlxTypedSpriteGroup<Player>();

			for (i in 0..._playerDefs.length)
			{
				var p:Player = new Player(_playerDefs[i]);
				p.x = (_tilemaps[0].widthInTiles / 2 - 4 + i) * TILE_WIDTH;
				p.y = _tilemaps[0].heightInTiles / 2 * TILE_HEIGHT;
				_playerGroup.add(p);
			}
		}

		{ // Create zombie spawns
			_zombieSpawns = [];
			_zombieSpawns.push(new FlxPoint(1, 1));
			_zombieSpawns.push(new FlxPoint(1, _tilemaps[0].heightInTiles - 2));
			_zombieSpawns.push(new FlxPoint(_tilemaps[0].widthInTiles - 2, 1));
			_zombieSpawns.push(new FlxPoint(_tilemaps[0].widthInTiles - 2, _tilemaps[0].heightInTiles - 2));
		}

		{ // Add groups
			add(_tilemaps[0]);
			add(_tilemaps[1]);
			add(_tilemaps[2]);
			add(_playerGroup);
			add(_zombieGroup);
			add(_tilemaps[3]);
			add(_collisionMap);
		}

	}

	override public function update(elapsed:Float):Void
	{
		{ // Update collision
			FlxG.collide(_collisionMap, _playerGroup);
		}

		{ // Update zombies
			{ // Spawning
				_zombieSpawnTimer -= elapsed;
				if (_zombieSpawnTimer <= 0)
				{
					_zombieSpawnTimer = ZOMBIE_TIMER;

					var spawnPoint:FlxPoint = new FlxPoint();
					_rnd.getObject(_zombieSpawns).copyTo(spawnPoint);

					spawnPoint.x = spawnPoint.x * TILE_WIDTH + _rnd.float(-20, 20);
					spawnPoint.y = spawnPoint.y * TILE_WIDTH + _rnd.float(-20, 20);

					var z:Zombie = new Zombie();
					z.currentTarget = _playerGroup.members[0];
					z.x = spawnPoint.x;
					z.y = spawnPoint.y;
					_zombieGroup.add(z);
				}
			}

			{ // Retargeting
				for (zombie in _zombieGroup.members)
				{
					zombie.targetTime -= elapsed;
					if (zombie.targetTime <= 0)
					{
						zombie.targetTime = Zombie.TARGET_TIME;

						for (player in _playerGroup.members)
						{
							if (FlxMath.distanceBetween(zombie, player) < FlxMath.distanceBetween(zombie, zombie.currentTarget)) zombie.currentTarget = player;
						}

						zombie.path.cancel();
						zombie.path.start(zombie, _collisionMap.findPath(zombie.getMidpoint(), zombie.currentTarget.getMidpoint()), 100);
					}
				}
			}
		}

		super.update(elapsed);
	}
}


typedef PlayerDef = 
{
	playerNumber:Int,
	controllerNumber:Int,
	characterNumber:Int
}
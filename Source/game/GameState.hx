package game;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import menu.MenuState;
import openfl.Assets;

class GameState extends FlxState
{
	public static inline var TILE_WIDTH:Int = 32;
	public static inline var TILE_HEIGHT:Int = 32;
	public static inline var ZOMBIE_TIMER:Int = 5;

	public static var save:Map<String, Dynamic>;

	private var _currentRound:Int;
	private var _totalRounds:Int;
	private var _diff:Float;

	private var _rnd:FlxRandom = new FlxRandom();

	private var _tilemaps:Array<FlxTilemap>;
	private var _collisionMap:FlxTilemap;
	private var _collisionMapDefs:Array<Array<Int>>;

	private var _playerDefs:Array<PlayerDef>;
	private var _mapName:String;
	private var _restarting:Bool;

	private var _zombieSpawns:Array<FlxPoint>;
	private var _zombieSpawnTimer:Float;

	private var _playerGroup:FlxTypedSpriteGroup<Player>;
	private var _zombieGroup:FlxTypedSpriteGroup<Zombie>;
	private var _bulletGroup:FlxTypedSpriteGroup<Bullet>;
	private var _medpackGroup:FlxTypedSpriteGroup<FlxSprite>;
	private var _baitGroup:FlxTypedSpriteGroup<FlxSprite>;
	private var _explosionGroup:FlxTypedSpriteGroup<Explosion>;
	private var _overlayGroup:FlxGroup;

	private var _hud:Hud;

	public function new(playerDefs:Array<PlayerDef>, mapName:String, totalRounds:Int, currentRound:Int = 0)
	{
		super();

		_playerDefs = playerDefs;
		_mapName = mapName;
		_totalRounds = totalRounds;
		_currentRound = currentRound;
	}

	override public function create():Void
	{
		{ // Create misc
			_zombieGroup = new FlxTypedSpriteGroup<Zombie>();
			_bulletGroup = new FlxTypedSpriteGroup<Bullet>();
			_explosionGroup = new FlxTypedSpriteGroup<Explosion>();
			_medpackGroup = new FlxTypedSpriteGroup<FlxSprite>();
			_baitGroup = new FlxTypedSpriteGroup<FlxSprite>();
			_overlayGroup = new FlxGroup();
			_zombieSpawnTimer = 0;
			_currentRound = 0;
			_restarting = false;
			_diff = 1;

			_hud = new Hud(_playerDefs.length);
			_overlayGroup.add(_hud);

			_collisionMapDefs = [];
			for (i in 0...1000) _collisionMapDefs.push([1, 1, 1, 1]);

			_collisionMapDefs[109] = [1, 0, 1, 0];
			_collisionMapDefs[108] = [0, 1, 0, 1];
			_collisionMapDefs[117] = [1, 0, 1, 0];
			_collisionMapDefs[118] = [0, 1, 0, 1];
			_collisionMapDefs[114] = [0, 0, 0, 0];
			_collisionMapDefs[115] = [0, 0, 0, 0];
			_collisionMapDefs[116] = [0, 0, 0, 0];
			_collisionMapDefs[105] = [0, 0, 0, 0];
			_collisionMapDefs[106] = [0, 0, 0, 0];
			_collisionMapDefs[107] = [0, 0, 0, 0];
			_collisionMapDefs[77] = [0, 0, 0, 0];
			_collisionMapDefs[78] = [0, 0, 0, 0];
			_collisionMapDefs[68] = [0, 0, 0, 0];
			_collisionMapDefs[69] = [0, 0, 0, 0];
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

			for (i in 0...4) _tilemaps.push(new FlxTilemap());

			_tilemaps[0].loadMapFromCSV(bot, Assets.getBitmapData("Assets/img/tilemap.png"), TILE_WIDTH, TILE_HEIGHT, null, 1);
			_tilemaps[1].loadMapFromCSV(mid, Assets.getBitmapData("Assets/img/tilemap.png"), TILE_WIDTH, TILE_HEIGHT, null, 1);
			_tilemaps[2].loadMapFromCSV(top, Assets.getBitmapData("Assets/img/tilemap.png"), TILE_WIDTH, TILE_HEIGHT, null, 1);
			_tilemaps[3].loadMapFromCSV(super_top, Assets.getBitmapData("Assets/img/tilemap.png"), TILE_WIDTH, TILE_HEIGHT, null, 1);

			{ // Collision map
				_collisionMap = new FlxTilemap();
				_collisionMap.visible = false;

				buildCollisionMap();
			}
		}

		{ // Create players
			_playerGroup = new FlxTypedSpriteGroup<Player>();

			for (i in 0..._playerDefs.length)
			{
				var p:Player = new Player(_playerDefs[i]);
				p.x = (_tilemaps[0].widthInTiles / 2 - 4 + i) * TILE_WIDTH;
				p.y = _tilemaps[0].heightInTiles / 2 * TILE_HEIGHT;
				for (obj in p.adds) _overlayGroup.add(obj);

				p.shootCallback = shoot;
				p.specialCallback = special;
				_playerGroup.add(p);
			}
		}

		{ // Setup zombie spawns
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
			add(_medpackGroup);
			add(_bulletGroup);
			add(_baitGroup);
			add(_explosionGroup);

			add(_tilemaps[3]);
			add(_collisionMap);
			add(_overlayGroup);
		}

		{ // Load save
			if (save != null)
			{
				FlxG.camera.fade(0xFFFFFFFF, .5, true, null, false);
				for (i in 0...save.get("scores").length) _playerGroup.members[i].score = save.get("scores")[i];
				for (i in 0...save.get("charges").length) _playerGroup.members[i].charges = save.get("charges")[i];
				for (i in 0...save.get("chargeTimes").length) _playerGroup.members[i].chargeTime = save.get("chargeTimes")[i];
				for (i in 0...save.get("tilemaps").length)
				{
					_tilemaps[i].reset(0, 0);
					_tilemaps[i].loadMapFromArray(save.get("tilemaps")[i], 30, 16, Assets.getBitmapData("Assets/img/tilemap.png"), TILE_WIDTH, TILE_HEIGHT, null, 1);
				}
			} else {
				FlxG.camera.fade(0xFF000000, .5, true, null, false);
			}
		}

	}

	override public function update(elapsed:Float):Void
	{
		{ // Update collision
			FlxG.collide(_playerGroup, _collisionMap);
			FlxG.collide(_medpackGroup, _collisionMap);

			FlxG.collide(_collisionMap, mapVBullet);
			FlxG.overlap(_zombieGroup, _bulletGroup, zombieVBullet);

			FlxG.overlap(_playerGroup, _medpackGroup, playerVMedpack);

			FlxG.overlap(_explosionGroup, _zombieGroup, explotsionVZombie);
			FlxG.overlap(_baitGroup, _zombieGroup, baitVZombie);

			for (player in _playerGroup.members) FlxG.collide(player.mine, _collisionMap);
		}

		{ // Update zombies
			{ // Spawning
				_zombieSpawnTimer -= elapsed;
				if (_zombieSpawnTimer <= 0)
				{
					_zombieSpawnTimer = ZOMBIE_TIMER * (1 / _diff);

					var spawnPoint:FlxPoint = new FlxPoint();
					_rnd.getObject(_zombieSpawns).copyTo(spawnPoint);

					spawnPoint.x = spawnPoint.x * TILE_WIDTH + _rnd.float(-20, 20);
					spawnPoint.y = spawnPoint.y * TILE_WIDTH + _rnd.float(-20, 20);

					var z:Zombie = new Zombie();
					z.currentTarget = _playerGroup.members[0];
					z.health *= _diff;
					z.x = spawnPoint.x;
					z.y = spawnPoint.y;
					_zombieGroup.add(z);
				}
			}

			for (zombie in _zombieGroup.members)
			{
				if (zombie.health < 0) continue;

				{ // Retargeting
					zombie.targetTime -= elapsed;
					if (zombie.targetTime <= 0)
					{
						zombie.targetTime = Zombie.TARGET_TIME;
						zombie.currentTarget = null;

						var targets:Array<FlxSprite> = [];

						for (player in _playerGroup.members)
						{
							if (player.health > 0) targets.push(cast(player, FlxSprite));
							for (bait in _baitGroup.members)
							{
								if (bait.health > 0) targets.push(cast(bait, FlxSprite));
							}
						}

						if (targets.length > 0) zombie.currentTarget = targets[0];
						for (target in targets)
						{
							if (FlxMath.distanceBetween(zombie, target) < FlxMath.distanceBetween(zombie, zombie.currentTarget)) zombie.currentTarget = target;
						}

						zombie.path.cancel();
						if (zombie.currentTarget != null)
						{
							zombie.path.start(zombie, _collisionMap.findPath(zombie.getMidpoint(), zombie.currentTarget.getMidpoint()), 50);
						}
					}
				}

				{ // Attacking
					zombie.attackTime -= elapsed;
					if (zombie.attackTime <= 0)
					{
						if (zombie.currentTarget != null && FlxMath.distanceBetween(zombie, zombie.currentTarget) <= Zombie.ATTACK_RANGE)
						{
							zombie.attackTime = Zombie.ATTACK_TIME;
							zombie.currentTarget.hurt(Zombie.DAMAGE);
						}
					}
				}
			}
		}

		{ // Update player
			for (player in _playerGroup.members)
			{
				if (_restarting) break;
				if (player.health > 0) player.score += elapsed / (_playerGroup.countLiving() / _playerGroup.members.length);
			}

			if (_playerGroup.countLiving() == 1) showScores();
		}

		{ // Update misc
			_hud.updateInfo(_playerGroup.members);
			_diff += (.00001 * _playerGroup.countLiving() + 1) - 1;
			trace(_diff);
		}

		super.update(elapsed);
	}

	public function shoot(loc:FlxPoint, dir:FlxPoint, damage:Float):Void
	{
		var b:Bullet = new Bullet();
		b.damage = damage;
		b.x = loc.x - b.width / 2;
		b.y = loc.y - b.height / 2;
		b.velocity.set(dir.x, dir.y);
		_bulletGroup.add(b);
	}

	public function special(loc:FlxPoint, dir:FlxPoint, type:Float, player:Player):Void
	{
		// Medic
		if (type == 0)
		{
			var throwVector:FlxPoint = new FlxPoint();
			throwVector.copyFrom(dir);
			throwVector.x *= 500;
			throwVector.y *= 500;

			var medpack:FlxSprite = new FlxSprite();
			medpack.makeGraphic(20, 20, 0xFFFFFFFF);
			medpack.x = loc.x - medpack.width / 2 + dir.x * 30;
			medpack.y = loc.y - medpack.height / 2 + dir.y * 30;
			medpack.velocity.set(throwVector.x, throwVector.y);
			medpack.drag.set(1500, 1500);
			medpack.elasticity = 0.8;
			_medpackGroup.add(medpack);
		}

		// Burst
		if (type == 1)
		{
			createExplosion(loc.x, loc.y);
		}

		// Demo
		if (type == 2)
		{
			if (!player.mine.visible)
			{
				player.mine.visible = true;

				var throwVector:FlxPoint = new FlxPoint();
				throwVector.copyFrom(dir);
				throwVector.x *= 800;
				throwVector.y *= 800;

				player.mine.velocity.set(throwVector.x, throwVector.y);
				player.mine.drag.set(2400, 2400);
				player.mine.x = loc.x;
				player.mine.y = loc.y;
				add(player.mine);
			} else {
				player.mine.visible = false;
				createExplosion(player.mine.x, player.mine.y, .25, true);
			}
		}

		// Bait
		if (type == 3)
		{
			var throwVector:FlxPoint = new FlxPoint();
			throwVector.copyFrom(dir);
			throwVector.x *= 500;
			throwVector.y *= 500;

			var bait:FlxSprite = new FlxSprite();
			bait.makeGraphic(3, 3, 0xFFCC5500);
			bait.x = loc.x - bait.width / 2;
			bait.y = loc.y - bait.height / 2;
			bait.velocity.set(throwVector.x, throwVector.y);
			bait.drag.set(1500, 1500);
			bait.elasticity = 0.8;
			_baitGroup.add(bait);

		}
	}

	private function createExplosion(xpos:Float, ypos:Float, ratio:Float = 1, destoryTerrain:Bool = false):Void
	{
		var explosion:Explosion = new Explosion();
		explosion.scale.set(ratio, ratio);
		explosion.width *= ratio;
		explosion.height *= ratio;
		explosion.x = xpos - explosion.width / 2;
		explosion.y = ypos - explosion.height / 2;
		explosion.centerOffsets(false);
		_explosionGroup.add(explosion);

		for (i in 0..._rnd.int(3, 5))
		{
			var smoke:Explosion = new Explosion(true);
			smoke.x = xpos - smoke.width / 2 + _rnd.float(-20, 20);
			smoke.y = ypos - smoke.height / 2 + _rnd.float(-20, 20);
			smoke.scale.set(ratio, ratio);
			add(smoke);
		}

		if (destoryTerrain)
		{
			var centreTileX:Int = Std.int(xpos / TILE_WIDTH);
			var centreTileY:Int = Std.int(ypos / TILE_HEIGHT);
			var points:Array<FlxPoint> = [];

			points.push(new FlxPoint(centreTileX, centreTileY));
			points.push(new FlxPoint(centreTileX + 1, centreTileY));
			points.push(new FlxPoint(centreTileX - 1, centreTileY));
			points.push(new FlxPoint(centreTileX, centreTileY + 1));
			points.push(new FlxPoint(centreTileX, centreTileY - 1));
			points.push(new FlxPoint(centreTileX - 1, centreTileY - 1));
			points.push(new FlxPoint(centreTileX + 1, centreTileY + 1));
			points.push(new FlxPoint(centreTileX + 1, centreTileY - 1));
			points.push(new FlxPoint(centreTileX - 1, centreTileY + 1));

			for (tile in points)
			{
				if (
					tile.x >= 0 &&
					tile.y >= 0 &&
					tile.x <= _tilemaps[1].widthInTiles - 1 &&
					tile.y <= _tilemaps[1].heightInTiles - 1)
						_tilemaps[1].setTile(Std.int(tile.x), Std.int(tile.y), 0);
			}

			buildCollisionMap();
		}
	}

	private function buildCollisionMap():Void
	{
		var collisionString:String = "";

		for (tileY in 0...Std.int(FlxG.height / TILE_HEIGHT * 2))
		{
			for (tileX in 0...Std.int(FlxG.width / TILE_WIDTH * 2)) collisionString += "0,";
			collisionString = collisionString.substr(0, collisionString.length - 1);
			collisionString += "\n";
		}

		collisionString = collisionString.substr(0, collisionString.length - 1);
		_collisionMap.loadMapFromCSV(collisionString, Assets.getBitmapData("Assets/img/tilemap.png"), Std.int(TILE_WIDTH / 2), Std.int(TILE_HEIGHT / 2), null, 1);

		for (tilemapNumber in 1...3)
		{
			for (tileX in 0..._tilemaps[tilemapNumber].widthInTiles)
			{
				for (tileY in 0..._tilemaps[tilemapNumber].heightInTiles)

				if (_tilemaps[tilemapNumber].getTile(tileX, tileY) != 0)
				{
					if (_collisionMapDefs[_tilemaps[tilemapNumber].getTile(tileX, tileY)][0] == 1) _collisionMap.setTile(tileX * 2, tileY * 2, 1);
					if (_collisionMapDefs[_tilemaps[tilemapNumber].getTile(tileX, tileY)][1] == 1) _collisionMap.setTile(tileX * 2 + 1, tileY * 2, 1);
					if (_collisionMapDefs[_tilemaps[tilemapNumber].getTile(tileX, tileY)][2] == 1) _collisionMap.setTile(tileX * 2, tileY * 2 + 1, 1);
					if (_collisionMapDefs[_tilemaps[tilemapNumber].getTile(tileX, tileY)][3] == 1) _collisionMap.setTile(tileX * 2 + 1, tileY * 2 + 1, 1);
				}
			}
		}
	}

	private function showScores():Void
	{
		if (_restarting) return;
		_restarting = true;

		if (_currentRound == _totalRounds)
		{
			new FlxTimer().start(5, function f(t:FlxTimer) { FlxG.camera.fade(0xFF000000, 2, false); });
			new FlxTimer().start(8, function f(t:FlxTimer) { FlxG.switchState(new MenuState()); });
			_hud.enlage();
			return;
		}

		new FlxTimer().start(5, function f(t:FlxTimer) { _hud.shrink(); } );
		new FlxTimer().start(5.5, function f(t:FlxTimer) { FlxG.camera.fade(0xFFFFFFFF, .5); });
		new FlxTimer().start(6, restartRound);
	}

	private function restartRound(t:FlxTimer = null):Void
	{
		_currentRound++;

		save = new Map();

		save.set("scores", []);
		save.set("charges", []);
		save.set("chargeTimes", []);
		save.set("tilemaps", []);

		for (player in _playerGroup.members)
		{
			save.get("scores").push(player.score);
			save.get("charges").push(player.charges);
			save.get("chargeTimes").push(player.chargeTime);
		}

		for (tilemap in _tilemaps) save.get("tilemaps").push(tilemap.getData());

		FlxG.switchState(new GameState(_playerDefs, _mapName, _totalRounds, _currentRound));
	}

	private function zombieVBullet(zombie:FlxBasic, bullet:FlxBasic):Void
	{
		cast(zombie, Zombie).hurt(cast(bullet).damage);
		bullet.kill();
	}

	private function mapVBullet(map:FlxBasic, bullet:FlxBasic):Void
	{
		bullet.kill();
	}

	private function playerVMedpack(player:FlxBasic, medpack:FlxBasic):Void
	{
		medpack.kill();
		cast(player, Player).health = 1;
	}

	private function explotsionVZombie(explosion:FlxBasic, zombie:FlxBasic):Void
	{
		FlxG.log.add("hit " + _rnd.int(0, 1));
		zombie.kill();
	}

	private function baitVZombie(bait:FlxBasic, zombie:FlxBasic):Void
	{
		cast(bait, FlxSprite).health = 0;
		bait.kill();
	}
}


typedef PlayerDef = 
{
	controllerNumber:Int,
	characterNumber:Int
}
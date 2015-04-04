package game;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.effects.particles.FlxParticle;
import flixel.effects.particles.FlxEmitter;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.tile.FlxTilemap;
import openfl.Assets;

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
	private var _bulletGroup:FlxTypedSpriteGroup<Bullet>;
	private var _medpackGroup:FlxTypedSpriteGroup<FlxSprite>;
	private var _explosionGroup:FlxTypedSpriteGroup<Explosion>;
	private var _overlayGroup:FlxGroup;

	private var _baitEmitter:FlxEmitter;

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
			_bulletGroup = new FlxTypedSpriteGroup<Bullet>();
			_medpackGroup = new FlxTypedSpriteGroup<FlxSprite>();
			_explosionGroup = new FlxTypedSpriteGroup<Explosion>();
			_overlayGroup = new FlxGroup();
			_zombieSpawnTimer = 0;

			_baitEmitter = new FlxEmitter(0, 0, 10);
			_baitEmitter.speed.set(50, 100);
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
				for (obj in p.adds) _overlayGroup.add(obj);

				p.shootCallback = shoot;
				p.specialCallback = special;
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
			add(_medpackGroup);
			add(_bulletGroup);
			for (p in _playerGroup.members) add(p.emitter);
			add(_explosionGroup);

			add(_tilemaps[3]);
			add(_collisionMap);
			add(_overlayGroup);
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

			FlxG.overlap(_zombieGroup, _explosionGroup, zombieVExplosion);
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

			for (zombie in _zombieGroup.members)
			{
				{ // Retargeting
					zombie.targetTime -= elapsed;
					if (zombie.targetTime <= 0)
					{
						zombie.targetTime = Zombie.TARGET_TIME;
						zombie.currentTarget = null;

						/*for (player in _playerGroup.members)
						{
							for (part in player.emitter)
							{
								if (part.health <= 0) continue;
								if (FlxMath.distanceBetween(zombie, part) < FlxMath.distanceBetween(zombie, zombie.currentTarget)) zombie.currentTarget = part;
							}

							if (player.health <= 0) continue;
							if (FlxMath.distanceBetween(zombie, player) < FlxMath.distanceBetween(zombie, zombie.currentTarget)) zombie.currentTarget = player;
						}

						zombie.path.cancel();
						if (zombie.currentTarget != null && FlxMath.distanceBetween(zombie, zombie.currentTarget) > Zombie.ATTACK_RANGE)
							zombie.path.start(zombie, _collisionMap.findPath(zombie.getMidpoint(), zombie.currentTarget.getMidpoint()), 50);
					}

					if (zombie.currentTarget != null && zombie.currentTarget.health <= 0) zombie.currentTarget = null;*/

						var targets:Array<FlxSprite> = [];

						for (player in _playerGroup.members)
						{
							if (player.health > 0) targets.push(cast(player, FlxSprite));
							for (part in player.emitter) if (part.health > 0) targets.push(cast(part, FlxSprite));
						}

						if (targets.length > 0) zombie.currentTarget = targets[0];
						for (target in targets)
						{
							if (FlxMath.distanceBetween(zombie, target) < FlxMath.distanceBetween(zombie, zombie.currentTarget)) zombie.currentTarget = target;
						}

						zombie.path.cancel();
						if (zombie.currentTarget != null && FlxMath.distanceBetween(zombie, zombie.currentTarget) > Zombie.ATTACK_RANGE)
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

			}
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
				createExplosion(player.mine.x, player.mine.y, .25);
			}
		}

		// Bait
		if (type == 3)
		{
			for (i in 0...10)
			{
				var part:FlxParticle = new FlxParticle();
				part.makeGraphic(2, 2, 0xFFCC5500);
				part.visible = false;
				part.health = 0.0001;
				player.emitter.add(part);
			}

			player.emitter.start(false, 0.1, 10);
		}
	}

	private function createExplosion(xpos:Float, ypos:Float, ratio:Float = 1):Void
	{
		var explosion:Explosion = new Explosion();
		explosion.scale.set(ratio, ratio);
		explosion.x = xpos - explosion.width / 2;
		explosion.y = ypos - explosion.height / 2;
		_explosionGroup.add(explosion);

		for (i in 0..._rnd.int(3, 5))
		{
			var smoke:Explosion = new Explosion(true);
			smoke.scale.set(ratio, ratio);
			smoke.x = explosion.x + _rnd.float(-20, 20);
			smoke.y = explosion.y + _rnd.float(-20, 20);
			smoke.deadly = false;
			_explosionGroup.add(smoke);
		}
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

	private function zombieVExplosion(zombie:FlxBasic, explosion:FlxBasic):Void
	{
		if (cast(explosion, Explosion).deadly) zombie.kill();
	}
}


typedef PlayerDef = 
{
	controllerNumber:Int,
	characterNumber:Int
}
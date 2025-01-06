SuperStrict
Import "game.entities.bmx"


Type TGameWorld Extends TGameEntity
	'elements in the world background
	Field backgroundEntities:TObjectList = New TObjectList
	'elements in the world foreground (over eg space ships)
	Field foregroundEntities:TObjectList = New TObjectList
	
	Field groundHeight:Int = 30

	Field score:Int
	Field player:TPlayerEntity
	Field mothershipDropWall:TMothershipDropWallEntity
	Field mothership:TMothershipEntity
	Field mothershipSmartBomb:TGameEntity
	Field mothershipDrops:TObjectList = New TObjectList
	Field bullets:TObjectList = New TObjectList
	'allows to simply iterate over all elements on the screen
	'do differently if you need to update in an individual order
	Field allEntities:TObjectList = New TObjectList()
	
	'could also be an "instance" if we made it a singleton..
	'this way the "currently handled" gameworld instance could be set there
	Global signalReceiver:TGameWorld

	Global SIGNAL_ENTITY_GOTHIT:ULong = GameSignals.RegisterSignal("entity.gothit")
	Global SIGNAL_GAMEWORLD_SCORECHANGED:ULong = GameSignals.RegisterSignal("gameworld.scorechanged")
	Global SIGNAL_GAMEWORLD_INITIALIZED:ULong = GameSignals.RegisterSignal("gameworld.initialized")

	
	Method New()
		GameSignals.RegisterSignalReceiver(TPlayerEntity.SIGNAL_PLAYER_FIREBULLET, _OnBulletGetsFired)
		GameSignals.RegisterSignalReceiver(TMothershipEntity.SIGNAL_MOTHERSHIP_FIREBULLET, _OnBulletGetsFired)
	End Method


	'global function which redirects to current instance
	Function _OnBulletGetsFired:Int(signalName:String, data:Object, sender:Object)
		signalReceiver.OnBulletGetsFired(signalName, data, sender)
	End Function

	Method OnBulletGetsFired:Int(signalName:String, data:Object, sender:Object)
		Local entity:TGameEntity = TGameEntity(sender)
		If Not entity Then Return False
		
		Local bullet:TBulletEntity = New TBulletEntity
		bullet.emitterID = entity.id
		if entity = player
			bullet.SetVelocity(New SVec2F(0, -400))
			bullet.SetPosition(New SVec2F(player.pos.x, player.pos.y - player.size.y/2))
		Elseif entity = mothership
			bullet.SetVelocity(New SVec2F(0, +400))
			bullet.SetPosition(New SVec2F(mothership.pos.x, mothership.pos.y + mothership.size.y/2))
			'make it a "drop"
			print "drop to lane: " + mothershipDropWall.GetLaneNumber(mothership.pos.x, 2)
		EndIf

		bullets.AddLast(bullet)
	End Method
	

	Method Init()
		allEntities.Clear()
		
		player = new TPlayerEntity()
		player.SetPosition(pos.x + size.x / 2.0, pos.y + size.y - 40)
		player.SetPositionLimits(New SRectI(Int(pos.x + 45), Int(player.pos.y), Int(pos.x + size.x - 90), 0), True)
		player.SetSize(60, 20)

		mothership = new TMothershipEntity()
		mothership.SetPosition(pos.x + size.x / 2.0, pos.y + 20)
		mothership.SetPositionLimits(New SRectI(Int(pos.x + 30), Int(mothership.pos.y), Int(pos.x + size.x - 60), 0), True)
		mothership.SetVelocity(New SVec2F(+300, 0))
		mothership.SetSize(80, 40)

		mothershipDropWall = New TMothershipDropWallEntity()
		mothershipDropWall.SetPosition(pos.x + size.x/2, 120 + 110/2)
		mothershipDropWall.SetSize(size.x, 110)

		foregroundEntities.AddLast(mothershipDropWall)

		allEntities.AddLast(mothershipDropWall)
		allEntities.AddLast(player)
		allEntities.AddLast(mothership)

		GameSignals.EmitSignal(SIGNAL_GAMEWORLD_INITIALIZED, null, self)
	End Method
	

	Method ResetLevel()
		player.SetPosition(pos.x + size.x / 2.0, pos.y + size.y - 40)
		mothership.SetPosition(pos.x + size.x / 2.0, pos.y + 20)
		bullets.Clear()
	End Method
	
	
	Method ChangeScore(value:Int)
		self.score :+ value
		GameSignals.EmitSignal(SIGNAL_GAMEWORLD_SCORECHANGED, string(value), self)
	End Method
	
	
	Method AddExplosion(x:Float, y:Float, direction:Int = 1)
		Local explosion:TExplosionEntity = New TExplosionEntity
		explosion.SetPosition(x, y)
		explosion.direction = direction
		explosion.SetLifetime(0.3) '300 milliseconds
		
		backgroundEntities.AddLast(explosion)
	End Method
	
	
	Method Update:Int(delta:Float) override
		'update currently handled element
		signalReceiver = self
	
		'player controls ... not done well here!
		If player
			If KeyDown(KEY_LEFT)
				player.SetVelocity(New SVec2F(-300, 0))
			ElseIf KeyDown(KEY_RIGHT)
				player.SetVelocity(New SVec2F(+300, 0))
			Else
				player.SetVelocity(New SVec2F(0, 0))
			EndIf
			
			If KeyDown(KEY_SPACE)
				if Millisecs() - player.lastBulletTime > 250
					player.FireBullet()
				EndIf
			EndIf
			'manual hits = rapid fire possible
			If KeyHit(KEY_SPACE)
				if Millisecs() - player.lastBulletTime > 50
					player.FireBullet()
				EndIf
			EndIf

		EndIf
	
		For Local entity:TGameEntity = EachIn allEntities
			entity.Update(delta)
		Next
		
		'inform mothership about state
		If mothership
			mothership.currentDropWallLaneNumber = mothershipDropWall.GetLaneNumber(mothership.pos.x, TBulletEntity.bulletSize.x)
		EndIf


		'update environment
		For Local e:TGameEntity = EachIn backgroundEntities.Reversed()
			e.Update(delta)
			if not e.alive Then backgroundEntities.Remove(e)
		Next
		For Local e:TGameEntity = EachIn foregroundEntities.Reversed()
			e.Update(delta)
			if not e.alive Then foregroundEntities.Remove(e)
		Next


		'update bullets
		For Local bullet:TBulletEntity = EachIn bullets
			bullet.Update(delta)
		Next
		'check bullet collisions
		For Local bullet:TBulletEntity = EachIn bullets
			if bullet.emitterID = player.id 
				If mothership.IntersectsWith(bullet)
					mothership.OnGetHit(bullet.emitterID)
					ChangeScore(+100)
					bullet.alive = False
					continue
				EndIf
			ElseIf bullet.emitterID = mothership.id
				If player.IntersectsWith(bullet)
					player.OnGetHit(bullet.emitterID)
					'start level again?
					ResetLevel()
					bullet.alive = False
					continue
				EndIf
			EndIf

			If mothershipDropWall.IntersectsWith(bullet)
				'wall or lane hit?
				Local laneNumber:Int = mothershipDropWall.GetLaneNumber(bullet.pos.x, bullet.size.x)

				'hit the wall
				If not laneNumber
					if bullet.emitterID = player.id
						AddExplosion(bullet.pos.x, mothershipDropWall.pos.y + mothershipDropWall.size.y/2, 2)
					EndIf

					mothershipDropWall.OnGetHit(bullet.emitterID)
					bullet.alive = False
				Else
					if bullet.emitterID = mothership.id
						'fill a lane (TODO: what happens if "full" - drop bomb?
						If Not mothershipDropWall.DropToLane(laneNumber)
							print "lane " + laneNumber + " full ... drop bomb?"
						EndIf
						bullet.alive = False
					EndIf

					if bullet.emitterID = player.id
						Local laneLevel:Int = mothershipDropWall.GetLane(laneNumber).GetLevel()
						If laneLevel > 0
							ChangeScore(+50)
							AddExplosion(bullet.pos.x, mothershipDropWall.pos.y + mothershipDropWall.size.y/2, 2)
							mothershipDropWall.GetLane(laneNumber).SetLevel(laneLevel - 1)
							bullet.alive = False
						EndIf
					EndIf
				EndIf
				continue
			EndIf
			
			'bullet too high or low (above mothership or below player
			'so above ground)
			If bullet.pos.y + bullet.size.y/2 < mothership.pos.y - mothership.size.y/2
				AddExplosion(bullet.pos.x, pos.y, 2)
				bullet.alive = False
				continue
			ElseIf bullet.pos.y + bullet.size.y/2 > pos.y + size.y - self.groundHeight 'player.pos.y + player.size.y/2
				AddExplosion(bullet.pos.x, pos.y + size.y - self.groundHeight)
				bullet.alive = False
				continue
			Endif
		Next
		'remove dead bullets
		For Local bullet:TBulletEntity = EachIn bullets.Reversed()
			if not bullet.alive Then bullets.Remove(bullet)
		Next
	End Method
	
	
	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)
		'render ground (should this become an own entity or should
		'ground elements ("decoration") just be backgroundEntities here?)
		SetColor 85,160,80
		DrawRect(0, pos.y + size.y - groundHeight, size.x, groundHeight)

		SetColor(oldCol)
		
	
		For Local entity:TGameEntity = EachIn backgroundEntities
			entity.Render()
		Next

		For Local bullet:TGameEntity = EachIn bullets
			bullet.Render()
		Next

		If player Then player.Render()
		For Local entity:TGameEntity = EachIn mothershipDrops
			entity.Render()
		Next
		If mothership Then mothership.Render()
		If mothershipSmartBomb Then mothershipSmartBomb.Render()

		For Local entity:TGameEntity = EachIn foregroundEntities
			entity.Render()
		Next
		
		'DrawText("Bullets: " + bullets.count(), 10,80)
		'DrawText("Lane: " + mothershipDropWall.GetLaneNumber(player.pos.x, 1), 10,100)
		'DrawText("LaneMX: " + mothershipDropWall.GetLaneNumber(MouseX(), 1) + "  intersects="+mothershipDropWall.IntersectsWith(MouseX(), MouseY(), 1, 1), 10,120)
	End Method
End Type

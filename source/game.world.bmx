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
		GameSignals.RegisterSignalReceiver(TMothershipDropWallEntity.SIGNAL_MOTHERSHIPDROPWALL_FIREBULLET, _OnBulletGetsFired)
	End Method


	'global function which redirects to current instance
	Function _OnBulletGetsFired:Int(signalName:String, data:Object, sender:Object)
		signalReceiver.OnBulletGetsFired(signalName, data, sender)
	End Function

	Method OnBulletGetsFired:Int(signalName:String, data:Object, sender:Object)
		Local entity:TGameEntity = TGameEntity(sender)
		If Not entity Then Return False

		Local bullet:TBulletEntity
		if entity = player
			bullet = New TBulletEntity
			bullet.SetEmitter(entity.id)
			bullet.SetVelocity(New SVec2F(0, -400))
			bullet.SetPosition(player.pos.x, player.pos.y - player.size.y/2)
			bullet.SetSize(10, 10)
		Elseif entity = mothership
			bullet = New TBulletEntity
			bullet.SetEmitter(entity.id)
			bullet.SetVelocity(New SVec2F(0, +400))
			bullet.SetPosition(mothership.pos.x, mothership.pos.y + mothership.size.y/2)
			'make it a "drop"
			print "drop to lane: " + mothershipDropWall.GetLaneNumber(mothership.pos.x, 2)
		Elseif entity = mothershipDropWall
			Local lane:TMothershipDropLaneEntity = mothershipDropWall.GetLane( Int(String(data)) )
			if lane
				bullet = New TMothershipDropEntity
				bullet.SetEmitter(mothershipDropWall.id) 'other emitter
				bullet.SetVelocity(New SVec2F(0, 400))
				bullet.SetSize(lane.size.x, 20)
				bullet.SetPosition(lane.GetPosition().x + lane.size.x/2, lane.GetPosition().y + lane.size.y/2 - bullet.size.y/2)
			EndIf
		Else
			Throw "OnBulletGetsFired with unsupported entity type"
		EndIf
		if bullet
			bullet.SetParent(self)
			bullets.AddLast(bullet)
		endif
	End Method
	

	Method Init()
		allEntities.Clear()
		
		player = new TPlayerEntity()
		player.SetSize(60, 20)
		player.SetPosition(size.x / 2.0, size.y - groundHeight - player.size.y/2)
		player.SetPositionLimits(New SRectI(Int(pos.x + 45), Int(player.pos.y), Int(pos.x + size.x), 0), True)
		player.SetParent(self)

		mothership = new TMothershipEntity()
		mothership.SetSize(80, 40)
		mothership.SetPosition(size.x / 2.0, mothership.size.y/2)
		mothership.SetPositionLimits(New SRectI(Int(pos.x + 30), Int(mothership.pos.y), Int(pos.x + size.x - 60), 0), True)
		mothership.SetVelocity(New SVec2F(+300, 0))
		mothership.SetParent(self)

		mothershipDropWall = New TMothershipDropWallEntity()
		mothershipDropWall.SetPosition(size.x/2, 110)
		mothershipDropWall.SetSize(size.x, 110)
		mothershipDropWall.SetParent(self)

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
	
	
	Method AddExplosion(worldX:Float, worldY:Float, direction:Int = 1)
		'make local
		Local x:Float = worldX - pos.x
		Local y:Float = worldY - pos.y
		Local explosion:TExplosionEntity = New TExplosionEntity
		explosion.SetPosition(x, y)
		explosion.direction = direction
		explosion.SetLifetime(0.3) '300 milliseconds
		explosion.SetParent(self)
		
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
		
		Local worldPos:SVec2F = GetPosition()
		'check bullet collisions
		For Local bullet:TBulletEntity = EachIn bullets
			if bullet.emitterID = player.id 
				If mothership.IntersectsWith(bullet)
					mothership.OnGetHit(bullet.emitterID)
					ChangeScore(+100)
					bullet.alive = False
					continue
				EndIf
			Else
				If player.IntersectsWith(bullet)
					player.OnGetHit(bullet.emitterID)
					'start level again?
					ResetLevel()
					bullet.alive = False
					continue
				EndIf
			EndIf

			If bullet.emitterID <> mothershipDropWall.id and mothershipDropWall.IntersectsWith(bullet)
				'wall or lane hit?
				Local laneNumber:Int = mothershipDropWall.GetLaneNumber(bullet.GetPosition().x, bullet.size.x/2)

				'hit the wall
				If not laneNumber
					if bullet.emitterID = player.id
						AddExplosion(bullet.GetPosition().x, mothershipDropWall.GetPosition().y + mothershipDropWall.size.y/2, 2)
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
							AddExplosion(bullet.GetPosition().x, mothershipDropWall.GetPosition().y + mothershipDropWall.size.y/2, 2)
							mothershipDropWall.GetLane(laneNumber).SetLevel(laneLevel - 1)
							bullet.alive = False
						EndIf
					EndIf
				EndIf
				continue
			EndIf
			
			'bullet too high or low (above mothership or below player
			'so above ground)
			If bullet.GetPosition().y + bullet.size.y/2 < mothership.GetPosition().y - mothership.size.y/2
				AddExplosion(bullet.GetPosition().x, GetPosition().y, 2)
				bullet.alive = False
				continue
			ElseIf bullet.emitterID <> player.ID and bullet.GetPosition().y + bullet.size.y/2 > GetPosition().y + size.y - self.groundHeight 'player.pos.y + player.size.y/2
				AddExplosion(bullet.GetPosition().x, GetPosition().y + size.y - self.groundHeight)
				bullet.alive = False
				continue
			Endif
			
			
			'did it hit another bullet?
			For Local otherBullet:TBulletEntity = EachIn bullets
				'avoid friendly fire
				If otherBullet.emitterID = bullet.emitterID Then continue

				If otherBullet.emitterID = player.id 
					If otherBullet.IntersectsWith(bullet)
						ChangeScore(+20)
						'both explosion styles -> "circle"
						AddExplosion(bullet.GetPosition().x, bullet.GetPosition().y + bullet.size.y, 1)
						AddExplosion(bullet.GetPosition().x, bullet.GetPosition().y + bullet.size.y, 2)
						otherBullet.alive = False
						bullet.alive = False
						Continue
					EndIf
				EndIf
			Next
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
		'DrawText("LaneMX: " + mothershipDropWall.GetLaneNumber(MouseX(), 1) + "  intersects="+mothershipDropWall.IntersectsWith(MouseX(), MouseY(), 1, 1) + " mouseY="+MouseY(), 10,120)
		'DrawText("Mouse: " + MouseX()+","+MouseY(), 10,120)
	End Method
End Type

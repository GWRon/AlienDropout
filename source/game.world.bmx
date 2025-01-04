SuperStrict
Import "game.entities.bmx"


Type TGameWorld Extends TGameEntity
	'elements in the world background
	Field backgroundEntities:TObjectList = New TObjectList
	'elements in the world foreground (over eg space ships)
	Field foregroundEntities:TObjectList = New TObjectList

	Field player:TPlayerEntity
	Field mothershipDropWall:TMothershipDropWallEntity
	Field mothership:TMothershipEntity
	Field mothershipSmartBomb:TGameEntity
	Field mothershipDrops:TObjectList = New TObjectList
	'allows to simply iterate over all elements on the screen
	'do differently if you need to update in an individual order
	Field allEntities:TObjectList = New TObjectList()
	
	'could also be an "instance" if we made it a singleton..
	'this way the "currently handled" gameworld instance could be set there
	Global signalReceiver:TGameWorld

	
	Method New()
		GameSignals.RegisterSignalReceiver(TPlayerEntity.SIGNAL_PLAYER_FIREBULLET, OnPlayerFiresBullet)
	End Method

	Function OnPlayerFiresBullet:Int(signalName:String, data:Object, sender:Object)
		print "player fires bullet"
	End Function
	

	Method Init()
		allEntities.Clear()
		
		player = new TPlayerEntity()
		player.SetPosition(pos.x / 2.0, pos.y + size.y - 40)
		player.SetPositionLimits(New SRectI(Int(pos.x + 45), Int(player.pos.y), Int(pos.x + size.x - 90), 0), True)
		player.SetSize(60, 20)

		mothership = new TMothershipEntity()
		mothership.SetPosition(pos.x / 2.0, pos.y + 20)
		mothership.SetPositionLimits(New SRectI(Int(pos.x + 30), Int(mothership.pos.y), Int(pos.x + size.x - 60), 0), True)
		mothership.SetVelocity(New SVec2F(+300, 0))
		mothership.SetSize(80, 40)

		mothershipDropWall = New TMothershipDropWallEntity()
		mothershipDropWall.SetPosition(pos.x, 100)
		mothershipDropWall.SetSize(size.x, 100)

		foregroundEntities.AddLast(mothershipDropWall)

		allEntities.AddLast(mothershipDropWall)
		allEntities.AddLast(player)
		allEntities.AddLast(mothership)
	End Method
	
	
	Method Update:Int(delta:Float) override
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
			mothership.currentDropWallSlot = mothershipDropWall.GetSlot(mothership.pos.x, TBulletEntity.bulletSize.x)
		EndIf
		
		'check bullets (do it here, avoids having bullets to know others)
		For Local bullet:TBulletEntity = EachIn player.bullets
			if bullet.emitterID = player.id 
				If mothership.IntersectsWith(bullet)
					bullet.alive = False
					continue
				EndIf
			ElseIf bullet.emitterID = mothership.id
				If player.IntersectsWith(bullet)
					bullet.alive = False
					continue
				EndIf
			EndIf

			If mothershipDropWall.IntersectsWith(bullet)
				'wall hit?
				If Not mothershipDropWall.GetSlot(bullet.pos.x, bullet.size.x)
					bullet.alive = False
				EndIf
				continue
			EndIf
			
			'bullet too high or low (above mothership or below player)
			If bullet.pos.y < mothership.pos.y - mothership.size.y
				'boom on the ground
				bullet.alive = False
				continue
			ElseIf bullet.pos.y > player.pos.y + player.size.y
				'boom on the ground
				bullet.alive = False
				continue
			Endif
		Next
	End Method
	
	
	Method Render:Int() override
		For Local entity:TGameEntity = EachIn backgroundEntities
			entity.Render()
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
		
		DrawText("Bullets: " + "p="+player.bullets.count() + " m="+mothership.bullets.count(), 10,80)
		DrawText("Slot: " + mothershipDropWall.GetSlot(player.pos.x, 1), 10,100)
	End Method
End Type

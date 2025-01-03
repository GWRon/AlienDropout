SuperStrict
Import "game.entities.bmx"


Type TGameWorld Extends TGameEntity
	'elements in the world background
	Field backgroundEntities:TObjectList = New TObjectList
	'elements in the world foreground (over eg space ships)
	Field foregroundEntities:TObjectList = New TObjectList

	Field player:TPlayerEntity
	Field mothershipDropWall:TMothershipDropWallEntity
	Field mothership:TGameEntity
	Field mothershipSmartBomb:TGameEntity
	Field mothershipDrops:TObjectList = New TObjectList
	'allows to simply iterate over all elements on the screen
	'do differently if you need to update in an individual order
	Field allEntities:TObjectList = New TObjectList()

	
	Method New()
	End Method
	

	Method Init()
		allEntities.Clear()
		
		player = new TPlayerEntity()
		player.SetPosition(pos.x / 2.0, pos.y + size.y - 50)
		player.SetPositionLimits(New SRectI(Int(pos.x + 60), Int(player.pos.y), Int(pos.x + size.x - 120), 0), True)
		player.SetSize(60, 30)

		mothership = new TMothershipEntity()
		mothership.SetPosition(pos.x / 2.0, pos.y + 20)
		mothership.SetPositionLimits(New SRectI(Int(pos.x + 60), Int(mothership.pos.y), Int(pos.x + size.x - 120), 0), True)
		mothership.SetVelocity(New SVec2F(+300, 0))
		mothership.SetSize(120, 30)

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
		
		'check bullets (do it here, avoids having bullets to know others)
		For Local bullet:TBulletEntity = EachIn player.bullets
			If mothership.IntersectsWith(bullet)
				bullet.alive = False
				continue
			EndIf

			If mothershipDropWall.IntersectsWith(bullet)
				'wall hit?
				Local slot:Int = mothershipDropWall.GetSlot(bullet.pos.x - bullet.size.x/2)
				if not slot or not mothershipDropWall.GetSlot(bullet.pos.x + bullet.size.x/2)
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
		
		DrawText("Bullets: " + player.bullets.count(), 10,80)
		DrawText("Slot: " + mothershipDropWall.GetSlot(MouseX()), 10,100)
	End Method
End Type

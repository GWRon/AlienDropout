SuperStrict
Import "game.entities.bmx"


Type TGameWorld Extends TGameEntity
	Field size:SVec2I
	
	'elements in the world background
	Field backgroundEntities:TObjectList = New TObjectList
	'elements in the world foreground (over eg space ships)
	Field foregroundEntities:TObjectList = New TObjectList

	Field player:TGameEntity
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
		player.SetPosition(New SVec2F(size.x / 2.0, size.y - 50))
		player.SetPositionLimits(New SRectI(40, size.y - 50, size.x - 80, 0), True)

		mothership = new TMothershipEntity()
		mothership.SetPosition(New SVec2F(size.x / 2.0, 50))
		mothership.SetVelocity(New SVec2F(+300, 0))
		mothership.SetPositionLimits(New SRectI(40, 50, size.x - 80, 0), True)

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
		EndIf
	
	
		For Local entity:TGameEntity = EachIn allEntities
			entity.Update(delta)
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
	End Method
End Type

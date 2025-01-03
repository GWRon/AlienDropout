SuperStrict
Import "game.entities.bmx"


Type TGameWorld Extends TGameEntity
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
	
	
	Method Update:Int() override
		For Local entity:TGameEntity = EachIn allEntities
			entity.Update()
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

SuperStrict
Import "game.entities.bmx"


Type TGameHUD Extends TGameEntity
	Field area:SRectI
	
	Method New()
	End Method
	
	
	Method Update:Int(delta:Float) override
	End Method
	
	
	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)
		SetColor 200,255,200
		DrawRect(area.x, area.y, area.w, area.h)
		
		SetColor 100,100,100
		DrawText("Score:", area.x + 10, area.y + 5)

		SetColor(oldCol)
	End Method
End Type

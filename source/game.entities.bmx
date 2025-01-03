SuperStrict
Import Brl.ObjectList
Import Math.Vector




Type TGameEntity
	Field pos:SVec2f
	Field id:Int
	Global _lastID:Int
	
	Method New()
		_lastID :+ 1
		self.id = _lastID
	End Method
	
	
	Method Update:Int()
	End Method


	Method Render:Int()
	End Method
End Type


	
	

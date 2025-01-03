SuperStrict

Interface IRenderable
	Method Render()
End Interface


Type TGameEntity
	Field id:Int
	Global _lastID:Int
	
	Method New()
		_lastID :+ 1
		self.id = _lastID
	End Method
	
	
	Method Update:Int()
	End Method
End Type


Type TGameWorld Extends TGameEntity Implements IRenderable
	Method Render() override
	End Method
End Type

	
	

SuperStrict
Import Brl.ObjectList
Import Math.Vector


Struct SRectI
	Field readonly x:Int
	Field readonly y:Int
	Field readonly w:Int
	Field readonly h:int

	Method New(x:Int, y:Int, w:Int, h:Int)
		self.x = x
		self.y = y
		self.w = w
		self.h = h
	End Method
End Struct


Type TGameEntity
	Field pos:SVec2f
	Field posLimit:SRectI
	Field posLimitActive:Int = False
	Field velocity:SVec2f
	Field id:Int
	Global _lastID:Int
	
	Method New()
		_lastID :+ 1
		self.id = _lastID
	End Method
	

	Method SetPosition(pos:SVec2F)
		self.pos = pos
	End Method


	Method SetPositionLimits(area:SRectI, active:Int)
		self.posLimit = area
		self.posLimitActive = active
	End Method
	
	
	Method ClampPosition()
		If pos.x < posLimit.x 
			pos = New SVec2F(posLimit.x, pos.y)
		Elseif pos.x > posLimit.x + posLimit.w 
			pos = New SVec2F(posLimit.x + posLimit.w, pos.y)
		EndIf
		If pos.y < posLimit.y 
			pos = New SVec2F(pos.x, posLimit.y)
		Elseif pos.y > posLimit.y + posLimit.h 
			pos = New SVec2F(pos.x, posLimit.y + posLimit.h)
		EndIf
	End Method


	Method SetVelocity(velocity:SVec2F)
		self.velocity = velocity
	End Method

	
	Method Move:Int(delta:Float)
		Local oldPos:SVec2F = pos

		pos = pos + velocity * delta
		
		If posLimitActive Then ClampPosition()
	
		Return (oldPos <> pos) 'moved?
	End Method
	

	Method Behaviour:Int(delta:Float)
	End Method

	
	Method Update:Int(delta:Float)
		Behaviour(delta)

		Move(delta)
	End Method


	Method Render:Int()
	End Method
End Type



Type TPlayerEntity Extends TGameEntity
	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)

		SetColor 200, 200, 255
		'pos is "bottom middle"
		DrawRect(pos.x -10, pos.y -20, 20,20)

		SetColor(oldCol)
	End Method
End Type




Type TMothershipEntity Extends TGameEntity
	Method Behaviour:Int(delta:Float) override
		'move left and right
		If self.pos.x <= posLimit.x
			self.SetVelocity(New SVec2f(+ Abs(self.velocity.x), self.velocity.y))
		ElseIf self.pos.x >= posLimit.x + posLimit.w
			self.SetVelocity(New SVec2f(- Abs(self.velocity.x), self.velocity.y))
		EndIf
	End Method


	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)

		SetColor 255, 100, 100
		'pos is "top middle"
		DrawRect(pos.x -30, pos.y, 60,10)
		DrawRect(pos.x -30, pos.y, 20,20)
		DrawRect(pos.x +10, pos.y, 20,20)

		SetColor(oldCol)
	End Method
End Type

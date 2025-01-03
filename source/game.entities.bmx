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
	
	
	Method Contains:Int(vec:SVec2I)
		Return (    vec.x >= Self.x And vec.x < Self.x + Self.w ..
		        And vec.y >= Self.y And vec.y < Self.y + Self.h ..
		       )
	End Method


	Method Contains:Int(vec:SVec2F)
		Return (    vec.x >= Self.x And vec.x < Self.x + Self.w ..
		        And vec.y >= Self.y And vec.y < Self.y + Self.h ..
		       )
	End Method


	Method Contains:Int(x:Int, y:Int, w:Int, h:Int)
		Return Contains( x, y ) And Contains(x + w, y + h)
	End Method


	Method Contains:Int(rect:SRectI)
		Return Contains(rect.x, rect.y) And Contains(rect.x + rect.w, rect.y + rect.h)
	End Method

	Method Contains:Int(x:Int, y:Int)
		Return (    x >= Self.x And x < Self.x + Self.w ..
		        And y >= Self.y And y < Self.y + Self.h ..
		       )
	End Method
End Struct


Type TGameEntity
	Field pos:SVec2f
	Field posLimit:SRectI
	Field posLimitActive:Int = False
	Field size:SVec2I
	Field velocity:SVec2f
	Field hitable:Int = False
	Field destroyable:Int = False
	
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
	
	
	Method ClampedPosition:SVec2F(toClampPos:SVec2F)
		Local clampedPos:SVec2F = toClampPos
		If clampedPos.x < posLimit.x 
			clampedPos = New SVec2F(posLimit.x, clampedPos.y)
		Elseif clampedPos.x > posLimit.x + posLimit.w 
			clampedPos = New SVec2F(posLimit.x + posLimit.w, clampedPos.y)
		EndIf
		If clampedPos.y < posLimit.y 
			clampedPos = New SVec2F(clampedPos.x, posLimit.y)
		Elseif clampedPos.y > posLimit.y + posLimit.h 
			clampedPos = New SVec2F(clampedPos.x, posLimit.y + posLimit.h)
		EndIf
		Return clampedPos
	End Method


	Method SetVelocity(velocity:SVec2F)
		self.velocity = velocity
	End Method


	Method SetSize(size:SVec2I)
		self.size = size
	End Method
		
	
	Method IntersectsEntity:Int(e:TGameEntity)
		'AABB approach
		Return Not (e.pos.x + e.size.x <= self.pos.x Or ..
					e.pos.x >= self.pos.x + self.size.x Or ..
					e.pos.y + e.size.y <= self.pos.y Or ..
					e.pos.y >= self.pos.y + self.size.y ..
				)
	End Method

	
	Method Move:Int(delta:Float)
		pos = pos + velocity * delta
		
		Local newPos:SVec2F = pos
		If posLimitActive Then newPos = ClampedPosition(newPos)

		If newPos <> pos
			pos = newPos
			Return True
		Else
			Return False
		EndIf
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



Type TBulletEntity Extends TGameEntity
	Field emitterID:Int
	Field hitID:Int
	Field alive:Int = True
	
	Method SetEmitter(id:Int)
		self.emitterID = id
	End Method
	

	Method Behaviour:Int(delta:Float) override
		'hit something
		If hitID Then alive = False
	End Method


	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)

		SetColor 200, 255, 255
		'pos is "middle"
		DrawRect(pos.x -4, pos.y -4, 8,8)

		SetColor(oldCol)
	End Method
End Type



Type TPlayerEntity Extends TGameEntity
	Field lastBulletTime:Int
	Field bullets:TObjectList = New TObjectList

	Method FireBullet()
		Local bullet:TBulletEntity = New TBulletEntity
		bullet.SetVelocity(New SVec2F(0, -400))
		bullet.SetPosition(New SVec2F(self.pos.x, self.pos.y - 10))
		bullets.AddLast(bullet)
		
		lastBulletTime = Millisecs()
	End Method


	Method Update:Int(delta:Float) override
		Super.Update(delta:Float)

		For Local bullet:TBulletEntity = EachIn bullets.Reversed()
			bullet.Update(delta)
			if not bullet.alive Then bullets.Remove(bullet)
		Next
	End Method
	

	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)

		SetColor 200, 200, 255
		'pos is "bottom middle"
		DrawRect(pos.x -10, pos.y -20, 20,20)

		For Local bullet:TGameEntity = EachIn bullets
			bullet.Render()
		Next

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

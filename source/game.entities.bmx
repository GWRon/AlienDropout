SuperStrict
Import Brl.ObjectList
Import Math.Vector
Import "game.globals.bmx"


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
	

	Method SetPosition(pos:SVec2F) Final
		SetPosition(pos.x, pos.y)
	End Method

	Method SetPosition(x:Float, y:Float)
		self.pos = New SVec2F(x, y)
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


	Method SetSize(size:SVec2I) Final
		SetSize(size.x, size.y)
	End Method

	Method SetSize(w:Int, h:Int)
		self.size = New SVec2I(w, h)
	End Method
		
	
	Method IntersectsWith:Int(e:TGameEntity)
		Return IntersectsWith(e.pos.x, e.pos.y, e.size.x, e.size.y)
	End Method

	Method IntersectsWith:Int(area:SRectI)
		Return IntersectsWith(area.x, area.y, area.w, area.h)
	End Method

	Method IntersectsWith:Int(x:Float, y:Float, w:Float, h:Float)
		'AABB approach
		Return Not (x + w <= self.pos.x Or ..
					x >= self.pos.x + self.size.x Or ..
					y + h <= self.pos.y Or ..
					y >= self.pos.y + self.size.y ..
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
	Global bulletSize:Svec2I = New SVec2I(8,8)
	
	Method New()
		size = bulletSize
	End Method
	
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
		DrawRect(pos.x - size.x/2, pos.y - size.y/2, size.x, size.y)

		SetColor(oldCol)
	End Method
End Type



Type TPlayerEntity Extends TGameEntity
	Field lastBulletTime:Int

	Global SIGNAL_PLAYER_FIREBULLET:ULong = GameSignals.RegisterSignal("player.firebullet")

	
	Method FireBullet()
		GameSignals.EmitSignal(SIGNAL_PLAYER_FIREBULLET, null, self)
		
		lastBulletTime = Millisecs()
	End Method


	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)

		SetColor 200, 200, 255
		'pos is "middle"
		DrawRect(pos.x -10, pos.y -10, 20,10)
		DrawRect(pos.x -30, pos.y, 60,10)

		SetColor(oldCol)
	End Method
End Type




Type TMothershipEntity Extends TGameEntity
	Field lastBulletTime:Int
	Field bulletInterval:Int = 500 'difficulty dependend?
	Field currentDropWallSlot:Int

	Global SIGNAL_MOTHERSHIP_FIREBULLET:ULong = GameSignals.RegisterSignal("mothership.firebullet")

	Method FireBullet()
		GameSignals.EmitSignal(SIGNAL_MOTHERSHIP_FIREBULLET, null, self)

		lastBulletTime = Millisecs()
	End Method


	Method Behaviour:Int(delta:Float) override
		'move left and right
		If self.pos.x - self.size.x/2 <= posLimit.x
			self.SetVelocity(New SVec2f(+ Abs(self.velocity.x), self.velocity.y))
		ElseIf self.pos.x + self.size.x/2 >= posLimit.x + posLimit.w
			self.SetVelocity(New SVec2f(- Abs(self.velocity.x), self.velocity.y))
		EndIf
		
		'over a slot?
		If currentDropWallSlot > 0 and currentDropWallSlot <> 7
			If Millisecs() - lastBulletTime > bulletInterval
				local oldLastBulletTime:Int = lastBulletTime
				FireBullet()
				lastBulletTime = lastBulletTime + bulletInterval 'so many bullets if not shot a while
				'todo ... nur wenn sich ein wenig bewegt wurde (um volle slots zu vermeiden)
			EndIf
		EndIf 
	End Method


	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)

		SetColor 255, 100, 100
		'pos is "middle"
		DrawRect(pos.x - size.x/2, pos.y - size.y/2, 80,10)
		DrawRect(pos.x - size.x/2 + 10, pos.y - size.y/2 + 10, 60,10)
		DrawRect(pos.x - size.x/2, pos.y - size.y/2 + 20, 80,10)
		DrawRect(pos.x - size.x/2 + 10, pos.y - size.y/2 + 30, 10,10)
		DrawRect(pos.x - size.x/2 + 30, pos.y - size.y/2 + 30, 20,10)
		DrawRect(pos.x - size.x/2 + 60, pos.y - size.y/2 + 30, 10,10)

		SetColor(oldCol)
	End Method
End Type




Type TMothershipDropWallEntity Extends TGameEntity
	Field wallOffsetX:Int = 40
	Field wallsPos:SVec2F[14]
	Field wallWidth:Int = 24
	Field wallHeight:Int = 100
	Field dropSlotWidth:Int = 24
	Field bombSlotWidth:Int

	Method SetSize(x:Int, y:Int) override
		Super.SetSize(x, y)
		
		'knowing the size we can now align stuff
		bombSlotWidth = size.x - 2*wallOffsetX - 14*wallWidth - 12*dropSlotWidth
		wallHeight = size.y
		
		For local i:int = 0 until 7
			wallsPos[i] = New SVec2F(wallOffsetX + pos.x + i*(wallWidth + dropSlotWidth), wallHeight)
		Next
		For local i:int = 0 until 7
			wallsPos[i+7] = New SVec2F(wallsPos[6].x + bombSlotWidth + i*(wallWidth + dropSlotWidth) + wallWidth, wallHeight)
		Next
	End Method


	Method IntersectsWith:Int(x:Float, y:Float, w:Float, h:Float) override
		'before doing fine grained checks, we check the bounding box
		If Not Super.IntersectsWith(x,y,w,h) Then Return False

		'check y once and then only x'es (as there are more variants)
		if y + h < pos.y Then Return False
		if y > pos.y + size.y Then Return False

		'left or right of wall
		if x + w < pos.x + 40 Then Return False
		if x > pos.x + size.x Then Return False
		'right of left wall and left of right wall (aka in the middle)
		if x > wallsPos[6].x + wallWidth and x + w < wallsPos[7].x Then Return False
		
		Return True
	End Method
	
	
	Method GetSlot:Int(x:Float, width:Int)
		Local xL:Int = x - width/2
		Local xR:Int = x + width/2
		For local i:Int = 1 until 14
			if xL > wallsPos[i-1].x + wallWidth and xR < wallsPos[i].x Then Return i 'so < wall 2(index1) returns slot 1
		Next
		Return 0
	End Method

	
	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)

		SetColor 100, 200, 255
		For local i:int = 0 until 14
			DrawRect(wallsPos[i].x, wallsPos[i].y, wallWidth, wallHeight)
		Next
		
		SetColor(oldCol)
	End Method
End Type

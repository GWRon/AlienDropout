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
		'entities are "centered"
		Return IntersectsWith(e.pos.x - e.size.x/2, e.pos.y - e.size.y/2, e.size.x, e.size.y)
	End Method

	Method IntersectsWith:Int(area:SRectI)
		Return IntersectsWith(area.x, area.y, area.w, area.h)
	End Method

	Method IntersectsWith:Int(x:Float, y:Float, w:Float, h:Float)
		'AABB approach
		Return Not (x + w <= self.pos.x - self.size.x/2 Or ..
					x >= self.pos.x + self.size.x/2 Or ..
					y + h <= self.pos.y - self.size.y/2 Or ..
					y >= self.pos.y + self.size.y/2 ..
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
	
	
	'information that an other entity has hit this one at (local) x,y
	Method OnGetHit:Int(hittingEntityID:Int, localX:Int=0, localY:Int=0)
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
	Global SIGNAL_PLAYER_GOTHIT:ULong = GameSignals.RegisterSignal("player.gothit")

	
	Method FireBullet()
		GameSignals.EmitSignal(SIGNAL_PLAYER_FIREBULLET, null, self)
		
		lastBulletTime = Millisecs()
	End Method


	' information that an other entity has hit this mothership
	Method OnGetHit:Int(hittingEntityID:Int, localX:Int=0, localY:Int=0)
		GameSignals.EmitSignal(SIGNAL_PLAYER_GOTHIT, null, self)

		' TODO: eg animate damage / shake something
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
	Field currentDropWallLaneNumber:Int

	Global SIGNAL_MOTHERSHIP_FIREBULLET:ULong = GameSignals.RegisterSignal("mothership.firebullet")
	Global SIGNAL_MOTHERSHIP_GOTHIT:ULong = GameSignals.RegisterSignal("mothership.gothit")
 
	Method FireBullet()
		GameSignals.EmitSignal(SIGNAL_MOTHERSHIP_FIREBULLET, null, self)

		lastBulletTime = Millisecs()
	End Method


	' information that an other entity has hit this mothership
	Method OnGetHit:Int(hittingEntityID:Int, localX:Int=0, localY:Int=0)
		GameSignals.EmitSignal(SIGNAL_MOTHERSHIP_GOTHIT, null, self)
		
		' TODO: eg animate damage / shake something
	End Method


	Method Behaviour:Int(delta:Float) override
		'move left and right
		If self.pos.x - self.size.x/2 <= posLimit.x
			self.SetVelocity(New SVec2f(+ Abs(self.velocity.x), self.velocity.y))
		ElseIf self.pos.x + self.size.x/2 >= posLimit.x + posLimit.w
			self.SetVelocity(New SVec2f(- Abs(self.velocity.x), self.velocity.y))
		EndIf
		
		'over a slot?
		If currentDropWallLaneNumber > 0 and currentDropWallLaneNumber <> 7
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



Type TMothershipDropEntity Extends TGameEntity
	'Todo: move down, emit signal when "full" etc
End Type



Type TMothershipDropLaneEntity Extends TGameEntity
	Field levels:TMothershipDropEntity[]
	
	Method SetLevelAmount(levelAmount:Int)
		levels = levels[.. levelAmount]
	End Method
End Type




Type TMothershipDropWallEntity Extends TGameEntity
	'center position of walls inside of the entity (local positions) 
	Field wallsCenterPos:SVec2F[]
	Field wallWidth:Int = 24
	Field wallHeight:Int = 100
	Field dropLaneCount:Int = 12    ' how many drop lane
	Field dropLaneLevels:Int = 5    ' how many levels each drop lane has 
	Field dropLaneWidth:Int = 24
	Field dropLanes:TMothershipDropLaneEntity[]
	Field bombSlotWidth:Int = 96
	
	Method New()
		wallsCenterPos = New SVec2F[dropLaneCount + 2]
		' prepare slot array so all can "fit in"
		dropLanes = new TMothershipDropLaneEntity[dropLaneCount]
		For local i:Int = 0 until dropLanes.length
			dropLanes[i] = New TMothershipDropLaneEntity
			dropLanes[i].SetLevelAmount(dropLaneLevels)
		Next
	End Method
	

	Method SetSize(x:Int, y:Int) override
		Super.SetSize(x, y)
		
		'knowing the size we can now align stuff
		wallHeight = size.y
		
		local halfWidth:Int = (wallsCenterPos.length * wallWidth + dropLaneCount * dropLaneWidth + bombSlotWidth) / 2
		For local i:int = 0 until 7
			wallsCenterPos[i] = New SVec2F(-halfWidth + i * (wallWidth + dropLaneWidth), -wallHeight/2)
		Next
		For local i:int = 0 until 7
			wallsCenterPos[i+7] = New SVec2F(bombSlotWidth/2 + i*(wallWidth + dropLaneWidth), -wallHeight/2)
		Next
	End Method


	Method IntersectsWith:Int(x:Float, y:Float, w:Float, h:Float) override
		'FOR NOW wall entity is "top left" aligned
		
		'before doing fine grained checks, we check the bounding box
		If Not Super.IntersectsWith(x,y,w,h) Then Return False

		'make coords local to "top left" to calculate positions in only once
		x :- (self.pos.x - self.size.x/2)
		y :- (self.pos.y - self.size.y/2)

		'check y once and then only x'es (as there are more variants)
		if y + h < 0 Then Return False
		if y > self.size.y Then Return False

		'left or right of wall
		if x + w < self.wallsCenterPos[0].x - self.wallWidth Then Return False
		if x > self.size.x Then Return False
		'right of left wall and left of right wall (aka in the middle)
		if x > wallsCenterPos[6].x + wallWidth and x + w < wallsCenterPos[7].x Then Return False
		
		Return True
	End Method
	
	
	Method GetLaneNumber:Int(x:Float, width:Int)
		'make x local to "top left" to calculate it only once
		x :- (self.pos.x)

		Local xL:Int = x - width/2
		Local xR:Int = x + width/2
		For local i:Int = 1 until 14
			if xL > wallsCenterPos[i-1].x + wallWidth and xR < wallsCenterPos[i].x Then Return i 'so < wall 2(index1) returns slot 1
		Next
		Return 0
	End Method
	
	
	'returns wether dropping was possible or not
	Method DropToLane:Int(laneNumber:Int)
		Local laneIndex:Int = laneNumber - 1
		If laneIndex < 0 or laneIndex >= dropLanes.length Then Return -1
		
		Local lane:TMothershipDropLaneEntity = dropLanes[laneIndex]
		'if self.dropLanes
		
		Return True
	End Method

	
	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)

		SetColor 100, 200, 255
		For local i:int = 0 until 14
			DrawRect(self.pos.x + wallsCenterPos[i].x, self.pos.y + wallsCenterPos[i].y, wallWidth, wallHeight)
		Next

		SetColor(oldCol)
	End Method
End Type

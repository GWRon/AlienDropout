SuperStrict
Import Brl.ObjectList
Import Math.Vector
Import Random.Xoshiro
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
	Field alive:Int = True
	Field parent:TGameEntity
	Field signals:TSignalSystem 'by default unused! null!
	
	Field id:Int
	Global _lastID:Int

	
	Method New()
		_lastID :+ 1
		self.id = _lastID
	End Method
	
	
    Method SetParent(p:TGameEntity)
		'inform parent
		'If self.parent
		'	self.parent.RemoveChild(self)
		'EndIf

        self.parent = p

		'If self.parent
		'	self.parent.AddChild(self)
		'EndIf
    End Method
    
    
    Method GetPosition:SVec2F()
		If parent
			Return parent.GetPosition() + pos
		Else
			return pos
		EndIf
    End Method

   	

	Method SetPosition(pos:SVec2F) Final
		SetPosition(pos.x, pos.y)
	End Method

	Method SetPosition(x:Float, y:Float)
		self.pos = New SVec2F(x, y)
		
		'if someone is interested, we inform them
		If signals Then signals.EmitSignal("setposition".hash(), null, self)
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
		Local worldPos:SVec2F = e.GetPosition()
		Return IntersectsWith(worldPos.x - e.size.x/2, worldPos.y - e.size.y/2, e.size.x, e.size.y)
	End Method

	Method IntersectsWith:Int(area:SRectI)
		Return IntersectsWith(area.x, area.y, area.w, area.h)
	End Method

	Method IntersectsWith:Int(x:Float, y:Float, w:Float, h:Float)
		Local worldPos:SVec2F = GetPosition()
		'AABB approach
		Return Not (x + w <= worldPos.x - self.size.x/2 Or ..
					x >= worldPos.x + self.size.x/2 Or ..
					y + h <= worldPos.y - self.size.y/2 Or ..
					y >= worldPos.y + self.size.y/2 ..
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
		local worldPos:SVec2F = GetPosition()
		'pos is "middle"
		DrawRect(worldPos.x - size.x/2, worldPos.y - size.y/2, size.x, size.y)

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
		local worldPos:SVec2F = GetPosition()
		'pos is "middle"
		DrawRect(worldPos.x -10, worldPos.y -10, 20,10)
		DrawRect(worldPos.x -30, worldPos.y, 60,10)

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
		local worldPos:SVec2F = GetPosition()
		'pos is "middle"
		DrawRect(worldPos.x - size.x/2, worldPos.y - size.y/2, 80,10)
		DrawRect(worldPos.x - size.x/2 + 10, worldPos.y - size.y/2 + 10, 60,10)
		DrawRect(worldPos.x - size.x/2, worldPos.y - size.y/2 + 20, 80,10)
		DrawRect(worldPos.x - size.x/2 + 10, worldPos.y - size.y/2 + 30, 10,10)
		DrawRect(worldPos.x - size.x/2 + 30, worldPos.y - size.y/2 + 30, 20,10)
		DrawRect(worldPos.x - size.x/2 + 60, worldPos.y - size.y/2 + 30, 10,10)

		SetColor(oldCol)
	End Method
End Type



Type TMothershipDropEntity Extends TBulletEntity
	Global SIGNAL_MOTHERSHIPDROP_GOTHIT:ULong = GameSignals.RegisterSignal("mothershipdrop.gothit")


	' information that an other entity has hit this mothership
	Method OnGetHit:Int(hittingEntityID:Int, localX:Int=0, localY:Int=0)
		GameSignals.EmitSignal(SIGNAL_MOTHERSHIPDROP_GOTHIT, null, self)

		' TODO: eg animate damage / shake something
	End Method


	Method Behaviour:Int(delta:Float) override
		'
	End Method
	

	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)

		SetColor 200,200,200
		Local worldPos:SVec2F = GetPosition()
		DrawRect(worldPos.x - self.size.x/4, worldPos.y, self.size.x/2, self.size.y/2)
		DrawRect(worldPos.x - self.size.x/2, worldPos.y - self.size.y/2, self.size.x, self.size.y/2)

		SetColor(oldCol)
	End Method
End Type



Type TMothershipDropLaneEntity Extends TGameEntity
	Field levels:TMothershipDropEntity[]
	Field levelTime:Int
	
	Method GetLevelAmount:Int()
		Return levels.length
	End Method


	Method SetLevelAmount(levelAmount:Int)
		levels = levels[.. levelAmount]
	End Method


	Method GetLevel:Int()
		For Local i:Int = 0 until levels.length
			If not levels[i] Then Return i 
		Next
		Return levels.length
	End Method
	
		
	Method SetLevel:Int(level:Int)
		If level < 0 or level > levels.length Then Return False

		Local levelIndex:Int = level -1
		For Local i:Int = 0 until levels.length
			'remove no longer needed
			if i > levelIndex 
				levels[i] = Null
			'create new
			ElseIf i <= levelIndex And Not levels[i] 
				Local dropEntity:TMothershipDropEntity = New TMothershipDropEntity
				dropEntity.SetSize(self.size.x, 20)
				dropEntity.SetPosition(dropEntity.size.x/2, self.size.y - i * (dropEntity.size.y + 5))
				dropEntity.SetParent(self) 'position relatively until they become separated

				levels[i] = dropEntity
			EndIf
		Next
		
		levelTime = Millisecs()
		Return True
	End Method


	Method Update:Int(delta:Float) override
		Local result:Int = Super.Update(delta)

		'also update drop entities
		For Local e:TMothershipDropEntity = EachIn levels
			e.Update(delta)
		Next
	End Method
	
	
	Method Render:Int() override
		Local result:Int = Super.Render()

		'SetColor 255,0,0
		'Local worldPos:SVec2F = GetPosition()
		'DrawRect(worldPos.x, worldPos.y, self.size.x, self.size.y)

		'also render drop entities
		For Local e:TMothershipDropEntity = EachIn levels
			e.Render()
		Next
	
'		DrawText(GetLevel(), GetPosition().x, GetPosition().y + size.y)
	End Method
End Type




Type TMothershipDropWallEntity Extends TGameEntity
	'topleft position of walls inside of the entity (local positions) 
	Field wallsPos:SVec2F[]
	Field wallWidth:Int = 24
	Field wallHeight:Int = 110
	Field dropLaneCount:Int = 12    ' how many drop lane
	Field dropLaneLevels:Int = 5    ' how many levels each drop lane has 
	Field dropLaneWidth:Int = 24
	Field dropLanes:TMothershipDropLaneEntity[]
	Field bombSlotWidth:Int = 96
	Field dropInterval:Int = 2000
	Field nextDropLane:Int
	Field lastDropTime:Int

	Global SIGNAL_MOTHERSHIPDROPWALL_FIREBULLET:ULong = GameSignals.RegisterSignal("mothershipdropwall.firebullet")

	Method New()
		wallsPos = New SVec2F[dropLaneCount + 2]
		' prepare slot array so all can "fit in"
		dropLanes = new TMothershipDropLaneEntity[dropLaneCount]
		For local i:Int = 0 until dropLanes.length
			dropLanes[i] = New TMothershipDropLaneEntity
			dropLanes[i].SetLevelAmount(dropLaneLevels)
			dropLanes[i].SetParent(self) 'position relatively
			dropLanes[i].SetSize(dropLaneWidth, wallHeight)
		Next

		lastDropTime = Millisecs()
	End Method
	

	Method SetSize(x:Int, y:Int) override
		Super.SetSize(x, y)
		
		'knowing the size we can now align stuff
		wallHeight = size.y
		
		local halfWidth:Int = (wallsPos.length * wallWidth + dropLaneCount * dropLaneWidth + bombSlotWidth) / 2
		
		'orient walls and lanes to center point of widget.
		'(their anchors is "top left")
		local wallsPerSide:Int = wallsPos.length/2
		For local i:int = 0 until wallsPerSide
			wallsPos[i] = New SVec2F(-halfWidth + i * (wallWidth + dropLaneWidth), -wallHeight/2)
			wallsPos[i+wallsPerSide] = New SVec2F(bombSlotWidth/2 + i*(wallWidth + dropLaneWidth), -wallHeight/2)
		Next
		Local dropLanesPerSide:Int = dropLanes.length / 2 
		For Local i:Int = 0 until dropLanesPerSide
			dropLanes[i].SetPosition(wallsPos[i].x + wallWidth, -wallHeight/2)
			dropLanes[i+dropLanesPerSide].SetPosition(wallsPos[i+dropLanesPerSide+1].x + wallWidth, -wallHeight/2)
		Next
	End Method


	Method IntersectsWith:Int(x:Float, y:Float, w:Float, h:Float) override
		'FOR NOW wall entity is "top left" aligned
		
		'before doing fine grained checks, we check the bounding box
		If Not Super.IntersectsWith(x,y,w,h) Then Return False
		
		Local worldPos:SVec2F = GetPosition()

		'make coords local to "center" to calculate positions in only once
		x :- (worldPos.x)
		y :- (worldPos.y)

		Local wallY:Int = self.wallsPos[0].y
		'check y once and then only x'es (as there are more variants)
		if y + h < wallY Then Return False
		if y > wallY + self.wallHeight Then Return False

		'left or right of wall
		if x + w < self.wallsPos[0].x Then Return False
		if x > self.wallsPos[self.wallsPos.length-1].x + self.wallWidth Then Return False
		'right of left wall and left of right wall (aka in the middle)
		if x > wallsPos[6].x + self.wallWidth and x + w < wallsPos[7].x Then Return False

		Return True
	End Method
	
	
	Method GetLaneNumber:Int(x:Float, width:Int)
		'make x local to "center" to calculate it only once
		x :- (self.pos.x)

		Local xL:Int = x - width/2
		Local xR:Int = x + width/2
		For Local i:Int = 0 until dropLanes.length
			if xL > dropLanes[i].pos.x and xR < dropLanes[i].pos.x + dropLanes[i].size.x Then Return i+1
		Next

		Return 0
	End Method


	Method GetLane:TMothershipDropLaneEntity(laneNumber:Int)
		If laneNumber < 1 or laneNumber > dropLanes.length Then Return Null
		Return dropLanes[laneNumber -1]
	End Method
	
	
	'returns wether dropping was possible or not
	Method DropToLane:Int(laneNumber:Int)
		Local laneIndex:Int = laneNumber - 1
		If laneIndex < 0 or laneIndex >= dropLanes.length Then Return False
		
		Local lane:TMothershipDropLaneEntity = dropLanes[laneIndex]

		Local laneLevel:Int = lane.GetLevel()
		If laneLevel < lane.GetLevelAmount()
			lane.SetLevel(laneLevel + 1)
			Return True
		Else
			Return False
		EndIf
	End Method


	Method FireBullet()
		Local lane:TMothershipDropLaneEntity = GetLane(nextDropLane)
		if not lane or lane.GetLevel() = 0 Then Return

		GameSignals.EmitSignal(SIGNAL_MOTHERSHIPDROPWALL_FIREBULLET, String(nextDropLane), self)
		
		lane.SetLevel(lane.GetLevel() - 1)
	End Method

	
	Method Behaviour:Int(delta:Float)
		If Millisecs() - lastDropTime > dropInterval
			'choose a lane
			nextDropLane = Rand(1, dropLanes.length)
			For local i:Int = 0 until dropLanes.length
				local laneIndex:Int = (nextDropLane + i) mod dropLanes.length
				if GetLane(laneIndex+1).GetLevel() > 0
					nextDropLane = laneIndex+1
					lastDropTime = Millisecs()
					FireBullet()
					exit
				EndIf
			Next
		EndIf
	End Method

	
	Method Update:Int(delta:Float) override
		Local result:Int = Super.Update(delta)

		'update lanes
		For Local e:TGameEntity = EachIn dropLanes
			e.Update(delta)
		Next
	End Method


	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)

		SetColor 100, 200, 255
		Local worldPos:SVec2F = GetPosition()
		For local i:int = 0 until 14
			DrawRect(worldPos.x + wallsPos[i].x, worldPos.y + wallsPos[i].y, wallWidth, wallHeight)
		Next
		SetColor(oldCol)
		
		'draw lanes
		For local lane:TGameEntity = EachIn dropLanes
			lane.Render()
		Next
	End Method
End Type



Type TExplosionEntity Extends TGameEntity
	Field lifetimeStart:Float
	Field lifetime:Float
	Field direction:Int = 1 '1=up, 2=down
	
	Method SetLifetime(lifetime:Float)
		self.lifetime = lifetime
		self.lifetimeStart = lifetime
	End Method


	Method Update:Int(delta:Float) override
		self.lifetime :- delta
		if self.lifetime <= 0.001 then alive = False

		Return Super.Update(delta)
	End Method
	

	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)

		Local explosionStep:Int = trunc((1.0 - lifetime/lifetimeStart) * 3 + 0.5) '0 to 5

		Select explosionStep
			Case 0
				SetColor 250,150,50
			
			Case 1
				SetColor 220,220,100

			Case 2
				SetColor 200,200,100

			Case 3
				SetColor 150, 100,50
		End Select

		'for upwards anchor point is "center, bottom"
		'for downwards anchor point is "center, top"
		Local worldPos:SVec2F = GetPosition()
		Select explosionStep
			Case 0, 3
				If direction = 1
					DrawRect(worldPos.x - 5, worldPos.y - 10, 10, 10)
				Else
					DrawRect(worldPos.x - 5, worldPos.y, 10, 10)
				EndIf
			Case 1
				If direction = 1
					DrawRect(worldPos.x - 5, worldPos.y - 20, 10, 10)
					DrawRect(worldPos.x - 15, worldPos.y - 10, 30, 10)
				Else
					DrawRect(worldPos.x - 15, worldPos.y, 30, 10)
					DrawRect(worldPos.x - 5, worldPos.y + 10, 10, 10)
				EndIf
			Case 2
				If direction = 1
					DrawRect(worldPos.x - 5, worldPos.y - 30, 10, 10)

					DrawRect(worldPos.x - 15, worldPos.y - 20, 10, 10)
					DrawRect(worldPos.x +  5, worldPos.y - 20, 10, 10)

					DrawRect(worldPos.x - 25, worldPos.y - 10, 10, 10)
					DrawRect(worldPos.x + 15, worldPos.y - 10, 10, 10)
				Else
					DrawRect(worldPos.x - 25, worldPos.y, 10, 10)
					DrawRect(worldPos.x + 15, worldPos.y, 10, 10)

					DrawRect(worldPos.x - 15, worldPos.y + 10, 10, 10)
					DrawRect(worldPos.x +  5, worldPos.y + 10, 10, 10)

					DrawRect(worldPos.x - 5, worldPos.y + 20, 10, 10)
				EndIf
		End Select
		
		SetColor(oldCol)
	End Method
End Type

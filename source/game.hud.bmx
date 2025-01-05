SuperStrict
Import "game.entities.bmx"


Type TGameHUD Extends TGameEntity
	Field area:SRectI
	Field score:Int 'score of the game
	Field scoreToDraw:Int 'score currently displayed (to animate...)
	'could also be an "instance" if we made it a singleton..
	'this way the "currently handled" hud instance could be set there
	Global signalReceiver:TGameHUD
	'could be done here ... or indirectly via "main" which then sends
	'out a received signal to the HUD (main knows world AND hud...)
	Global SIGNAL_GAMEWORLD_SCORECHANGED:ULong = GameSignals.RegisterSignal("gameworld.scorechanged")
	Global SIGNAL_GAMEWORLD_INITIALIZED:ULong = GameSignals.RegisterSignal("gameworld.initialized")

	
	Method New()
		GameSignals.RegisterSignalReceiver(TGameHUD.SIGNAL_GAMEWORLD_SCORECHANGED, OnGameWorldScoreChanged)
		GameSignals.RegisterSignalReceiver(TGameHUD.SIGNAL_GAMEWORLD_INITIALIZED, OnGameWorldInitialized)
	End Method

	Function OnGameWorldScoreChanged:Int(signalName:String, data:Object, sender:Object)
		Local value:Int = Int(String(data))
		signalReceiver.score :+ value
	End Function


	Function OnGameWorldInitialized:Int(signalName:String, data:Object, sender:Object)
		'reset
		SignalReceiver.score = 0
	End Function
	
	
	Method Update:Int(delta:Float) override
		'update currently handled element
		signalReceiver = self
		
		if Abs(scoreToDraw - score) < 5 Then scoreToDraw = score
		If scoreToDraw > score
			scoreToDraw :- 5
		ElseIf scoreToDraw < score
			scoreToDraw :+ 5
		EndIf

	End Method
	
	
	Method Render:Int() override
		Local oldCol:SColor8; GetColor(oldCol)
		SetColor 200,255,200
		DrawRect(area.x, area.y, area.w, area.h)
		
		SetColor 100,100,100
		DrawText("Score: " + scoreToDraw, area.x + 10, area.y + 5)

		SetColor(oldCol)
	End Method
End Type

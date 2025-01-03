SuperStrict
Framework SDL.SDLRenderMax2D
Import "source/framework/base.util.deltatimer.bmx"
Import "source/game.entities.bmx"
Import Brl.Map

'=== SETUP GRAPHICS / WINDOW ===
Graphics 800,600,0,0, SDL_WINDOW_RESIZABLE | GRAPHICS_SWAPINTERVAL1



'=== GAME GLOBALS ===
Enum EGameScreens
	Start
	Game
	Highscore
End Enum

Global appExit:Int = False
Global gameScreen:EGameScreens = EGameScreens.Game 'start right in the game
'all "game screen" entities "managed" by the game
Global gameEntities:TIntMap = New TIntMap



'=== PREPARE GAME LOOP ===
GetDeltatimer().Init(60, 60) '60 UPS, 60 FPS
GetDeltaTimer()._funcUpdate = AppUpdate
GetDeltaTimer()._funcRender = AppRender


Function AppUpdate:Int()
	If KeyHit(KEY_ESCAPE) Then AppExit = True
	
	Select gameScreen
		case EGameScreens.Game
			ScreenGameUpdate()
	End Select
End Function

Function AppRender:Int()
	Cls

	Select gameScreen
		case EGameScreens.Game
			ScreenGameRender()
	End Select

	Flip 0
End Function



'=== GAME LOGIC ===
Function ScreenGameUpdate:Int()
	For Local entity:TGameEntity = EachIn gameEntities.Values()
		entity.Update()
	Next
End Function


Function ScreenGameRender:Int()
	For Local renderable:IRenderable = EachIn gameEntities.Values()
		renderable.Render()
	Next
End Function




Repeat
	GetDeltaTimer().Loop()
Until AppTerminate() or AppExit

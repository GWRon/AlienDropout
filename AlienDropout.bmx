SuperStrict
Framework SDL.SDLRenderMax2D
Import "source/framework/base.util.deltatimer.bmx"
Import "source/game.entities.bmx"
Import "source/game.world.bmx"
Import Brl.ObjectList

'=== SETUP GRAPHICS / WINDOW ===
Graphics 800,600,0,0, SDL_WINDOW_RESIZABLE | GRAPHICS_SWAPINTERVAL1



'=== GAME GLOBALS ===
Enum EGameScreens
	Start
	Game
	Highscore
End Enum

Global appExit:Int = False
Global gameScreen:EGameScreens = EGameScreens.Start 'start right in the game
'all "game screen" entities "managed" by the game(screen)
Global gameScreenEntities:TObjectList = New TObjectList



'=== PREPARE GAME LOOP ===
GetDeltatimer().Init(60, 60) '60 UPS, 60 FPS
GetDeltaTimer()._funcUpdate = AppUpdate
GetDeltaTimer()._funcRender = AppRender


Function AppUpdate:Int()
	If KeyHit(KEY_ESCAPE) Then AppExit = True
	
	Select gameScreen
		case EGameScreens.Start
			'for now: init new game and move to game
			StartGame()
			gameScreen = EGameScreens.Game
		
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
Function StartGame:Int()
	gameScreenEntities.Clear()
	Local gameWorld:TGameWorld = New TGameWorld
	
	gameScreenEntities.AddLast(gameWorld)

End Function


Function ScreenGameUpdate:Int()
	For Local entity:TGameEntity = EachIn gameScreenEntities
		entity.Update()
	Next
End Function


Function ScreenGameRender:Int()
	For Local entity:TGameEntity = EachIn gameScreenEntities
		entity.Render()
	Next
End Function




Repeat
	GetDeltaTimer().Loop()
Until AppTerminate() or AppExit

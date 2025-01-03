SuperStrict
Framework SDL.SDLRenderMax2D
Import "source/framework/base.util.deltatimer.bmx"
Import "source/game.globals.bmx"
Import "source/game.entities.bmx"
Import "source/game.world.bmx"
Import "source/game.hud.bmx"


'=== SETUP GRAPHICS / WINDOW ===
Graphics 800,600,0,0, SDL_WINDOW_RESIZABLE | GRAPHICS_SWAPINTERVAL1
SetVirtualResolution(APP_WIDTH, APP_HEIGHT) 'resize properly
SetBlend AlphaBlend



'=== PREPARE GAME LOOP ===
GetDeltatimer().Init(60, -1) '60 UPS, 60 FPS
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
	SetColor 255,255,255

	Select gameScreen
		case EGameScreens.Game
			ScreenGameRender()
	End Select

	Flip 1
End Function



'=== GAME LOGIC ===
Function StartGame:Int()
	gameScreenEntities.Clear()
	Local gameWorld:TGameWorld = New TGameWorld
	'20 on top for hud
	gameWorld.area = New SRectI(0, 50, APP_WIDTH, APP_HEIGHT - 50)
	gameWorld.Init()

	'20 on top for hud
	Local gameHUD:TGameHUD = New TGameHUD
	gameHUD.area = New SRectI(0, 0, APP_WIDTH, 50)

	gameScreenEntities.AddLast(gameWorld)
	gameScreenEntities.AddLast(gameHUD)
End Function


Function ScreenGameUpdate:Int()
	For Local entity:TGameEntity = EachIn gameScreenEntities
		entity.Update( GetDeltaTimer().GetDelta() )
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

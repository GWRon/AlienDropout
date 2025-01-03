SuperStrict
Import Brl.ObjectList

'=== GAME GLOBALS ===

Global APP_HEIGHT:INT = 600
Global APP_WIDTH:INT = 800

Enum EGameScreens
	Start
	Game
	Highscore
End Enum

Global appExit:Int = False
Global gameScreen:EGameScreens = EGameScreens.Start 'start right in the game
'all "game screen" entities "managed" by the game(screen)
Global gameScreenEntities:TObjectList = New TObjectList

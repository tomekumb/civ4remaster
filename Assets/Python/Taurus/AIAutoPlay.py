# trs.autoplay: Just the core functionality, adopted from AdvCiv.
# Most comments, including attribution (see AIAutoPlay.xml for that), deleted.

from CvPythonExtensions import *
import BugEventManager
import CvScreenEnums
import CvUtil
import PyHelpers
import Popup as PyPopup

gc = CyGlobalContext()
game = CyGame()
localText = CyTranslator()

class AIAutoPlay :

	def __init__(self, eventManager) :
		self.DefaultTurnsToAuto = 1

		self.em = eventManager

		self.em.addEventHandler( 'BeginPlayerTurn', self.onBeginPlayerTurn )
		self.em.addEventHandler( 'EndPlayerTurn', self.onEndPlayerTurn )
		self.em.addEventHandler( 'victory', self.onVictory )

		self.em.setPopupHandler( 7050, ["toAIChooserPopup", self.AIChooserHandler,self.blankHandler] )
		# Keep game from showing messages about handling this popup
		CvUtil.SilentEvents.extend([7050])

		try :
			self.em.removeEventHandler( "cityBuilt", self.em.onCityBuilt )
			self.em.addEventHandler( "cityBuilt", self.onCityBuilt )
		except ValueError :
			self.em.setEventHandler( "cityBuilt", self.onCityBuilt )

		try :
			self.em.removeEventHandler( "BeginGameTurn", self.em.onBeginGameTurn )
			self.em.addEventHandler( "BeginGameTurn", self.onBeginGameTurn )
		except ValueError :
			self.em.setEventHandler( "BeginGameTurn", self.onBeginGameTurn )


	def removeEventHandlers( self ) :
		self.em.removeEventHandler( 'BeginPlayerTurn', self.onBeginPlayerTurn )
		self.em.removeEventHandler( 'EndPlayerTurn', self.onEndPlayerTurn )
		self.em.removeEventHandler( 'victory', self.onVictory )

		self.em.setPopupHandler( 7050, ["toAIChooserPopup",self.blankHandler,self.blankHandler] )

		self.em.removeEventHandler( "cityBuilt", self.onCityBuilt )
		self.em.addEventHandler( "cityBuilt", self.em.onCityBuilt )
		self.em.removeEventHandler( "BeginGameTurn", self.onBeginGameTurn )
		self.em.addEventHandler( "BeginGameTurn", self.em.onBeginGameTurn )

	def blankHandler( self, playerID, netUserData, popupReturn ) :
		return # Dummy handler to take the second event for popup

	def onVictory( self, argsList ) :
		self.reEnableHuman()

	def onBeginPlayerTurn( self, argsList ) :
		iGameTurn, iPlayer = argsList

		if( game.getAIAutoPlay() == 1 and iPlayer > game.getActivePlayer() and gc.getActivePlayer().isAlive() ) :
			return

		elif( game.getAIAutoPlay() <= 0 and not gc.getActivePlayer().isAlive() and iPlayer > game.getActivePlayer() ) :
			self.reEnableHuman()

	def onEndPlayerTurn( self, argsList ) :
		iGameTurn, iPlayer = argsList

		turnsLeft = game.getAIAutoPlay()
		if turnsLeft > 1:
			return
		# Find the closest player preceding the disabled human in the turn order
		# (normally the barbarians)
		disabledHuman = game.getActivePlayer()
		if gc.getPlayer(disabledHuman).isHuman():
			return
		preceding = iPlayer
		turnsLeftTarget = 0
		m = gc.getMAX_PLAYERS()
		for x in range(disabledHuman - 1, disabledHuman - m, -1):
			y = x % m
			if gc.getPlayer(y).isAlive():
				preceding = y
				break
		if preceding > disabledHuman:
			# This wrap-around check doesn't work correctly with simultaneous turns;
			# I guess b/c multiple players execute it.
			if not game.isMPOption(MultiplayerOptionTypes.MPOPTION_SIMULTANEOUS_TURNS):
				turnsLeftTarget = 1
		if turnsLeft <= turnsLeftTarget and iPlayer == preceding:
			self.reEnableHuman()

	def reEnableHuman( self ): # (replacing more complex "checkPlayer" method)
		game.setAIAutoPlay(-1)
		pPlayer = gc.getActivePlayer()
		if( not pPlayer.isHuman() ) :
			game.setActivePlayer( pPlayer.getID(), False )
			pPlayer.setIsHuman( True )

	def onBeginGameTurn( self, argsList):
		iGameTurn = argsList[0]
		if (game.getAIAutoPlay() <= 0):
			self.em.onBeginGameTurn(argsList)

	def onCityBuilt(self, argsList):
		city = argsList[0]
		if (game.getAIAutoPlay() <= 0):
			self.em.onCityBuilt(argsList)


	def toAIChooser( self ) :
		screen = CyGInterfaceScreen( "MainInterface", CvScreenEnums.MAIN_INTERFACE )
		xResolution = screen.getXResolution()
		yResolution = screen.getYResolution()
		popupSizeX = 400
		popupSizeY = 250

		popup = PyPopup.PyPopup(7050, contextType = EventContextTypes.EVENTCONTEXT_ALL)
		popup.setPosition((xResolution - popupSizeX )/2, (yResolution-popupSizeY)/2-50)
		popup.setSize(popupSizeX,popupSizeY)
		popup.setHeaderString( localText.getText("TXT_KEY_AIAUTOPLAY_TURN_ON", ()) )
		popup.setBodyString( localText.getText("TXT_KEY_AIAUTOPLAY_TURNS", ()) )
		popup.addSeparator()
		popup.createPythonEditBox( '%d'%(self.DefaultTurnsToAuto), 'Number of turns to turn over to AI', 0)
		popup.setEditBoxMaxCharCount( 4, 2, 0 )

		popup.addSeparator()
		popup.addButton("OK")
		popup.addButton(localText.getText("TXT_KEY_POPUP_CANCEL", ()))

		popup.launch(False, PopupStates.POPUPSTATE_IMMEDIATE)

	def AIChooserHandler( self, playerID, netUserData, popupReturn ) :
		if( popupReturn.getButtonClicked() == 1 ):
			return

		self.numTurns = 0
		if( popupReturn.getEditBoxString(0) != '' ) :
			self.numTurns = int( popupReturn.getEditBoxString(0) )

		if( self.numTurns > 0 ) :
			game.setAIAutoPlay(self.numTurns)


aiplay = None

def init():
	global aiplay
	aiplay = AIAutoPlay(BugEventManager.g_eventManager)


def launchAIAutoPlayDialog(argsList=None):
	if getChtLvl() <= 0 or (
			game.getActivePlayer() != PlayerTypes.NO_PLAYER and
			gc.getPlayer(game.getActivePlayer()).getAdvancedStartPoints() > 0):
		return
	if game.getAIAutoPlay() > 0:
		game.setAIAutoPlay(-1) # Signaling to Civ4lerts that Auto Play has just ended
		aiplay.reEnableHuman()
	else:
		aiplay.toAIChooser()

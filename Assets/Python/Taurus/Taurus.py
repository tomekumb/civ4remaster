# trs. So far, used only as glue between Config/Taurus.xml and the DLL.

from CvPythonExtensions import *
import CvUtil
import BugPath

gc = CyGlobalContext()

# trs.balloon: (for Taurus__PlotIndicatorSize option)
def updatePlotIndicatorSize(option, value):
	cyUpdatePlotIndicatorSize()

# trs.camdist:
def updateDefaultCamDistance(option, value):
	gc.updateDefaultCamDistance()

# trs.camSpeed:
def updateCamScrollSpeed(option, value):
	gc.updateCamScrollSpeed()

# trs.modname:
def exportSaveGame(argsList):
	gc.getGame().exportSaveGame()

# trs.wcitybars:
def updateCityBarWidth(option, value):
	gc.getGame().setCityBarWidth(value)

# trs.cheats (from AdvCiv):
def toggleDebugMode(argsList=None): 
	# The built-in shortcut (also Ctrl+Z) in the EXE only works if ChtLvl>0.
	# Let the DLL decide whether ChtLvl should matter.
	if getChtLvl() <= 0:
		gc.getGame().toggleDebugMode()

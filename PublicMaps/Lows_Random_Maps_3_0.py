#
#   FILE: lowRandom.py v5 by low
#-----------------------------------------------------------------------------

'''
v3 was going to be the final script, but after a couple of weeks of several games and map generations
I have decided to remove the tiny islands. I really, really dislike those map types and I know I'm not
alone on that. Sorry. Also, after a few archipelago maps I've dicovered a small problem that nobody
has yet brought to my attention. Too many mountain peeks were seperating the islands making the other
half of an island unexplorable until sailing. I've included the fix for that. Peeks should no longer
seperate archipelago islands. I have also removed the max sea level definition. This makes games much more
interesting if playing with more than the default number of civs on a particular map size and a high sea
level is generated. This should be it now.

Updated 11-10-06 
With the release of Warlords, a needed patch, and some great mods, I've returned to Civ4 after many months away. I've fixed the problem with "Top Civs" screen simply by renaiming the file.  This is it. Enjoy.

'''

from CvPythonExtensions import *
import CvUtil
import CvMapGeneratorUtil
from CvMapGeneratorUtil import FractalWorld
from CvMapGeneratorUtil import TerrainGenerator
from CvMapGeneratorUtil import FeatureGenerator

def getDescription():
	return "Random map (Pangaea, Continents, Archipelago)"

def getNumCustomMapOptions():
	return 1
	
def getCustomMapOptionName(argsList):
	translated_text = unicode(CyTranslator().getText("TXT_KEY_MAP_SCRIPT_LANDMASS_TYPE", ()))
	return translated_text

def getNumCustomMapOptionValues(argsList):
	return 1
	
def getCustomMapOptionDescAt(argsList):
	iSelection = argsList[1]
	selection_names = ["TXT_KEY_MAP_SCRIPT_RANDOM"]
	translated_text = unicode(CyTranslator().getText(selection_names[iSelection], ()))
	return translated_text
	
def getCustomMapOptionDefault(argsList):
	return -1

def isRandomCustomMapOption(argsList):
	return false
 
def generatePlotTypes():
	gc = CyGlobalContext()
	map = CyMap()
	dice = gc.getGame().getMapRand()
	fractal_world = FractalWorld()

	userInputLandmass = map.getCustomMapOption(0)
	if userInputLandmass == 0:
		random = True
		terrainRoll = dice.get(12, "")
		if terrainRoll < 3:
			land_type = 0
		elif terrainRoll < 6:
			land_type = 1
		elif terrainRoll < 9:
			land_type = 2
		else:
			land_type = 3

	else: 
		if userInputLandmass > 1:
			land_type = userInputLandmass
		else:
			continentRoll = dice.get(4, "")
			if continentRoll > 1:
				land_type = 1
			else:
				land_type = 0

	if land_type == 2: ### small continents
		fractal_world.initFractal(continent_grain = 3, rift_grain = 2, has_center_rift = True, polar = True)
		return fractal_world.generatePlotTypes(grain_amount = 4)
		
	elif land_type == 3: ### archipelago
		fractal_world.initFractal(continent_grain = 4, rift_grain = -1, has_center_rift = False, polar = True)
		return fractal_world.generatePlotTypes(grain_amount = 4)
		
	elif land_type == 0: ### pangaea
		fractal_world.initFractal(continent_grain = 1, rift_grain = -1, has_center_rift = False, polar = True)
		return fractal_world.generatePlotTypes(grain_amount = 4)
	
	else: ### large continents
		fractal_world.initFractal(rift_grain = 2, has_center_rift = True, polar = True)
		return fractal_world.generatePlotTypes(grain_amount = 4)

class TerrainGenerator(CvMapGeneratorUtil.TerrainGenerator):
	def __init__(self, iDesertPercent=25, iPlainsPercent=35, 
	             fSnowLatitude=0.75, fTundraLatitude=0.6,
	             fGrassLatitude=0.1, fDesertBottomLatitude=0.15, 
	             fDesertTopLatitude=0.3, fracXExp=-1, 
	             fracYExp=-1, grain_amount=4):
		
		self.gc = CyGlobalContext()
		self.map = CyMap()

		self.iWidth = self.map.getGridWidth()
		self.iHeight = self.map.getGridHeight()

		self.mapRand = self.gc.getGame().getMapRand()
		self.iFlags = self.map.getMapFractalFlags()

		self.grain_amount = grain_amount + self.gc.getWorldInfo(self.map.getWorldSize()).getTerrainGrainChange()

		self.deserts=CyFractal()
		self.plains=CyFractal()
		self.variation=CyFractal()

		self.iDesertTopPercent = 100
		self.iDesertBottomPercent = max(0,int(100-iDesertPercent))
		self.iPlainsTopPercent = 100
		self.iPlainsBottomPercent = max(0,int(100-iDesertPercent-iPlainsPercent))
		self.iMountainTopPercent = 75
		self.iMountainBottomPercent = 60

		self.fSnowLatitude = fSnowLatitude
		self.fTundraLatitude = fTundraLatitude
		self.fGrassLatitude = fGrassLatitude
		self.fDesertBottomLatitude = fDesertBottomLatitude
		self.fDesertTopLatitude = fDesertTopLatitude

		self.iDesertPercent = iDesertPercent
		self.iPlainsPercent = iPlainsPercent

		self.fracXExp = fracXExp
		self.fracYExp = fracYExp

		self.initFractals()
	    	
def generateTerrainTypes():
	NiTextOut("Generating Terrain ...")
	terraingen = TerrainGenerator()
	terrainTypes = terraingen.generateTerrain()
	return terrainTypes

def addFeatures():
	map = CyMap()
	iW = map.getGridWidth()
	iH = map.getGridHeight()
	for plotIndex in range(iW * iH):
		pPlot = map.plotByIndex(plotIndex)
		if pPlot.isPeak() and pPlot.isCoastalLand():
			pPlot.setPlotType(PlotTypes.PLOT_HILLS, true, true)
	
	NiTextOut("Adding Features ...")
	featuregen = FeatureGenerator()
	featuregen.addFeatures()
	return 0

def normalizeRemoveBadTerrain():
	return None

def normalizeStartingPlotLocations():
	return None

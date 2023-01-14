#
#	FILE:	 Ring World.py
#	AUTHOR:  Ruff_Hi
#    - Civilization Fanatics (http://forums.civfanatics.com/member.php?u=64034)
#    - Deviant Minds (http://deviantminds.us/forum/memberlist.php?mode=viewprofile&u=8)
#    - Realms Beyond (http://realmsbeyond.net/forums/member.php?u=555)
#    - Ruff_Hi at yahoo dot com
#	PURPOSE: Regional map script
#-----------------------------------------------------------------------------
#	Copyright (c) 2008 Ruff_Hi. All rights reserved.
#-----------------------------------------------------------------------------
#
#	This map is based on Larry Niven's Ring World.  http://en.wikipedia.org/wiki/Ringworld
#
#   This map script constructs a long skinny map that is only 12 tiles high.
#	Note that the map wraps left to right so Civ4 puts ice caps on the top and bottom.
#   The width of the map depends upon the size selected by the user.
#   The top and bottom 4 tiles of the map are water
#   The other 4 tiles form the 'land' section and will be land or water based on a user selection
#
#	The user has two options: land density and region strength
#
#	Land Density
#		Solid - The 'land' section is all land
#		Semi-solid - The 'land' section is land with some water
#		Large Islands - The 'land' section has some water so that large islands are formed
#		Small Islands - The 'land' section has more water so that small islands are formed
#		Land / Water mix - The 'land' section is a mixture of water and land
#
#	Regions
#		There are 4 regions in the map: underlying, plains, desert, hills
#		The user can designate how strongly regional the map is.
#		Options include:
#			Zero
#			Weak
#			Moderate
#			Strong
#			Extreme


from CvPythonExtensions import *
import CvUtil
import CvMapGeneratorUtil
import sys
from CvMapGeneratorUtil import FractalWorld
from CvMapGeneratorUtil import HintedWorld
from CvMapGeneratorUtil import TerrainGenerator
from CvMapGeneratorUtil import FeatureGenerator

def getDescription():
	return "Ring World Map"

def getNumCustomMapOptions():
	return 2
	
def getNumHiddenCustomMapOptions():
	return 1
	
def getCustomMapOptionName(argsList):
	[iOption] = argsList
	option_names = {
		0:	"Land Density",
		1:	"Region Strength"
		}
	translated_text = unicode(CyTranslator().getText(option_names[iOption], ()))
	return translated_text
	
def getNumCustomMapOptionValues(argsList):
	[iOption] = argsList
	option_values = {
		0:	5,
		1:	5
		}
	return option_values[iOption]
	
def getCustomMapOptionDescAt(argsList):
	[iOption, iSelection] = argsList

	selection_names = {
		0:	{
			0: "Solid: All land 4 tiles wide",
			1: "Semi-solid: Most land 4 tiles wide",
			2: "Large Islands",
			3: "Small Islands",
			4: "Land / Water mix"
			},
		1:	{
			0: "Zero",
			1: "Weak",
			2: "Moderate",
			3: "Strong",
			4: "Extreme"
			},
		}

	translated_text = unicode(CyTranslator().getText(selection_names[iOption][iSelection], ()))
	return translated_text


def getCustomMapOptionDefault(argsList):
	[iOption] = argsList
	option_defaults = {
		0:	1,
		1:	2
		}
	return option_defaults[iOption]

def isRandomCustomMapOption(argsList):
	[iOption] = argsList
	option_random = {
		0:	true,
		1:	false,
		2:  false
		}
	return option_random[iOption]

def isAdvancedMap():
	"This map should not show up in simple mode"
	return 1

def isSeaLevelMap():
	return 0

def getWrapX():
	return true
	
def getWrapY():
	return false
	
def getTopLatitude():
	return 80
def getBottomLatitude():
	return -80
	
def minStartingDistanceModifier():
	return -65

def beforeGeneration():
	global team_num
	team_num = []
	team_index = 0

	for teamCheckLoop in range(18):
		if CyGlobalContext().getTeam(teamCheckLoop).isEverAlive():
			team_num.append(team_index)
			team_index += 1
		else:
			team_num.append(-1)
	return None

def getGridSize(argsList):
	"Different grids, depending on the choice of Team Placement. Very small worlds."
	if (argsList[0] == -1): # (-1,) is passed to function on loads
		return []

	grid_sizes = {WorldSizeTypes.WORLDSIZE_DUEL:		( 7,3),
	              WorldSizeTypes.WORLDSIZE_TINY:		(12,3),
	              WorldSizeTypes.WORLDSIZE_SMALL:		(20,3),
	              WorldSizeTypes.WORLDSIZE_STANDARD:	(30,3),
	              WorldSizeTypes.WORLDSIZE_LARGE:		(52,3),
	              WorldSizeTypes.WORLDSIZE_HUGE:		(80,3)
	}

	[eWorldSize] = argsList
	return grid_sizes[eWorldSize]

def generatePlotTypes():
	NiTextOut("Setting Plot Types (Python Ring_World) ...")
	global hinted_world, mapRand
	global fractal_world
	gc = CyGlobalContext()
	map = CyMap()
	mapRand = gc.getGame().getMapRand()

	hinted_world = HintedWorld()

	iNumPlotsX = map.getGridWidth()
	iNumPlotsY = map.getGridHeight()

	# Set the top and bottom two tiles to ocean, others to land
	for x in range(iNumPlotsX):
		for y in range(iNumPlotsY):
			if (y <= 3
			or  y >= 8):
				hinted_world.setValue(x,y,0) # ocean
			else:
				hinted_world.setValue(x,y,255) # land

	hinted_world.buildAllContinents()
	plotTypes = hinted_world.generatePlotTypes(water_percent = 0)

	# fix the water and land mix
	for x in range(iNumPlotsX):
		for y in range(iNumPlotsY):
			i = map.plotNum(x, y)
			if (y <= 3
			or  y >= 8):
				if plotTypes[i] != PlotTypes.PLOT_OCEAN:
					plotTypes[i] = PlotTypes.PLOT_OCEAN
			else:
				if plotTypes[i] != PlotTypes.PLOT_LAND:
					plotTypes[i] = PlotTypes.PLOT_LAND

	# Templates are nested by keys: [Land Density, Number of Land tiles]}
	Land_Template = {0: [100.0,100.0,100.0,100.0,100.0],
					 1: [ 70.0, 80.0, 90.0,100.0,100.0],
					 2: [ 40.0, 60.0, 80.0, 90.0,100.0],
					 3: [ 10.0, 20.0, 40.0, 60.0,100.0],
					 4: [ 20.0, 40.0, 60.0, 80.0,100.0]
					}

	userInputPlots = map.getCustomMapOption(0)
	dice = gc.getGame().getMapRand()

	# fix the water and land mix
	for x in range(iNumPlotsX):

		iRand = dice.get(100, "Shuffling Land 1 - TBG PYTHON")
		iNumWater = 0
		while iRand > Land_Template[userInputPlots][iNumWater]:
			print "iRand %i iNumWater %i template %i" % (iRand, iNumWater, Land_Template[userInputPlots][iNumWater])
			iNumWater += 1

		print "iRand %i iNumWater %i" % (iRand, iNumWater)

		if iNumWater == 0:
			# no water tile
			iRand = dice.get(2, "Shuffling Land 2 - TBG PYTHON")

		elif iNumWater == 1:
			# only 1 water tile
			# tiles can be WLLL or LLLW
			iRand = dice.get(2, "Shuffling Land 2a - TBG PYTHON")
			if iRand == 0: # WLLL
				i = map.plotNum(x, 4)
				plotTypes[i] = PlotTypes.PLOT_OCEAN
			else: # LLLW
				i = map.plotNum(x, 7)
				plotTypes[i] = PlotTypes.PLOT_OCEAN

		elif iNumWater == 2:
			# 2 water tiles
			# tiles can be WWLL, LLWW or WLLW
			iRand = dice.get(3, "Shuffling Land 2b - TBG PYTHON")
			if iRand == 0: # WWLL
				i = map.plotNum(x, 4)
				plotTypes[i] = PlotTypes.PLOT_OCEAN
				i = map.plotNum(x, 5)
				plotTypes[i] = PlotTypes.PLOT_OCEAN
			elif iRand == 1: # WLLW
				i = map.plotNum(x, 4)
				plotTypes[i] = PlotTypes.PLOT_OCEAN
				i = map.plotNum(x, 7)
				plotTypes[i] = PlotTypes.PLOT_OCEAN
			else: # LLWW
				i = map.plotNum(x, 6)
				plotTypes[i] = PlotTypes.PLOT_OCEAN
				i = map.plotNum(x, 7)
				plotTypes[i] = PlotTypes.PLOT_OCEAN

		else:
			# either 3 or 4 water tiles
			# set all to water and then set 1 back to land if required
			i = map.plotNum(x, 4)
			plotTypes[i] = PlotTypes.PLOT_OCEAN
			i = map.plotNum(x, 5)
			plotTypes[i] = PlotTypes.PLOT_OCEAN
			i = map.plotNum(x, 6)
			plotTypes[i] = PlotTypes.PLOT_OCEAN
			i = map.plotNum(x, 7)
			plotTypes[i] = PlotTypes.PLOT_OCEAN

			if iNumWater == 3:
				# 3 water tiles
				# tiles can be WWWL, WWLW, WLWW or LWWW
				iRand = dice.get(4, "Shuffling Land 2c - TBG PYTHON")
				if iRand == 0: # WWWL
					i = map.plotNum(x, 7)
					plotTypes[i] = PlotTypes.PLOT_LAND
				elif iRand == 1: # WWLW
					i = map.plotNum(x, 6)
					plotTypes[i] = PlotTypes.PLOT_LAND
				elif iRand == 2: # WLWW
					i = map.plotNum(x, 5)
					plotTypes[i] = PlotTypes.PLOT_LAND
				else: # LWWW
					i = map.plotNum(x, 4)
					plotTypes[i] = PlotTypes.PLOT_LAND

#		calc regional density
#	this calculation determines the probability of a tile at location x being desert, plains or hills
#	the map is broken into 4 regions: no feature (let map scrip decide), desert, plains, hills
#	the desert strength starts at 0 at tile x = 0 x width / 4 + 1  and increases linearly to maximum at tile x = 1 x width / 4
#	  at which point it starts to decrease back to zero at x = 2 x width / 4
#	the plains strength starts at 0 at tile x = 1 x width / 4 + 1 and increases linearly to maximum at tile x = 2 x width / 4
#	  at which point it starts to decrease back to zero at x = 3 x width / 4
#	the hills  strength starts at 0 at tile x = 2 x width / 4 + 1 and increases linearly to maximum at tile x = 3 x width / 4
#	  at which point it starts to decrease back to zero at x = 4 x width / 4

#	the iRegionW (region weight) controls the overall strength of the regionality and is user controlled.
#	A setting of 0 means that no regionality takes place and the balance of the map script does what it does
#	A setting of weak (20) means that each tile has a maximum change of 20% of being adjusted, if not adjusted, then the map script does what it does
#	A setting of moderate (40) means that each tile has a maximum change of 40% of being adjusted, if not adjusted, then the map script does what it does
#	etc ...

#	Region Density
		Region_Template = [0.0, 30.0, 60.0, 90.0, 120.0]

		userRegionDensity = map.getCustomMapOption(1)
		iRegionW = Region_Template[userRegionDensity]
		iW4 = iNumPlotsX / 4

		iDesert =           iRegionW * max(0, 1 - float(abs(x - 1 * iW4)) / float(iW4))
		iPlains = iDesert + iRegionW * max(0, 1 - float(abs(x - 2 * iW4)) / float(iW4))
		iHills  = iPlains + iRegionW * max(0, 1 - float(abs(x - 3 * iW4)) / float(iW4))

#		loop over land tiles and change to hill if required
		for y in range(4, 7):
			i = map.plotNum(x, y)
			
			if plotTypes[i] == PlotTypes.PLOT_LAND:
				iRand = dice.get(100, "Region Determination 1 - TBG PYTHON")
				if (iRand > iPlains
				and iRand <= iHills):
					plotTypes[i] = PlotTypes.PLOT_HILLS

	return plotTypes

class TeamBGTerrainGenerator(CvMapGeneratorUtil.TerrainGenerator):
	def generateTerrainAtPlot(self, iX, iY):

		if (self.map.plot(iX, iY).isWater()):
			return self.map.plot(iX, iY).getTerrainType()

		map = CyMap()
		gc = CyGlobalContext()
		dice = gc.getGame().getMapRand()

		iNumPlotsX = map.getGridWidth()
		i = map.plotNum(iX, iY)

		terrainVal = self.terrainGrass

	#	calc region type density - see description above
		Region_Template = [0.0, 30.0, 60.0, 90.0, 120.0]

		userRegionDensity = map.getCustomMapOption(1)
		iRegionW = Region_Template[userRegionDensity]
		iW4 = iNumPlotsX / 4

		iDesert =           iRegionW * max(0, 1 - float(abs(iX - 1 * iW4)) / float(iW4))
		iPlains = iDesert + iRegionW * max(0, 1 - float(abs(iX - 2 * iW4)) / float(iW4))
		iHills  = iPlains + iRegionW * max(0, 1 - float(abs(iX - 3 * iW4)) / float(iW4))

		iRand = dice.get(100, "Region Determination 2 - TBG PYTHON")
		print "iRand %i iDesert %i iPlains %i iHills %i" % (iRand, iDesert, iPlains, iHills)

		if iRand <= iDesert:
			terrainVal = self.terrainDesert
		elif iRand <= iPlains:
			terrainVal = self.terrainPlains
	#	calc region type density - see description above

		if (terrainVal == TerrainTypes.NO_TERRAIN):
			return self.map.plot(iX, iY).getTerrainType()

		return terrainVal

def generateTerrainTypes():
	NiTextOut("Generating Terrain (Python Ring_World) ...")
	terraingen = TeamBGTerrainGenerator()
	terraingen.__init__(iDesertPercent=15)
	terrainTypes = terraingen.generateTerrain()
	return terrainTypes

class TeamBGFeatureGenerator(CvMapGeneratorUtil.FeatureGenerator):
	def getLatitudeAtPlot(self, iX, iY):
		"returns a value in the range of 0.0 (tropical) to 1.0 (polar)"
		return 0.8 * (abs((self.iGridH/2) - iY)/float(self.iGridH/2))

def addFeatures():
	NiTextOut("Adding Features (Python Ring_World) ...")
	featuregen = TeamBGFeatureGenerator()
	featuregen.addFeatures()
	return 0

def assignStartingPlots():
	gc = CyGlobalContext()

	CyPythonMgr().allowDefaultImpl()
	
def findStartingPlot(argsList):
	[playerID] = argsList

	def isValid(playerID, x, y):

		return true

	return CvMapGeneratorUtil.findStartingPlot(playerID, isValid)

def normalizeStartingPlotLocations():

	return None

def getRiverStartCardinalDirection(argsList):
	"Returns the cardinal direction of the first river segment."
	pPlot = argsList[0]

	CyPythonMgr().allowDefaultImpl()

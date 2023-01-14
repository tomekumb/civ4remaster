## BugMapOptionsTab
##
## Tab for the BUG Map Options.
##
## Copyright (c) 2009 The BUG Mod.
##
## Author: EmperorFool

import BugOptionsTab

class BugMapOptionsTab(BugOptionsTab.BugOptionsTab):
	"BUG Nap Options Screen Tab"
	
	def __init__(self, screen):
		BugOptionsTab.BugOptionsTab.__init__(self, "Map", "Map")

	def create(self, screen):
		tab = self.createTab(screen)
		panel = self.createMainPanel(screen)
		column = self.addOneColumnLayout(screen, panel)
		
		left, center, right = self.addThreeColumnLayout(screen, column, "Top", True)
		# trs. Since there is no four-column layout ...
		leftL, leftR = self.addTwoColumnLayout(screen, left, "MapOverlays", True)
		self.createStrategyLayerPanel(screen, leftL) # trs. Was (screen, left).
		self.createOtherLayersPanel(screen, leftR) # trs. New panel.
		self.createCityBarPanel(screen, center)
		self.createTileHoverPanel(screen, center)
		# <trs>
		self.createCameraPanel(screen, right)
		self.addSpacer(screen, right, "BetweenCameraAndMisc") # </trs.>
		self.createMiscellaneousPanel(screen, right)
		
		screen.attachHSeparator(column, column + "Sep1")
		self.createCityTileStatusPanel(screen, column)

		# trs.savtab: Moved to Saves tab
		#screen.attachHSeparator(column, column + "Sep2")
		#self.createMapFinderPanel(screen, column)
		
	def createStrategyLayerPanel(self, screen, panel):
		self.addLabel(screen, panel, "StrategyOverlay", "Strategy Layer:")
		self.addCheckbox(screen, panel, "StrategyOverlay__Enabled")
		self.addCheckbox(screen, panel, "StrategyOverlay__ShowDotMap")
		self.addCheckbox(screen, panel, "StrategyOverlay__DotMapDrawDots")
		# trs. Don't have room for two columns in here anymore
		#left, right = self.addTwoColumnLayout(screen, panel, "DotMapBrightness")
		#self.addTextEdit(screen, panel, panel, "StrategyOverlay__DotMapDotIcon")

		# trs. Was labelPanel=left, controlPanel=right in both calls
		# (and in the addTextEdit above, which was already commented out).
		# stacked=True param added to put the labels on a separate line.
		self.addSlider(screen, panel, panel,
				"StrategyOverlay__DotMapBrightness",
				False, False, False, "up", 0, 100, True)
		self.addSlider(screen, panel, panel,
				"StrategyOverlay__DotMapHighlightBrightness",
				False, False, False, "up", 0, 100, True)

	# trs. For map overlays (broadly speaking) other than the DotMap.
	# Might add more here in the future.
	def createOtherLayersPanel(self, screen, panel):
		self.addLabel(screen, panel, "MapLayers")
		# <trs.balloon>
		self.addTextDropdown(screen, panel, panel, "Taurus__PlotIndicatorSize")
		self.addTextDropdown(screen, panel, panel, "Taurus__OffScreenUnitSizeMult")
		# </trs.balloon>
		# trs.start-with-resources:
		self.addCheckbox(screen, panel, "Taurus__StartWithResourceDisplay")
		self.addCheckbox(screen, panel, "Taurus__FoundingYields") # trs.found-yield
		self.addTextDropdown(screen, panel, panel, "Taurus__FoundingBorder") # trs.found.border
		
	def createCityBarPanel(self, screen, panel):
		self.addLabel(screen, panel, "CityBar", "CityBar:")
		self.addCheckbox(screen, panel, "Taurus__WideCityBars") # trs.wcitybars
		self.addCheckbox(screen, panel, "CityBar__AirportIcons")
		self.addCheckbox(screen, panel, "CityBar__StarvationTurns")
		
	def createTileHoverPanel(self, screen, panel):
		self.addLabel(screen, panel, "TileHover", "Tile Hover:")
		self.addCheckbox(screen, panel, "MiscHover__PlotWorkingCity")
		self.addCheckbox(screen, panel, "MiscHover__PlotRecommendedBuild")
		self.addCheckbox(screen, panel, "MiscHover__PartialBuilds")
		self.addCheckbox(screen, panel, "MiscHover__LatLongCoords")

	# trs.
	def createCameraPanel(self, screen, panel):
		self.addLabel(screen, panel, "Camera", "Camera:")
		# FoV options moved from Misc. panel ...
		self.addCheckbox(screen, panel, "MainInterface__FieldOfView")
		self.addCheckbox(screen, panel, "MainInterface__FieldOfView_Remember", True)
		# trs.camdist:
		self.addTextDropdown(screen, panel, panel, "Taurus__DefaultCamDistance")
		# trs.camspeed:
		self.addTextDropdown(screen, panel, panel, "Taurus__CamScrollSpeed")
		
	def createMiscellaneousPanel(self, screen, panel):
		self.addLabel(screen, panel, "Misc", "Misc:")
		# (trs. FoV options moved into a separate panel.)
		self.addCheckbox(screen, panel, "EventSigns__Enabled")
		# (trs. Remove-feature effects moved to General tab,
		# harmless Barbarians to Alerts tab.)
		
	def createCityTileStatusPanel(self, screen, panel):
		left, center, right = self.addThreeColumnLayout(screen, panel, "CityPlotsEnabled", True)
		self.addLabel(screen, left, "CityPlots", "City Tiles:")
		self.addCheckbox(screen, center, "CityBar__CityControlledPlots")
		self.addCheckbox(screen, right, "CityBar__CityPlotStatus")
		
		one, two, three, four, five = self.addMultiColumnLayout(screen, panel, 5, "CityPlotsOptions")
		self.addLabel(screen, one, "WorkingPlots", "Working:")
		self.addCheckbox(screen, two, "CityBar__WorkingImprovedPlot")
		self.addCheckbox(screen, three, "CityBar__WorkingImprovablePlot")
		self.addCheckbox(screen, four, "CityBar__WorkingImprovableBonusPlot")
		self.addCheckbox(screen, five, "CityBar__WorkingUnimprovablePlot")
		self.addLabel(screen, one, "NotWorkingPlots", "Not Working:")
		self.addCheckbox(screen, two, "CityBar__NotWorkingImprovedPlot")
		self.addCheckbox(screen, three, "CityBar__NotWorkingImprovablePlot")
		self.addCheckbox(screen, four, "CityBar__NotWorkingImprovableBonusPlot")
		self.addCheckbox(screen, five, "CityBar__NotWorkingUnimprovablePlot")

	# trs.savtab: Moved to Saves tab
	#def createMapFinderPanel(self, screen, panel): ...

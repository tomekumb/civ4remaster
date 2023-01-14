## BugGeneralOptionsTab
##
## Tab for the BUG General Options (Main and City Screens).
##
## Copyright (c) 2007-2008 The BUG Mod.
##
## Author: EmperorFool

import BugOptionsTab
import Buffy

class BugGeneralOptionsTab(BugOptionsTab.BugOptionsTab):
	"BUG General Options Screen Tab"
	
	def __init__(self, screen):
		BugOptionsTab.BugOptionsTab.__init__(self, "General", "General")

	def create(self, screen):
		tab = self.createTab(screen)
		panel = self.createMainPanel(screen)
		column = self.addOneColumnLayout(screen, panel)
		
		left, center, right = self.addThreeColumnLayout(screen, column, "Top", True)

		# <trs.noflash>
		# Moved from System tab
		self.addCheckbox(screen, left, "MainInterface__OptionsButton")
		self.createFlashHintsPanel(screen, left)
		# left and center swapped
		self.createActionsPanel(screen, left)
		# </trs.noflash>

		# trs.noflash: now center
		self.createGreatPersonGeneralPanel(screen, center)
		self.addSpacer(screen, center, "General1")
		self.createTechSplashPanel(screen, center)
		self.addSpacer(screen, center, "General2")
		self.createLeaderheadPanel(screen, center)

		# trs.savtab: Moved to Saves tab
		#self.createAutoSavePanel(screen, center)
		#self.addSpacer(screen, center, "General3")
		# trs.noflash: now left (see above)
		#self.createActionsPanel(screen, center)
		
		self.createInfoPanePanel(screen, right)
		#self.addSpacer(screen, right, "General4") # trs.promoleads: Need the space
		self.createMiscellaneousPanel(screen, right)
		if Buffy.isEnabled():
			self.addSpacer(screen, right, "General5")
			self.createBuffyPanel(screen, right)
		
	def createGreatPersonGeneralPanel(self, screen, panel):
		self.addLabel(screen, panel, "ProgressBars", "Progress Bars:")
		self.addCheckboxTextDropdown(screen, panel, panel, "MainInterface__GPBar", "MainInterface__GPBar_Types")
		#self.addCheckbox(screen, panel, "MainInterface__GPBar")
		#self.addTextDropdown(screen, panel, panel, "MainInterface__GPBar_Types", True)
		self.addCheckbox(screen, panel, "MainInterface__Combat_Counter")
		
	def createLeaderheadPanel(self, screen, panel):
		self.addLabel(screen, panel, "Leaderheads", "Leaderheads:")
		self.addCheckbox(screen, panel, "MiscHover__LeaderheadHiddenAttitude")
		self.addCheckbox(screen, panel, "MiscHover__LeaderheadWorstEnemy")
		self.addCheckbox(screen, panel, "MiscHover__LeaderheadDefensivePacts")

	# trs.savtab: Moved to Saves tab
	#def createAutoSavePanel(self, screen, panel): ...

	# trs.noflash:
	def createFlashHintsPanel(self, screen, panel):
		self.addLabel(screen, panel, "FlashHints")
		# Moved from System tab
		self.addCheckbox(screen, panel, "MainInterface__OptionsKey")
		self.addCheckbox(screen, panel, "Taurus__EndTurnFlash")
		self.addCheckbox(screen, panel, "Taurus__ExitCityFlash")
		
	def createActionsPanel(self, screen, panel):
		self.addLabel(screen, panel, "Actions", "Actions:")
		self.addCheckbox(screen, panel, "Actions__AskDeclareWarUnits")
		self.addCheckbox(screen, panel, "Actions__SentryHealing")
		self.addCheckbox(screen, panel, "Actions__SentryHealingOnlyNeutral", True)
		self.addCheckbox(screen, panel, "Actions__PreChopForests")
		self.addCheckbox(screen, panel, "Actions__PreChopImprovements")
		# <trs.> Moved from the Map tab.
		self.addCheckbox(screen, panel, "MiscHover__RemoveFeatureHealthEffects")
		self.addCheckbox(screen, panel, "MiscHover__RemoveFeatureHealthEffectsCountOtherTiles", True)
		# </trs.>
		
	def createTechSplashPanel(self, screen, panel):
		self.addLabel(screen, panel, "TechWindow", "Tech Splash Screen:")
		self.addTextDropdown(screen, panel, panel, "TechWindow__ViewType", True)
		self.addCheckbox(screen, panel, "TechWindow__CivilopediaText")
	
	def createBuffyPanel(self, screen, panel):
		self.addLabel(screen, panel, "BUFFY", "BUFFY:")
		self.addCheckbox(screen, panel, "BUFFY__WarningsDawnOfMan")
		self.addCheckbox(screen, panel, "BUFFY__WarningsSettings")
	
	def createInfoPanePanel(self, screen, panel):
		self.addLabel(screen, panel, "InfoPane", "Unit/Stack Info:")
		self.addCheckbox(screen, panel, "MainInterface__UnitMovementPointsFraction")
		self.addCheckbox(screen, panel, "MainInterface__StackMovementPoints")
		self.addCheckbox(screen, panel, "MainInterface__StackPromotions")
		left, center, right = self.addThreeColumnLayout(screen, panel, "StackPromotionColors")
		self.addCheckbox(screen, left, "MainInterface__StackPromotionCounts", True)
		self.addColorDropdown(screen, center, right, "MainInterface__StackPromotionColor", False)
		self.addColorDropdown(screen, center, right, "MainInterface__StackPromotionColorAll", False)
		
	def createMiscellaneousPanel(self, screen, panel):
		self.addLabel(screen, panel, "Misc", "Misc:")
		self.addCheckbox(screen, panel, "MainInterface__GoldRateWarning")
		self.addCheckbox(screen, panel, "MainInterface__MinMax_Commerce")
		self.addCheckbox(screen, panel, "MainInterface__ProgressBarsTickMarks")
		self.addTextDropdown(screen, panel, panel, "MainInterface__BuildIconSize", True)
		self.addCheckbox(screen, panel, "Taurus__PromotionLeadsTo") # trs.promoleads
		self.addCheckbox(screen, panel, "MainInterface__CityArrows")

# trs.savtab: New tab for options related to savegames

import BugOptionsTab

class BugSavesOptionsTab(BugOptionsTab.BugOptionsTab):

	def __init__(self, screen):
		BugOptionsTab.BugOptionsTab.__init__(self, "Saves", "Saves")

	def create(self, screen):
		tab = self.createTab(screen)
		panel = self.createMainPanel(screen)
		column = self.addOneColumnLayout(screen, panel)

		left, center, right = self.addThreeColumnLayout(screen, column, "Top", True)

		self.createCompatPanel(screen, left)
		self.createFeedbackPanel(screen, left) # trs.savmsg
		self.createStartEndPanel(screen, center)

		# Right column is unused so far
		screen.setLayoutFlag(right, "LAYOUT_RIGHT")
		screen.setLayoutFlag(right, "LAYOUT_SIZE_HPREFERREDEXPANDING")

		# MapFinder moved from Map tab
		self.addSpacer(screen, left, "AboveMapFinder")
		screen.attachHSeparator(column, column + "Sep")
		self.createMapFinderPanel(screen, column)

	def createCompatPanel(self, screen, panel):
		self.addLabel(screen, panel, "Compat")
		self.addCheckbox(screen, panel, "Taurus__SaveModName") # trs.modname
		self.addCheckbox(screen, panel, "Taurus__ModNameInReplays") # trs.replayname

	# trs.savmsg
	def createFeedbackPanel(self, screen, panel):
		self.addLabel(screen, panel, "SaveMsg")
		left, right = self.addTwoColumnLayout(screen, panel, "SaveMsg")
		self.addTextDropdown(screen, left, right, "Taurus__AutoSaveMsg")
		self.addTextDropdown(screen, left, right, "Taurus__QuickSaveMsg")

	# Cut from General tab
	def createStartEndPanel(self, screen, panel):
		self.addLabel(screen, panel, "AutoSave")
		self.addCheckbox(screen, panel, "AutoSave__CreateStartSave")
		self.addCheckbox(screen, panel, "AutoSave__CreateEndSave")
		self.addCheckbox(screen, panel, "AutoSave__CreateExitSave")
		self.addCheckbox(screen, panel, "AutoSave__UsePlayerName")

	# Cut from Map tab
	def createMapFinderPanel(self, screen, panel):
		left, right = self.addTwoColumnLayout(screen, panel, "MapFinderEnabled", True)
		self.addLabel(screen, left, "MapFinder", "MapFinder:")
		self.addCheckbox(screen, right, "MapFinder__Enabled")

		self.addTextEdit(screen, panel, panel, "MapFinder__Path")
		self.addTextEdit(screen, panel, panel, "MapFinder__SavePath")

		left, right = self.addTwoColumnLayout(screen, panel, "MapFinderOptions", True)
		leftL, leftR = self.addTwoColumnLayout(screen, left, "MapFinderDelays")
		self.addFloatDropdown(screen, leftL, leftR, "MapFinder__RegenerationDelay")
		self.addFloatDropdown(screen, leftL, leftR, "MapFinder__SkipDelay")
		self.addFloatDropdown(screen, leftL, leftR, "MapFinder__SaveDelay")

		rightL, rightR = self.addTwoColumnLayout(screen, right, "MapFinderLimits")
		self.addTextEdit(screen, rightL, rightR, "MapFinder__RuleFile")
		self.addTextEdit(screen, rightL, rightR, "MapFinder__RegenerationLimit")
		self.addTextEdit(screen, rightL, rightR, "MapFinder__SaveLimit")

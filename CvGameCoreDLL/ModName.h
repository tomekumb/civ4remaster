/*	trs.modname: Class for accessing and modifying(!) strings stored in the DLL
	and in the EXE(!) that contain the name of the folder where the mod is
	installed and its path. Regarding the path, our class only stores what
	CvDLLUtilityIFaceBase::getModName provides, and, regardless of the bFullPath
	parameter, that always seems to be a path relative to the parent folder of
	the "Mods" folder. Let's refer to that parent folder as the "root" folder.
	So the paths stored will be e.g. "Mods/Taurus". We'll still use separate
	variables for the paths returned by getModName b/c we can't be sure that the
	"full path" can't be longer under some circumstances, or the "mod name"
	just the name of the mod's folder. */
#pragma once
#ifndef MOD_NAME_H
#define MOD_NAME_H

#include "ModNameChecker.h"

class ModName : public ModNameChecker
{
public:
	ModName(char const* szFullPath, char const* szPathInRoot);
	/*	These first three getters always return the (true) names as set
		by the ctor */
	char const* getFullPath() const { return m_sFullPath.c_str(); }
	char const* getPathInRoot() const { return m_sPathInRoot.c_str(); }
	// Just the name of the mod's folder, e.g. "Taurus".
	char const* getName() const { return m_sName.c_str(); }
	/*	These three getters return the names currently stored in the EXE.
		These can temporarily, while reading or writing a savegame, differ
		from the true names. */
	char const* getExtFullPath() const { return m_pExtFullPath->GetCString(); }
	char const* getExtPathInRoot() const { return m_pExtPathInRoot->GetCString(); }
	char const* getExtName() const { return m_sExtName.c_str(); }
	bool isNameCheckOverrideKey() const { return GetKeyState('X') & 0x8000; }
	int getExtNameLengthLimit() const;
	// Replaces the name of the mod folder in the paths stored by the EXE
	void setExtModName(const char* szName,
			/*	Whether the name change should apply only until exportDone is called.
				Also, until then, setExtModName and resetExt calls will be ignored. */
			bool bExporting = false);
	void setSaving(bool b);
	bool isSaving() const { return m_bSaving; }
	bool isExporting() const { return m_bExporting; }
	// Restore the true paths in the EXE (if they've been changed)
	void resetExt();
	/*	Whether we should attempt to load savegames with the mod name
		szSavedModName (override) */
	bool isCompatible(char const* szSavedModName, char const* szSavedModCRC) const;
	/*	0 except while exporting a savegame to a BULL-based mod that uses
		additional game options, units etc. */
	int getNumExtraGameOptions() const;
	// <trs.bat> These are only needed for compatibility with BAT
	int getNumExtraUnits() const;
	int getNumExtraUnitCombats() const;
	int getNumExtraFeatures() const;
	static int getBATExtraGameOptions() { return 2; }
	static int getBATExtraUnits() { return 21; } // Female missionaries, executives, GP
	static int getBATExtraUnitCombats() { return 1; } // UNITCOMBAT_IFV (unused)
	static int getBATExtraFeatures() { return 1; } // SCRUB (unused)
	/*	Replacement for unit with BAT id equal to the
		highest BtS id plus iExtra plus 1. (Weird but convenient to use.) */
	static UnitTypes replBATUnit(int iExtraID);
	static UnitTypes replBATUnit(UnitTypes eBATUnitID);
	/*	Could get this info from isCompatible, but, in theory, the callback
		can be disabled and then the BAT import flag wouldn't get updated.
		Also wouldn't work for BAT in CustomAssets. */
	void setBATImport(bool b) { m_bBATImport = b; }
	/*	This will be accurate not just while reading savegame data, but, fwiw,
		until another save gets loaded or a new game started. */
	bool isBATImport() const { return m_bBATImport; }
	// </trs.bat>

private:
	/*	I'm guessing that the string structure used by the EXE for storing
		the mod name is the mysterious FString class (F for "Firaxis Game Engine")
		mentioned in comments in CvString.h. */
	class FString
	{
	public:
		char const* GetCString() const { return &m_cFirstChar; }
		int getCapacity() const { return m_iCapacity; }
		// The EXE will provide a C string, like in the function above.
		static FString* create(char const* szExternal);
		bool assign(char const* szChars);
	private:
		FString(); // W/o implementation; will get our instances only from the EXE.
		int const m_iCapacity; // Can't grow the char array
		int m_iSize;
		/*	MSVC's std::string uses
			union { Elem _Buf[_BUF_SIZE]; _Elem *_Ptr; }
			however, a test with a really long mod name has confirmed that this
			local char array has a dynamic size. I guess through allocation of
			raw memory and a reinterpret_cast. It could well be that the class
			I've reverse-engineered here is in fact only a component that the
			actual FString classes hold a pointer to. */
		char m_cFirstChar;
		char const& at(int i) const { return *(&m_cFirstChar + i); }
		char& at(int i) { return *(&m_cFirstChar + i); }
		bool isValid() const;
	};
	FString* m_pExtFullPath;
	FString* m_pExtPathInRoot;

	bool m_bSaving, m_bExporting;
	std::string m_sFullPath;
	std::string m_sPathInRoot;
	std::string m_sName;
	std::string m_sExtName; // Not stored separately by the EXE; handy to have.
	// <trs.bat>
	bool m_bBATImport;
	bool isExportingToBAT() const; // </trs.bat>
};

#endif

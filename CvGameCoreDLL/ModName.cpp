// trs.modname: New implementation file; see comment in header.
#include "CvGameCoreDLL.h"
#include "ModName.h"


namespace
{
	std::string parseName(std::string sPath)
	{
		std::string sName = sPath;
		char const cSep1 = '\\';
		char const cSep2 = '/';
		// Looking for this folder name seems like the safest bet
		std::string sMods = "Mods";
		size_t posMods = sName.find(sMods);
		if (posMods != sName.npos)
		{
			/*	Skip over "Mods" plus the path separator.
				And chop off the separator at the end. */
			int iOffsetStart = sMods.length() + 1;
			int iOffsetEnd = iOffsetStart;
			char const cLastChar = sName[sName.length() - 1];
			if (cLastChar == cSep1 || cLastChar == cSep2)
				iOffsetEnd++;
			sName = sName.substr(posMods + iOffsetStart,
					sName.length() - posMods - iOffsetEnd);
		}
		else
		{
			/*	I'm not sure that the folder name is hardcoded. Don't know where
				the EXE gets it. Let's try to work with different names too. */
			std::vector<std::string> asTokens;
			std::string sSeps; sSeps += cSep1; sSeps += cSep2;
			boost::split(asTokens, sName, boost::is_any_of(sSeps));
			if (asTokens.size() > 1 && asTokens.size() <= 3)
				sName = asTokens[1];
			else
			{
				FErrorMsg("Failed to parse mod's folder name");
				return "";
			}
		}
		return sName;
	}
}


bool ModName::isCompatible(char const* szSavedModName,
	char const* szSavedModCRC) const
{
	if (isNameCheckOverrideKey())
		return true;
	if (GC.getDefineBOOL("LOAD_BTS_SAVEGAMES") && cstring::empty(szSavedModName))
		return true;
	std::string sSavedName = parseName(szSavedModName);
	// Always accept our own saves
	if (sSavedName == m_sName)
		return true;
	/*	Reject BUFFY (version 005) even when one of our name prefixes somehow
		matches the mod name. BUFFY saves are encrypted, we can never read them. */
	if (strcmp(szSavedModCRC, "e7dcd7a0b27ffe3cb49ca64c3b2ff2a6") == 0)
		return false;
	std::string sPrefixes = GC.getDefineSTRING("COMPATIBLE_MOD_NAME_PREFIXES");
	std::vector<std::string> asPrefixes;
	boost::split(asPrefixes, sPrefixes, boost::is_any_of(","));
	std::vector<std::string> asSanitizedPrefixes;
	for (size_t i = 0; i < asPrefixes.size(); i++)
	{
		std::string sPrefix = asPrefixes[i];
		int iLeadingSpaces = 0;
		int iTrailingSpaces = 0;
		bool bFirstNonSpaceFound = false;
		bool bLastNonSpaceFound = false;
		for (size_t i = 0; i < sPrefix.length(); i++)
		{
			if (!bFirstNonSpaceFound && sPrefix[i] == ' ')
				iLeadingSpaces++;
			else bFirstNonSpaceFound = true;
			if (!bLastNonSpaceFound && sPrefix[sPrefix.length() - i - 1] == ' ')
				iTrailingSpaces++;
			else bLastNonSpaceFound = true;
		}
		sPrefix = sPrefix.substr(iLeadingSpaces, std::max(0,
				((int)sPrefix.length()) - iTrailingSpaces - iLeadingSpaces));
		if (!sPrefix.empty())
			asSanitizedPrefixes.push_back(sPrefix);
	}
	if (asSanitizedPrefixes.empty())
		return false;
	cstring::tolower(sSavedName);
	for (size_t i = 0; i < asSanitizedPrefixes.size(); i++)
	{
		if (STDSTR_STARTS_WITH(
			sSavedName, cstring::tolower(asSanitizedPrefixes[i])))
		{
			return true;
		}
	}
	return false;
}


int ModName::getNumExtraGameOptions() const
{
	if (!isExporting())
		return 0;
	std::string sName = getExtName();
	cstring::tolower(sName);
	// <trs.bat>
	if (STDSTR_STARTS_WITH(sName, "bat"))
		return getBATExtraGameOptions(); // </trs.bat>
	if (STDSTR_STARTS_WITH(sName, "buffy"))
		return 1;
	return 0;
}

// <trs.bat>
bool ModName::isExportingToBAT() const
{
	if (!isExporting())
		return false;
	std::string sName = getExtName();
	cstring::tolower(sName);
	return STDSTR_STARTS_WITH(sName, "bat");
}


int ModName::getNumExtraUnits() const
{
	if (isExportingToBAT())
		return getBATExtraUnits();
	return 0;
}


int ModName::getNumExtraUnitCombats() const
{
	if (isExportingToBAT())
		return getBATExtraUnitCombats();
	return 0;
}


int ModName::getNumExtraFeatures() const
{
	if (isExportingToBAT())
		return getBATExtraFeatures();
	return 0;
}


UnitTypes ModName::replBATUnit(int iExtraID)
{
	FAssert(iExtraID >= 0 && iExtraID < getBATExtraUnits());
	int iID = GC.getNumUnitInfos() + iExtraID;
	if (iExtraID < 7) // Female GPs have the lowest extra IDs
		iID -= 7; // Male GP have the highest regular IDs
	else if (iExtraID < 14) // Female missionary
		iID -= 113; // Male missionary IDs are ... somewhere in the middle
	// Female execs come last, after the female missionaries.
	else iID -= 127; // Male execs come before male missionaries
	FAssertBounds(0, iID, GC.getNumUnitInfos());
	return static_cast<UnitTypes>(iID);
}


UnitTypes ModName::replBATUnit(UnitTypes eBATUnitID)
{
	int iExtra = eBATUnitID - GC.getNumUnitInfos();
	if (iExtra < 0)
		return eBATUnitID;
	return replBATUnit(iExtra);
} // </trs.bat>


ModName::ModName(char const* szFullPath, char const* szPathInRoot)
:	m_pExtFullPath(NULL), m_pExtPathInRoot(NULL),
	m_bSaving(false), m_bExporting(false),
	m_bBATImport(false) // trs.bat
{
	m_sFullPath = szFullPath;
	m_sPathInRoot = szPathInRoot;
	m_pExtFullPath = FString::create(szFullPath);
	m_pExtPathInRoot = FString::create(szPathInRoot);
	FAssert(m_pExtFullPath != NULL && m_pExtPathInRoot != NULL);
	m_sName = parseName(m_sPathInRoot);
	m_sExtName = m_sName;
}


int ModName::getExtNameLengthLimit() const
{
	int iLimit = std::min(m_pExtFullPath->getCapacity(),
			m_pExtPathInRoot->getCapacity());
	// Path other than name will take up characters
	iLimit -= std::max(m_sFullPath.length(), m_sPathInRoot.length());
	iLimit += m_sName.length();
	return iLimit;
}


namespace
{
	void replaceRightmost(std::string& s,
		char const* szPattern, char const* szReplacement)
	{
		size_t pos = s.rfind(szPattern);
		if (pos != std::string::npos)
			s.replace(pos, std::strlen(szPattern), szReplacement);
		else FErrorMsg("Pattern not found");
	}
}

void ModName::setExtModName(const char* szName, bool bExporting)
{
	// Mod name set for one-time export takes precedence
	if (isExporting() && !bExporting)
		return;
	if (m_pExtFullPath == NULL || m_pExtPathInRoot == NULL)
	{
		FErrorMsg("Can't change external mod name b/c failed parsing it in ctor");
		return;
	}
	std::string sNewFullPath, sNewPathInRoot;
	// Empty name implies empty paths (no Mods folder involved)
	if (!cstring::empty(szName))
	{
		sNewFullPath = getExtFullPath();
		sNewPathInRoot = getExtPathInRoot();
		replaceRightmost(sNewFullPath, getExtName(), szName);
		replaceRightmost(sNewPathInRoot, getExtName(), szName);
	}
	if (((int)sNewFullPath.length()) > m_pExtFullPath->getCapacity() ||
		((int)sNewPathInRoot.length()) > m_pExtPathInRoot->getCapacity())
	{
		FErrorMsg("Insufficient capacity for new mod name");
		return;
	}
	m_bExporting = bExporting;
	bool bSuccess = (m_pExtFullPath->assign(sNewFullPath.c_str()) &&
			m_pExtPathInRoot->assign(sNewPathInRoot.c_str()));
	if (!bSuccess ||
		/*	The EXE will return NULL instead of an empty string
			when the FString size is 0 */
		((gDLL->getModName(true) == NULL || gDLL->getModName(false) == NULL) ?
		!cstring::empty(szName) :
		(std::strcmp(sNewFullPath.c_str(), gDLL->getModName(true)) != 0 ||
		std::strcmp(sNewPathInRoot.c_str(), gDLL->getModName(false)) != 0)))
	{
		/*	Our std::string members should all be good.
			Just need to make the FStrings consistent with them. */
		resetExt();
		/*	Result still won't be what our caller expects - szName has
			not been adopted. */
		FErrorMsg("Failed to change mod name in EXE");
	}
	// Don't update this until we're certain of having succeeded
	else m_sExtName = szName;
}


void ModName::setSaving(bool b)
{
	m_bSaving = b;
	if (!isSaving() && isExporting())
	{
		m_bExporting = false;
		resetExt();
	}
}


void ModName::resetExt()
{
	if (isExporting())
		return;
	// Avoid messing with the EXE unnecessarily
	if (gDLL->getModName(true) != NULL &&
		std::strcmp(gDLL->getModName(true), m_sFullPath.c_str()) == 0 &&
		gDLL->getModName(false) != NULL &&
		std::strcmp(gDLL->getModName(false), m_sPathInRoot.c_str()) == 0)
	{
		return;
	}
	if (m_pExtFullPath->assign(m_sFullPath.c_str()) &&
		m_pExtPathInRoot->assign(m_sPathInRoot.c_str()))
	{
		m_sExtName = m_sName;
	}
	else FErrorMsg("Failed to reset external mod name");
}


bool ModName::FString::isValid() const
{
	// Verify that our instance is laid out as expected
	if (m_iCapacity >= 31 && // The smallest value I've seen in the debugger
		m_iCapacity <= 128 && // sanity test
		m_iSize >= 0 && m_iSize <= m_iCapacity)
	{
		if (m_iSize > 0)
		{
			if (at(m_iSize) != '\0')
				return false;
			for (int i = 0; i < m_iSize; i++)
			{
				if (at(i) == '\0')
					return false;
			}
		}
		return true;
	}
	return false;
}


ModName::FString* ModName::FString::create(char const* szExternal)
{
	if (szExternal == NULL)
		return NULL;
	FString& kInst = *reinterpret_cast<FString*>(
			const_cast<char*>(szExternal - sizeof(int) * 2));
	if (!kInst.isValid())
	{
		FErrorMsg("Invalid FString data");
		return NULL;
	}
	return &kInst;
}


bool ModName::FString::assign(char const* szChars)
{
	bool bSuccess = false;
	int iNewSize = 0;
	for (int i = 0; i < m_iCapacity; i++)
	{
		char c = szChars[i];
		at(i) = c;
		if (c == '\0')
		{
			bSuccess = true;
			break;
		}
		iNewSize++;
	}
	/*	Don't know if the string class in the EXE ensures that too;
		it looks like it in the debugger. */
	for (int i = iNewSize; i < m_iCapacity; i++)
		at(i) = '\0';
	m_iSize = iNewSize;
	return bSuccess;
}

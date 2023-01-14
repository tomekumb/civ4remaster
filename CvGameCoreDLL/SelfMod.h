// trs.smc: Let's put all self-modifying code in a single place
#pragma once
#ifndef SELF_MOD_H
#define SELF_MOD_H

class ModNameChecker; // trs.modname

// Runtime modifications to the native code of Civ4BeyondSword.exe (v3.19)
class Civ4BeyondSwordPatches
{
public:
	// <trs.balloon>
	void patchPlotIndicatorSize(); // (exposed to Python via CyGameCoreUtils) 
	bool isPlotIndicatorSizePatched() const { return m_bPlotIndicatorSizePatched; }
	// </trs.balloon>
	// <trs.modname>
	/*	Disables the mod name check in the EXE and inserts a hook that will call
		pChecker->isCompatible(szSavedModName)
		to decide whether saves with a given mod name should be loaded
		(callback mechanism). If pChecker returns false, the hook will re-enable
		the mod name check in the EXE.
		This function should be called each time that the EXE begins loading
		a savegame (i.e. when it accesses the SAVE_VERSION global define through
		the DLL). This way, the name check gets briefly re-enabled whenever
		the player attempts to load an incompatible savegame.
		The hook, once placed, remains in the EXE and can't be removed. Only the
		callback can be disabled by passing pChecker=NULL. */
	void patchModNameCheck(ModNameChecker const* pChecker);
	bool isModNameCheckHooked() const { return (m_pModNameChecker != NULL); }
	bool isModNameCheckEnabled() const { return !m_bModNameCheckDisabled; }
	// </trs.modname>
	void patchLockedAssetsCheck(bool bEnable); // trs.lma

	Civ4BeyondSwordPatches()
	:	m_bPlotIndicatorSizePatched(false), // trs.balloon
		m_bLockedAssetsCheckEnabled(true), // trs.lma
		// trs.modname:
		m_bModNameCheckDisabled(false), m_bHookingFailed(false),
		m_iNameCheckAddressOffset(0), m_pModNameChecker(NULL)
	{}

private:
	bool m_bPlotIndicatorSizePatched; // trs.balloon
	bool m_bLockedAssetsCheckEnabled; // trs.lma
	// <trs.modname>
	bool m_bModNameCheckDisabled, m_bHookingFailed;
	int m_iNameCheckAddressOffset;
	ModNameChecker const* m_pModNameChecker;

	static int __cdecl modNameCheckHook(uint uiEDI, uint uiEBP);
	void doModNameCheckCallBack(char const* szSavedModName);
	void patchModNameCheck(bool bEnableCheck);
	void insertModNameCheckHook();
	// </trs.modname>
	void showErrorMsgToPlayer(CvWString szMsg);
};

namespace smc
{
	extern Civ4BeyondSwordPatches BtS_EXE;
}

#endif

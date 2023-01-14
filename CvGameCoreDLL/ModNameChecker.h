/*	trs.modname: Interface for receiving callbacks from the hook inserted by
	Civ4BeyondSwordPatches::patchModNameCheck (SelfMod.h). In a separate header
	in order to minimize header-in-header inclusions. */
#pragma once
#ifndef MOD_NAME_CHECKER_H
#define MOD_NAME_CHECKER_H

class ModNameChecker
{
public:
	virtual bool isCompatible(char const* szSavedModName, char const* szSavedModCRC) const=0;
};

#endif

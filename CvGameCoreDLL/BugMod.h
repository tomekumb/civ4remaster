/**********************************************************************

File:		BugMod.h
Author:		EmperorFool
Created:	2009-01-22

Defines common constants and functions for use throughout the BUG Mod.

		Copyright (c) 2010 The BUG Mod. All rights reserved.

**********************************************************************/

#pragma once

#ifndef BUG_MOD_H
#define BUG_MOD_H

// name of the Python module where all the BUG functions that the DLL calls must live
// MUST BE A BUILT-IN MODULE IN THE ENTRYPOINTS FOLDER
// currently CvAppInterface
#define PYBugModule				PYCivModule

// Increment this by 1 each time you commit new/changed functions/constants in the Python API.
#define BUG_DLL_API_VERSION		6

// Used to signal the BULL saved game format is used
// trs.modname (note): Mustn't change this - or we'll be unable to load BAT saves.
#define BUG_DLL_SAVE_FORMAT		(1 << 6)

// <trs.modname> Moved from CvInitCore::write
#if defined(_BUFFY) || defined(_MOD_GWARM)
	#define BULL_MOD_SAVE_MASK	BUG_DLL_SAVE_FORMAT
#else
	#define BULL_MOD_SAVE_MASK	0
#endif
// One bit to the left of the BULL bit
#define TAURUS_SAVE_FORMAT		(BUG_DLL_SAVE_FORMAT << 1)
// </trs.modname>

// These are display-only values, and the version should be changed for each release.
// trs.build: Was L"BULL", L"1.3", L"216"
#define BUG_DLL_NAME			L"Taurus"
#define BUG_DLL_VERSION			L"1.00"
#define BUG_DLL_BUILD			L"1"

#endif

#pragma once

#ifndef FASSERT_H
#define FASSERT_H

// Only compile in FAssert's if FASSERT_ENABLE is defined.  By default, however, let's key off of
// _DEBUG.  Sometimes, however, it's useful to enable asserts in release builds, and you can do that
// simply by changing the following lines to define FASSERT_ENABLE or using project settings to override
#ifdef _DEBUG
#define FASSERT_ENABLE
#endif 

#ifdef FASSERT_ENABLE

#ifdef WIN32

bool FAssertDlg( const char*, const char*, const char*, unsigned int, bool& );

#define FAssert( expr )	\
{ \
	static bool bIgnoreAlways = false; \
	if( !bIgnoreAlways && !(expr) ) \
{ \
	if( FAssertDlg( #expr, 0, __FILE__, __LINE__, bIgnoreAlways ) ) \
{ _asm int 3 } \
} \
}

#define FAssertMsg( expr, msg ) \
{ \
	static bool bIgnoreAlways = false; \
	if( !bIgnoreAlways && !(expr) ) \
{ \
	if( FAssertDlg( #expr, msg, __FILE__, __LINE__, bIgnoreAlways ) ) \
{ _asm int 3 } \
} \
}

/*  <trs.debug> sprintf doesn't handle buffer overflows well, so I'd like to use
	snprintf instead (as K-Mod does). I guess that has been replaced by _snprintf_s
	in more recent versions of MSVC. To avoid red underlines in the code editor: */
#ifdef _CODE_EDITOR
	#define snprintf _snprintf_s
#endif

// Moved from CvInitCore.h, params ordered more intuitively.
#define FAssertBounds(lower, index, upper) \
	if (index < lower) \
	{ \
		char acOut[256]; \
		snprintf(acOut, 256, "Index expected to be >= %d. (value: %d)", lower, index); \
		FAssertMsg(index >= lower, acOut); \
	} \
	else if (index >= upper) \
	{ \
		char acOut[256]; \
		snprintf(acOut, 256, "Index expected to be < %d. (value: %d)", upper, index); \
		FAssertMsg(index < upper, acOut); \
	}
// </trs.debug>

#else
// Non Win32 platforms--just use built-in FAssert
#define FAssert( expr )	FAssert( expr )
#define FAssertMsg( expr, msg )	FAssert( expr )

#endif

#else
// FASSERT_ENABLE not defined
/*	<trs.debug> void(0) added to allow FAssert in otherwise empty branches
	and to force semicolon. */
#define FAssert( expr ) (void)0
#define FAssertMsg( expr, msg ) (void)0
#define FAssertBounds(lower, index, upper) (void)0
// </trs.debug>

#endif

// trs.debug:
#define FErrorMsg(msg) FAssertMsg(false, msg)

#endif // FASSERT_H

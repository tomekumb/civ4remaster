/*	trs.modname: New header, for function that decides whether gameplay changes
	from v1.6 of the Unofficial Patch should take effect. I'm disabling them in
	network games b/c UP 1.6 can lead to OOS errors when BULL players are in the
	game. (Would be nice to check whether that's actually the case ...)
	BULL 1.2 (the last official release) only uses UP 1.5. */

#pragma once
#ifndef UNOFFICIAL_PATCH_H
#define UNOFFICIAL_PATCH_H

/*	trs.fix: Will use this guard for minor Taurus gameplay changes
	(probably exclusively bugfixes). Somewhat fits in this header as one could
	consider such bugfixes as part of a UP fork. */
inline bool isBULL12Rules() { return GC.getInitCore().getMultiplayer(); }
inline bool isEnableUP16() { return !isBULL12Rules(); }

#endif

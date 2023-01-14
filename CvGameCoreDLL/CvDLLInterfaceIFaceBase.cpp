// trs.autoplay: Implementation file for wrapper around addMessage
#include "CvGameCoreDLL.h"
#include "CvDLLInterfaceIFaceBase.h"

void CvDLLInterfaceIFaceBase::addMessage(PlayerTypes ePlayer, bool bForce,
	int iLength, CvWString sString, char const* szSound,
	InterfaceMessageTypes eType, char const* szIcon,
	ColorTypes eFlashColor, int iFlashX, int iFlashY,
	bool bShowOffScreenArrows, bool bShowOnScreenArrows)
{
	CvPlayer& kPlayer = GET_PLAYER(ePlayer);
	if (kPlayer.isHumanDisabled()) // Adjustments during AI Auto Play
	{
		if (eType != MESSAGE_TYPE_MAJOR_EVENT)
			 return; // Announce only major events during AI Auto Play
		// Never delay messages until the start of the active player's next turn
		bForce = true;
		// Don't show any message longer than the default time
		iLength = std::min(iLength, GC.getEVENT_MESSAGE_TIME());
		szSound = NULL; // No interface sound
		szIcon = NULL; // No plot indicator icon!
		// (Toggling these off is probably redundant when there is no icon)
		bShowOffScreenArrows = false;
		bShowOnScreenArrows = false;
		/*	(Do not discard the "flash" info. It's used for the text color and the
			coordinates stored in the Event Log -- not just for the icon.) */
	}
	// <trs.opt> (from K-Mod) No point in adding interface messages to an AI player
	else if (!kPlayer.isHuman())
		return;
	addMessageExternal(ePlayer, bForce, iLength, sString, szSound, eType, szIcon,
			eFlashColor, iFlashX, iFlashY, bShowOffScreenArrows, bShowOnScreenArrows);
}

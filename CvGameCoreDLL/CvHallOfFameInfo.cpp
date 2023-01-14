#include "CvGameCoreDLL.h"
#include "CvHallOfFameInfo.h"
#include "CvGlobals.h"

// <trs.clearhof>
CvHallOfFameInfo::CvHallOfFameInfo()
{
	GC.getGame().setHallOfFame(this);
}

CvHallOfFameInfo::~CvHallOfFameInfo()
{
	uninit();
}

void CvHallOfFameInfo::uninit()
{
	GC.getGame().setHallOfFame(NULL);
	CvGlobals::getInstance().setHoFScreenUp(false); // trs.replayname
	// (as in BtS)
	for (uint i = 0; i < m_aReplays.size(); i++)
	{
		SAFE_DELETE(m_aReplays[i]);
	}
} // </trs.clearhof>

void CvHallOfFameInfo::loadReplays()
{
	CvGlobals::getInstance().setHoFScreenUp(true); // trs.replayname
	gDLL->loadReplays(m_aReplays);
}

int CvHallOfFameInfo::getNumGames() const
{
	return (int)m_aReplays.size();
}

CvReplayInfo* CvHallOfFameInfo::getReplayInfo(int i)
{
	return m_aReplays[i];
}
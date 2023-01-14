#include "CvGameCoreDLL.h"
#include "CvReplayInfo.h"
#include "CvInfos.h"
#include "CvGlobals.h"
#include "CvGameAI.h"
#include "CvPlayerAI.h"
#include "CvMap.h"
#include "CvReplayMessage.h"
#include "CvGameTextMgr.h"
#include "CvDLLInterfaceIFaceBase.h"
// <trs.replayname>
#include "ModName.h"
#include "CvBugOptions.h"
#include "BugMod.h"
// </trs.replayname>

int CvReplayInfo::REPLAY_VERSION = 4
		// <trs.replayname>
		/*	So that we can always identify Taurus replays,
			even if the mod name hasn't been saved. */
		| TAURUS_SAVE_FORMAT;

namespace
{
	bool shouldWriteModName()
	{
		// OK if BUG not yet initialized; will get another call later on.
		if (!isBug() || getBugOptionBOOL("Taurus__ModNameInReplays"))
			return true;
		/*	This is just to make modders aware that BtS won't be able to read
			their replays */
		if ((GC.getNumPlayerColorInfos() > 44 && GC.getNumColorInfos() > 127) ||
			GC.getNumWorldInfos() > 6 || GC.getNumVictoryInfos() > 7 ||
			GC.getNumHandicapInfos() > 9 || GC.getNumGameSpeedInfos() > 4)
		{
			FErrorMsg("Writing mod name to replay b/c not compatible with BtS");
			return true;
		}
		return false;
	}
}

CvReplayInfo::Data::Data() :
	iNormalizedScore(0),
	iVersionRead(-1)
{} // </trs.replayname>

/*	trs.safety (from AdvCiv): Needs to have a copy-constructor b/c of its
	Python counterpart, but I don't think it'll actually get called.
	Won't want to copy m_pcMinimapPixels. */
CvReplayInfo::CvReplayInfo(CvReplayInfo const&) : m(*new Data)
{
	FErrorMsg("No copy-constructor implemented for CvReplayInfo");
}

CvReplayInfo::CvReplayInfo() :
	m(*new Data), // trs.replayname
	m_iActivePlayer(0),
	m_eDifficulty(NO_HANDICAP),
	m_eWorldSize(NO_WORLDSIZE),
	m_eClimate(NO_CLIMATE),
	m_eSeaLevel(NO_SEALEVEL),
	m_eEra(NO_ERA),
	m_eGameSpeed(NO_GAMESPEED),
	m_iInitialTurn(0),
	m_iFinalTurn(0),
	m_eVictoryType(NO_VICTORY),
	m_iMapHeight(0),
	m_iMapWidth(0),
	m_pcMinimapPixels(NULL),
	m_bMultiplayer(false),
	m_iStartYear(0),
	m_eCalendar(NO_CALENDAR) // trs.safety
{
	m_nMinimapSize = ((GC.getDefineINT("MINIMAP_RENDER_SIZE") * GC.getDefineINT("MINIMAP_RENDER_SIZE")) / 2); 
}

CvReplayInfo::~CvReplayInfo()
{
	ReplayMessageList::const_iterator it;
	for (uint i = 0; i < m_listReplayMessages.size(); i++)
	{
		SAFE_DELETE(m_listReplayMessages[i]);
	}
	SAFE_DELETE(m_pcMinimapPixels);
	delete &m; // trs.replayname
}

void CvReplayInfo::createInfo(PlayerTypes ePlayer)
{
	CvGame& game = GC.getGameINLINE();
	CvMap& map = GC.getMapINLINE();

	if (ePlayer == NO_PLAYER)
	{
		ePlayer = game.getActivePlayer();
	}
	if (NO_PLAYER != ePlayer)
	{
		CvPlayer& player = GET_PLAYER(ePlayer);

		m_eDifficulty = player.getHandicapType();
		m_szLeaderName = player.getName();
		m_szCivDescription = player.getCivilizationDescription();
		m_szShortCivDescription = player.getCivilizationShortDescription();
		m_szCivAdjective = player.getCivilizationAdjective();
		m_szMapScriptName = GC.getInitCore().getMapScriptName();
		m_eWorldSize = map.getWorldSize();
		m_eClimate = map.getClimate();
		m_eSeaLevel = map.getSeaLevel();
		m_eEra = game.getStartEra();
		m_eGameSpeed = game.getGameSpeedType();

		m_listGameOptions.clear();
		for (int i = 0; i < NUM_GAMEOPTION_TYPES; i++)
		{
			GameOptionTypes eOption = (GameOptionTypes)i;
			if (game.isOption(eOption))
			{
				m_listGameOptions.push_back(eOption);
			}
		}

		m_listVictoryTypes.clear();
		for (int i = 0; i < GC.getNumVictoryInfos(); i++)
		{
			VictoryTypes eVictory = (VictoryTypes)i;
			if (game.isVictoryValid(eVictory))
			{
				m_listVictoryTypes.push_back(eVictory);
			}
		}
		if (game.getWinner() == player.getTeam())
		{
			m_eVictoryType = game.getVictory();
		}
		else
		{
			m_eVictoryType = NO_VICTORY;
		}

		m.iNormalizedScore = player.calculateScore(true, player.getTeam() == GC.getGameINLINE().getWinner());
	}

	m_bMultiplayer = game.isGameMultiPlayer();


	m_iInitialTurn = GC.getGameINLINE().getStartTurn();
	m_iStartYear = GC.getGameINLINE().getStartYear();
	m_iFinalTurn = game.getGameTurn();
	GAMETEXT.setYearStr(m_szFinalDate, m_iFinalTurn, false, GC.getGameINLINE().getCalendar(), GC.getGameINLINE().getStartYear(), GC.getGameINLINE().getGameSpeedType());

	m_eCalendar = GC.getGameINLINE().getCalendar();


	std::map<PlayerTypes, int> mapPlayers;
	m_listPlayerScoreHistory.clear();
	int iPlayerIndex = 0;
	for (int iPlayer = 0; iPlayer < MAX_PLAYERS; iPlayer++)
	{
		CvPlayer& player = GET_PLAYER((PlayerTypes)iPlayer);
		if (player.isEverAlive())
		{
			mapPlayers[(PlayerTypes)iPlayer] = iPlayerIndex;
			if ((PlayerTypes)iPlayer == game.getActivePlayer())
			{
				m_iActivePlayer = iPlayerIndex;
			}
			++iPlayerIndex;

			PlayerInfo playerInfo;
			playerInfo.m_eLeader = player.getLeaderType();
			playerInfo.m_eColor = (ColorTypes)GC.getPlayerColorInfo(player.getPlayerColor()).getColorTypePrimary();
			for (int iTurn = m_iInitialTurn; iTurn <= m_iFinalTurn; iTurn++)
			{
				TurnData score;
				score.m_iScore = player.getScoreHistory(iTurn);
				score.m_iAgriculture = player.getAgricultureHistory(iTurn);
				score.m_iIndustry = player.getIndustryHistory(iTurn);
				score.m_iEconomy = player.getEconomyHistory(iTurn);

				playerInfo.m_listScore.push_back(score);
			}
			m_listPlayerScoreHistory.push_back(playerInfo);
		}
	}

	//m_listReplayMessages.clear();
	FAssert(m_listReplayMessages.empty()); // trs.safety
	for (uint i = 0; i < game.getNumReplayMessages(); i++)
	{
		std::map<PlayerTypes, int>::iterator it = mapPlayers.find(game.getReplayMessagePlayer(i));
		if (it != mapPlayers.end())
		{
			CvReplayMessage* pMsg = new CvReplayMessage(game.getReplayMessageTurn(i), game.getReplayMessageType(i), (PlayerTypes)it->second);
			if (NULL != pMsg)
			{
				pMsg->setColor(game.getReplayMessageColor(i));
				pMsg->setText(game.getReplayMessageText(i));
				pMsg->setPlot(game.getReplayMessagePlotX(i), game.getReplayMessagePlotY(i));
				m_listReplayMessages.push_back(pMsg);
			}	
		}
		else
		{
			CvReplayMessage* pMsg = new CvReplayMessage(game.getReplayMessageTurn(i), game.getReplayMessageType(i), NO_PLAYER);
			if (NULL != pMsg)
			{
				pMsg->setColor(game.getReplayMessageColor(i));
				pMsg->setText(game.getReplayMessageText(i));
				pMsg->setPlot(game.getReplayMessagePlotX(i), game.getReplayMessagePlotY(i));
				m_listReplayMessages.push_back(pMsg);
			}	
		}
	}

	m_iMapWidth = GC.getMapINLINE().getGridWidthINLINE();
	m_iMapHeight = GC.getMapINLINE().getGridHeightINLINE();
	
	SAFE_DELETE(m_pcMinimapPixels);	
	m_pcMinimapPixels = new unsigned char[m_nMinimapSize];
	
	void *ptexture = (void*)gDLL->getInterfaceIFace()->getMinimapBaseTexture();
	if (ptexture)
		memcpy((void*)m_pcMinimapPixels, ptexture, m_nMinimapSize);

	if (shouldWriteModName()) // trs.replayname
		m_szModName = gDLL->getModName();
}

int CvReplayInfo::getNumPlayers() const
{
	return (int)m_listPlayerScoreHistory.size();
}


bool CvReplayInfo::isValidPlayer(int i) const
{
	return (i >= 0 && i < (int)m_listPlayerScoreHistory.size());
}

bool CvReplayInfo::isValidTurn(int i) const
{
	return (i >= m_iInitialTurn && i <= m_iFinalTurn);
}

int CvReplayInfo::getActivePlayer() const
{
	return m_iActivePlayer;
}

LeaderHeadTypes CvReplayInfo::getLeader(int iPlayer) const
{
	if (iPlayer < 0)
	{
		iPlayer = m_iActivePlayer;
	}
	if (isValidPlayer(iPlayer))
	{
		return m_listPlayerScoreHistory[iPlayer].m_eLeader;
	}
	return NO_LEADER;
}

ColorTypes CvReplayInfo::getColor(int iPlayer) const
{
	if (iPlayer < 0)
	{
		iPlayer = m_iActivePlayer;
	}
	if (isValidPlayer(iPlayer))
	{
		return m_listPlayerScoreHistory[iPlayer].m_eColor;
	}
	return NO_COLOR;
}

HandicapTypes CvReplayInfo::getDifficulty() const
{
	return m_eDifficulty;
}

const CvWString& CvReplayInfo::getLeaderName() const
{
	return m_szLeaderName;
}

const CvWString& CvReplayInfo::getCivDescription() const
{
	return m_szCivDescription;
}

const CvWString& CvReplayInfo::getShortCivDescription() const
{
	return m_szShortCivDescription;
}

const CvWString& CvReplayInfo::getCivAdjective() const
{
	return m_szCivAdjective;
}

const CvWString& CvReplayInfo::getMapScriptName() const
{
	return m_szMapScriptName;
}

WorldSizeTypes CvReplayInfo::getWorldSize() const
{
	return m_eWorldSize;
}

ClimateTypes CvReplayInfo::getClimate() const
{
	return m_eClimate;
}

SeaLevelTypes CvReplayInfo::getSeaLevel() const
{
	return m_eSeaLevel;
}

EraTypes CvReplayInfo::getEra() const
{
	return m_eEra;
}

GameSpeedTypes CvReplayInfo::getGameSpeed() const
{
	return m_eGameSpeed;
}

bool CvReplayInfo::isGameOption(GameOptionTypes eOption) const
{
	for (uint i = 0; i < m_listGameOptions.size(); i++)
	{
		if (m_listGameOptions[i] == eOption)
		{
			return true;
		}
	}
	return false;
}

bool CvReplayInfo::isVictoryCondition(VictoryTypes eVictory) const
{
	for (uint i = 0; i < m_listVictoryTypes.size(); i++)
	{
		if (m_listVictoryTypes[i] == eVictory)
		{
			return true;
		}
	}
	return false;
}

VictoryTypes CvReplayInfo::getVictoryType() const
{
	return m_eVictoryType;
}

bool CvReplayInfo::isMultiplayer() const
{
	return m_bMultiplayer;
}


void CvReplayInfo::addReplayMessage(CvReplayMessage* pMessage)
{
	m_listReplayMessages.push_back(pMessage);
}

void CvReplayInfo::clearReplayMessageMap()
{
	for (ReplayMessageList::const_iterator itList = m_listReplayMessages.begin(); itList != m_listReplayMessages.end(); itList++)
	{
		const CvReplayMessage* pMessage = *itList;
		if (NULL != pMessage)
		{
			delete pMessage;
		}
	}
	m_listReplayMessages.clear();
}

// trs.refactor: To get rid of duplicate code in the functions below
bool CvReplayInfo::isReplayMsgValid(uint i) const
{
	return (i < m_listReplayMessages.size() && m_listReplayMessages[i] != NULL);
}

int CvReplayInfo::getReplayMessageTurn(uint i) const
{
	return (isReplayMsgValid(i) ? m_listReplayMessages[i]->getTurn() : -1);
}

ReplayMessageTypes CvReplayInfo::getReplayMessageType(uint i) const
{
	return (isReplayMsgValid(i) ? m_listReplayMessages[i]->getType() : NO_REPLAY_MESSAGE);
}

int CvReplayInfo::getReplayMessagePlotX(uint i) const
{
	return (isReplayMsgValid(i) ? m_listReplayMessages[i]->getPlotX() : -1);
}

int CvReplayInfo::getReplayMessagePlotY(uint i) const
{
	return (isReplayMsgValid(i) ? m_listReplayMessages[i]->getPlotY() : -1);
}

PlayerTypes CvReplayInfo::getReplayMessagePlayer(uint i) const
{
	return (isReplayMsgValid(i) ? m_listReplayMessages[i]->getPlayer() : NO_PLAYER);
}

LPCWSTR CvReplayInfo::getReplayMessageText(uint i) const
{
	return (isReplayMsgValid(i) ? m_listReplayMessages[i]->getText().c_str() : NULL);
}

ColorTypes CvReplayInfo::getReplayMessageColor(uint i) const
{
	return (isReplayMsgValid(i) ? m_listReplayMessages[i]->getColor() : NO_COLOR);
}


uint CvReplayInfo::getNumReplayMessages() const
{
	return m_listReplayMessages.size();
}


int CvReplayInfo::getInitialTurn() const
{
	return m_iInitialTurn;
}

int CvReplayInfo::getStartYear() const
{
	return m_iStartYear;
}

int CvReplayInfo::getFinalTurn() const
{
	return m_iFinalTurn;
}

const wchar* CvReplayInfo::getFinalDate() const
{
	return m_szFinalDate;
}

CalendarTypes CvReplayInfo::getCalendar() const
{
	return m_eCalendar;
}


int CvReplayInfo::getPlayerScore(int iPlayer, int iTurn) const
{
	if (isValidPlayer(iPlayer) && isValidTurn(iTurn))
	{
		return m_listPlayerScoreHistory[iPlayer].m_listScore[iTurn-m_iInitialTurn].m_iScore;
	}
	return 0;
}

int CvReplayInfo::getPlayerEconomy(int iPlayer, int iTurn) const
{
	if (isValidPlayer(iPlayer) && isValidTurn(iTurn))
	{
		return m_listPlayerScoreHistory[iPlayer].m_listScore[iTurn-m_iInitialTurn].m_iEconomy;
	}
	return 0;
}

int CvReplayInfo::getPlayerIndustry(int iPlayer, int iTurn) const
{
	if (isValidPlayer(iPlayer) && isValidTurn(iTurn))
	{
		return m_listPlayerScoreHistory[iPlayer].m_listScore[iTurn-m_iInitialTurn].m_iIndustry;
	}
	return 0;
}

int CvReplayInfo::getPlayerAgriculture(int iPlayer, int iTurn) const
{
	if (isValidPlayer(iPlayer) && isValidTurn(iTurn))
	{
		return m_listPlayerScoreHistory[iPlayer].m_listScore[iTurn-m_iInitialTurn].m_iAgriculture;
	}
	return 0;
}

int CvReplayInfo::getFinalScore() const
{
	return getPlayerScore(m_iActivePlayer, m_iFinalTurn);
}

int CvReplayInfo::getFinalEconomy() const
{
	return getPlayerEconomy(m_iActivePlayer, m_iFinalTurn);
}

int CvReplayInfo::getFinalIndustry() const
{
	return getPlayerIndustry(m_iActivePlayer, m_iFinalTurn);
}

int CvReplayInfo::getFinalAgriculture() const
{
	return getPlayerAgriculture(m_iActivePlayer, m_iFinalTurn);
}

int CvReplayInfo::getNormalizedScore() const
{
	return m.iNormalizedScore;
}

int CvReplayInfo::getMapHeight() const
{
	return m_iMapHeight;
}

int CvReplayInfo::getMapWidth() const
{
	return m_iMapWidth;
}

const unsigned char* CvReplayInfo::getMinimapPixels() const
{
	return m_pcMinimapPixels;
}

const char* CvReplayInfo::getModName() const
{
	// <trs.replayname>
	static int iReplayLoadMode = GC.getDefineINT("HOF_LIST_OTHER_REPLAYS"); // (ad-hoc cache)
	if (iReplayLoadMode >= 3 || m.iVersionRead == REPLAY_VERSION || m.iVersionRead < 0 ||
		(iReplayLoadMode >= 1 && m_szModName.empty()) ||
		(iReplayLoadMode >= 2 && GC.getModName().isCompatible(m_szModName.c_str(), "")))
	{	// Pretend to the EXE that this is a replay that we've created
		return GC.getModName().getFullPath(); // (gDLL->getModName() would go out of scope)
	} // </trs.replayname>
	return m_szModName;
}

// trs.safety:
namespace
{
	bool isInBounds(int iValue, int iLower, int iUpper)
	{
		return (iValue >= iLower && iValue < iUpper);
	}
}

bool CvReplayInfo::read(FDataStreamBase& stream)
{
	int iType;
	int iNumTypes;
	bool bSuccess = true;

	/*	trs.safety (note): This won't handle interrupts (unless we compile
		with /EHa). Hence the isInBounds checks below (not tagged w/ comments). */
	try
	{
		int iVersion;
		stream.Read(&iVersion);
		if (iVersion < 2)
			return false;
		// <trs.replayname>
		m.iVersionRead = iVersion;
		/*	If a mod uses a different replay format, then we may not be able to
			parse that. However, we can parse the AdvCiv format, and which other
			mod uses a different format? */
		/*{
			int iDataVersion = iVersion & ~TAURUS_SAVE_FORMAT;
			if (iDataVersion > 4)
				return false; 
		}*/ // </trs.replayname>
		stream.Read(&m_iActivePlayer);
		if (!isInBounds(m_iActivePlayer, 0, 128)) return false;

		stream.Read(&iType);
		m_eDifficulty = (HandicapTypes)iType;
		if (!isInBounds(m_eDifficulty, 0, 2 * GC.getNumHandicapInfos())) return false;
		stream.ReadString(m_szLeaderName);
		if (!isInBounds(m_szLeaderName.length(), 0, 256)) return false;
		stream.ReadString(m_szCivDescription);
		if (!isInBounds(m_szCivDescription.length(), 0, 256)) return false;
		stream.ReadString(m_szShortCivDescription);
		if (!isInBounds(m_szShortCivDescription.length(), 0, 256)) return false;
		stream.ReadString(m_szCivAdjective);
		if (!isInBounds(m_szCivAdjective.length(), 0, 256)) return false;
		if (iVersion > 3)
		{
			stream.ReadString(m_szMapScriptName);
			if (!isInBounds(m_szMapScriptName.length(), 0, 256)) return false;
		}
		else
		{
			m_szMapScriptName = gDLL->getText("TXT_KEY_TRAIT_PLAYER_UNKNOWN");
		}
		stream.Read(&iType);
		m_eWorldSize = (WorldSizeTypes)iType;
		if (!isInBounds(m_eWorldSize, 0, 2 * GC.getNumWorldInfos())) return false;
		stream.Read(&iType);
		m_eClimate = (ClimateTypes)iType;
		if (!isInBounds(m_eClimate, 0, 2 * GC.getNumClimateInfos())) return false;
		stream.Read(&iType);
		m_eSeaLevel = (SeaLevelTypes)iType;
		// (trs.replayname: Sea level is unused, so mods may repurpose it. AdvCiv does.)
		//if (!isInBounds(m_eSeaLevel, 0, 2 * GC.getNumSeaLevelInfos())) return false;
		stream.Read(&iType);
		m_eEra = (EraTypes)iType;
		if (!isInBounds(m_eEra, 0, 2 * GC.getNumWorldInfos())) return false;
		stream.Read(&iType);
		m_eGameSpeed = (GameSpeedTypes)iType;
		if (!isInBounds(m_eGameSpeed, 0, 2 * GC.getNumGameSpeedInfos())) return false;
		stream.Read(&iNumTypes);
		if (!isInBounds(iNumTypes, 0, 2 * NUM_GAMEOPTION_TYPES)) return false;
		for (int i = 0; i < iNumTypes; i++)
		{
			stream.Read(&iType);
			if (!isInBounds(iType, 0, 2 * NUM_GAMEOPTION_TYPES)) return false;
			m_listGameOptions.push_back((GameOptionTypes)iType);
		}
		stream.Read(&iNumTypes);
		if (!isInBounds(iNumTypes, 0, 2 * GC.getNumVictoryInfos())) return false;
		for (int i = 0; i < iNumTypes; i++)
		{
			stream.Read(&iType);
			if (!isInBounds(iType, 0, 2 * GC.getNumVictoryInfos())) return false;
			m_listVictoryTypes.push_back((VictoryTypes)iType);
		}
		stream.Read(&iType);
		m_eVictoryType = (VictoryTypes)iType;
		if (!isInBounds(m_eVictoryType, -1, 2 * GC.getNumVictoryInfos())) return false;
		stream.Read(&iNumTypes);
		if (!isInBounds(iNumTypes, 0, 64000)) return false;
		for (int i = 0; i < iNumTypes; i++)
		{
			CvReplayMessage* pMessage = new CvReplayMessage(0);
			if (NULL != pMessage)
			{
				pMessage->read(stream);
			}
			m_listReplayMessages.push_back(pMessage);
		}
		stream.Read(&m_iInitialTurn);
		if (!isInBounds(m_iInitialTurn, 0, 1500)) return false;
		stream.Read(&m_iStartYear);
		if (!isInBounds(m_iStartYear, -15000, 150000)) return false;
		stream.Read(&m_iFinalTurn);
		if (!isInBounds(m_iInitialTurn, 0, 15000)) return false;
		stream.ReadString(m_szFinalDate);
		if (!isInBounds(m_szFinalDate.length(), 4, 64)) return false;
		stream.Read(&iType);
		m_eCalendar = (CalendarTypes)iType;
		if (!isInBounds(m_eCalendar, 0, 2 * GC.getNumCalendarInfos())) return false;
		stream.Read(&m.iNormalizedScore);
		if (!isInBounds(m.iNormalizedScore, -15000, 1500000)) return false;
		stream.Read(&iNumTypes);
		if (!isInBounds(iNumTypes, 1, 128)) return false;
		for (int i = 0; i < iNumTypes; i++)
		{
			PlayerInfo info;
			stream.Read(&iType);
			info.m_eLeader = (LeaderHeadTypes)iType;
			if (!isInBounds(info.m_eLeader, 0, 2 * GC.getNumLeaderHeadInfos())) return false;
			stream.Read(&iType);
			info.m_eColor = (ColorTypes)iType;
			if (!isInBounds(info.m_eColor, 0, 2 * GC.getNumColorInfos())) return false;
			int jNumTypes;
			stream.Read(&jNumTypes);
			if (!isInBounds(jNumTypes, 0, 15000)) return false;
			for (int j = 0; j < jNumTypes; j++)
			{
				TurnData data;
				stream.Read(&(data.m_iScore));
				stream.Read(&(data.m_iEconomy));
				stream.Read(&(data.m_iIndustry));
				stream.Read(&(data.m_iAgriculture));
				info.m_listScore.push_back(data);
			}
			m_listPlayerScoreHistory.push_back(info);
		}
		stream.Read(&m_iMapWidth);
		if (!isInBounds(m_iMapWidth, 1, 1000)) return false;
		stream.Read(&m_iMapHeight);
		if (!isInBounds(m_iMapHeight, 1, 1000)) return false;
		SAFE_DELETE(m_pcMinimapPixels);
		m_pcMinimapPixels = new unsigned char[m_nMinimapSize];
		stream.Read(m_nMinimapSize, m_pcMinimapPixels);
		stream.Read(&m_bMultiplayer);
		if (iVersion > 2)
		{
			stream.ReadString(m_szModName);
		}
	}
	catch (...)
	{
		bSuccess = false;
	}
	return bSuccess;
}

void CvReplayInfo::write(FDataStreamBase& stream)
{
	stream.Write(REPLAY_VERSION);
	stream.Write(m_iActivePlayer);
	stream.Write((int)m_eDifficulty);
	stream.WriteString(m_szLeaderName);
	stream.WriteString(m_szCivDescription);
	stream.WriteString(m_szShortCivDescription);
	stream.WriteString(m_szCivAdjective);
	stream.WriteString(m_szMapScriptName);
	stream.Write((int)m_eWorldSize);
	stream.Write((int)m_eClimate);
	stream.Write((int)m_eSeaLevel);
	stream.Write((int)m_eEra);
	stream.Write((int)m_eGameSpeed);
	stream.Write((int)m_listGameOptions.size());
	for (uint i = 0; i < m_listGameOptions.size(); i++)
	{
		stream.Write((int)m_listGameOptions[i]);
	}
	stream.Write((int)m_listVictoryTypes.size());
	for (uint i = 0; i < m_listVictoryTypes.size(); i++)
	{
		stream.Write((int)m_listVictoryTypes[i]);
	}
	stream.Write((int)m_eVictoryType);
	stream.Write((int)m_listReplayMessages.size());
	ReplayMessageList::const_iterator it;
	for (uint i = 0; i < m_listReplayMessages.size(); i++)
	{
		if (NULL != m_listReplayMessages[i])
		{
			m_listReplayMessages[i]->write(stream);
		}
	}
	stream.Write(m_iInitialTurn);
	stream.Write(m_iStartYear);
	stream.Write(m_iFinalTurn);
	stream.WriteString(m_szFinalDate);
	stream.Write((int)m_eCalendar);
	stream.Write(m.iNormalizedScore);
	stream.Write((int)m_listPlayerScoreHistory.size());
	for (uint i = 0; i < m_listPlayerScoreHistory.size(); i++)
	{
		PlayerInfo& info = m_listPlayerScoreHistory[i];
		stream.Write((int)info.m_eLeader);
		stream.Write((int)info.m_eColor);
		stream.Write((int)info.m_listScore.size());
		for (uint j = 0; j < info.m_listScore.size(); j++)
		{
			stream.Write(info.m_listScore[j].m_iScore);
			stream.Write(info.m_listScore[j].m_iEconomy);
			stream.Write(info.m_listScore[j].m_iIndustry);
			stream.Write(info.m_listScore[j].m_iAgriculture);
		}
	}
	stream.Write(m_iMapWidth);
	stream.Write(m_iMapHeight);
	stream.Write(m_nMinimapSize, m_pcMinimapPixels);
	stream.Write(m_bMultiplayer);
	stream.WriteString(m_szModName);
}

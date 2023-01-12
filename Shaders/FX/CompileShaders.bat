
set FXC= fxc.exe
set Outdir=..\FXO

md %outdir%

for %%I in (Water Civ4FlagDecal Civ4Leaderheadshader Civ4Mech Civ4SkinningTeamColor Civ4Wave ContourShader CultureBOrderShader PlotIndicator River Symbols Terrain_splatTile Civ4Bloom Civ4TorusFur) do (
	%FXC% /LD /nologo /T fx_2_0 /Fo %Outdir%\%%I.fx %%I.fx
)

PAUSE
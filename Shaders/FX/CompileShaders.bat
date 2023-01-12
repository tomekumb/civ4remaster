
set FXC= fxc.exe
set Outdir="D:\SteamLibrary\steamapps\common\Sid Meier's Civilization IV Beyond the Sword\Beyond the Sword\Shaders\FXO"

md %outdir%

@REM for %%I in (Water Civ4FlagDecal Civ4Leaderheadshader Civ4Mech Civ4SkinningTeamColor Civ4Wave ContourShader CultureBOrderShader PlotIndicator River Symbols Terrain_splatTile Civ4Bloom Civ4TorusFur) do (
@REM 	%FXC% /LD /nologo /T fx_2_0 /Fo %Outdir%\%%I.fx %%I.fx
@REM )


for %%I in (Terrain_splatTile ContourShader River Civ4Wave Water) do (
	%FXC% /LD /nologo /T fx_2_0 /Fo %Outdir%\%%I.fx %%I.fx
)

@REM PAUSE
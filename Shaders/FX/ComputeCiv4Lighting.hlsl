// Globals
float3		f3LightDiffuse : GLOBAL;
float3		f3LightDir : GLOBAL;
float3      f3AmbientColor : GLOBAL;//  = { 0.9463, 0.0, 0.0 };
//------------------------------------------------------------------------------------------------
//                          FUNCTION - ComputeCiv4Lighting
//
//	f3Normal		: - The normal of the given vertex having its lighting calculation performed
//-------------------------------------------------------------------------------------------------
//	Notes:	#1. Lighting calculations are based on those of Civ4's scenelights.nif
//				The direction/color of the lights are used as globals in this file. If they
//				are going to change, then they should be put in the global shader constant map
//------------------------------------------------------------------------------------------------
float3 ComputeCiv4Lighting( float3 f3Normal )
{
	// Calculate the diffuse light color, based on three lights	
	float3 fDiffuse = 0.0;
	fDiffuse += dot( f3Normal.xyz, -f3LightDir ) * f3LightDiffuse;
	fDiffuse += f3AmbientColor;
	
	return fDiffuse;
}


technique TCustomBuildDummy
{
}
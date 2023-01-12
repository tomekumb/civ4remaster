// SunLight
float3		f3SunLightDiffuse : GLOBAL = {-0.6428f, 0.24603, -0.7254f};
float3		f3SunLightDir : GLOBAL     = {1.0f, 1.0f, 1.0f};
float3      f3SunAmbientColor : GLOBAL = { 0.2471f, 0.2353f,  0.3020f};

//Unit Light
float3      f3UnitLightDir: GLOBAL		= {-0.6428f, 0.24603, -0.7254f};
float3      f3UnitLightDiffuse: GLOBAL	= {1.0f, 1.0f, 1.0f};
float3      f3UnitAmbientColor: GLOBAL	= { 0.2471f, 0.2353f,  0.3020f};


//Mech Light
float3      f3MechLightDir: GLOBAL    = {-0.6428f, 0.24603, -0.7254f};
float3      f3MechLightDiffuse: GLOBAL= {1.0f, 1.0f, 1.0f};
float3      f3MechAmbientColor: GLOBAL= { 0.2471f, 0.2353f,  0.3020f};

//------------------------------------------------------------------------------------------------
//                          FUNCTION - ComputeCiv4Lighting
//
//	f3Normal		: - The normal of the given vertex having its lighting calculation performed
//-------------------------------------------------------------------------------------------------
//	Notes:	#1. Lighting calculations are based on those of Civ4's Civilization4\Assets\Art\Terrain\Lights
//				The direction/color of the lights are used as globals in this file. If they
//				are going to change, then they should be put in the global shader constant map
//------------------------------------------------------------------------------------------------
float3 ComputeCiv4Lighting( float3 f3Normal )
{
	return saturate(dot(f3Normal.xyz, -f3SunLightDir )) * f3SunLightDiffuse + f3SunAmbientColor;
}

float3 ComputeCiv4UnitLighting( float3 f3Normal )
{
	return saturate(dot(f3Normal.xyz, -f3UnitLightDir )) * f3UnitLightDiffuse + f3UnitAmbientColor;
}

float3 ComputeCiv4MechLighting( float3 f3Normal )
{
	return saturate(dot(f3Normal.xyz, -f3MechLightDir )) * f3MechLightDiffuse + f3MechAmbientColor;
}


technique TCustomBuildDummy
{
}

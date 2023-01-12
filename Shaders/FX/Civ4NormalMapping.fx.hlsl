//  $Header: $
//------------------------------------------------------------------------------------------------
//
//  ***************** CIV4 GAME ENGINE   ********************
//
//! \file		Civ4NormalMapping.hlsl
//! \author		Bart Muzzin & Jason Winokur-- 4-19-2005
//! \brief		
//
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2005 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------
	
//------------------------------------------------------------------------------------------------
//                          STRUCTURES
//------------------------------------------------------------------------------------------------  

struct NMLIGHT_INPUT
{
	float3 f3Position;
	float4 f4ObjectViewDir;
	float3x3 mtxObjToTangentSpace;
	float4x4 mtxWorldInv;
};

struct NMLIGHT_OUTPUT
{
	float3 f3LightHalfAngle;
	float3 f3LightVec;
};

//------------------------------------------------------------------------------------------------
//                          FUNCTIONS
//------------------------------------------------------------------------------------------------  
NMLIGHT_OUTPUT ComputeNormalMappingVectors( float3 f3LightPos, NMLIGHT_INPUT kInput )
{
	NMLIGHT_OUTPUT kOutput = (NMLIGHT_OUTPUT)(0);
	float4 f4ObjectLightDir = mul(f3LightPos - kInput.f3Position, kInput.mtxWorldInv);
	float4 f4VertNormLightVec = normalize(f4ObjectLightDir);
	kOutput.f3LightHalfAngle.xyz = 0.5 * mul( kInput.mtxObjToTangentSpace, ( kInput.f4ObjectViewDir + f4VertNormLightVec.xyz ) / 2.0 ) + float3( 0.5, 0.5, 0.5 );
	kOutput.f3LightVec.xyz = 0.5 * mul( kInput.mtxObjToTangentSpace, f4VertNormLightVec.xyz ) + float3(0.5, 0.5, 0.5);
	return kOutput;
}

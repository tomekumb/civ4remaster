//  $Header: $
//------------------------------------------------------------------------------------------------
//
//  ***************** CIV4 GAME ENGINE   ********************
//
//! \file		Civ4TorusFur.fx
//! \author		Bart Muzzin -- 06/30/2005
//! \brief		Torus lighting (for fur effect on Genghis Khan).
//
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2005 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------
// VARIABLES
//------------------------------------------------------------------------------------------------  

float4x4	mtxViewProj			: VIEWPROJECTION;
float4x4	mtxWorld			: WORLD;

float2		f2RadiusParam		: GLOBAL = { 9.28, 4.08 };
float3		f3TorusCenter		: GLOBAL = { 0.0, 0.0, 0.0 };
float3		f3LightPos1			: GLOBAL = { -378, -476, 605.0 };	// key light world position
float3		f3DiffuseColor1		: GLOBAL = { 1.0, 1.0, 1.0 };		// key light diffuse color
float3		f3LightPos2			: GLOBAL = { 500, -494, 0.0 };		// fill light world position
float3		f3DiffuseColor2		: GLOBAL = { 0.4, 0.4, 0.4 };		// fill light diffuse color
float3		f3LightPos3			: GLOBAL = { 624, 409, -203 };		// back light world position
float3		f3DiffuseColor3		: GLOBAL = { 0.6, 0.6, 0.6 };		// back light diffuse color
float3		f3Ambient			: GLOBAL = { 0.5, 0.5, 0.5 };		// ambient color




//------------------------------------------------------------------------------------------------
// TEXTURES
//------------------------------------------------------------------------------------------------  
texture BaseTexture < string NTM = "base";>;

//------------------------------------------------------------------------------------------------
// SAMPLERS
//------------------------------------------------------------------------------------------------  
sampler BaseSampler = sampler_state
{
	Texture = (BaseTexture);
	AddressU = Clamp;
	AddressV = Clamp;
	AddressW = Clamp;
	MagFilter = Linear;
	MipFilter = Linear;
	MinFilter = Linear; 
};

//------------------------------------------------------------------------------------------------
// STRUCTURES
//------------------------------------------------------------------------------------------------  
struct VS_INPUT
{
	float4	f4Position : POSITION;
	float4	f4Normal	: NORMAL; //remove!
	float2	f2TexCoord : TEXCOORD0;
};

struct PS_INPUT
{
	float4	f4Position	: POSITION;
	float2	f2TexCoord	: TEXCOORD0;
	float3	f3Diffuse	: COLOR0;
};

//------------------------------------------------------------------------------------------------
// SHADERS
//------------------------------------------------------------------------------------------------
PS_INPUT VSFurPass_11( VS_INPUT kInput)
{
	PS_INPUT kOutput = (PS_INPUT)(0);
	
	float4 f4WorldPosition = mul( kInput.f4Position, mtxWorld );
	kOutput.f4Position = mul( f4WorldPosition, mtxViewProj );
	kOutput.f2TexCoord = kInput.f2TexCoord;
	
	// Do normal calculations in object space, then convert to worldview space
	float3 f3WorkPos = kInput.f4Position;
	float fTheta = atan2( f3WorkPos.x, f3WorkPos.y );
	float3 f3MajorRadiusPos = float3( mul( f2RadiusParam.x, sin( fTheta ) ), mul( f2RadiusParam.x, cos( fTheta ) ), 0.0 );
	f3MajorRadiusPos = mul( f3MajorRadiusPos, mtxWorld );
	
	float3 f3WSNormal = normalize( f3WorkPos - f3MajorRadiusPos);
	
	float3 f3Diffuse;
	float3 f3Specular;
	
	float3 f3LightDir1 = normalize(f4WorldPosition - f3LightPos1);
	float3 f3LightDir2 = normalize(f4WorldPosition - f3LightPos2);
	float3 f3LightDir3 = normalize(f4WorldPosition - f3LightPos3);
	
	f3Diffuse	= (saturate( dot( f3WSNormal, -f3LightDir1 ) ) * f3DiffuseColor1);
	f3Diffuse	+= (saturate( dot( f3WSNormal, -f3LightDir2 ) ) * f3DiffuseColor2);
	f3Diffuse	+= (saturate( dot( f3WSNormal, -f3LightDir3 ) ) * f3DiffuseColor3);

	kOutput.f3Diffuse = saturate( f3Diffuse );
			
	return kOutput;
}

//------------------------------------------------------------------------------------------------
// TECHNIQUES
//------------------------------------------------------------------------------------------------
technique TTorusFur<
	string shadername = "TTorusFur";
	int implementation = 0;
	bool UsesNIRenderState = true; >
{
	pass P0
	{
        // Disable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;		
        Lighting		= TRUE;

        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = TRUE;
        AlphaRef		 = 180;
        AlphaFunc		 = GREATER;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;

		VertexShader = compile vs_1_1 VSFurPass_11();
		PixelShader = NULL;
		
		Sampler[0] = <BaseSampler>;
		
		ColorOp[0] = Modulate;
		ColorArg0[0] = Diffuse;
		ColorArg1[0] = Texture;
	}
};

technique TTorusFur_FF <
	string shadername = "TTorusFur";
	int implementation = 1;
	bool UsesNIRenderState = true; >
{
	pass P0
	{
        // Disable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;		
        Lighting		= TRUE;

        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = TRUE;
        AlphaRef		 = 180;
        AlphaFunc		 = GREATER;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;

		VertexShader = NULL;
		PixelShader = NULL;
		
		Sampler[0] = <BaseSampler>;
		
		ColorOp[0] = SelectArg1;
		ColorArg0[0] = Texture;
		ColorArg1[0] = Texture;
	}
};

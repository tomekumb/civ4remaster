//------------------------------------------------------------------------------------------------
//  $Header: $
//------------------------------------------------------------------------------------------------
//  *****************   FIRAXIS GAME ENGINE   ********************
//
//  FILE:    TreeGroupVS11
//
//  AUTHOR:  Tom Whittaker - 12/10/2003
//
//  PURPOSE: Tree Group Vertex Shader
//                - Adjusts a vertex by a worldspace offset. 
//                - Used to place tree patches on the terrain.
//                - Could be used for similar patches( rocks, bushes,etc)
//
//  Listing: fxc /Tvs_1_1 /ETreeVS /FcTreeShader.lst TreeShader.fx
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2003 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------


//------------------------------------------------------------------------------------------------
//                          VARIABLES
//------------------------------------------------------------------------------------------------          
// EffectEdit varibles
int    BCLR = 0xff202080;   // background
string XFile = "tiger.x";   // model


// Globals
float3		f3LightColor1		= { 1.0 * 0.9, 0.9922 * 0.9, 0.9373 * 0.9 };
float3		f3LightColor2		= { 1.0 * 0.2, 1.0 * 0.2, 1.0 * 0.2 };
float3		f3LightColor3		= { 0.8431 * 0.25, 0.9490 * 0.25, 1.0 * 0.25 };
float3		f3LightDir1			= { -0.88352085, 0.32610506, -0.33596089 };
float3		f3LightDir2			= { -0.2408, 0.1204, -0.9631 };
float3		f3LightDir3			= { 0.9463, 0.3232, -0.0045 };



//Need updated Gamebyro to support SetArray() calls
float4 fHeightOffset0[24] : GLOBAL;						// Height offset index by Id
float4x4 mtxFogMat  : GLOBAL;

// Transformations
float4x4 World      : WORLD;
float4x4 WorldViewProj: WORLDVIEWPROJECTION;


//------------------------------------------------------------------------------------------------
//                          VERTEX INPUT & OUTPUT FORMATS
//------------------------------------------------------------------------------------------------ 
struct VS_INPUT
{
   float3 Pos     : POSITION;
   float3 Normal  : NORMAL;
   float4 Color   : COLOR;
   float2 Tex     : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 f4Pos                : POSITION;
    float4 Diff					: COLOR0;
    float2 f2TexCoords          : TEXCOORD0;
    float2 f2TexCoords2         : TEXCOORD1;
};


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
	float3 f3Diffuse = 0;
	f3Diffuse += dot( f3Normal.xyz, -f3LightDir1 ) * f3LightColor1;
	f3Diffuse += dot( f3Normal.xyz, -f3LightDir2 ) * f3LightColor2;
	f3Diffuse += dot( f3Normal.xyz, -f3LightDir3 ) * f3LightColor3;
	return f3Diffuse;
}


//------------------------------------------------------------------------------------------------
//                          VERTEX SHADER
//------------------------------------------------------------------------------------------------
//
// - Adjust Z height based on Heights[Color.R] 
//

VS_OUTPUT TreeVS( VS_INPUT v )
{
    VS_OUTPUT Out = (VS_OUTPUT)0;

    v.Pos.z += fHeightOffset0[v.Color.r*256.0f].x;				//Adjut height by Height offset 
	Out.f4Pos  = mul(float4(v.Pos, 1), WorldViewProj);
    float3 P = mul(float4(v.Pos, 1), (float4x3)World);			//todotw: if we're only going to need this for Fog combine the 2 and remove the transform

    // Set texture coordinates
    Out.f2TexCoords = v.Tex;
    Out.f2TexCoords2 = mul(float4(P,1),mtxFogMat);
   	Out.Diff.rgb	= ComputeCiv4Lighting( v.Normal );	// L.N
   	Out.Diff.a = 1.0f;
    //Out.Diff = (1.0, 0.0, 0.0, 1.0);    
    
    return Out;
}

//------------------------------------------------------------------------------------------------
//                          PIXEL SHADER
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//                          SAMPLERS
//------------------------------------------------------------------------------------------------  
texture BaseTexture <string NTM = "base";>;

sampler TreeBase = sampler_state
{
    Texture = (BaseTexture);
    AddressU  = WRAP;
    AddressV  = WRAP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;
};

texture FogOfWarMap <string NTM = "shader"; int NTMIndex = 1; >;
sampler FogOfWarSampler = sampler_state
{
    Texture = (FogOfWarMap);
    AddressU  = WRAP;
    AddressV  = WRAP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;
};


PIXELSHADER Basic_PS = asm
{
	ps_1_1	
	tex			t0						
	tex			t1						

	mul			r0, t0,t1
	mul			r0, r0, v0.rgba 
};

//------------------------------------------------------------------------------------------------
//                          TECHNIQUES
//------------------------------------------------------------------------------------------------
technique TTree_Basic
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;
        
        // Enable lighting
        Lighting       = TRUE;

        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;//FALSE;
        AlphaTestEnable	 = TRUE;
        AlphaFunc		 = GREATER;
        AlphaRef		 = 32;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;
        
        // Set the smaplers
        Sampler[0] = <TreeBase>;
   		Texture[1] = <FogOfWarMap>;
   		
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;

        TextureTransformFlags[1] = PROJECTED;//
        
        // Set up textures and texture stage states
        VertexShader = compile vs_1_1 TreeVS();
        PixelShader  = <Basic_PS>;//null;//
    }
}

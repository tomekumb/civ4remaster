//------------------------------------------------------------------------------------------------
//  $Header: $
//------------------------------------------------------------------------------------------------
//  *****************   FIRAXIS GAME ENGINE   ********************
//
//  FILE:    ContourGroupVS11
//
//  AUTHOR:  Tom Whittaker - 12/10/2003
//
//  PURPOSE: Contour Group Vertex Shader
//                - Adjusts a vertex by a worldspace offset. 
//                - Used to place objects patches on the terrain.
//
//  Listing: fxc /Tvs_1_1 /EContourVS /FcContourShader.lst ContourShader.fx
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2003 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------
//                          VARIABLES
//------------------------------------------------------------------------------------------------          

float4x4 World : WORLD;
float4x4 WorldViewProj: WORLDVIEWPROJECTION;

float4x4 mtxFOW  : GLOBAL;
float4x4 mtxLightmap: GLOBAL;
float4 fHeightOffset0[64] : GLOBAL;		// Height offset index by Id 
float fFrameTime : GLOBAL;



//------------------------------------------------------------------------------------------------
//                          VERTEX INPUT & OUTPUT FORMATS
//------------------------------------------------------------------------------------------------ 
struct VS_INPUT
{
   float3 Pos     : POSITION;
   float3 Normal  : NORMAL;
   float4 InstanceIndex: COLOR;
   float2 Tex     : TEXCOORD0;
};


struct VS_OUTPUT
{
    float4 f4Pos                : POSITION;
    float4 Diff					: COLOR0;
    float2 f2TexCoords0         : TEXCOORD0;	//base
    float4 f4TexCoords1         : TEXCOORD1;	//fow
    float4 f4TexCoords2			: TEXCOORD2;	//texkill
};


//Include Civ4's generic lighting equation, used in several shaders
#include "ComputeCiv4Lighting.fx"

//float treeKillHeight : LOCAL  = 240.0f ;

float3 windir :GLOBAL= { 0.2, 0, 0.0f};
//------------------------------------------------------------------------------------------------
//                          VERTEX SHADER
//------------------------------------------------------------------------------------------------
//
// - Adjust Z height based on Heights[Color.R] 
//
VS_OUTPUT ContourVS( VS_INPUT vIn )
{
    VS_OUTPUT vOut = (VS_OUTPUT)0;

	//Transform vertex and adjust height offset
	int index = vIn.InstanceIndex.x * 256.0f;
    vIn.Pos.z += fHeightOffset0[index].x;				//Adjut height by Height offset 
    float zdist = vIn.Pos.z - fHeightOffset0[index].x;
    vIn.Pos += sin(fFrameTime + index) * zdist * windir * 0.15;
	vOut.f4Pos  = mul(float4(vIn.Pos, 1), WorldViewProj);
    float3 P = mul(float4(vIn.Pos, 1), (float4x3)World);			

    // Set texture coordinates
    vOut.f2TexCoords0 = vIn.Tex;
    vOut.f4TexCoords1 = mul(float4(P,1),mtxFOW);
    vOut.f4TexCoords2.xy = vIn.Pos.z + 80.0f;//treeKillHeight;//mul(float4(P,1),mtxLightmap);
   	vOut.Diff.rgb	  = 1.0f;//ComputeCiv4Lighting( vIn.Normal );	// L.N
   	vOut.Diff.a       = 1.0f;
    
    return vOut;
}

//------------------------------------------------------------------------------------------------
//                          PIXEL SHADER
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//                          SAMPLERS
//------------------------------------------------------------------------------------------------  
texture BaseTexture <string NTM = "base";>;
texture ShadowMap   <string NTM = "shader"; int NTMIndex = 1; >;
texture FogOfWarMap <string NTM = "shader"; int NTMIndex = 2; >;

sampler ContourBase      = sampler_state{ Texture = (BaseTexture);  AddressU = wrap; AddressV = wrap; MagFilter = linear; MinFilter = linear; MipFilter = linear;};
sampler ShadowMapSampler = sampler_state{ Texture = (ShadowMap);    AddressU = wrap; AddressV = wrap; MagFilter = linear; MinFilter = linear; MipFilter = linear;};
sampler FogOfWarSampler  = sampler_state{ Texture = (FogOfWarMap);  AddressU = wrap; AddressV = wrap; MagFilter = linear; MinFilter = linear; MipFilter = linear;};


PIXELSHADER Shadowmap_PS = asm
{
	ps_1_1	
	tex			t0				//base		
	tex			t1				//fow
	//tex		    t2				//shadowmap					

	texkill  t2
	mul			r0, t0,t1		// base * fow
	//mul			r0, r0,t2		// base * fow * shadow
	mul			r0, r0, v0.rgba // base * fow * shadow * color
};

//------------------------------------------------------------------------------------------------
//                          TECHNIQUES //bool UsesNIRenderState = true;>
//------------------------------------------------------------------------------------------------
technique Contour_Shader< string shadername = "Contour_Shader"; int implementation=0; bool UsesNIRenderState = true;>
{
    pass P0
    {
        // Set the smaplers
        Sampler[0] = <ContourBase>;
   		Sampler[1] = <FogOfWarSampler>;
   		//Sampler[2] = <ShadowMapSampler>;
   		
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        //TexCoordIndex[2] = 2;

		TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = PROJECTED;
        //TextureTransformFlags[2] = PROJECTED;
        
        // Set up textures and texture stage states
        VertexShader = compile vs_1_1 ContourVS();
        PixelShader  = <Shadowmap_PS>;
    }
}

//<bool UsesNIRenderState = true;>
technique TContour_FF< string shadername = "Contour_Shader"; int implementation=1; bool UsesNIRenderState = true;>
{
    pass P0
    {
		// Enable depth writing
		ZEnable				= TRUE;
		ZWriteEnable		= TRUE;
		ZFunc				= LESSEQUAL;

		// Disable lighting
		Lighting			= FALSE;

		// Disable alpha blending and testing	
		AlphaBlendEnable = true;
		AlphaTestEnable	 = true;
		//AlphaRef         = 0;
		AlphaFunc        = GREATER;
		SrcBlend		 = SRCALPHA;
		DestBlend		 = INVSRCALPHA;
   
        // textures
        Texture[0]  = (BaseTexture);
        Texture[1]  = (FogOfWarMap);

		TexCoordIndex[0] = 0;
		TexCoordIndex[1] = CAMERASPACEPOSITION;

		TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = Count3;	

		TextureTransform[0] = 0;
		TextureTransform[1] = <mtxFOW>;
        
       	// texture stage 0 - Base Texture
		ColorOp[0]       = SelectArg1;
		ColorArg1[0]     = Texture;
		AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;

		// texture stage 2	- FoW
		ColorOp[1]       = Modulate;
		ColorArg1[1]     = Texture;
		ColorArg2[1]     = Current;
		AlphaOp[1]		 = SelectArg1;
		AlphaArg1[1]	 = Current;

		// texture stage 3 
		ColorOp[2]       = disable;
		AlphaOp[2]		 = disable;

      	// shaders
		VertexShader     = NULL;
		PixelShader      = NULL;
    }
}



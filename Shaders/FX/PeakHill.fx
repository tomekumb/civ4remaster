//------------------------------------------------------------------------------------------------
//  $Header: $
//------------------------------------------------------------------------------------------------
//  *****************   FIRAXIS GAME ENGINE   ********************
//
//  FILE:    Peak and Hill decal shader
//
//  AUTHOR:  Tom Whittaker - 4/2005
//
//  PURPOSE: Decal texture blends for peak and hill terrain decals
//
//  Listing: fxc /Tvs_1_1 /EWaterVS /FcWater.lst Water.fx
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2003 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------
//                          VARIABLES
//------------------------------------------------------------------------------------------------          

// Transformations
float4x4 mtxWorldViewProj: WORLDVIEWPROJECTION;
float4x4    mtxWorld   : WORLD;
float4x4	mtxFOW     : GLOBAL;
float4x4    mtxLightmap: GLOBAL;


//------------------------------------------------------------------------------------------------
// TEXTURES
//------------------------------------------------------------------------------------------------  
texture DecalBaseTexture	   <string NTM = "base";>;//<string NTM = "shader";  int NTMIndex = 0;>;
texture TerrainFOWarTexture    <string NTM = "shader";  int NTMIndex = 1;>;
texture TerrainLightmapTexture <string NTM = "shader";  int NTMIndex = 2;>;


//------------------------------------------------------------------------------------------------
//                          SAMPLERS
//------------------------------------------------------------------------------------------------  
sampler DecalBase	   = sampler_state{ Texture = (DecalBaseTexture);		AddressU = wrap;  AddressV = wrap;  MagFilter = LINEAR; MinFilter = LINEAR; MipFilter = LINEAR;};
sampler FOWar          = sampler_state{ Texture = (TerrainFOWarTexture);	AddressU = Wrap; AddressV = Wrap;	MagFilter = Linear;	MipFilter = Linear;	MinFilter = Linear; };
sampler TerrainLightmap= sampler_state{ Texture = (TerrainLightmapTexture); AddressU = Wrap;  AddressV = Wrap;  MagFilter = Linear; MipFilter = Linear; MinFilter = Linear; };

//------------------------------------------------------------------------------------------------
//                          VERTEX INPUT & OUTPUT FORMATS
//------------------------------------------------------------------------------------------------ 
struct VS_INPUT
{
   float3 f3Pos     : POSITION;
   float4 f4Color   : COLOR;
   float2 f2BaseTex : TEXCOORD0;
};

struct VS_OUTPUT
{
	float4 f4Pos		: POSITION;
	float4 f4Diff		: COLOR0;
	float2 f2BaseTex	: TEXCOORD0;
	float2 f2FowTex		: TEXCOORD1;
	float2 f2LightMapTex: TEXCOORD2;	// Lightmap 

};

//------------------------------------------------------------------------------------------------
//                          VERTEX SHADER
//------------------------------------------------------------------------------------------------
VS_OUTPUT PeakHillVS( VS_INPUT vIn )
{
    VS_OUTPUT vOut = (VS_OUTPUT)0;
	
   	vOut.f4Pos  = mul(float4(vIn.f3Pos, 1), mtxWorldViewProj);	
	float3 worldPos = mul(float4(vIn.f3Pos, 1), (float4x3)mtxWorld);			//todotw: if we're only going to need this for Fog combine the 2 and remove the transform

    // Set texture coordinates
    vOut.f2BaseTex = vIn.f2BaseTex;
    vOut.f2FowTex  = mul(float4(worldPos,1),mtxFOW);			// fog of war
   	vOut.f2LightMapTex = mul(float4(worldPos,1),mtxLightmap);	// Lightmap 
	vOut.f4Diff = vIn.f4Color;

   return vOut;
}
//------------------------------------------------------------------------------------------------
//                          PIXEL SHADER
//------------------------------------------------------------------------------------------------
float4 PeakHillPS( VS_OUTPUT vIn ) : COLOR
{
	float4	f4FinalColor = 0.0f;

	// Get Base textures 
	float4 f4Base    = tex2D( DecalBase,  vIn.f2BaseTex );
	float3 f4LighMap = tex2D( TerrainLightmap, vIn.f2LightMapTex);
	float3 f4FOWTex  = tex2D( FOWar, vIn.f2FowTex );

	f4FinalColor = f4Base;				// base 
	f4FinalColor.rgb *= f4LighMap;		// modulate by the diffuse,ambient, shadow term(no specular)
	f4FinalColor.rgb *= f4FOWTex;		// fow
		
	return f4FinalColor;
}
//------------------------------------------------------------------------------------------------
//                          TECHNIQUES
//------------------------------------------------------------------------------------------------
technique TPeakHill_Shader_11
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;
        
        
        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = FALSE;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;
        
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
       
        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
        TextureTransformFlags[2] = 0;
               
        // Set up textures and texture stage states
        VertexShader = compile vs_1_1 PeakHillVS();
        PixelShader  = compile ps_1_1 PeakHillPS();
    }
}

technique TPeakHill_Shader_FF
{
	//todotw: fix function version
}

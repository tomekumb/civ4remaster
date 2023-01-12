//------------------------------------------------------------------------------------------------
//  $Header: $
//------------------------------------------------------------------------------------------------
//  FILE:   Decal Shader
//
//  AUTHOR:  Tom Whittaker - 4/12/2004
//
//  PURPOSE: Decal need to use a shader transform if terrain is rendered using shaders
//------------------------------------------------------------------------------------------------

//Include Civ4's generic lighting equation, used in several shaders
//#include "ComputeCiv4Lighting.hlsl"

//------------------------------------------------------------------------------------------------
//                          VARIABLES
//------------------------------------------------------------------------------------------------          

// Transformations
float4x4 mtxWorldViewProj: WORLDVIEWPROJECTION;

//------------------------------------------------------------------------------------------------
//                          VERTEX INPUT & OUTPUT FORMATS
//------------------------------------------------------------------------------------------------ 
struct VS_INPUT
{
   float3 f3Pos     : POSITION;
   float2 f2BaseTex : TEXCOORD0;
 };
struct VS_OUTPUT
{
	float4 f4Pos     : POSITION;
	float4 f4Diff	 : COLOR0;
	float2 f2BaseTex : TEXCOORD0;
};

//------------------------------------------------------------------------------------------------
//                          VERTEX SHADER
//------------------------------------------------------------------------------------------------
VS_OUTPUT DecalVS( float3 f3Pos : POSITION, 
							float2 f2TexCoord1	: TEXCOORD0
							)
{
    VS_OUTPUT vOut = (VS_OUTPUT)0;
	
	//Transform point
   	vOut.f4Pos  = mul(float4(f3Pos, 1), mtxWorldViewProj);	

    // Set texture coordinates
    float4 color={ 1.0f, 1.0f, 1.0f, 1.0f };  
    vOut.f4Diff = color;
    vOut.f2BaseTex =f2TexCoord1;

   return vOut;
}
//------------------------------------------------------------------------------------------------
texture BaseTexture <string NTM = "base";>;
sampler DecalBase = sampler_state
{
    Texture = (BaseTexture);
    AddressU  = CLAMP;//WRAP;
    AddressV  = CLAMP;//WRAP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;
};

//------------------------------------------------------------------------------------------------
float4 DecalPS( VS_OUTPUT vIn ) : COLOR
{
	float4	f4FinalColor = 0.0f;

	// Get Base textures 
	f4FinalColor = tex2D( DecalBase,  vIn.f2BaseTex );
	
	return f4FinalColor;
}
//------------------------------------------------------------------------------------------------
//                          TECHNIQUES
//------------------------------------------------------------------------------------------------
technique TDecal_Transform_11
{
    pass P0
    {
        VertexShader = compile vs_1_1 DecalVS();
        PixelShader  = compile ps_1_1 DecalPS();
    }
}


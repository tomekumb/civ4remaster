//------------------------------------------------------------------------------------------------
//  $Header: $
//------------------------------------------------------------------------------------------------
//  *****************   FIRAXIS GAME ENGINE   ********************
//
//  FILE:    Waves
//
//  AUTHOR:  Tom Whittaker - 05
//
//  PURPOSE: Draw waves with fog/decal
//
//  Listing: fxc /Tvs_1_1 /EWaveVS /FcWave.lst Water.fx
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2003 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------
//                          VARIABLES
//------------------------------------------------------------------------------------------------          

// Transformations
float4x4 mtxWorldViewProj: WORLDVIEWPROJECTION;
float4x4 mtxWorld: WORLD;
float4x4 mtxFOW  : GLOBAL;
float4x4 mtxBaseTexture : TEXTRANSFORMBASE;
float4x4 mtxDecalTexture: TEXTRANSFORMDECAL;


//------------------------------------------------------------------------------------------------
//                          VERTEX INPUT & OUTPUT FORMATS
//------------------------------------------------------------------------------------------------ 
struct VS_INPUT
{
	float4 f4Pos     : POSITION;
	float4 f4Color   : COLOR;
	float2 f2BaseTex : TEXCOORD0;
};

struct VS_OUTPUT
{
	float4 f4Pos     : POSITION;
	float4 f4Color   : COLOR;
	float2 f2BaseTex : TEXCOORD0;
	float2 f2DecalTex: TEXCOORD1;
	float2 f2FowTex  : TEXCOORD2;
};

//------------------------------------------------------------------------------------------------
//                          VERTEX SHADER
//------------------------------------------------------------------------------------------------
VS_OUTPUT WaveVS_11( VS_INPUT vIn )
{
    VS_OUTPUT vOut = (VS_OUTPUT)0;
	
	//Transform point
  	vOut.f4Pos  = mul(float4(vIn.f4Pos), mtxWorldViewProj);	
  	
    // Set texture coordinates
    vOut.f2BaseTex  = mul(float4(vIn.f2BaseTex,1,1),  mtxBaseTexture);
    vOut.f2DecalTex = mul(float4(vIn.f2BaseTex,1,1), mtxDecalTexture);
    
	//transform worldpos to FOW
    float3 P = mul(float4(vIn.f4Pos), (float4x3)mtxWorld);			
    vOut.f2FowTex   = mul(float4(P,1),mtxFOW);

	vOut.f4Color = vIn.f4Color; //vertex alpha
   return vOut;
}
//------------------------------------------------------------------------------------------------
//                          PIXEL SHADER
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// TEXTURES
//------------------------------------------------------------------------------------------------  
texture BaseTexture		 <string NTM = "base";  int NTMIndex = 0;>;
texture DecalTexture	 <string NTM = "decal";  int NTMIndex = 0;>;
texture FOGTexture		 <string NTM = "shader";  int NTMIndex = 1;>;
//------------------------------------------------------------------------------------------------
//                          SAMPLERS
//------------------------------------------------------------------------------------------------  
sampler WaveBase = sampler_state  { Texture = (BaseTexture);	   AddressU = Wrap; AddressV = Wrap; MagFilter = Linear; MipFilter = Linear; MinFilter = Linear; };
sampler DecalBase = sampler_state  { Texture = (DecalTexture);	   AddressU = Wrap; AddressV = Wrap; MagFilter = Linear; MipFilter = Linear; MinFilter = Linear; };
sampler Fog    	  = sampler_state  { Texture = (FOGTexture);	   AddressU = Clamp;  AddressV = Clamp;  MagFilter = Linear; MipFilter = Linear; MinFilter = Linear; };
//------------------------------------------------------------------------------------------------
float4 WavePS_11( VS_OUTPUT vIn ) : COLOR
{
	float4	f4FinalColor = tex2D( WaveBase,  vIn.f2BaseTex );
	float4 f4Decal       = tex2D( DecalBase, vIn.f2DecalTex);
	f4FinalColor= lerp(f4FinalColor,f4Decal, f4Decal.a);

	f4FinalColor.a *= vIn.f4Color.a;
	
	// apply fog of war
	float3 f4FOWTex   = tex2D( Fog, vIn.f2FowTex ).rgb;
	f4FinalColor.rgb *= f4FOWTex;

    if (f4FOWTex.r < 0.5f) {
		f4FinalColor.a = 0.0f;
	}
	
	return f4FinalColor;
}
//------------------------------------------------------------------------------------------------
//                          TECHNIQUES
//------------------------------------------------------------------------------------------------

technique Wave_Shader
<
	string shadername = "Wave_Shader"; 
	int implementation=0;
	string Description = "Civ4 Wave shader";
	bool UsesNiRenderState = true;
>
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = false;
        ZFunc          = LESSEQUAL;
        
        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = true;
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
        VertexShader = compile vs_1_1 WaveVS_11();
        PixelShader  = compile ps_1_1 WavePS_11();
    }
}

//-----------------------------------------------------------------------------------------------
// FF Version of the wave shader. 
technique TWave_FF
< 
	string shadername = "Wave_Shader";
	int implementation=1;
>
{
    pass P0
    {
		// Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = false;
        ZFunc          = LESSEQUAL;
        
        // Enable lighting
        Lighting       = FALSE;

        // enable alpha blending
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;
        AlphaBlendEnable = true;
        AlphaTestEnable  = false;
        
        // Set the smaplers
		Sampler[0] = <WaveBase>;
        Sampler[1] = <DecalBase>;
		Sampler[2] = <Fog>;
        
        // transforms
        TextureTransform[0] = <mtxBaseTexture>;
        TextureTransform[1] = <mtxDecalTexture>;
        TextureTransform[2] = <mtxFOW>;	//fow
        
        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
		TextureTransformFlags[2] = Count3;	

        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 0;
        TexCoordIndex[2] = CAMERASPACEPOSITION;

        // texture stage 0 - Base Texture
        ColorOp[0]       = SelectArg1;
        ColorArg1[0]     = Texture;
       	AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;
		AlphaArg2[0]	 = Current;

        // texture stage 1 - Decal textures
        ColorOp[1]       = BlendTextureAlpha;
        ColorArg0[1]	 = Current;
        ColorArg1[1]     = Texture;
       	AlphaOp[1]		 = SelectArg1;
		AlphaArg1[1]	 = Texture;
		AlphaArg2[1]	 = Current;
       
        // texture stage 3	- FOW
        ColorOp[2]       = Modulate;
        ColorArg1[2]     = Texture;
        ColorArg2[2]     = Current;
        
		// terminate state 4
        ColorOp[3]		= Disable;
        AlphaOp[3]		= Disable;
        
        // shaders
        VertexShader     = NULL;
        PixelShader      = NULL;
    }
}
//-----------------------------------------------------------------------------------------------
// FF 2 Texture Pass Card Versionof the wave shader.  No Decal Texture
technique TWave2TP_FF
< 
	string shadername = "Wave_Shader";
	int implementation=2;
>
{
    pass P0
    {
		// Enable depth writing
        ZEnable        = true;
        ZWriteEnable   = false;
        ZFunc          = LESSEQUAL;
        
        // Enable lighting
        Lighting       = false;

        // enable alpha blending
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;
        AlphaBlendEnable = true;
        AlphaTestEnable  = false;
        
        // Set the smaplers
		Sampler[0] = <WaveBase>;
		Sampler[1] = <Fog>;

        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = CAMERASPACEPOSITION;

        // transforms
        TextureTransform[0] = <mtxBaseTexture>;
        TextureTransform[1] = <mtxFOW>;	//fow
        
        TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = Count3;	

        // texture stage 0 - Base Texture
        ColorOp[0]       = SelectArg1;
        ColorArg1[0]     = Texture;
       	AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;

        // texture stage 1	- FOW
        ColorOp[1]       = Modulate;
        ColorArg1[1]     = Texture;
        ColorArg2[1]     = Current;
        AlphaOp[1]		 = SelectArg1;
		AlphaArg1[1]	 = Current;
        
		// terminate state 2
        ColorOp[2]		= Disable;
        AlphaOp[2]		= Disable;

        // shaders
        VertexShader     = NULL;
        PixelShader      = NULL;
    }
}

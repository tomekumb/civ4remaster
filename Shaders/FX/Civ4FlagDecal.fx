//------------------------------------------------------------------------------------------------
//  $Header: $
//------------------------------------------------------------------------------------------------
//  *****************   FIRAXIS GAME ENGINE   ********************
//
//  FILE:    FlagDecal.fx
//
//  AUTHOR:  Bart Muzzin
//			 Tom Whittaker
//
//  PURPOSE: Draw the flags with primary color and modulated decal texture
//
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2005 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------

float4x4 mtxWorldViewProj: WORLDVIEWPROJECTION;
float4x4 mtxWorldView: WORLDVIEW;
float4x4 mtxWorld : WORLD;
float4x4 mtxBaseTransform : TEXTRANSFORMBASE;

#include "ComputeCiv4Lighting.fx"

//------------------------------------------------------------------------------------------------
// TEXTURES
//------------------------------------------------------------------------------------------------  
texture BaseTexture <string NTM = "base";>;
texture DecalTexture < string NTM = "detail";>;
texture BaseColor <string NTM = "decal"; int NTMIndex = 0;>;
texture DecalColor <string NTM = "decal"; int NTMIndex = 1;>;
texture GlossMap <string NTM = "gloss"; int NTMIndex = 0;>;
texture EnvironMap <string NTM= "glow"; int NTMIndex = 0;>;

//------------------------------------------------------------------------------------------------
//                          SAMPLERS
//------------------------------------------------------------------------------------------------  
sampler BaseSampler = sampler_state
{
    Texture = (BaseTexture);
    AddressU  = WRAP;
    AddressV  = WRAP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;
};

sampler BaseColorSampler = sampler_state
{
    Texture = (BaseColor);
    AddressU  = WRAP;
    AddressV  = WRAP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;
};

sampler DecalSampler = sampler_state
{ 
	Texture = (DecalTexture);
	AddressU = Clamp;
	AddressV = Clamp;
	MagFilter = Linear;
	MipFilter = Linear;
	MinFilter = Linear; 
};

sampler DecalColorSampler = sampler_state
{ 
	Texture = (DecalColor);
	AddressU = Clamp;
	AddressV = Clamp;
	MagFilter = Linear;
	MipFilter = Linear;
	MinFilter = Linear; 
};

sampler GlossSampler = sampler_state
{
	Texture = (GlossMap);
	ADDRESSU = wrap;
	ADDRESSV = wrap;
	MAGFILTER = linear;
	MINFILTER = linear;
	MIPFILTER = linear;
};

sampler EnvironmentMapSampler = sampler_state
{
	Texture = (EnvironMap);
	ADDRESSU = wrap;
	ADDRESSV = wrap;
	MAGFILTER = linear;
	MINFILTER = linear;
	MIPFILTER = linear;
};

struct VS_INPUT 
{
    float4 f4Position	: POSITION;
    float3 f3Normal		: NORMAL;
    float2 f2TexCoords    : TEXCOORD0;
};

struct VS_OUTPUT
{
	float4 f4Position : POSITION;
	float2 f2TexCoord0 : TEXCOORD0;
	float2 f2TexCoord1 : TEXCOORD1;
	float2 f2TexCoord2 : TEXCOORD2;
	float2 f2TexCoord3 : TEXCOORD3;
};

struct VS_OUTPUTGLOSS 
{
    float4 f4Position : POSITION;
    float2 f2TexCoords : TEXCOORD0;
    float2 f2GlossCoords	 : TEXCOORD1;
    float4 f4Diff	 : COLOR0;
};

VS_OUTPUT FlagVS_11(VS_INPUT vIn)
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	Out.f4Position = mul(vIn.f4Position, mtxWorldViewProj);
	Out.f2TexCoord0 = vIn.f2TexCoords;
	Out.f2TexCoord1 = vIn.f2TexCoords;
	Out.f2TexCoord2 = vIn.f2TexCoords;
	Out.f2TexCoord3 = mul(float4(vIn.f2TexCoords, 1, 1), mtxBaseTransform);

	return Out;
}

float4 FlagPS_11(VS_OUTPUT vIn) : COLOR
{
	//icon color
	float4 f4IconColor = tex2D(DecalSampler, vIn.f2TexCoord0);
	float4 f4FrontColor = tex2D(BaseColorSampler, vIn.f2TexCoord1);
	f4IconColor.rgb *= f4FrontColor.rgb;
	
	//background color
	float4 f4BackColor = tex2D(DecalColorSampler, vIn.f2TexCoord2);
		
	//combine back and front based on icon alpha
	float4 f4FinalColor = lerp(f4IconColor, f4BackColor, f4IconColor.a);
	
	//base texture
	float4 f4BaseTexture = tex2D(BaseSampler, vIn.f2TexCoord3);
	f4FinalColor *= f4BaseTexture;
	f4FinalColor.a = f4BaseTexture.a;
	
	//finish
	return f4FinalColor;
}

VS_OUTPUTGLOSS FlagGlossVS_11(VS_INPUT vIn)
{
	VS_OUTPUTGLOSS Out = (VS_OUTPUTGLOSS)0;

	Out.f4Position = mul(vIn.f4Position, mtxWorldViewProj);
	Out.f2TexCoords = vIn.f2TexCoords;

	float3 wsNormal = mul(vIn.f3Normal, mtxWorld );
    wsNormal  = normalize(wsNormal );
	
   	Out.f4Diff.rgb = ComputeCiv4UnitLighting( wsNormal );	// L.N
   	Out.f4Diff.a = 1.0f;
   	
   	// Environment map coordiantes, normal in view space
   	float3 temp = mul(float4(vIn.f3Normal,0.0), mtxWorldView);
	Out.f2GlossCoords.x = 0.5 * temp.x + 0.5;
	Out.f2GlossCoords.y = -0.5 * temp.y + 0.5;	

	return Out;
}

float4 FlagGlossPS_14(VS_OUTPUTGLOSS vIn) : COLOR
{
	//gloss
	float4 f4EnvironmentMap = tex2D( EnvironmentMapSampler, vIn.f2GlossCoords );
	float4 f4GlossMask = tex2D( GlossSampler, vIn.f2TexCoords );
	f4EnvironmentMap *= f4GlossMask;
	
	//icon color
	float4 f4IconColor = tex2D(DecalSampler, vIn.f2TexCoords);
	float4 f4FrontColor = tex2D(BaseColorSampler, vIn.f2TexCoords);
	f4IconColor.rgb *= f4FrontColor.rgb;
	
	//background color
	float4 f4BackColor = tex2D(DecalColorSampler, vIn.f2TexCoords);
		
	//combine back and front based on icon alpha
	float4 f4FinalColor = lerp(f4IconColor, f4BackColor, f4IconColor.a);
	
	//base texture
	float4 f4BaseTexture = tex2D(BaseSampler, vIn.f2TexCoords);
	f4FinalColor *= f4BaseTexture;
	f4FinalColor.a = f4BaseTexture.a;
	
	//add lighting
	f4FinalColor *= vIn.f4Diff + f4EnvironmentMap;
	
	//finish
	return f4FinalColor;
}

technique TFlagGloss
<
	string shadername = "TFlagGloss";
	bool UsesNiRenderState = true;
	int implementation=0;
>
{
  	pass P0
	{
		VertexShader = compile vs_1_1 FlagGlossVS_11();
		PixelShader = compile ps_1_4 FlagGlossPS_14();
	}
}

technique TFlagGloss_2TPP< string shadername = "TFlagGloss"; int implementation=1;>
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;
        
        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = TRUE;
        AlphaRef		 = 0;
        AlphaFunc		 = GREATER;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;
        
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 0;
        TexCoordIndex[2] = 0;
        TexCoordIndex[3] = 0;
        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
        TextureTransformFlags[2] = 0;
        TextureTransformFlags[3] = 0;

        // Set the smaplers
		Sampler[0] = <BaseColorSampler>;
        Sampler[1] = <DecalSampler>;
        Sampler[2] = <DecalColorSampler>;
   		Sampler[3] = <BaseSampler>;

        // Set up texture stage states
        ColorArg1[0] = Texture;
        ColorOp[0] = SelectArg1;
        AlphaArg1[0] = Texture;
        AlphaOp[0] = SelectArg1;

		ColorArg2[1] = Current;
		ColorArg1[1] = Texture;
		ColorOp[1] = Modulate;
		AlphaArg1[1] = Texture;
		AlphaOp[1] = SelectArg1;

		ColorArg1[2] = Texture;
		ColorArg2[2] = Current;
		ColorOp[2] = BlendCurrentAlpha;
		AlphaArg1[2] = Texture;
		AlphaArg2[2] = Current;
		AlphaOp[2] = Modulate;

		ColorArg2[3] = Current;
		ColorArg1[3] = Texture;
		ColorOp[3] = Modulate;
		AlphaArg1[3] = Texture;
		AlphaOp[3] = SelectArg1;
		
		// shaders
        VertexShader     = NULL;
        PixelShader      = NULL;
   	}
}

//This is actually the 2 Textures Per Pass shader version. However the Nifs already have the 
//shaders attached as TFlagShader_2TPP.
technique TFlagGloss_2TPP_2TPP < string shadername = "TFlagGloss"; int implementation=2;>
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;
        
        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = TRUE;
        AlphaRef		 = 0;
        AlphaFunc		 = GREATER;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;
        
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 0;
        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
    
        // Set the smaplers
		Sampler[0] = <BaseColorSampler>;
        Sampler[1] = <BaseSampler>;

        // Set up texture stage states
        ColorArg1[0] = Texture;
        ColorOp[0] = SelectArg1;
        AlphaArg1[0] = Texture;
        AlphaOp[0] = SelectArg1;

		ColorArg2[1] = Current;
		ColorArg1[1] = Texture;
		ColorOp[1] = Modulate;
		AlphaArg1[1] = Texture;
		AlphaOp[1] = SelectArg1;
		
		ColorOp[2] = Disable;
		AlphaOp[2] = Disable;
		
        // shaders
        VertexShader     = NULL;
        PixelShader      = NULL;
	}
	
	// Second Pass to combine Seconday color
	pass P1
	{
		//decal these textures over first set, operations are the identical
		Sampler[0] = <DecalColorSampler>;
	    Sampler[1] = <DecalSampler>;
	}
}

technique TFlagShader_2TPP
<
	string shadername = "TFlagShader_2TPP";
	bool UsesNiRenderState = true;
	int implementation=0;
>
{
  	pass P0
	{
		VertexShader = compile vs_1_1 FlagVS_11();
		PixelShader = compile ps_1_1 FlagPS_11();
	}
}

//------------------------------------------------------------------------------------------------
//                          TECHNIQUES
//------------------------------------------------------------------------------------------------
technique TFlagShader_2TPP_01 < string shadername = "TFlagShader_2TPP"; int implementation=1; bool UsesNiRenderState = true;>
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;
        
        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = TRUE;
        AlphaRef		 = 0;
        AlphaFunc		 = GREATER;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;
        
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 0;
        TexCoordIndex[2] = 0;
        TexCoordIndex[3] = 0;
        TextureTransform[0] = 0;
        TextureTransform[1] = 0;
        TextureTransform[2] = 0;
        TextureTransform[3] = <mtxBaseTransform>;
        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
        TextureTransformFlags[2] = 0;
        TextureTransformFlags[3] = COUNT2;

        // Set the smaplers
		Sampler[0] = <BaseColorSampler>;
        Sampler[1] = <DecalSampler>;
        Sampler[2] = <DecalColorSampler>;
   		Sampler[3] = <BaseSampler>;

        // Set up texture stage states
        ColorArg1[0] = Texture;
        ColorOp[0] = SelectArg1;
        AlphaArg1[0] = Texture;
        AlphaOp[0] = SelectArg1;

		ColorArg2[1] = Current;
		ColorArg1[1] = Texture;
		ColorOp[1] = Modulate;
		AlphaArg1[1] = Texture;
		AlphaOp[1] = SelectArg1;

		ColorArg1[2] = Texture;
		ColorArg2[2] = Current;
		ColorOp[2] = BlendCurrentAlpha;
		AlphaArg1[2] = Texture;
		AlphaArg2[2] = Current;
		AlphaOp[2] = Modulate;

		ColorArg2[3] = Current;
		ColorArg1[3] = Texture;
		ColorOp[3] = Modulate;
		AlphaArg1[3] = Texture;
		AlphaOp[3] = SelectArg1;
		
		// shaders
        VertexShader     = NULL;
        PixelShader      = NULL;
   	}
}


//This is actually the 2 Textures Per Pass shader version. However the Nifs already have the 
//shaders attached as TFlagShader_2TPP.
technique TFlagShader_2TPP_2TPP < string shadername = "TFlagShader_2TPP"; int implementation=2; bool UsesNiRenderState = true;>
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;
        
        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = TRUE;
        AlphaRef		 = 0;
        AlphaFunc		 = GREATER;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;
        
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 0;
        TextureTransform[0] = 0;
        TextureTransform[1] = <mtxBaseTransform>;
        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = COUNT2;
    
        // Set the smaplers
		Sampler[0] = <BaseColorSampler>;
        Sampler[1] = <BaseSampler>;

        // Set up texture stage states
        ColorArg1[0] = Texture;
        ColorOp[0] = SelectArg1;
        AlphaArg1[0] = Texture;
        AlphaOp[0] = SelectArg1;

		ColorArg2[1] = Current;
		ColorArg1[1] = Texture;
		ColorOp[1] = Modulate;
		AlphaArg1[1] = Texture;
		AlphaOp[1] = SelectArg1;
		
		ColorOp[2] = Disable;
		AlphaOp[2] = Disable;
		
        // shaders
        VertexShader     = NULL;
        PixelShader      = NULL;
	}
	
	// Second Pass to combine Seconday color
	pass P1
	{
		TextureTransform[0] = 0;
        TextureTransform[1] = 0;
        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
        
		//decal these textures over first set, operations are the identical
		Sampler[0] = <DecalColorSampler>;
	    Sampler[1] = <DecalSampler>;
	}
}
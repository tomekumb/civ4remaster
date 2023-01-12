//------------------------------------------------------------------------------------------------
//  $Header: $
//------------------------------------------------------------------------------------------------
//  *****************   FIRAXIS GAME ENGINE   ********************
//
//  FILE:    CultureBorder
//
//  AUTHOR:  Jason Winokur - 3/29/2005
//
//  PURPOSE: Draw culture with fog/decal(borders)
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
float4x4 mtxWorld : WORLD;
float4x4 mtxFOW	: GLOBAL;

float4x4 mtxBorderTextureMat1 : GLOBAL;
float4x4 mtxBorderTextureMat2 : GLOBAL;
float4x4 mtxBorderTextureMat3 : GLOBAL;
float4x4 mtxBorderTextureMat4 : GLOBAL;
float4 f4BorderColor1 : GLOBAL;
float4 f4BorderColor2 : GLOBAL;
float4 f4BorderColor3 : GLOBAL;
float4 f4BorderColor4 : GLOBAL;

//------------------------------------------------------------------------------------------------
//                          VERTEX INPUT & OUTPUT FORMATS
//------------------------------------------------------------------------------------------------ 
struct VS_INPUT
{
   float3 f3Pos     : POSITION;
   float2 f2BaseTex : TEXCOORD0;
};

struct VS_OUTPUT_14
{
	float4 f4Pos      : POSITION;
	float2 f2BaseTex1 : TEXCOORD0;
	float2 f2BaseTex2 : TEXCOORD1;
	float2 f2BaseTex3 : TEXCOORD2;
	float2 f2BaseTex4 : TEXCOORD3;
	float2 f2FOWTex	  : TEXCOORD4;
};

struct VS_OUTPUT_11_0
{
	float4 f4Pos      : POSITION;
	float2 f2BaseTex1 : TEXCOORD0;
	float2 f2BaseTex2 : TEXCOORD1;
	float2 f2FOWTex	  : TEXCOORD2;
};

struct VS_OUTPUT_11_1
{
	float4 f4Pos      : POSITION;
	float2 f2BaseTex3 : TEXCOORD0;
	float2 f2BaseTex4 : TEXCOORD1;
	float2 f2FOWTex	  : TEXCOORD2;
};

//------------------------------------------------------------------------------------------------
//                          VERTEX SHADER
//------------------------------------------------------------------------------------------------
VS_OUTPUT_14 CultureBorderVS14( VS_INPUT vIn )
{
    VS_OUTPUT_14 vOut = (VS_OUTPUT_14)0;
	
	//Transform point
   	vOut.f4Pos  = mul(float4(vIn.f3Pos, 1), mtxWorldViewProj);	
   	float4 f4WorldPos = mul(float4(vIn.f3Pos, 1), mtxWorld);

    // Set texture coordinates
    //vOut.f2BaseTex1 = vIn.f2BaseTex;
    vOut.f2BaseTex1 = mul(float3(vIn.f2BaseTex,1), mtxBorderTextureMat1);
    vOut.f2BaseTex2 = mul(float3(vIn.f2BaseTex,1), mtxBorderTextureMat2);
    vOut.f2BaseTex3 = mul(float3(vIn.f2BaseTex,1), mtxBorderTextureMat3);
    vOut.f2BaseTex4 = mul(float3(vIn.f2BaseTex,1), mtxBorderTextureMat4);
    vOut.f2FOWTex = mul(f4WorldPos, mtxFOW);

	return vOut;
}

VS_OUTPUT_11_0 CultureBorderVS11_0( VS_INPUT vIn )
{
    VS_OUTPUT_11_0 vOut = (VS_OUTPUT_11_0) 0;
	
	//Transform point
   	vOut.f4Pos  = mul(float4(vIn.f3Pos, 1), mtxWorldViewProj);	
   	float4 f4WorldPos = mul(float4(vIn.f3Pos, 1), mtxWorld);

    // Set texture coordinates
    vOut.f2BaseTex1 = mul(float3(vIn.f2BaseTex,1), mtxBorderTextureMat1);
    vOut.f2BaseTex2 = mul(float3(vIn.f2BaseTex,1), mtxBorderTextureMat2);
    vOut.f2FOWTex = mul(f4WorldPos, mtxFOW);

	return vOut;
}

VS_OUTPUT_11_1 CultureBorderVS11_1( VS_INPUT vIn )
{
    VS_OUTPUT_11_1 vOut = (VS_OUTPUT_11_1) 0;
	
	//Transform point
   	vOut.f4Pos  = mul(float4(vIn.f3Pos, 1), mtxWorldViewProj);	
   	float4 f4WorldPos = mul(float4(vIn.f3Pos, 1), mtxWorld);

    // Set texture coordinates
    vOut.f2BaseTex3 = mul(float3(vIn.f2BaseTex,1), mtxBorderTextureMat3);
    vOut.f2BaseTex4 = mul(float3(vIn.f2BaseTex,1), mtxBorderTextureMat4);
    vOut.f2FOWTex = mul(f4WorldPos, mtxFOW);

	return vOut;
}

//------------------------------------------------------------------------------------------------
//                          PIXEL SHADER
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// TEXTURES
//------------------------------------------------------------------------------------------------  
texture BaseTexture <string NTM = "base";>;
texture TerrainFOWarTexture <string NTM = "shader";  int NTMIndex = 0;>;

//------------------------------------------------------------------------------------------------
//                          SAMPLERS
//------------------------------------------------------------------------------------------------  
sampler CultureBorderBase = sampler_state
{
    Texture = (BaseTexture);
    AddressU  = CLAMP;
    AddressV  = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = NONE;
};

sampler TerrainFOWar = sampler_state
{
	Texture = (TerrainFOWarTexture);
	AddressU = Wrap;
	AddressV = Wrap;
	MagFilter = Linear;
	MipFilter = Linear;
	MinFilter = Linear;
};

//------------------------------------------------------------------------------------------------
float4 CultureBorderPS14( VS_OUTPUT_14 vIn ) : COLOR
{
	float4 f4FinalColor = 0;

	// Get Base textures 
	float4 f4Base1 = tex2D(CultureBorderBase, vIn.f2BaseTex1);
	float4 f4Color1 = f4Base1 * f4BorderColor1;

	float4 f4Base2 = tex2D(CultureBorderBase, vIn.f2BaseTex2);
	float4 f4Color2 = f4Base2 * f4BorderColor2;

	float4 f4Base3 = tex2D(CultureBorderBase, vIn.f2BaseTex3);
	float4 f4Color3 = f4Base3 * f4BorderColor3;

	float4 f4Base4 = tex2D(CultureBorderBase, vIn.f2BaseTex4);
	float4 f4Color4 = f4Base4 * f4BorderColor4;
	
	float4 f4FOWTex = tex2D( TerrainFOWar, vIn.f2FOWTex );

	//find pixel with highest alpha (most opaque)
//	f4FinalColor = f4Color1;
//	if(f4Color2.a > f4FinalColor.a) //replace with base2
//		f4FinalColor = f4Color2;
//	if(f4Color3.a > f4FinalColor.a) //replace with base3
//		f4FinalColor = f4Color3;
//	if(f4Color4.a > f4FinalColor.a) //replace with base4
//		f4FinalColor = f4Color4;
		
	f4FinalColor = f4Color1 + f4Color2 + f4Color3 + f4Color4;
		
	f4FinalColor.rgb *= f4FOWTex.rgb;		//FOW textures
	
	return f4FinalColor;
}

//------------------------------------------------------------------------------------------------
float4 CultureBorderPS11_0( VS_OUTPUT_11_0 vIn ) : COLOR
{
	//mixes textures 1 and 2
	float4	f4FinalColor = 0.0f;

	// Get Base textures 
	float4 f4Base1 = tex2D( CultureBorderBase, vIn.f2BaseTex1 );
	float4 f4Color1 = f4Base1 * f4BorderColor1;

	float4 f4Base2 = tex2D( CultureBorderBase, vIn.f2BaseTex2 );
	float4 f4Color2 = f4Base2 * f4BorderColor2;

	float4 f4FOWTex = tex2D( TerrainFOWar, vIn.f2FOWTex );

	//find pixel with highest alpha (most opaque)
	f4FinalColor = f4Color1;
	if(f4Color2.a > f4FinalColor.a) //replace with base2
		f4FinalColor = f4Color2;
		
	f4FinalColor.rgb *= f4FOWTex.rgb;		//FOW textures
			
	return f4FinalColor;
}

//------------------------------------------------------------------------------------------------
float4 CultureBorderPS11_1( VS_OUTPUT_11_1 vIn ) : COLOR
{
	//mixes textures 3 and 4
	float4	f4FinalColor = 0.0f;

	// Get Base textures 
	float4 f4Base3 = tex2D( CultureBorderBase, vIn.f2BaseTex3 );
	float4 f4Color3 = f4Base3 * f4BorderColor3;

	float4 f4Base4 = tex2D( CultureBorderBase, vIn.f2BaseTex4 );
	float4 f4Color4 = f4Base4 * f4BorderColor4;
	
	float4 f4FOWTex = tex2D( TerrainFOWar, vIn.f2FOWTex );

	//find pixel with highest alpha (most opaque)
	f4FinalColor = f4Color3;
	if(f4Color4.a > f4FinalColor.a) //replace with base2
		f4FinalColor = f4Color4;
		
	f4FinalColor.rgb *= f4FOWTex.rgb;		//FOW textures
			
	return f4FinalColor;
}

//------------------------------------------------------------------------------------------------
//                          TECHNIQUES
//------------------------------------------------------------------------------------------------
/*
technique TCultureBorder_Shader14
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = FALSE;
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
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TexCoordIndex[3] = 3;
        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
        TextureTransformFlags[2] = 0;
        TextureTransformFlags[3] = 0;
        
        // Set up textures and texture stage states
        VertexShader = compile vs_1_1 CultureBorderVS14();
        PixelShader  = compile ps_1_4 CultureBorderPS14();
    }
}
*/

technique TCultureBorder_Shader14
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = FALSE;
        ZFunc          = LESSEQUAL;
        
        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = TRUE;
		AlphaRef		 = 0;
        AlphaFunc		 = GREATER;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;
        
        // Set the smaplers
        Sampler[0] = <CultureBorderBase>;
        Sampler[1] = <TerrainFOWar>;
   		
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
        TextureTransformFlags[2] = 0;
        
        // Set up textures and texture stage states
        VertexShader = compile vs_1_1 CultureBorderVS11_0();
        PixelShader  = compile ps_1_1 CultureBorderPS11_0();
    }
    
    pass P1
    {
        // Set up textures and texture stage states
        VertexShader = compile vs_1_1 CultureBorderVS11_1();
        PixelShader  = compile ps_1_1 CultureBorderPS11_1();		
    }
}

technique TCultureBorder_Shader11
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = FALSE;
        ZFunc          = LESSEQUAL;
        
        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = TRUE;
		AlphaRef		 = 0;
        AlphaFunc		 = GREATER;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;
        
        // Set the smaplers
        Sampler[0] = <CultureBorderBase>;
        Sampler[1] = <TerrainFOWar>;
   		
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
        TextureTransformFlags[2] = 0;
        
        // Set up textures and texture stage states
        VertexShader = compile vs_1_1 CultureBorderVS11_0();
        PixelShader  = compile ps_1_1 CultureBorderPS11_0();
    }
    
    pass P1
    {
        // Set up textures and texture stage states
        VertexShader = compile vs_1_1 CultureBorderVS11_1();
        PixelShader  = compile ps_1_1 CultureBorderPS11_1();		
    }
}

// Fixed Function Version
technique TCultureBorder_FixedFunction
{
	pass P0
	{
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = FALSE;
        ZFunc          = LESSEQUAL;

        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = TRUE;
		AlphaRef		 = 0;
        AlphaFunc		 = GREATER;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;

		// textures
		Texture[0]    =   (BaseTexture);
		Texture[1]    =   (TerrainFOWarTexture);

		TexCoordIndex[0] = 0;
		TexCoordIndex[1] = CAMERASPACEPOSITION;

		TextureTransformFlags[0] = Count2;
		TextureTransformFlags[1] = Count3;	

		TextureTransform[0] = <mtxBorderTextureMat1>;
		TextureTransform[1] = <mtxFOW>;

		TextureFactor = <f4BorderColor1>;
		//TextureFactor = 0xFF00FFFF;
		
		// texture stage 0 - Base Texture
		ColorOp[0]       = SelectArg1;
		ColorArg1[0]     = TFactor;
		AlphaOp[0]		 = Modulate;
		AlphaArg1[0]	 = Texture;
		AlphaArg2[0]	 = TFactor;

		// texture stage 1	- FoW
		ColorOp[1]       = Modulate;
		ColorArg1[1]     = Texture;
		ColorArg2[1]     = Current;
		AlphaOp[1]		 = SelectArg1;
		AlphaArg1[1]	 = Current;
				
		ColorOp[2]       = disable;
		AlphaOp[2]		 = disable;

		// shaders
		VertexShader     = NULL;
		PixelShader      = NULL;
	}
	
	pass P1
	{
		// textures
		Texture[0]    =   (BaseTexture);
		Texture[1]    =   (TerrainFOWarTexture);

		TextureTransform[0] = <mtxBorderTextureMat2>;
		TextureTransform[1] = <mtxFOW>;
		
		TextureFactor = <f4BorderColor2>;
		
		//operations defined in pass 0
	}
	
	pass P2
	{
		// textures
		Texture[0]    =   (BaseTexture);
		Texture[1]    =   (TerrainFOWarTexture);

		TextureTransform[0] = <mtxBorderTextureMat3>;
		TextureTransform[1] = <mtxFOW>;
		
		TextureFactor = <f4BorderColor3>;
		
		//operations defined in pass 0
	}
	
	pass P3
	{
		// textures
		Texture[0]    =   (BaseTexture);
		Texture[1]    =   (TerrainFOWarTexture);

		TextureTransform[0] = <mtxBorderTextureMat4>;
		TextureTransform[1] = <mtxFOW>;
		
		TextureFactor = <f4BorderColor4>;
		
		//operations defined in pass 0
	}
}

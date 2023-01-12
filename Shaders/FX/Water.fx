//------------------------------------------------------------------------------------------------
//  $Header: $
//------------------------------------------------------------------------------------------------
//  *****************   FIRAXIS GAME ENGINE   ********************
//
//  FILE:    Water
//
//  AUTHOR:  Tom Whittaker - 4/12/2004
//
//  PURPOSE: Draw water with fog/decal(borders)
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
float4x4 mtxWorld   : WORLD;
float4x4 mtxWaterTextureMat : GLOBAL;
float4x4 mtxWaterTextureMat2: GLOBAL;
float4x4 mtxFOW     : GLOBAL;
float f3WaterAlpha: GLOBAL;

//------------------------------------------------------------------------------------------------
//                          VERTEX INPUT & OUTPUT FORMATS
//------------------------------------------------------------------------------------------------ 
struct VS_INPUT
{
   float3 f3Pos     : POSITION;
   float3 f3Normal  : NORMAL;
   float2 f2BaseTex : TEXCOORD0;
   float2 f2CoastTex: TEXCOORD1;
   float2 f2FowTex  : TEXCOORD2;
};

struct VS_OUTPUT
{
	float4 f4Pos     : POSITION;
	float2 f2BaseTex1: TEXCOORD0;
	float2 f2BaseTex2: TEXCOORD1;
	float2 f2CoastTex: TEXCOORD2;
	float2 f2FowTex  : TEXCOORD3;
};

//------------------------------------------------------------------------------------------------
//                          VERTEX SHADER
//------------------------------------------------------------------------------------------------
VS_OUTPUT WaterVS_11( VS_INPUT vIn )
{
	VS_OUTPUT vOut = (VS_OUTPUT)0;

	//Transform point
	vOut.f4Pos  = mul(float4(vIn.f3Pos, 1), mtxWorldViewProj);	
	float3 worldPos = mul(float4(vIn.f3Pos,1), (float4x3)mtxWorld);			

	// Set texture coordinates
	vOut.f2BaseTex1 = mul(float4(worldPos,1),mtxWaterTextureMat);
	vOut.f2BaseTex2 = mul(float4(worldPos,1),mtxWaterTextureMat2);
	vOut.f2CoastTex = vIn.f2CoastTex;
	vOut.f2FowTex   = vIn.f2FowTex;

	return vOut;
}
//------------------------------------------------------------------------------------------------
//                          PIXEL SHADER
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// TEXTURES
//------------------------------------------------------------------------------------------------  
texture BaseTexture		 <string NTM = "shader";  int NTMIndex = 0;>;
texture CoastFadeTexture <string NTM = "shader";  int NTMIndex = 1;>;
texture FOGTexture		 <string NTM = "shader";  int NTMIndex = 2;>;
//------------------------------------------------------------------------------------------------
//                          SAMPLERS
//------------------------------------------------------------------------------------------------  
sampler WaterBase = sampler_state  { Texture = (BaseTexture);	   AddressU = Wrap; AddressV = Wrap; MagFilter = Linear; MipFilter = Linear; MinFilter = Linear; };
sampler CoastFade = sampler_state  { Texture = (CoastFadeTexture); AddressU = Wrap; AddressV = Wrap; MagFilter = Linear; MipFilter = None; MinFilter = Linear; };
sampler Fog    	  = sampler_state  { Texture = (FOGTexture);	   AddressU = Wrap;  AddressV = Wrap;  MagFilter = Linear; MipFilter = Linear; MinFilter = Linear; };
//------------------------------------------------------------------------------------------------
float4 WaterPS_11( VS_OUTPUT vIn ) : COLOR
{
	float4	f4FinalColor = 0.0f;

	// Get Base textures 
	float3 f4Base    = tex2D( WaterBase, vIn.f2BaseTex1 ).rgb;
	float3 f4Base2   = tex2D( WaterBase, vIn.f2BaseTex2 ).rgb;
	f4FinalColor.rgb = lerp(f4Base,f4Base2,0.5f);

	float coastAlpha = tex2D( CoastFade, vIn.f2CoastTex ).r;
	
	// Get Alpha textures 
	float f4Alpha1  = tex2D( WaterBase, vIn.f2BaseTex1 ).a;
	float f4Alpha2  = tex2D( WaterBase, vIn.f2BaseTex2 ).a;
	// float alphablend = f4Alpha1  * f4Alpha2 * coastAlpha ;
	
	// f4FinalColor.rgb += alphablend;

	// Get FOW
	float4 f4FOWTex   = tex2D( Fog, vIn.f2FowTex );

	f4FinalColor *= f4FOWTex;
	
	// Now adjust alpha by Diffuse Alpha
	f4FinalColor.a = f3WaterAlpha * coastAlpha * f4FOWTex.r;

	return f4FinalColor;
}
//------------------------------------------------------------------------------------------------
//                          TECHNIQUES
//------------------------------------------------------------------------------------------------
technique Water_Shader< string shadername = "Water_Shader"; int implementation=0;>
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;
        
        // Enable alpha blending & testing
        AlphaBlendEnable = true;
        AlphaTestEnable	 = true;
		AlphaRef         = 0;

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
        VertexShader = compile vs_1_1 WaterVS_11();
        PixelShader  = compile ps_1_1 WaterPS_11();
    }
}

// FF Version of the water shader. 
//  - No land/water blend support
technique Water_4TPP< string shadername = "Water_Shader"; int implementation=1;>
{
    pass P0
    {
      
		// Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;
        
        // enable alpha blending
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;
        AlphaBlendEnable = true;
        AlphaTestEnable  = true;
		AlphaRef         = 0;
        
        // textures
        Sampler[0]  = <WaterBase>;
        Sampler[1]  = <WaterBase>;
        Sampler[2]  = <Fog>;
        
        TextureTransform[0] = 0;//<mtxWaterTextureMat>;
		TextureTransform[1] = 0;//<mtxWaterTextureMat2>;
		TextureTransform[2] = <mtxFOW>;
		
        TextureTransformFlags[0] = Count2;
		TextureTransformFlags[1] = Count2;	
		TextureTransformFlags[2] = Count3;	
		
        // transforms
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = CAMERASPACEPOSITION;	//fow;

		TextureFactor = 0x80808080;				//Blend Lerp Factor

        // texture stage 0 - Base Texture
        ColorOp[0]       = SelectArg1;
        ColorArg1[0]     = Texture;
		AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = TFactor;

        // texture stage 1 - Blend 2 textures
        ColorOp[1]       = Lerp;
        ColorArg0[1]	 = TFactor;
        ColorArg1[1]     = Texture;
        ColorArg2[1]     = Current;
        AlphaOp[1]		 = SelectArg1;
		AlphaArg1[1]	 = Current;

       
        // texture stage 3	- FOW
        ColorOp[2]       = Modulate;
        ColorArg1[2]     = Texture;
        ColorArg2[2]     = Current;
        AlphaOp[2]		 = SelectArg1;
		AlphaArg1[2]	 = Current;

        
		// terminate state 4
        ColorOp[3]		= Disable;
        AlphaOp[3]		= Disable;
        
        // shaders
        VertexShader     = NULL;
        PixelShader      = NULL;
    }
}


// FF Version of the water shader  2 Texture Stage cards 
//  - No land/water blend support
technique Water_FF_2TPP< string shadername = "Water_Shader"; int implementation=2;>
{
    pass P0
    {
   		// Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;
        
        // Enable lighting
        Lighting       = false;

        // enable alpha blending
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;
        AlphaBlendEnable = true;
        AlphaTestEnable  = true;
   		AlphaRef         = 0;
        
        // textures
        Sampler[0]  = <WaterBase>;
        Sampler[1]  = <Fog>;

        TexCoordIndex[0] = 0;	
        TexCoordIndex[1] = CAMERASPACEPOSITION;	//fow
                
       	TextureTransformFlags[0] = Count2;
		TextureTransformFlags[1] = Count3;	
                
        // transforms
        TextureTransform[0] = 0;//<mtxWaterTextureMat>;
		TextureTransform[1] = <mtxFOW>;
		
		TextureFactor = 0x80808080;				//Blend Lerp Factor

        // texture stage 0 - Base Texture
        ColorOp[0]       = SelectArg1;
        ColorArg1[0]     = Texture;
       	AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = TFactor;
				
        // texture stage 1	- FOW
        ColorOp[1]       = Modulate;
        ColorArg1[1]     = Texture;
        ColorArg2[1]     = Current;
        AlphaOp[1]		 = SelectArg1;
   		AlphaArg1[1]	 = current;

		ColorOp[2]		 = disable;
		AlphaOp[2]		 = disable;
		    
        // shaders
        VertexShader     = NULL;
        PixelShader      = NULL;
    }
}


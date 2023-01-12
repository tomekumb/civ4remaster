//------------------------------------------------------------------------------------------------
//  $Header: $
//------------------------------------------------------------------------------------------------
//  *****************   FIRAXIS GAME ENGINE   ********************
//
//  FILE:    River
//
//  AUTHOR:  Jason Winnaker - 4/08/2005
//
//  PURPOSE: Draw river sparkles over base map.
//
//  Listing: fxc /Tvs_1_1 /ERiverVS /FcRiver.lst River.fx
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2003 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------
//                          VARIABLES
//------------------------------------------------------------------------------------------------          

// Transformations
float4x4 mtxWorldViewProj : WORLDVIEWPROJECTION;
float4x4 mtxWorld : WORLD;
float4x4 mtxWorldInv : WORLDINVERSE;
float4x4 mtxFOW : GLOBAL;
float3x3 mtxFloodPlainMaskMat : GLOBAL;
float3x3 mtxBaseTextureMat : GLOBAL;
float3 f3SunLightDir : GLOBAL;
float3 f3SunLightDiffuse : GLOBAL;
float3 f3SunAmbientColor : GLOBAL;

//------------------------------------------------------------------------------------------------
//                          VERTEX INPUT & OUTPUT FORMATS
//------------------------------------------------------------------------------------------------ 
struct VS_INPUT
{
	float3 f3Pos : POSITION;
	float2 f2BaseTex : TEXCOORD0;
	float2 f2UniformTex : TEXCOORD1;
	float3 f3Normal		: NORMAL;
	float3 f3Binormal	: BINORMAL;
	float3 f3Tangent	: TANGENT;
};

struct VS_OUTPUT_11_0
{
	float4 f4Pos : POSITION;
	float3 f3LightVec : COLOR0;
	float2 f2NormalTex : TEXCOORD0;
	float2 f2FOWTex : TEXCOORD1;
	float2 f2FloodPlainTex : TEXCOORD2;
	float2 f2FloodPlainMask : TEXCOORD3;
};

struct VS_OUTPUT_11_1
{
	float4 f4Pos : POSITION;
	float3 f3LightVec : COLOR0;
	float2 f2NormalTex : TEXCOORD0;
	float2 f2FOWTex : TEXCOORD1;
	float2 f2BaseTex : TEXCOORD2;
};

//------------------------------------------------------------------------------------------------
//                          VERTEX SHADER
//------------------------------------------------------------------------------------------------
VS_OUTPUT_11_0 RiverVS11_0(VS_INPUT vIn)
{
    VS_OUTPUT_11_0 vOut = (VS_OUTPUT_11_0)0;
	
	//Transform point
   	vOut.f4Pos = mul(float4(vIn.f3Pos, 1), mtxWorldViewProj);
   	float4 f4WorldPos = mul(float4(vIn.f3Pos, 1), mtxWorld);
   	
   	// compute the 3x3 tranform from tangent space to object space
	float3x3 objToTangentSpace;
	objToTangentSpace[0] = vIn.f3Tangent;
	objToTangentSpace[1] = vIn.f3Binormal; //possible sign problem
	objToTangentSpace[2] = vIn.f3Normal;

	//transform the light vector to object space
    float3 f3ObjectSpaceLight = mul(-f3SunLightDir, mtxWorldInv);
    float3 f3TangentSpaceLight = mul(objToTangentSpace, f3ObjectSpaceLight);
    vOut.f3LightVec = 0.5 * f3TangentSpaceLight + 0.5;

    // Set texture coordinates
    vOut.f2FloodPlainTex = mul(float3(vIn.f2UniformTex, 1), mtxBaseTextureMat);
    vOut.f2FloodPlainMask = mul(float3(vIn.f2UniformTex, 1), mtxFloodPlainMaskMat);
    vOut.f2NormalTex = vOut.f2FloodPlainTex;
    vOut.f2FOWTex = mul(f4WorldPos, mtxFOW);

	return vOut;
}

VS_OUTPUT_11_1 RiverVS11_1(VS_INPUT vIn)
{
    VS_OUTPUT_11_1 vOut = (VS_OUTPUT_11_1)0;
	
	//Transform point
   	vOut.f4Pos = mul(float4(vIn.f3Pos, 1), mtxWorldViewProj);
   	float4 f4WorldPos = mul(float4(vIn.f3Pos, 1), mtxWorld);
   	
   	// compute the 3x3 tranform from tangent space to object space
	float3x3 objToTangentSpace;
	objToTangentSpace[0] = vIn.f3Tangent;
	objToTangentSpace[1] = vIn.f3Binormal; //possible sign problem
	objToTangentSpace[2] = vIn.f3Normal;
	
	//transform the light vector to object space
    float3 f3ObjectSpaceLight = mul(-f3SunLightDir, mtxWorldInv);
    float3 f3TangentSpaceLight = mul(objToTangentSpace, f3ObjectSpaceLight);
    vOut.f3LightVec = 0.5 * f3TangentSpaceLight + 0.5;

    // Set texture coordinates
    vOut.f2BaseTex = mul(float3(vIn.f2UniformTex, 1), mtxBaseTextureMat);
    vOut.f2NormalTex = vOut.f2BaseTex;
    vOut.f2FOWTex = mul(f4WorldPos, mtxFOW);

	return vOut;
}
//------------------------------------------------------------------------------------------------
//                          PIXEL SHADER
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// TEXTURES
//------------------------------------------------------------------------------------------------  
texture BaseTexture <string NTM = "shader";  int NTMIndex = 0;>;
texture RiverNormalTexture <string NTM = "shader";  int NTMIndex = 1;>;
texture RiverFOWTexture <string NTM = "shader";  int NTMIndex = 2;>;
texture FloodPlainTexture <string NTM = "shader"; int NTMIndex = 3;>;
texture FloodPlainMask <string NTM = "shader"; int NTMIndex = 4;>;

//------------------------------------------------------------------------------------------------
//                          SAMPLERS
//------------------------------------------------------------------------------------------------  
sampler RiverNormalSampler = sampler_state
{ 
	Texture = (RiverNormalTexture);
	AddressU = WRAP;
	AddressV = WRAP;
	MagFilter = Linear;
	MipFilter = None;
	MinFilter = Linear; 
};

sampler RiverBase = sampler_state
{
    Texture = (BaseTexture);
    AddressU  = WRAP;
    AddressV  = WRAP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;
};

sampler RiverFOWSampler = sampler_state
{
	Texture = (RiverFOWTexture);
	AddressU = Wrap;
	AddressV = Wrap;
	MagFilter = Linear;
	MipFilter = Linear;
	MinFilter = Linear;
};

sampler FloodPlainSampler = sampler_state
{
	Texture = (FloodPlainTexture);
	AddressU = Wrap;
	AddressV = Wrap;
	MagFilter = Linear;
	MipFilter = Linear;
	MinFilter = Linear;
};

sampler FloodPlainMaskSampler = sampler_state
{
	Texture = (FloodPlainMask);
	AddressU = Clamp;
	AddressV = Clamp;
	MagFilter = Linear;
	MipFilter = Linear;
	MinFilter = Linear;
};

//------------------------------------------------------------------------------------------------
//This applies the flood plain texture
float4 RiverPS11_0( VS_OUTPUT_11_0 vIn ) : COLOR
{
	float4 f4FinalColor = 0.0f;
	
	// Get texture values
	//float3 f3Normal = tex2D(RiverNormalSampler, vIn.f2NormalTex).rgb;
	float4 f4FOW = tex2D(RiverFOWSampler, vIn.f2FOWTex);
	float4 f4FloodPlain = tex2D(FloodPlainSampler, vIn.f2FloodPlainTex);
	float4 f4FloodPlainMask = tex2D(FloodPlainMaskSampler, vIn.f2FloodPlainMask);

	// Uncompress normals
	//f3Normal = (f3Normal - 0.5) * 2;
	//float3 f3LightVec = (vIn.f3LightVec - 0.5) * 2;

	//calculate diffuse lighting
	//float3 f3Diffuse = dot(f3Normal, f3LightVec) * f3SunLightDiffuse;
	
	//light flood plain texture
	f4FinalColor = f4FloodPlain;
	//f4FinalColor.rgb = saturate(f4FinalColor.rgb * (f3Diffuse + f3SunAmbientColor));
	f4FinalColor.a *= f4FloodPlainMask.a;
	
	//FOW
	f4FinalColor.rgb *= f4FOW.rgb;
	
	return f4FinalColor;
}

//------------------------------------------------------------------------------------------------
//This applies the river base texture and normal map
float4 RiverPS11_1( VS_OUTPUT_11_1 vIn ) : COLOR
{
	float4 f4FinalColor = 0;

	// Get Base textures 
	float3 f3Normal = tex2D(RiverNormalSampler, vIn.f2NormalTex).rgb;
	float4 f4FOW = tex2D(RiverFOWSampler, vIn.f2FOWTex);
	float4 f4Base = tex2D(RiverBase, vIn.f2BaseTex);

	// Uncompress normals
	f3Normal = (f3Normal - 0.5) * 2;
	float3 f3LightVec = (vIn.f3LightVec - 0.5) * 2;
	
	//calculate diffuse lighting
	float3 f3Diffuse = dot(f3Normal, f3LightVec) * f3SunLightDiffuse;
	
	//light base texture
	f4FinalColor = f4Base;
	f4FinalColor.rgb = saturate(f4FinalColor.rgb * (f3Diffuse + f3SunAmbientColor));
	
	// Get FOW
	f4FinalColor.rgb *= f4FOW.rgb;
	
	return f4FinalColor;
}
//------------------------------------------------------------------------------------------------
//                          TECHNIQUES
//------------------------------------------------------------------------------------------------
technique River_Shader< string shadername = "River_Shader"; int implementation=0;>
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
        VertexShader = compile vs_1_1 RiverVS11_0();
        PixelShader  = compile ps_1_1 RiverPS11_0();
    }
    
    pass P1
    {
        // Set up textures and texture stage states
        VertexShader = compile vs_1_1 RiverVS11_1();
        PixelShader  = compile ps_1_1 RiverPS11_1();		
    }
}

technique TRiver_FixedFunction< string shadername = "River_Shader"; int implementation=1;>
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = FALSE;
        ZFunc          = LESSEQUAL;
        
        // Enable lighting
        Lighting       = FALSE;
        
        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = TRUE;
        AlphaRef		 = 0;
        AlphaFunc		 = GREATER;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;
        
        // textures
		Texture[0] = (FloodPlainTexture);
		Texture[1] = (FloodPlainMask);
		Texture[2] = (RiverFOWTexture);
		
		TexCoordIndex[0] = 1;
		TexCoordIndex[1] = 1;
		TexCoordIndex[2] = CAMERASPACEPOSITION;
        
        TextureTransformFlags[0] = Count2;
        TextureTransformFlags[1] = Count2;
		TextureTransformFlags[2] = Count3;	
        
		TextureTransform[0] = <mtxBaseTextureMat>;
		TextureTransform[1] = <mtxFloodPlainMaskMat>;
		TextureTransform[2] = <mtxFOW>;
        
		// texture stage 0 - base flood plain
		ColorOp[0]       = SelectArg1;
		ColorArg1[0]     = Texture;
		AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;
		
		// texture state 1 - flood plain mask
		ColorOp[1] = SelectArg1;
		ColorArg1[1] = Current;
		AlphaOp[1] = Modulate;
		AlphaArg1[1] = Current;
		AlphaArg2[1] = Texture;
		
		// texture stage 2	- FoW
		ColorOp[2]       = Modulate;
		ColorArg1[2]     = Texture;
		ColorArg2[2]     = Current;
		AlphaOp[2]		 = SelectArg1;
		AlphaArg1[2]	 = Current;
				
		ColorOp[3]       = disable;
		AlphaOp[3]		 = disable;

		// shaders
		VertexShader     = NULL;
		PixelShader      = NULL;
    }
    
    pass P1
    {
        // textures
		Texture[0] = (BaseTexture);
		Texture[1] = (RiverFOWTexture);

		TexCoordIndex[0] = 1;
		TexCoordIndex[1] = CAMERASPACEPOSITION;
		
		TextureTransform[0] = <mtxBaseTextureMat>;
		TextureTransform[1] = <mtxFOW>;
        
		// texture stage 0 - Base Texture
		ColorOp[0]       = SelectArg1;
		ColorArg1[0]     = Texture;
		AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;
		
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
}

/*
technique TRiver_FixedFunction_2TPP< string shadername = "River_Shader"; int implementation=2;>
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = FALSE;
        ZFunc          = LESSEQUAL;
        
        // Enable lighting
        Lighting       = FALSE;
        
        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = TRUE;
        AlphaRef		 = 0;
        AlphaFunc		 = GREATER;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;
        
        // textures
		Texture[0] = (FloodPlainTexture);
		Texture[1] = (FloodPlainMask);
		
		TexCoordIndex[0] = 1;
		TexCoordIndex[1] = 1;
        
        TextureTransformFlags[0] = Count2;
        TextureTransformFlags[1] = Count2;
        
		TextureTransform[0] = <mtxBaseTextureMat>;
		TextureTransform[1] = <mtxFloodPlainMaskMat>;
        
		// texture stage 0 - base flood plain
		ColorOp[0]       = SelectArg1;
		ColorArg1[0]     = Texture;
		AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;
		
		// texture state 1 - flood plain mask
		ColorOp[1] = SelectArg1;
		ColorArg1[1] = Current;
		AlphaOp[1] = Modulate;
		AlphaArg1[1] = Current;
		AlphaArg2[1] = Texture;
		
		// shaders
		VertexShader     = NULL;
		PixelShader      = NULL;
    }
    
    pass P1
    {
        // textures
		Texture[0] = (BaseTexture);
		Texture[1] = (RiverFOWTexture);

		TexCoordIndex[0] = 1;
		TexCoordIndex[1] = CAMERASPACEPOSITION;
		
		TextureTransform[0] = <mtxBaseTextureMat>;
		TextureTransform[1] = <mtxFOW>;
        
		// texture stage 0 - Base Texture
		ColorOp[0]       = SelectArg1;
		ColorArg1[0]     = Texture;
		AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;
		
		// texture stage 1	- FoW
		ColorOp[1]       = Modulate;
		ColorArg1[1]     = Texture;
		ColorArg2[1]     = Current;
		AlphaOp[1]		 = SelectArg1;
		AlphaArg1[1]	 = Current;
				
		// shaders
		VertexShader     = NULL;
		PixelShader      = NULL;
    }
}
*/

technique TRiver_FixedFunction_2TPP< string shadername = "River_Shader"; int implementation=2;>
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = FALSE;
        ZFunc          = LESSEQUAL;
        
        // Enable lighting
        Lighting       = FALSE;
        
        // Enable alpha blending & testing
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = TRUE;
        AlphaRef		 = 0;
        AlphaFunc		 = GREATER;
        SrcBlend         = SRCALPHA;
        DestBlend        = INVSRCALPHA;
        
        // textures
		Texture[0] = (BaseTexture);
		Texture[1] = (RiverFOWTexture);

		TexCoordIndex[0] = 1;
		TexCoordIndex[1] = CAMERASPACEPOSITION;
		
		TextureTransform[0] = <mtxBaseTextureMat>;
		TextureTransform[1] = <mtxFOW>;
        
		// texture stage 0 - Base Texture
		ColorOp[0]       = SelectArg1;
		ColorArg1[0]     = Texture;
		AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;
		
		// texture stage 1	- FoW
		ColorOp[1]       = Modulate;
		ColorArg1[1]     = Texture;
		ColorArg2[1]     = Current;
		AlphaOp[1]		 = SelectArg1;
		AlphaArg1[1]	 = Current;
				
		// shaders
		VertexShader     = NULL;
		PixelShader      = NULL;
    }
}
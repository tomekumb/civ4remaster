//------------------------------------------------------------------------------------------------
//  $Header: $
//------------------------------------------------------------------------------------------------
//  *****************   FIRAXIS GAME ENGINE   ********************
//
//  FILE:    Route
//
//  AUTHOR:  Jason Winokur - 6/20/2005
//
//  PURPOSE: Draw routes with normal maps.
//
//  Listing: fxc /Tvs_1_1 /ERouteVS /FcRoute.lst Route.fx
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
	float3 f3Normal		: NORMAL;
	float3 f3Binormal	: BINORMAL;
	float3 f3Tangent	: TANGENT;
};

struct VS_OUTPUT_11
{
	float4 f4Pos : POSITION;
	float3 f3LightVec : COLOR0;
	float2 f2BaseTex : TEXCOORD0;
	float2 f2NormalTex : TEXCOORD1;
	float2 f2FOWTex : TEXCOORD2;
};

//------------------------------------------------------------------------------------------------
//                          VERTEX SHADER
//------------------------------------------------------------------------------------------------
VS_OUTPUT_11 RouteVS11(VS_INPUT vIn)
{
    VS_OUTPUT_11 vOut = (VS_OUTPUT_11)0;
	
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
    vOut.f2BaseTex = vIn.f2BaseTex;
    vOut.f2NormalTex = vIn.f2BaseTex;
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
texture RouteNormalTexture <string NTM = "shader";  int NTMIndex = 0;>;
texture RouteFOWTexture <string NTM = "shader";  int NTMIndex = 1;>;

//------------------------------------------------------------------------------------------------
//                          SAMPLERS
//------------------------------------------------------------------------------------------------  
sampler RouteBase = sampler_state
{
    Texture = (BaseTexture);
    AddressU  = Wrap;
    AddressV  = Wrap;
    MagFilter = Linear;
    MinFilter = Linear;
    MipFilter = Linear;
};

sampler RouteNormalSampler = sampler_state
{ 
	Texture = (RouteNormalTexture);
	AddressU = Wrap;
	AddressV = Wrap;
	MagFilter = Linear;
	MipFilter = None;
	MinFilter = Linear; 
};

sampler RouteFOWSampler = sampler_state
{
	Texture = (RouteFOWTexture);
	AddressU = Wrap;
	AddressV = Wrap;
	MagFilter = Linear;
	MipFilter = Linear;
	MinFilter = Linear;
};

//------------------------------------------------------------------------------------------------
//This applies the route base texture and normal map
float4 RoutePS11(VS_OUTPUT_11 vIn) : COLOR
{
	float4 f4FinalColor = 0;

	// Get Base textures 
	float4 f4Base = tex2D(RouteBase, vIn.f2BaseTex);
	float3 f3Normal = tex2D(RouteNormalSampler, vIn.f2NormalTex).rgb;
	float4 f4FOW = tex2D(RouteFOWSampler, vIn.f2FOWTex);

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
technique TRoute_Shader
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
        
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
        TextureTransformFlags[2] = 0;
                
        VertexShader = compile vs_1_1 RouteVS11();
        PixelShader  = compile ps_1_1 RoutePS11();		
    }
}

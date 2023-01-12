
//------------------------------------------------------------------------------------------------
//
//  ***************** CIV4 GAME ENGINE   ********************
//
//! \file		Civ4Mech.fx
//! \author		tomw -- 09.20.05
//! \brief		Mech shader with Decal damage states, team color and gloss map
//
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2005 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------
//Include Civ4's generic lighting equation, used in several shaders
#include "ComputeCiv4Lighting.fx"

float4x4 mtxViewProj : VIEWPROJ;
float4x4 mtxInvView : INVVIEW;
float4x4 mtxDecalTexture : TEXTRANSFORMDECAL;

static const int MAX_BONES = 20;						 
float4x3 mtxWorldBones[MAX_BONES] : SKINBONEMATRIX3; //world space bone matrix

float3 f3TeamColor: GLOBAL = {0.0f, 1.0f, 0.0f};
dword dwTeamColor: GLOBAL = 0xFF0000FF;
float4 fUnitFade: MATERIALDIFFUSE = (1.0.xxxx);
						   
struct VS_INPUT
{
    float4 Pos			: POSITION;
    float3 f3Normal		: NORMAL;
    float2 TexCoord0   : TEXCOORD0;
    float4 BlendWeights : BLENDWEIGHT;
    float4 BlendIndices : BLENDINDICES;
};

struct VS_OUTPUT
{
    float4 Pos		 : POSITION;
    float2 TexBase   : TEXCOORD0;
    float2 TexDecal  : TEXCOORD1;
    float4 f4Diff	 : COLOR0;
};

struct VS_OUTPUTGLOSS
{
    float4 Pos		 : POSITION;
    float2 TexBase   : TEXCOORD0;
    float2 TexDecal  : TEXCOORD1;
    float3 f3Normal	 : TEXCOORD2;
    float4 f4Diff	 : COLOR0;
};

//------------------------------------------------------------------------------------------------  
float4x3 ComputeWorldBoneTransform( float4 f4BlendIndices, float4 f4BlendWeights )
{
	// Compensate for lack of UBYTE4 on Geforce3
    int4 indices = D3DCOLORtoUBYTE4(f4BlendIndices);

    // Calculate normalized fourth bone weight
    float weight4 = 1.0f - f4BlendWeights[0] - f4BlendWeights[1] - f4BlendWeights[2];
    float4 weights = float4(f4BlendWeights[0], f4BlendWeights[1], f4BlendWeights[2], weight4);

    // Calculate bone transform
    float4x3 BoneTransform;
	BoneTransform = weights[0] * mtxWorldBones[indices[0]];
	BoneTransform += weights[1] * mtxWorldBones[indices[1]];
	BoneTransform += weights[2] * mtxWorldBones[indices[2]];
	BoneTransform += weights[3] * mtxWorldBones[indices[3]];
	return BoneTransform;
}

//------------------------------------------------------------------------------------------------  
VS_OUTPUT SkinningDecalVS_11(VS_INPUT vIn)
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	float4x3 mtxBoneTransform = ComputeWorldBoneTransform( vIn.BlendIndices, vIn.BlendWeights );
	float3 worldPosition = mul(vIn.Pos, mtxBoneTransform);

	Out.Pos = mul(float4(worldPosition, 1.0), mtxViewProj);
	Out.TexBase = vIn.TexCoord0;
	Out.TexDecal= mul(float4(vIn.TexCoord0,1,1), mtxDecalTexture);
	
	float3 wsNormal = mul(vIn.f3Normal, (float3x3)mtxBoneTransform );
    wsNormal  = normalize(wsNormal );
	
   	Out.f4Diff.rgb = ComputeCiv4MechLighting( wsNormal );	// L.N
   	Out.f4Diff.a = 1.0f;

	return Out;
}
//------------------------------------------------------------------------------------------------  
VS_OUTPUTGLOSS SkinningDecalGlossVS_11(VS_INPUT vIn)
{
	VS_OUTPUTGLOSS Out = (VS_OUTPUTGLOSS)0;

	float4x3 mtxBoneTransform = ComputeWorldBoneTransform( vIn.BlendIndices, vIn.BlendWeights );
	float3 worldPosition = mul(vIn.Pos, mtxBoneTransform);

	Out.Pos = mul(float4(worldPosition, 1.0), mtxViewProj);
	Out.TexBase = vIn.TexCoord0;
	Out.TexDecal= mul(float4(vIn.TexCoord0,1,1), mtxDecalTexture);
	
	float3 wsNormal = mul(vIn.f3Normal, (float3x3)mtxBoneTransform );
    wsNormal  = normalize(wsNormal );
	
   	Out.f4Diff.rgb = ComputeCiv4MechLighting( wsNormal );	// L.N
   	Out.f4Diff.a = 1.0f;
   	
   	// Environment map coordiantes	
   	float3 cameraPosition = mul(float4(0, 0, 0, 1), mtxInvView);
   	float3 cameraVector = worldPosition - cameraPosition;
   	cameraVector = normalize(cameraVector);
   	cameraVector = reflect(cameraVector, wsNormal);
   	Out.f3Normal.x = 0.5 * cameraVector.x + 0.5;
	Out.f3Normal.y = 0.5 * cameraVector.z + 0.5;

	return Out;
}
//------------------------------------------------------------------------------------------------  
//------------------------------------------------------------------------------------------------  
//Base- 	Tank (Base Material UV 1 non animated)
//Decal	-	Tank Damage (Base Material UV 1 animated)
//Gloss	-	Tank Gloss
texture BaseMap <string NTM = "detail";>;
texture DecalMap <string NTM = "decal"; int NTMIndex = 0;>;
texture GlossMap <string NTM = "gloss"; int NTMIndex = 0;>;
texture EnvironMap <string NTM= "glow"; int NTMIndex = 0;>;
sampler BaseSampler = sampler_state { Texture=(BaseMap); ADDRESSU=wrap; ADDRESSV=wrap; MAGFILTER=linear; MINFILTER=linear; MIPFILTER=linear; };
sampler DecalSampler = sampler_state { Texture=(DecalMap); ADDRESSU=wrap; ADDRESSV=wrap; MAGFILTER=linear; MINFILTER=linear; MIPFILTER=linear; };
sampler GlossSampler = sampler_state { Texture=(GlossMap); ADDRESSU=wrap; ADDRESSV=wrap; MAGFILTER=linear; MINFILTER=linear; MIPFILTER=linear; };
sampler EnvironmentMapSampler = sampler_state { Texture=(EnvironMap); ADDRESSU=wrap; ADDRESSV=wrap; MAGFILTER=linear; MINFILTER=linear; MIPFILTER=linear; };

//-------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------  
float4 MechTeamColorDecalPS_11(VS_OUTPUT vIn) : COLOR
{
	float4	f4FinalColor = tex2D(BaseSampler, vIn.TexBase);
	float4  f4Decal = tex2D(DecalSampler,vIn.TexDecal);

	f4FinalColor.rgb = lerp(f3TeamColor,f4FinalColor.rgb, f4FinalColor.a);
	f4FinalColor.rgb = lerp(f4FinalColor.rgb,f4Decal.rgb, f4Decal.a);
	
	f4FinalColor.rgb *= vIn.f4Diff.rgb;
	f4FinalColor.a = fUnitFade.a;
	
   return f4FinalColor;
}

float4 MechTeamColorDecalGlossPS_14(VS_OUTPUTGLOSS vIn) : COLOR
{
	float4	f4FinalColor = tex2D(BaseSampler, vIn.TexBase);
	float4  f4Decal = tex2D(DecalSampler,vIn.TexDecal);
	float3 f3EnvironmentMap = tex2D( EnvironmentMapSampler, float2( vIn.f3Normal.x, -vIn.f3Normal.y ) );
	float3 f3GlossMask = tex2D( GlossSampler, vIn.TexBase );
	
	f4FinalColor.rgb = lerp(f3TeamColor,f4FinalColor.rgb, f4FinalColor.a);
	f4FinalColor.rgb = lerp(f4FinalColor.rgb,f4Decal.rgb, f4Decal.a);
		
	float3 f3EnvMap = f3EnvironmentMap * f3GlossMask;
	f4FinalColor.rgb *= vIn.f4Diff.rgb;
	f4FinalColor.rgb += f3EnvMap;
	f4FinalColor.a = fUnitFade.a;
	return f4FinalColor;
}

//-------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------

technique TCiv4MechShader
<
	string Description = "Civ4 Damage Decal FX-based skinning shader w/TeamColor(20 bones)";
	int BonesPerPartition = MAX_BONES;
	bool UsesNiRenderState = true;
>
{
  	pass P0
	{
		VertexShader = compile vs_1_1 SkinningDecalVS_11();		
		PixelShader = compile ps_1_1 MechTeamColorDecalPS_11();
	}
}

technique TCiv4MechNonShader
<
	string Description = "Civ4 Damage Decal NonShader-based skinning shader w/TeamColor(4 bones)";
	int BonesPerPartition = 4;
	bool UsesNiRenderState = true;
>
{
  	pass P0
	{
        // Set the smaplers
		Sampler[0] = <BaseSampler>;
        Sampler[1] = <DecalSampler>;
		//Sampler[2] = <GlossSampler>;

	    // transforms
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 0;
        //TexCoordIndex[2] = 0;	
        
        TextureTransform[0] = 0;
		TextureTransform[1] = <mtxDecalTexture>;	
		//TextureTransform[2] = 0;
        
        TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = Count2;	
		//TextureTransformFlags[2] = 0;	
        
		TextureFactor = <dwTeamColor>;
           
		// texture stage 1 - Base Texture + TeamCOlor
        ColorOp[0]       = BlendTextureAlpha;
        ColorArg1[0]     = Texture;
        ColorArg2[0]	 = TFactor;
       	AlphaOp[0]		 = SelectArg2;
		AlphaArg1[0]	 = Texture;
		AlphaArg2[0]	 = TFactor;

        // texture stage 1 - Decal
        ColorOp[1]       = BlendTextureAlpha;
        ColorArg1[1]     = Texture;
        ColorArg2[1]     = Current;
       	AlphaOp[1]		 = Disable;
       
		// terminate state 4
        ColorOp[2]		= Disable;
        AlphaOp[2]		= Disable;
  
        // shaders
        VertexShader     = NULL;
        PixelShader      = NULL;
	}
}



technique TCiv4MechShaderGloss
<
	string shadername = "TCiv4MechShaderGloss";
	string Description = "Civ4 Damage Gloss Decal FX-based skinning shader w/TeamColor(20 bones)";
	int BonesPerPartition = MAX_BONES;
	bool UsesNiRenderState = true;
	int implementation=0;
>
{
  	pass P0
	{
		AlphaTestEnable  = false;
   		AlphaRef         = 0;
   		
		VertexShader = compile vs_1_1 SkinningDecalGlossVS_11();		
		PixelShader = compile ps_1_4 MechTeamColorDecalGlossPS_14();
	}
}

technique TCiv4MechShader
<
	string shadername = "TCiv4MechShaderGloss";
	string Description = "Civ4 Damage Gloss Decal FX-based skinning shader w/TeamColor(20 bones)";
	int BonesPerPartition = MAX_BONES;
	bool UsesNiRenderState = true;
	int implementation=1;
>
{
  	pass P0
	{
	    AlphaTestEnable  = false;
   		AlphaRef         = 0;
   		
		VertexShader = compile vs_1_1 SkinningDecalVS_11();		
		PixelShader = compile ps_1_1 MechTeamColorDecalPS_11();
	}
}
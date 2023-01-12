//------------------------------------------------------------------------------------------------
//
//  ***************** CIV4 GAME ENGINE   ********************
//
//! \file		Civ4SkinShader.fx
//! \author		tomw -- 06.15.05
//! \brief		Skin shader w/ team color
//
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2005 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------

float4x4 mtxViewProj : VIEWPROJ;
float4x4 mtxInvView : INVVIEW;
float4x4 mtxDecalTexture : TEXTRANSFORMDECAL;
float4x4 mtxFOW  : GLOBAL;

static const int MAX_BONES = 20;						 
float4x3 mtxWorldBones[MAX_BONES] : SKINBONEMATRIX3; //world space bone matrix

float3 f3TeamColor: GLOBAL = {0.0f, 1.0f, 0.0f};
float4 fUnitFade: MATERIALDIFFUSE = (1.0.xxxx);

//Include Civ4's generic lighting equation, used in several shaders
#include "ComputeCiv4Lighting.fx"

struct VS_INPUT 
{
    float4 Pos			: POSITION;
    float3 f3Normal		: NORMAL;
    float2 TexCoords    : TEXCOORD0;
    float4 BlendWeights : BLENDWEIGHT;
    float4 BlendIndices : BLENDINDICES;
};

struct VS_OUTPUT
{
    float4 Pos		 : POSITION;
    float2 TexCoords : TEXCOORD0;
    float4 f4Diff	 : COLOR0;
};

struct VS_OUTPUTFOW 
{
    float4 Pos		 : POSITION;
    float2 TexCoords : TEXCOORD0;
    float2 f2FowTex  : TEXCOORD1;
    float4 f4Diff	 : COLOR0;
};

struct VS_OUTPUTGLOSS 
{
    float4 Pos		 : POSITION;
    float2 TexCoords : TEXCOORD0;
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
VS_OUTPUT SkinningVS_11(VS_INPUT vIn)
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	float4x3 mtxBoneTransform = ComputeWorldBoneTransform( vIn.BlendIndices, vIn.BlendWeights );
	float3 worldPosition = mul(vIn.Pos, mtxBoneTransform);

	Out.Pos = mul(float4(worldPosition, 1.0), mtxViewProj);
	Out.TexCoords = vIn.TexCoords;

	float3 wsNormal = mul(vIn.f3Normal, (float3x3)mtxBoneTransform );
    wsNormal  = normalize(wsNormal);
	
   	Out.f4Diff.rgb = ComputeCiv4UnitLighting( wsNormal );	// L.N
   	Out.f4Diff.a = 1.0f;

	return Out;
}
//------------------------------------------------------------------------------------------------  
VS_OUTPUTGLOSS SkinningGlossVS_11(VS_INPUT vIn)
{
	VS_OUTPUTGLOSS Out = (VS_OUTPUTGLOSS)0;

	float4x3 mtxBoneTransform = ComputeWorldBoneTransform( vIn.BlendIndices, vIn.BlendWeights );
	float3 worldPosition = mul(vIn.Pos, mtxBoneTransform);

	Out.Pos = mul(float4(worldPosition, 1.0), mtxViewProj);
	Out.TexCoords = vIn.TexCoords;

	float3 wsNormal = mul(vIn.f3Normal, (float3x3)mtxBoneTransform );
    wsNormal = normalize(wsNormal);
	
   	Out.f4Diff.rgb = ComputeCiv4UnitLighting( wsNormal );	// L.N
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
VS_OUTPUTFOW SkinningFOWVS_11(VS_INPUT vIn)
{
	VS_OUTPUTFOW Out = (VS_OUTPUTFOW)0;

	float4x3 mtxBoneTransform = ComputeWorldBoneTransform( vIn.BlendIndices, vIn.BlendWeights );
	float3 worldPosition = mul(vIn.Pos, mtxBoneTransform);

	Out.Pos = mul(float4(worldPosition, 1.0), mtxViewProj);
	Out.TexCoords = vIn.TexCoords;

	Out.f2FowTex   = mul(float4(worldPosition,1),mtxFOW);

	float3 wsNormal = mul(vIn.f3Normal, (float3x3)mtxBoneTransform);
    wsNormal = normalize(wsNormal);
	
   	Out.f4Diff.rgb = ComputeCiv4UnitLighting( wsNormal );	// L.N
   	Out.f4Diff.a = 1.0f;

	return Out;
}

//------------------------------------------------------------------------------------------------
//                          PIXEL SHADER
//------------------------------------------------------------------------------------------------
texture BaseMap <string NTM = "base";>;
texture DecalMap <string NTM = "decal"; int NTMIndex = 0;>;
texture GlossMap <string NTM = "gloss"; int NTMIndex = 0;>;
texture EnvironMap <string NTM= "glow"; int NTMIndex = 0;>;
texture FOGTexture<string NTM = "shader";  int NTMIndex = 1;>;

sampler BaseSampler = sampler_state { Texture=(BaseMap); ADDRESSU=wrap; ADDRESSV=wrap; MAGFILTER=linear; MINFILTER=linear; MIPFILTER=linear; };
sampler DecalSampler = sampler_state { Texture=(DecalMap); ADDRESSU=wrap; ADDRESSV=wrap; MAGFILTER=linear; MINFILTER=linear; MIPFILTER=linear; };
sampler GlossSampler = sampler_state { Texture=(GlossMap); ADDRESSU=wrap; ADDRESSV=wrap; MAGFILTER=linear; MINFILTER=linear; MIPFILTER=linear; };
sampler EnvironmentMapSampler = sampler_state { Texture=(EnvironMap); ADDRESSU=wrap; ADDRESSV=wrap; MAGFILTER=linear; MINFILTER=linear; MIPFILTER=linear; };
sampler Fog = sampler_state  { Texture = (FOGTexture);	   AddressU = Clamp;  AddressV = Clamp;  MagFilter = Linear; MipFilter = Linear; MinFilter = Linear; };


float4 SkinningTeamColorPS_11(VS_OUTPUT vIn) : COLOR
{
	float4	f4FinalColor = tex2D(BaseSampler, vIn.TexCoords);
	f4FinalColor.rgb = lerp(f3TeamColor, f4FinalColor.rgb, f4FinalColor.a);
	f4FinalColor.rgb *= vIn.f4Diff.rgb;	 
	f4FinalColor.a = fUnitFade.a;
	return f4FinalColor;
}

float4 SkinningPS_11(VS_OUTPUT vIn) : COLOR
{
	float4	f4FinalColor = tex2D(BaseSampler, vIn.TexCoords);
	f4FinalColor.rgb *= vIn.f4Diff.rgb;	 
	f4FinalColor.a *= fUnitFade.a;
	return f4FinalColor;
}

float4 SkinningFOWPS_11(VS_OUTPUTFOW vIn) : COLOR
{
	float4	f4FinalColor = tex2D(BaseSampler, vIn.TexCoords);
	float3 f4FOWTex   = tex2D( Fog, vIn.f2FowTex ).rgb;
	
	f4FinalColor.rgb *= vIn.f4Diff.rgb;	
	f4FinalColor.rgb *= f4FOWTex; // apply fog of war
	f4FinalColor.a *= fUnitFade.a;
	return f4FinalColor;
}

float4 SkinningTeamColorGlossPS_14(VS_OUTPUTGLOSS vIn) : COLOR
{
	float4	f4FinalColor = tex2D(BaseSampler, vIn.TexCoords);
	float3 f3EnvironmentMap = tex2D( EnvironmentMapSampler, float2( vIn.f3Normal.x, -vIn.f3Normal.y ) );
	float3 f3GlossMask = tex2D( GlossSampler, vIn.TexCoords );
	float3 f3EnvMap = f3EnvironmentMap * f3GlossMask;
	
	f4FinalColor.rgb = lerp(f3TeamColor,f4FinalColor.rgb, f4FinalColor.a);
	f4FinalColor.rgb *= vIn.f4Diff.rgb;
	f4FinalColor.rgb += f3EnvMap;	
	f4FinalColor.a = fUnitFade.a;
	return f4FinalColor;
}


//------------------------------------------------------------------------------------------------
//                          TECHNIQUES
//------------------------------------------------------------------------------------------------
technique TCiv4Skinning
<
	string Description = "Civ4 TeamColor FX-based skinning shader(20 bones)";
	int BonesPerPartition = MAX_BONES;
	bool UsesNiRenderState = true;
>
{
  	pass P0
	{
		VertexShader = compile vs_1_1 SkinningVS_11();
		PixelShader = compile ps_1_1 SkinningTeamColorPS_11();
	}
}

technique TCiv4SkinningNoTeamColor
<
	string Description = "Civ4 FX-based skinning shader(20 bones)";
	int BonesPerPartition = MAX_BONES;
	bool UsesNiRenderState = true;
>
{
  	pass P0
	{
		VertexShader = compile vs_1_1 SkinningVS_11();
		PixelShader = compile ps_1_1 SkinningPS_11();
	}
}

technique TCiv4SkinningNoTColorFOW
<
	string Description = "Civ4 FOW FX-based skinning shader(20 bones)";
	int BonesPerPartition = MAX_BONES;
	bool UsesNiRenderState = true;
>
{
  	pass P0
	{
		VertexShader = compile vs_1_1 SkinningFOWVS_11();
		PixelShader = compile ps_1_1 SkinningFOWPS_11();
	}
}

//-------------------------------------------------------------------------------------------
// Environment Map Units---------------------------------------------------------------------
//-------------------------------------------------------------------------------------------
technique TCiv4SkinningGloss
<
	string shadername = "TCiv4SkinningGloss";
	string Description = "Civ4 TeamColor GlossMap FX-based skinning shader(20 bones)";
	int BonesPerPartition = MAX_BONES;
	bool UsesNiRenderState = true;
	int implementation=0;

>
{
  	pass P0
	{
		VertexShader = compile vs_1_1 SkinningGlossVS_11();
		PixelShader = compile ps_1_4 SkinningTeamColorGlossPS_14();
	}
}

//ps11 fallback
technique TCiv4SkinningGloss_11
<
	string shadername = "TCiv4SkinningGloss";
	string Description = "Civ4 TeamColor GlossMap FX-based skinning shader(20 bones)";
	int BonesPerPartition = MAX_BONES;
	bool UsesNiRenderState = true;
	int implementation=1;
>
{
  	pass P0
	{
		VertexShader = compile vs_1_1 SkinningVS_11();
		PixelShader = compile ps_1_1 SkinningTeamColorPS_11();
	}
}


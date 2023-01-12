//------------------------------------------------------------------------------------------------
//  $Header: $
//------------------------------------------------------------------------------------------------
//  *****************   FIRAXIS GAME ENGINE   ********************
//
//  FILE:    Civ4LeaderheadShader.fx
//
//  AUTHOR:  Bart Muzzin
//
//  PURPOSE: All decked out leader heads...
//
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2005 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------

#include "Civ4NormalMapping.fx.hlsl"

//------------------------------------------------------------------------------------------------
// VARIABLES
//------------------------------------------------------------------------------------------------  
float4x4	mtxSkinWorldViewProj	: SKINWORLDVIEWPROJ;
float4x4	mtxSkinWorldView		: SKINWORLDVIEW;
float4x4	mtxSkinWorld			: WORLD;
float4x4	mtxWorldViewProj		: WORLDVIEWPROJECTION;
float4x4    mtxWorldView			: WORLDVIEW;
float4x4	mtxWorldInv				: WORLDINVERSE;
float4x4 mtxBaseTransform : TEXTRANSFORMBASE;

static const int LEADER_MAX_BONES = 16;
float4x3 mtxBones[LEADER_MAX_BONES] : BONEMATRIX3;

float3		f3LightPos1			: GLOBAL;	// key light world position
float3		f3DiffuseColor1		: GLOBAL;	// key light diffuse color
float4		f4SpecularColor1	: GLOBAL;	// key light specular color - 4th component = shininess exponent
float3		f3LightPos2			: GLOBAL;	// fill light world position
float3		f3DiffuseColor2		: GLOBAL;	// fill light diffuse color
float4		f4SpecularColor2	: GLOBAL;	// fill specular color - 4th component = shininess exponent
float3		f3LightPos3			: GLOBAL;	// back light world position
float3		f3DiffuseColor3		: GLOBAL;	// back light diffuse color
float4		f4SpecularColor3	: GLOBAL;	// back - 4th component = shininess exponent
float3		f3Ambient			: GLOBAL;	// Ambient values
float3		f3CameraPos			: GLOBAL;	// Camera world position

//------------------------------------------------------------------------------------------------
//							TEXTURES
//------------------------------------------------------------------------------------------------  
texture BaseTexture <string NTM = "base";>;
texture DecalTexture <string NTM = "decal"; int NTMIndex = 0;>;
texture NormalMap < string NTM = "shader"; int NTMIndex = 1;>;
texture SpecularIntensity < string NTM = "shader"; int NTMIndex = 2;>;
texture EnvironmentIntensity < string NTM = "shader"; int NTMIndex = 3;>;
texture EnvironmentMap< string NTM = "shader"; int NTMIndex = 0;>;			// must be index zero - something wrong with the max exporter?

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

sampler DecalSampler = sampler_state
{
    Texture = (DecalTexture);
    AddressU  = WRAP;
    AddressV  = WRAP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;
};

sampler NormalSampler = sampler_state
{ 
	Texture = (NormalMap);
	AddressU = Clamp;
	AddressV = Clamp;
	MagFilter = Linear;
	MipFilter = None;
	MinFilter = Linear; 
};

sampler SpecularMaskSampler = sampler_state
{
	Texture = (SpecularIntensity);
	AddressU = Clamp;
	AddressV = Clamp;
	MagFilter = Linear;
	MipFilter = Linear;
	MinFilter = Linear; 
};

sampler EnvironmentMapSampler = sampler_state
{
	Texture = (EnvironmentMap);
	AddressU = Wrap;
	AddressV = Wrap;
	AddressW = Wrap;
	MagFilter = Linear;
	MipFilter = Linear;
	MinFilter = Linear; 
};

sampler EnvironmentMaskSampler = sampler_state
{
	Texture = (EnvironmentIntensity);
	AddressU = Clamp;
	AddressV = Clamp;
	MagFilter = Linear;
	MipFilter = Linear;
	MinFilter = Linear; 
};

//------------------------------------------------------------------------------------------------
//                          STRUCTURES
//------------------------------------------------------------------------------------------------  

struct LHINPUT_20
{
	float4 f4Position	: POSITION;
	float2 f2TexCoord	: TEXCOORD;
	float3 f3Normal		: NORMAL;
	float3 f3Binormal	: BINORMAL;
	float3 f3Tangent	: TANGENT;
	float4 f4BlendIndices	: BLENDINDICES;
	float4 f4BlendWeights	: BLENDWEIGHT;
};


struct LHOUTPUT_20
{
	float4	f4Position		: POSITION;
	float3	f3Normal		: TEXCOORD3;
	float3	f3LightVec1		: COLOR0;
	float3	f3LightHalfAng1	: COLOR1;
	float3	f3LightVec2		: TEXCOORD7;
	float3	f3LightHalfAng2	: TEXCOORD6;
	float3	f3LightVec3		: TEXCOORD5;
	float3	f3LightHalfAng3	: TEXCOORD4;
	float2	f2TexCoord		: TEXCOORD0;
};

//------------------------------------------------------------------------------------------------  

struct LHINPUT_11_1
{
	float4 f4Position		: POSITION;
	float2 f2TexCoord		: TEXCOORD;
	float3 f3Normal			: NORMAL;
	float3 f3Binormal		: BINORMAL;
	float3 f3Tangent		: TANGENT;
	float4 f4BlendIndices	: BLENDINDICES;
	float4 f4BlendWeights	: BLENDWEIGHT;
};

struct LHINPUT_11_2x
{
	float4 f4Position		: POSITION;
	float2 f2TexCoord		: TEXCOORD;
	float3 f3Normal			: NORMAL;
	float3 f3Binormal		: BINORMAL;
	float3 f3Tangent		: TANGENT;
	float4 f4BlendIndices	: BLENDINDICES;
	float4 f4BlendWeights	: BLENDWEIGHT;
};

struct LHINPUT_11_3
{
	float4 f4Position		: POSITION;
	float2 f2TexCoord		: TEXCOORD;
	float3 f3Normal			: NORMAL;
	float4 f4BlendIndices	: BLENDINDICES;
	float4 f4BlendWeights	: BLENDWEIGHT;
};

struct LHOUTPUT_11_1
{
	float4	f4Position		: POSITION;
	float3	f3LightVec1		: COLOR0;
	float3	f3LightVec2		: COLOR1;
	float3	f3LightVec3		: TEXCOORD0;
	float2	f2TexCoord1		: TEXCOORD1;
	float2	f2TexCoord2		: TEXCOORD2;
};

struct LHOUTPUT_11_2x
{
	float4	f4Position		: POSITION;
	float3	f3LightHalfAng	: COLOR0;
	float3	f3LightVec		: COLOR1;
	float2	f2TexCoord1		: TEXCOORD0;
	float2	f2TexCoord1b	: TEXCOORD1;
	float2	f2TexCoord2		: TEXCOORD2;
};

struct LHOUTPUT_11_3
{
	float4	f4Position		: POSITION;
	float2	f2TexCoord1		: TEXCOORD0;
	float2	f2TexCoord1b	: TEXCOORD1;
	float3	f3Normal		: TEXCOORD2;
};

struct LHPOUTPUT_20
{
	float4	f4Position		: POSITION;
	float2	f2TexCoord		: TEXCOORD0;	
};

struct LHINPUT_ALPHA_DECAL
{
	float4 f4Position	: POSITION;
	float2 f2TexCoord	: TEXCOORD;
};

struct LHOUTPUT_ALPHA_DECAL
{
	float4	f4Position		: POSITION;
	float2	f2TexCoord0		: TEXCOORD0;
	float2	f2TexCoord1		: TEXCOORD1;
};

//------------------------------------------------------------------------------------------------
//                          Shaders
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------
//                         Alpha Decal Shaders
//------------------------------------------------------------------------------------------------

LHOUTPUT_ALPHA_DECAL VSLeaderheadAlphaDecal11(LHINPUT_ALPHA_DECAL input)
{
	LHOUTPUT_ALPHA_DECAL output = (LHOUTPUT_ALPHA_DECAL) 0;
	output.f4Position = mul(input.f4Position, mtxWorldViewProj);
	output.f2TexCoord0 = mul(float4(input.f2TexCoord, 1, 1), mtxBaseTransform);
	output.f2TexCoord1 = input.f2TexCoord;
	return output;
}

float4 PSLeaderheadAlphaDecal11(LHOUTPUT_ALPHA_DECAL input) : COLOR
{
	//textures
	float4 f4BaseColor = tex2D(BaseSampler, input.f2TexCoord0);
	float4 f4DecalColor = tex2D(DecalSampler, input.f2TexCoord1);
	float4 f4FinalColor = f4DecalColor + f4BaseColor * f4BaseColor.a;
	f4FinalColor.a = f4BaseColor.a * f4DecalColor.a;
	return f4FinalColor;
}

float4x3 ComputeBoneTransform( float4 f4BlendIndices, float4 f4BlendWeights )
{
	// Compensate for lack of UBYTE4 on Geforce3
    int4 indices = D3DCOLORtoUBYTE4(f4BlendIndices);

    // Calculate normalized fourth bone weight
    float weight4 = 1.0f - f4BlendWeights[0] - f4BlendWeights[1] - f4BlendWeights[2];
    float4 weights = float4(f4BlendWeights[0], f4BlendWeights[1], f4BlendWeights[2], weight4);

    // Calculate bone transform
    float4x3 BoneTransform;
	BoneTransform = weights[0] * mtxBones[indices[0]];
	BoneTransform += weights[1] * mtxBones[indices[1]];
	BoneTransform += weights[2] * mtxBones[indices[2]];
	BoneTransform += weights[3] * mtxBones[indices[3]];
	return BoneTransform;
}


//------------------------------------------------------------------------------------------------
// Shaders 2.0 path
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------

// Vertex shader
LHOUTPUT_20 VSLeaderhead20( LHINPUT_20 kInput )
{
	LHOUTPUT_20	kOutput = (LHOUTPUT_20)0;

	float4 f4VertNormLightVec;
	float3x3 mtxObjToTangentSpace;

	// Transform the position, and copy the texture coordinates
	float4x3 mtxBoneTransform = ComputeBoneTransform( kInput.f4BlendIndices, kInput.f4BlendWeights );
	float3 f3BoneSpacePos = mul(float4(kInput.f4Position), mtxBoneTransform);
	kOutput.f4Position = mul(float4(f3BoneSpacePos, 1.0), mtxSkinWorldViewProj );
	
	float4x4 mtxBoneWorldView = mul( mtxBoneTransform, mtxSkinWorldView);
	
	// Environment map coordiantes	
	float3 temp = mul(float4(kInput.f3Normal,0.0), mtxBoneWorldView );
	kOutput.f3Normal.x = temp.x / 2.0 + 0.5;
	kOutput.f3Normal.y = -temp.y / 2.0 + 0.5;	
	kOutput.f2TexCoord = kInput.f2TexCoord;

	// Make the world-space to tangent-space matrix
	mtxObjToTangentSpace[0] = mul(kInput.f3Tangent, mtxBoneTransform);
	mtxObjToTangentSpace[1] = mul(kInput.f3Binormal, mtxBoneTransform);
	mtxObjToTangentSpace[2] = mul(kInput.f3Normal, mtxBoneTransform);

	// Compute the object-space camera direction
	float4 f4ObjectViewDir = mul( f3CameraPos - mul(f3BoneSpacePos,mtxSkinWorld), mtxWorldInv);
	f4ObjectViewDir = normalize(f4ObjectViewDir);
	
	// Compute the object-space light direction and half-angle for light #1.
	NMLIGHT_INPUT kLightInput;
	NMLIGHT_OUTPUT kLightOutput;

	kLightInput.f3Position = kOutput.f4Position.xyz;
	kLightInput.f4ObjectViewDir = f4ObjectViewDir;
	kLightInput.mtxObjToTangentSpace = mtxObjToTangentSpace;
	kLightInput.mtxWorldInv = mtxWorldInv;
	
	kLightOutput = ComputeNormalMappingVectors( f3LightPos1, kLightInput );	
	kOutput.f3LightHalfAng1.xyz = kLightOutput.f3LightHalfAngle;
	kOutput.f3LightVec1.xyz = kLightOutput.f3LightVec;
		
	kLightOutput = ComputeNormalMappingVectors( f3LightPos2, kLightInput );	
	kOutput.f3LightHalfAng2.xyz = kLightOutput.f3LightHalfAngle;
	kOutput.f3LightVec2.xyz = kLightOutput.f3LightVec;

	kLightOutput = ComputeNormalMappingVectors( f3LightPos3, kLightInput );	
	kOutput.f3LightHalfAng3.xyz = kLightOutput.f3LightHalfAngle;
	kOutput.f3LightVec3.xyz = kLightOutput.f3LightVec;
	
	return kOutput;
}

//------------------------------------------------------------------------------------------------
LHOUTPUT_20 VSLeaderheadNoSkin20( LHINPUT_20 kInput )
{
	LHOUTPUT_20	kOutput = (LHOUTPUT_20)0;

	// Transform the position, and copy the texture coordinates
	kOutput.f4Position = mul(kInput.f4Position, mtxWorldViewProj );	
	
	float4 f4VertNormLightVec;
	float3x3 mtxObjToTangentSpace;

	// Compute the object-space camera direction
	float4 f4ObjectViewDir = mul( f3CameraPos - kInput.f4Position.xyz, mtxWorldInv);
	f4ObjectViewDir = normalize(f4ObjectViewDir);

	// Environment map coordiantes	
	float3 temp = mul(float4(kInput.f3Normal,0.0), mtxWorldView );
	kOutput.f3Normal.x = temp.x / 2.0 + 0.5;
	kOutput.f3Normal.y = -temp.y / 2.0 + 0.5;	
	kOutput.f2TexCoord = kInput.f2TexCoord;

	// Make the world-space to tangent-space matrix
	mtxObjToTangentSpace[0] = kInput.f3Tangent;
	mtxObjToTangentSpace[1] = kInput.f3Binormal;
	mtxObjToTangentSpace[2] = kInput.f3Normal;

	// Compute the object-space light direction and half-angle for light #1.
	NMLIGHT_INPUT kLightInput;
	NMLIGHT_OUTPUT kLightOutput;

	kLightInput.f3Position = kOutput.f4Position.xyz;
	kLightInput.f4ObjectViewDir = f4ObjectViewDir;
	kLightInput.mtxObjToTangentSpace = mtxObjToTangentSpace;
	kLightInput.mtxWorldInv = mtxWorldInv;
	
	kLightOutput = ComputeNormalMappingVectors( f3LightPos1, kLightInput );	
	kOutput.f3LightHalfAng1.xyz = kLightOutput.f3LightHalfAngle;
	kOutput.f3LightVec1.xyz = kLightOutput.f3LightVec;
		
	kLightOutput = ComputeNormalMappingVectors( f3LightPos2, kLightInput );	
	kOutput.f3LightHalfAng2.xyz = kLightOutput.f3LightHalfAngle;
	kOutput.f3LightVec2.xyz = kLightOutput.f3LightVec;

	kLightOutput = ComputeNormalMappingVectors( f3LightPos3, kLightInput );	
	kOutput.f3LightHalfAng3.xyz = kLightOutput.f3LightHalfAngle;
	kOutput.f3LightVec3.xyz = kLightOutput.f3LightVec;
	
	return kOutput;
}

//------------------------------------------------------------------------------------------------
// Pixel shader

float4 PSLeaderhead20( LHOUTPUT_20 kOutput ) : COLOR
{
	// Sample textures
	float4 f4BaseColor = tex2D( BaseSampler, kOutput.f2TexCoord );
	float3 f3NormalSample = tex2D( NormalSampler, kOutput.f2TexCoord );
	float3 f3SpecularMask = tex2D( SpecularMaskSampler, kOutput.f2TexCoord );
	float3 f3EnvironmentMap = tex2D( EnvironmentMapSampler, float2( kOutput.f3Normal.x, kOutput.f3Normal.y ) );
	float3 f3EnvironmentMask = tex2D( EnvironmentMaskSampler, kOutput.f2TexCoord );
	
	// Unbias the object-space light dirs
	f3NormalSample = normalize((f3NormalSample - 0.5) * 2.0);
	float3 f3ExpLightDir1 = ( kOutput.f3LightVec1 -0.5 ) * 2.0;
	float3 f3ExpLightDir2 = ( kOutput.f3LightVec2 -0.5 ) * 2.0;
	float3 f3ExpLightDir3 = ( kOutput.f3LightVec3 -0.5 ) * 2.0;
	
	// Unbias the object-space half-angles
	float3 f3ExpHalfAngle1 = ( kOutput.f3LightVec1 -0.5 ) * 2.0;
	float3 f3ExpHalfAngle2 = ( kOutput.f3LightVec2 -0.5 ) * 2.0;
	float3 f3ExpHalfAngle3 = ( kOutput.f3LightVec3 -0.5 ) * 2.0;
	
	// Diffuse lighting (for 3 lights) = (N.L) * Cs
	float3 f3Diffuse1 = saturate( dot( f3NormalSample.xyz, f3ExpLightDir1 ) * f3DiffuseColor1 );
	float3 f3Diffuse2 = saturate( dot( f3NormalSample.xyz, f3ExpLightDir2 ) * f3DiffuseColor2 );
	float3 f3Diffuse3 = saturate( dot( f3NormalSample.xyz, f3ExpLightDir3 ) * f3DiffuseColor3 );
	
	// Specular lighting (for 3 lights) = (N.H)^n * Cs
	float3 f3Specular1 = saturate( pow( saturate( dot(f3NormalSample.xyz, f3ExpHalfAngle1) ), f3SpecularMask.r * 90.0 ) * f4SpecularColor1 );
	float3 f3Specular2 = saturate( pow( saturate( dot(f3NormalSample.xyz, f3ExpHalfAngle2) ), f3SpecularMask.r * 90.0 ) * f4SpecularColor2 );
	float3 f3Specular3 = saturate( pow( saturate( dot(f3NormalSample.xyz, f3ExpHalfAngle3) ), f3SpecularMask.r * 90.0 ) * f4SpecularColor3 );
	
	// Compute the total specular and diffuse lighting
	float3 f3SpecularTotal = f3SpecularMask * saturate( f3Specular1 + f3Specular2 + f3Specular3 );
	float3 f3DiffuseTotal = saturate(f3Diffuse1 + f3Diffuse2 + f3Diffuse3);
	float3 f3EnvMap = f3EnvironmentMap * f3EnvironmentMask;
	
	// Final summation
	return float4(  f3SpecularTotal + f3EnvMap + ( f3DiffuseTotal + f3Ambient) * f4BaseColor, f4BaseColor.a );
}

//------------------------------------------------------------------------------------------------
// Shaders 1.1 path
//------------------------------------------------------------------------------------------------

LHOUTPUT_11_1 VSLeaderhead11_1( LHINPUT_11_1 kInput )
{
	LHOUTPUT_11_1 kOutput = (LHOUTPUT_11_1)0;

	// Transform the position, and copy the texture coordinates
	float4x3 mtxBoneTransform = ComputeBoneTransform( kInput.f4BlendIndices, kInput.f4BlendWeights );
	float3 f3BoneSpacePos = mul(float4(kInput.f4Position), mtxBoneTransform);	
	kOutput.f4Position = mul(float4(f3BoneSpacePos, 1.0), mtxSkinWorldViewProj );
	
	float4x4 mtxBoneWorldView = mul( mtxBoneTransform, mtxSkinWorldView);
	
	float4 f4VertNormLightVec;
	float4 f4ObjectViewDir;
	float3x3 mtxObjToTangentSpace;

	// Copy texture coordinates
	kOutput.f2TexCoord1 = kInput.f2TexCoord;
	kOutput.f2TexCoord2 = kInput.f2TexCoord;

	// Make the world-space to tangent-space matrix
	mtxObjToTangentSpace[0] = mul(kInput.f3Tangent, mtxBoneTransform);
	mtxObjToTangentSpace[1] = mul(kInput.f3Binormal, mtxBoneTransform);
	mtxObjToTangentSpace[2] = mul(kInput.f3Normal, mtxBoneTransform);
	
	// Compute the object-space camera direction
	f4ObjectViewDir = mul( f3CameraPos - mul(f3BoneSpacePos,mtxSkinWorld), mtxWorldInv);
	f4ObjectViewDir = normalize(f4ObjectViewDir);
	
	NMLIGHT_INPUT kLightInput;
	NMLIGHT_OUTPUT kLightOutput;

	kLightInput.f3Position = kOutput.f4Position.xyz;
	kLightInput.f4ObjectViewDir = f4ObjectViewDir;
	kLightInput.mtxObjToTangentSpace = mtxObjToTangentSpace;
	kLightInput.mtxWorldInv = mtxWorldInv;
	
	// Compute the object-space light direction #1.
	kLightOutput = ComputeNormalMappingVectors( f3LightPos1, kLightInput );	
	kOutput.f3LightVec1.xyz = kLightOutput.f3LightVec;
	
	// Compute the object-space light direction #2.
	kLightOutput = ComputeNormalMappingVectors( f3LightPos2, kLightInput );	
	kOutput.f3LightVec2.xyz = kLightOutput.f3LightVec;
	
	// Compute the object-space light direction #3.
	kLightOutput = ComputeNormalMappingVectors( f3LightPos3, kLightInput );	
	kOutput.f3LightVec3.xyz = kLightOutput.f3LightVec;

	return kOutput;
}

//------------------------------------------------------------------------------------------------

LHOUTPUT_11_1 VSLeaderheadNoSkin11_1( LHINPUT_11_1 kInput )
{
	LHOUTPUT_11_1 kOutput = (LHOUTPUT_11_1)0;

	// Transform the position, and copy the texture coordinates
	kOutput.f4Position = mul(kInput.f4Position, mtxWorldViewProj );

	float4 f4VertNormLightVec;
	float4 f4ObjectViewDir;
	float3x3 mtxObjToTangentSpace;

	// Copy texture coordinates
	kOutput.f2TexCoord1 = kInput.f2TexCoord;
	kOutput.f2TexCoord2 = kInput.f2TexCoord;

	// Make the world-space to tangent-space matrix
	mtxObjToTangentSpace[0] = kInput.f3Tangent;
	mtxObjToTangentSpace[1] = kInput.f3Binormal;
	mtxObjToTangentSpace[2] = kInput.f3Normal;
	
	// Compute the object-space camera direction
	f4ObjectViewDir = mul( float4(f3CameraPos - kInput.f4Position.xyz,1.0), mtxWorldInv);
	f4ObjectViewDir = normalize(f4ObjectViewDir);
	
	NMLIGHT_INPUT kLightInput;
	NMLIGHT_OUTPUT kLightOutput;

	kLightInput.f3Position = kOutput.f4Position.xyz;
	kLightInput.f4ObjectViewDir = f4ObjectViewDir;
	kLightInput.mtxObjToTangentSpace = mtxObjToTangentSpace;
	kLightInput.mtxWorldInv = mtxWorldInv;
	
	// Compute the object-space light direction #1.
	kLightOutput = ComputeNormalMappingVectors( f3LightPos1, kLightInput );	
	kOutput.f3LightVec1.xyz = kLightOutput.f3LightVec;
	
	// Compute the object-space light direction #2.
	kLightOutput = ComputeNormalMappingVectors( f3LightPos2, kLightInput );	
	kOutput.f3LightVec2.xyz = kLightOutput.f3LightVec;
	
	// Compute the object-space light direction #3.
	kLightOutput = ComputeNormalMappingVectors( f3LightPos3, kLightInput );	
	kOutput.f3LightVec3.xyz = kLightOutput.f3LightVec;

	return kOutput;
}

//------------------------------------------------------------------------------------------------

// Specular pass #1/#2/#3
LHOUTPUT_11_2x VSLeaderhead11_2x( LHINPUT_11_2x kInput, uniform float3 f3LightPosition)
{
	LHOUTPUT_11_2x	kOutput = (LHOUTPUT_11_2x)0;

	// Transform the position, and copy the texture coordinates
	float4x3 mtxBoneTransform = ComputeBoneTransform( kInput.f4BlendIndices, kInput.f4BlendWeights );
	float3 f3BoneSpacePos = mul(float4(kInput.f4Position), mtxBoneTransform);	
	kOutput.f4Position = mul(float4(f3BoneSpacePos, 1.0), mtxSkinWorldViewProj );

	float4 f4ObjectLightDir;
	float4 f4VertNormLightVec;
	float4 f4ObjectViewDir;
	float3x3 mtxObjToTangentSpace;

	kOutput.f2TexCoord1 = kInput.f2TexCoord;
	kOutput.f2TexCoord1b = kInput.f2TexCoord;
	kOutput.f2TexCoord2 = kInput.f2TexCoord;
	
	// Make the world-space to tangent-space matrix
	mtxObjToTangentSpace[0] = mul(kInput.f3Tangent, mtxBoneTransform);
	mtxObjToTangentSpace[1] = mul(kInput.f3Binormal, mtxBoneTransform);
	mtxObjToTangentSpace[2] = mul(kInput.f3Normal, mtxBoneTransform);
	
	// Compute the object-space camera direction
	f4ObjectViewDir = mul( f3CameraPos - mul(f3BoneSpacePos,mtxSkinWorld), mtxWorldInv);
	f4ObjectViewDir = normalize(f4ObjectViewDir);
	
	// Compute the object-space light direction and half-angle for light #1.
	f4ObjectLightDir = mul( f3LightPosition - kOutput.f4Position.xyz, mtxWorldInv);
	f4VertNormLightVec = normalize(f4ObjectLightDir);
	kOutput.f3LightHalfAng.xyz = 0.5 * mul( mtxObjToTangentSpace, ( f4ObjectViewDir + f4VertNormLightVec.xyz ) / 2.0 ) + float3( 0.5, 0.5, 0.5 );
	kOutput.f3LightVec.xyz = 0.5 * mul(mtxObjToTangentSpace, f4VertNormLightVec.xyz ) + float3(0.5, 0.5, 0.5);
		
	return kOutput;
}

//------------------------------------------------------------------------------------------------

LHOUTPUT_11_2x VSLeaderheadNoSkin11_2x( LHINPUT_11_2x kInput, uniform float3 f3LightPosition)
{
	LHOUTPUT_11_2x	kOutput = (LHOUTPUT_11_2x)0;

	// Transform the position, and copy the texture coordinates
	kOutput.f4Position = mul(kInput.f4Position, mtxWorldViewProj );

	float4 f4ObjectLightDir;
	float4 f4VertNormLightVec;
	float4 f4ObjectViewDir;
	float3x3 mtxObjToTangentSpace;

	kOutput.f2TexCoord1 = kInput.f2TexCoord;
	kOutput.f2TexCoord1b = kInput.f2TexCoord;
	kOutput.f2TexCoord2 = kInput.f2TexCoord;
	
	// Make the world-space to tangent-space matrix
	mtxObjToTangentSpace[0] = kInput.f3Tangent;
	mtxObjToTangentSpace[1] = kInput.f3Binormal;
	mtxObjToTangentSpace[2] = kInput.f3Normal;
	
	// Compute the object-space camera direction
	f4ObjectViewDir = mul( f3CameraPos - kInput.f4Position.xyz, mtxWorldInv);
	f4ObjectViewDir = normalize(f4ObjectViewDir);
	
	// Compute the object-space light direction and half-angle for light #1.
	f4ObjectLightDir = mul( f3LightPosition - kInput.f4Position.xyz, mtxWorldInv);
	f4VertNormLightVec = normalize(f4ObjectLightDir);
	kOutput.f3LightHalfAng.xyz = 0.5 * mul( mtxObjToTangentSpace, ( f4ObjectViewDir + f4VertNormLightVec.xyz ) / 2.0 ) + float3( 0.5, 0.5, 0.5 );
	kOutput.f3LightVec.xyz = 0.5 * mul(mtxObjToTangentSpace, f4VertNormLightVec.xyz ) + float3(0.5, 0.5, 0.5);
		
	return kOutput;
}

//------------------------------------------------------------------------------------------------

LHOUTPUT_11_3 VSLeaderhead11_3( LHINPUT_11_3 kInput )
{
	LHOUTPUT_11_3 kOutput = (LHOUTPUT_11_3)(0);
	
	// Transform the position, and copy the texture coordinates
	float4x3 mtxBoneTransform = ComputeBoneTransform( kInput.f4BlendIndices, kInput.f4BlendWeights );
	float3 f3BoneSpacePos = mul(float4(kInput.f4Position), mtxBoneTransform);	
	kOutput.f4Position = mul(float4(f3BoneSpacePos, 1.0), mtxSkinWorldViewProj );	

	float4x4 mtxBoneWorldView = mul( mtxBoneTransform, mtxSkinWorldView);

	kOutput.f2TexCoord1 = kInput.f2TexCoord;
	kOutput.f2TexCoord1b = kInput.f2TexCoord;
	float3 temp = mul(float4(kInput.f3Normal,0.0), mtxBoneWorldView );
	kOutput.f3Normal.x = temp.x / 2.0 + 0.5;
	kOutput.f3Normal.y = -temp.y / 2.0 + 0.5;	
	
	return kOutput;
}

//------------------------------------------------------------------------------------------------

LHOUTPUT_11_3 VSLeaderheadNoSkin11_3( LHINPUT_11_3 kInput )
{
	LHOUTPUT_11_3 kOutput = (LHOUTPUT_11_3)(0);
	
	// Transform the position, and copy the texture coordinates
	kOutput.f4Position = mul(kInput.f4Position, mtxWorldViewProj );

	kOutput.f2TexCoord1 = kInput.f2TexCoord;
	kOutput.f2TexCoord1b = kInput.f2TexCoord;
	float3 temp = mul(float4(kInput.f3Normal,0.0), mtxWorldView );
	kOutput.f3Normal.x = temp.x / 2.0 + 0.5;
	kOutput.f3Normal.y = -temp.y / 2.0 + 0.5;	
	
	return kOutput;
}

//------------------------------------------------------------------------------------------------

// Diffuse pass
float4 PSLeaderhead11_1( LHOUTPUT_11_1 kOutput, uniform float3 f3AmbientColor ) : COLOR
{
	float4 f4BaseColor = tex2D( BaseSampler, kOutput.f2TexCoord1 );
	float3 f3NormalSample = tex2D( NormalSampler, kOutput.f2TexCoord2 );
	float3 f3ExpLightDir1;
	float3 f3ExpLightDir2;
	float3 f3ExpLightDir3;
	float3 f3Diffuse1;
	float3 f3Diffuse2;
	float3 f3Diffuse3;
	
	// Decompress normal sample, and the light direction
	f3NormalSample = ( f3NormalSample - 0.5 ) * 2.0;
	f3ExpLightDir1 = ( kOutput.f3LightVec1 - 0.5 ) * 2.0;
	f3ExpLightDir2 = ( kOutput.f3LightVec2 - 0.5 ) * 2.0;
	f3ExpLightDir3 = ( kOutput.f3LightVec3 - 0.5 ) * 2.0;
	f3Diffuse1 = saturate(dot( f3NormalSample, f3ExpLightDir1 )) * f3DiffuseColor1;
	f3Diffuse2 = saturate(dot( f3NormalSample, f3ExpLightDir2 )) * f3DiffuseColor2;
	f3Diffuse3 = saturate(dot( f3NormalSample, f3ExpLightDir3 )) * f3DiffuseColor3;
	
	// Diffuse lighting = (N.L) * Cs
	float3 f3DiffuseTotal = f4BaseColor * (saturate(f3Diffuse1 + f3Diffuse2 + f3Diffuse3) + f3AmbientColor);
	
	// Final summation
	return float4( f3DiffuseTotal, f4BaseColor.a );
}


// Specular pass (#1/#2/#3)
float4 PSLeaderhead11_2x( LHOUTPUT_11_2x kOutput, uniform float4 f4SpecularColor ) : COLOR
{
	float3 f3NormalSample = tex2D( NormalSampler, kOutput.f2TexCoord1 );
	float3 f3SpecularMask = tex2D( SpecularMaskSampler, kOutput.f2TexCoord2 );
	float4 f4BaseColor = tex2D( BaseSampler, kOutput.f2TexCoord1b );
	float3 f3ExpHalfAng;
	f3NormalSample = ( f3NormalSample - 0.5 ) * 2.0;
	
	// Decompress normal sample, and the light direction
	f3ExpHalfAng = ( kOutput.f3LightVec - 0.5 ) * 2.0;
	float fNdH = dot( f3NormalSample.xyz, f3ExpHalfAng );
	fNdH = fNdH * fNdH * fNdH * fNdH * fNdH * fNdH * fNdH * fNdH * fNdH;
	float3 f3Specular = saturate(fNdH * f4SpecularColor.xyz);
	
	// Final summation
	return float4( f3SpecularMask * f3Specular, f4BaseColor.a );
}

//------------------------------------------------------------------------------------------------

// Environmentmap (#4)
float4 PSLeaderhead11_3( LHOUTPUT_11_3 kOutput ) : COLOR
{
	float3 f3EnvironmentMask = tex2D( EnvironmentMaskSampler, kOutput.f2TexCoord1 );
	float3 f3EnvironmentMap = tex2D( EnvironmentMapSampler, float2( kOutput.f3Normal.x, kOutput.f3Normal.y ) );	
	float4 f4BaseColor = tex2D( BaseSampler, kOutput.f2TexCoord1b );
	float3 f3EnvMap = f3EnvironmentMap * f3EnvironmentMask;
	return float4(f3EnvMap, f4BaseColor.a);
}

//------------------------------------------------------------------------------------------------
//                          TECHNIQUES
//------------------------------------------------------------------------------------------------

technique TLeaderheadShader_20
< 
	string shadername= "TLeaderheadShader_20"; 
	int implementation=0;
	string NBTMethod = "NDL";	// required for MAX to export the NBT information
	int BonesPerPartition = LEADER_MAX_BONES;
>	
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;
        
        // Disable alpha blending & testing - everything is opaque
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = FALSE;
        SrcBlend		 = SRCALPHA;
        DestBlend		 = INVSRCALPHA;
        
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TexCoordIndex[3] = 3;
        TexCoordIndex[4] = 4;

        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
        TextureTransformFlags[2] = 0;
        TextureTransformFlags[3] = 0;
        TextureTransformFlags[4] = 0;

		// Compile!
		VertexShader = compile vs_2_0 VSLeaderhead20( );
		PixelShader = compile ps_2_0 PSLeaderhead20( );
   	}
}

//------------------------------------------------------------------------------------------------

technique TLeaderheadShaderNoSkin_20
< 
	string shadername= "TLeaderheadShaderNoSkin_20"; 
	string NBTMethod = "NDL";	// required for MAX to export the NBT information
	int implementation=0;
>	
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;
        
        // Disable alpha blending & testing - everything is opaque
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = FALSE;
		SrcBlend		 = SRCALPHA;
        DestBlend		 = INVSRCALPHA;
        
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TexCoordIndex[3] = 3;
        TexCoordIndex[4] = 4;

        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
        TextureTransformFlags[2] = 0;
        TextureTransformFlags[3] = 0;
        TextureTransformFlags[4] = 0;

		// Compile!
		VertexShader = compile vs_2_0 VSLeaderheadNoSkin20( );
		PixelShader = compile ps_2_0 PSLeaderhead20( );
   	}
}

//------------------------------------------------------------------------------------------------

technique TLeaderheadShader_11
<
	string shadername= "TLeaderheadShader_20"; 
	int implementation=1;
	string NBTMethod = "NDL";
	int BonesPerPartition = LEADER_MAX_BONES;
>
{
	
	pass DiffuseLighting
	{
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;
        
        // Disable alpha blending & testing - everything is opaque
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = FALSE;
        SrcBlend		 = SRCALPHA;
        DestBlend		 = INVSRCALPHA;
        
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TexCoordIndex[3] = 3;

        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
        TextureTransformFlags[2] = 0;
        TextureTransformFlags[3] = 0;

		// Compile!
		VertexShader = compile vs_1_1 VSLeaderhead11_1( );
		PixelShader = compile ps_1_1 PSLeaderhead11_1( f3Ambient );
	}
	
	pass SpecularLighting_1
	{
        // Enable alpha blending - but leave test disabled
        AlphaBlendEnable = TRUE;
        SrcBlend		 = ONE;
        DestBlend		 = ONE;
        AlphaTestEnable	 = FALSE;
        
		// Compile!
		VertexShader = compile vs_1_1 VSLeaderhead11_2x( f3LightPos1 );
		PixelShader = compile ps_1_1 PSLeaderhead11_2x( f4SpecularColor1 );
	}

	pass SpecularLighting_2
	{
		// Compile!
		VertexShader = compile vs_1_1 VSLeaderhead11_2x( f3LightPos2 );
		PixelShader = compile ps_1_1 PSLeaderhead11_2x( f4SpecularColor2 );
	}

	pass SpecularLighting_3
	{
		// Compile!
		VertexShader = compile vs_1_1 VSLeaderhead11_2x( f3LightPos3 );
		PixelShader = compile ps_1_1 PSLeaderhead11_2x( f4SpecularColor3 );
	}
	
	pass EnvironmentMap
	{
		// Compile!
		VertexShader = compile vs_1_1 VSLeaderhead11_3( );
		PixelShader = compile ps_1_1 PSLeaderhead11_3( );
	}	
}

//------------------------------------------------------------------------------------------------

technique TLeaderheadShaderNoSkin_11
<
	string shadername= "TLeaderheadShaderNoSkin_20"; 
	string NBTMethod = "NDL";
	int implementation=1;
>
{
	pass DiffuseLighting
	{
        // Enable depth writing
        ZEnable        = TRUE;
        ZWriteEnable   = TRUE;
        ZFunc          = LESSEQUAL;
        
        // Disable alpha blending & testing - everything is opaque
        AlphaBlendEnable = TRUE;
        AlphaTestEnable	 = FALSE;
        SrcBlend		 = SRCALPHA;
        DestBlend		 = INVSRCALPHA;
        
   		// Allow the use of multiple texcoord indices
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TexCoordIndex[3] = 3;
        TexCoordIndex[4] = 4;

        TextureTransformFlags[0] = 0;
        TextureTransformFlags[1] = 0;
        TextureTransformFlags[2] = 0;
        TextureTransformFlags[3] = 0;
        TextureTransformFlags[4] = 0;

		// Compile!
		VertexShader = compile vs_1_1 VSLeaderheadNoSkin11_1( );
		PixelShader = compile ps_1_1 PSLeaderhead11_1( f3Ambient );
	}
	
	pass SpecularLighting_1
	{
        // Enable alpha blending - but leave test disabled
        AlphaBlendEnable = TRUE;
        SrcBlend		 = ONE;
        DestBlend		 = ONE;
        AlphaTestEnable	 = FALSE;
        
		// Compile!
		VertexShader = compile vs_1_1 VSLeaderheadNoSkin11_2x( f3LightPos1 );
		PixelShader = compile ps_1_1 PSLeaderhead11_2x( f4SpecularColor1 );
	}

	pass SpecularLighting_2
	{
		// Compile!
		VertexShader = compile vs_1_1 VSLeaderheadNoSkin11_2x( f3LightPos2 );
		PixelShader = compile ps_1_1 PSLeaderhead11_2x( f4SpecularColor2 );
	}

	pass SpecularLighting_3
	{
		// Compile!
		VertexShader = compile vs_1_1 VSLeaderheadNoSkin11_2x( f3LightPos3 );
		PixelShader = compile ps_1_1 PSLeaderhead11_2x( f4SpecularColor3 );
	}
	
	pass EnvironmentMap
	{
        // Change the blending
        AlphaBlendEnable = TRUE;
        SrcBlend		 = DESTCOLOR;
        DestBlend		 = ONE;
        AlphaTestEnable	 = FALSE;
	
		// Compile!
		VertexShader = compile vs_1_1 VSLeaderheadNoSkin11_3( );
		PixelShader = compile ps_1_1 PSLeaderhead11_3( );
	}	
}

technique TLeaderheadAlphaDecal
<
	string shadername = "TLeaderheadAlphaDecal";
	bool UsesNiRenderState = true;
	int implementation=0;
>
{
  	pass P0
	{
		VertexShader = compile vs_1_1 VSLeaderheadAlphaDecal11();
		PixelShader = compile ps_1_1 PSLeaderheadAlphaDecal11();
	}
}

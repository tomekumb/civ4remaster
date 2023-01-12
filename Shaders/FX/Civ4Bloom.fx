//  $Header: $
//------------------------------------------------------------------------------------------------
//
//  ***************** CIV4 GAME ENGINE   ********************
//
//! \file		Civ4Bloom.fx
//! \author		Bart Muzzin -- 04-28-2005
//! \brief		Blooming postprocess effect
//
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2005 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------
// VARIABLES
//------------------------------------------------------------------------------------------------  

static const float fTexelSize = (2.0/256.0);
float3 g_f3BloomMin : GLOBAL = { 0.65, 0.65, 0.65 };
float3 g_f3BloomFactors : GLOBAL = { 0.0, 0.7, 3.16 };		// 1st component = don't do anything anymore
																// 2nd component = The luminosity scaling range minimum value
																// 3rd component = The inverse of the luminosity remapping range
float3 g_f3BloomColorChannelMix : GLOBAL = { 1.8, 1.8, 2.0 };	// The amount of each component of the bloom included in the final image

//------------------------------------------------------------------------------------------------  

float4x4	mtxWorldViewProj	: WORLDVIEWPROJECTION;

//------------------------------------------------------------------------------------------------  
// Kernel size = 4

static const float g_afBlurFactorKS4[4] = 
{
	0.1,
	0.4,
	0.4,
	0.1
};

static const float2 g_afOffsetXKS4[4] =
{
	{ -1.5 * fTexelSize, 0 },
	{ -0.2 * fTexelSize, 0 },
	{  0.2 * fTexelSize, 0 },
	{  1.5 * fTexelSize, 0 }
};

static const float2 g_afOffsetYKS4[4] =
{
	{ 0, -1.5 * fTexelSize },
	{ 0, -0.2 * fTexelSize },
	{ 0,  0.2 * fTexelSize },
	{ 0,  1.5 * fTexelSize }
};

//------------------------------------------------------------------------------------------------  
// Kernel size = 9

static const float g_afBlurFactorKS9[9] = 
{
	0.054670025,
	0.080656908,
	0.106482669,
	0.125794409,
	0.13298076,
	0.125794409,
	0.106482669,
	0.080656908,
	0.054670025
};

static const float2 g_afOffsetXKS9[9] =
{
	{ -4.0 * fTexelSize, 0 },
	{ -3.0 * fTexelSize, 0 },
	{ -2.0 * fTexelSize, 0 },
	{ -1.0 * fTexelSize, 0 },
	{  0.0 * fTexelSize, 0 },
	{  1.0 * fTexelSize, 0 },
	{  2.0 * fTexelSize, 0 },
	{  3.0 * fTexelSize, 0 },
	{  4.0 * fTexelSize, 0 }
};

static const float2 g_afOffsetYKS9[9] =
{
	{ 0, -4.0 * fTexelSize },
	{ 0, -3.0 * fTexelSize },
	{ 0, -2.0 * fTexelSize },
	{ 0, -1.0 * fTexelSize },
	{ 0,  0.0 * fTexelSize },
	{ 0,  1.0 * fTexelSize },
	{ 0,  2.0 * fTexelSize },
	{ 0,  3.0 * fTexelSize },
	{ 0,  4.0 * fTexelSize }
};

//------------------------------------------------------------------------------------------------  
// Kernel size = 13

static const float g_afBlurFactorKS13[13] = 
{
	0.017996989,
	0.033159046,
	0.054670025,
	0.080656908,
	0.106482669,
	0.125794409,
	0.13298076,
	0.125794409,
	0.106482669,
	0.080656908,
	0.054670025,
	0.033159046,
	0.017996989
};

static const float2 g_afOffsetXKS13[13] =
{
	{ -6.0 * fTexelSize, 0 },
	{ -5.0 * fTexelSize, 0 },
	{ -4.0 * fTexelSize, 0 },
	{ -3.0 * fTexelSize, 0 },
	{ -2.0 * fTexelSize, 0 },
	{ -1.0 * fTexelSize, 0 },
	{  0.0 * fTexelSize, 0 },
	{  1.0 * fTexelSize, 0 },
	{  2.0 * fTexelSize, 0 },
	{  3.0 * fTexelSize, 0 },
	{  4.0 * fTexelSize, 0 },
	{  5.0 * fTexelSize, 0 },
	{  6.0 * fTexelSize, 0 }
};

static const float2 g_afOffsetYKS13[13] =
{
	{ 0, -6.0 * fTexelSize },
	{ 0, -5.0 * fTexelSize },
	{ 0, -4.0 * fTexelSize },
	{ 0, -3.0 * fTexelSize },
	{ 0, -2.0 * fTexelSize },
	{ 0, -1.0 * fTexelSize },
	{ 0,  0.0 * fTexelSize },
	{ 0,  1.0 * fTexelSize },
	{ 0,  2.0 * fTexelSize },
	{ 0,  3.0 * fTexelSize },
	{ 0,  4.0 * fTexelSize },
	{ 0,  5.0 * fTexelSize },
	{ 0,  6.0 * fTexelSize }
};


//------------------------------------------------------------------------------------------------
// TEXTURES
//------------------------------------------------------------------------------------------------  
texture BaseTexture< string NTM = "base";>;
texture BlurHighPassTexture< string NTM = "detail";>;

//------------------------------------------------------------------------------------------------
// SAMPLERS
//------------------------------------------------------------------------------------------------  
sampler BaseSampler = sampler_state
{
    Texture = (BaseTexture);
    AddressU  = CLAMP;
    AddressV  = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;
};

sampler HighPassTexture = sampler_state
{
    Texture = (BlurHighPassTexture);
    AddressU  = CLAMP;
    AddressV  = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;
};

//------------------------------------------------------------------------------------------------
// STRUCTURES
//------------------------------------------------------------------------------------------------  
struct BLOOMINPUT
{
	float4 f4Position : POSITION;
	float2 f2TexCoords : TEXCOORD0;
};

struct BLOOMOUTPUT_11
{
	float4 f4Position : POSITION;
	float2 f2TexCoords1 : TEXCOORD0;
	float2 f2TexCoords2 : TEXCOORD1;
	float2 f2TexCoords3 : TEXCOORD2;
	float2 f2TexCoords4 : TEXCOORD3;
};

struct BLOOMOUTPUT
{
	float4 f4Position : POSITION;
	float2 f2TexCoords : TEXCOORD0;
};

struct RECOMBINEINPUT
{
	float4 f4Position : POSITION;
	float2 f2TexCoords : TEXCOORD0;
};

struct RECOMBINEOUTPUT
{
	float4 f4Position : POSITION;
	float2 f2TexCoords1 : TEXCOORD0;
	float2 f2TexCoords2 : TEXCOORD1;
};

//------------------------------------------------------------------------------------------------
// SHADERS
//------------------------------------------------------------------------------------------------

float4 PSHighPass( BLOOMOUTPUT kOutput ) : COLOR0
{
	float3 f3Color = tex2D( BaseSampler, kOutput.f2TexCoords );
	f3Color = f3Color * ( f3Color - g_f3BloomFactors.yyy ) * g_f3BloomFactors.z;
	
	return float4( saturate(f3Color), 1.0 );
}

float4 PSBlurH_KS9( BLOOMOUTPUT kOutput ) : COLOR0
{
	float3 f3Color = 0;
	for ( int i = 0; i < 9; i++ )
	{
		f3Color += tex2D( BaseSampler, kOutput.f2TexCoords + g_afOffsetXKS9[i] ) * g_afBlurFactorKS9[i];
	}
	return float4( f3Color, 1.0 );
}

float4 PSBlurVRecombine_KS9( BLOOMOUTPUT kOutput ) : COLOR0
{
	float3 f3Color = 0;
	for ( int i = 0; i < 9; i++ )
	{
		f3Color += tex2D( HighPassTexture, kOutput.f2TexCoords + g_afOffsetYKS9[i] ) * g_afBlurFactorKS9[i];
	}	
	float3 f3BaseColor = tex2D( BaseSampler, kOutput.f2TexCoords );
	float fLuminosity = (f3Color.r + f3Color.g + f3Color.b) /3.0;
	//return float4( f3BaseColor + fLuminosity * (f3Color * g_f3BloomFactors.x), 1.0 );
	return float4( f3Color, 1.0 );
}

float4 PSBlurH_KS13( BLOOMOUTPUT kOutput ) : COLOR0
{
	float3 f3Color = 0;
	for ( int i = 0; i < 13; i++ )
	{
		f3Color += tex2D( BaseSampler, kOutput.f2TexCoords + g_afOffsetXKS13[i] ) * g_afBlurFactorKS13[i];
	}
	return float4( f3Color, 1.0 );
}

float4 PSBlurVRecombine_KS13( BLOOMOUTPUT kOutput ) : COLOR0
{
	float3 f3Color = 0;
	for ( int i = 0; i < 13; i++ )
	{
		f3Color += tex2D( HighPassTexture, kOutput.f2TexCoords + g_afOffsetYKS13[i] ) * g_afBlurFactorKS13[i];
	}	
	float3 f3BaseColor = tex2D( BaseSampler, kOutput.f2TexCoords );
	float fLuminosity = (f3Color.r + f3Color.g + f3Color.b) /3.0;
	return float4( f3BaseColor + fLuminosity * (f3Color * g_f3BloomColorChannelMix), 1.0 );
	//return float4( f3Color, 1.0 );
}

//------------------------------------------------------------------------------------------------
// pixel shader 1.1
float4 PSBlurH_11( BLOOMOUTPUT_11 kOutput ) : COLOR0
{
	float3 f3Color = 0;
	f3Color += tex2D( BaseSampler, kOutput.f2TexCoords1 ) * g_afBlurFactorKS4[0];
	f3Color += tex2D( BaseSampler, kOutput.f2TexCoords2 ) * g_afBlurFactorKS4[1];
	f3Color += tex2D( BaseSampler, kOutput.f2TexCoords3 ) * g_afBlurFactorKS4[2];
	f3Color += tex2D( BaseSampler, kOutput.f2TexCoords4 ) * g_afBlurFactorKS4[3];
	return float4( f3Color, 1.0 );
}

float4 PSBlurVHighPass_11( BLOOMOUTPUT_11 kOutput ) : COLOR0
{
	float3 f3Color = 0;

	f3Color += tex2D( BaseSampler, kOutput.f2TexCoords1 ) * g_afBlurFactorKS4[0];
	f3Color += tex2D( BaseSampler, kOutput.f2TexCoords2 ) * g_afBlurFactorKS4[1];
	f3Color += tex2D( BaseSampler, kOutput.f2TexCoords3 ) * g_afBlurFactorKS4[2];
	f3Color += tex2D( BaseSampler, kOutput.f2TexCoords4 ) * g_afBlurFactorKS4[3];
	
	f3Color = saturate( f3Color-g_f3BloomMin );

	return float4( f3Color, 1.0 );
}

float4 PSRecombine( RECOMBINEOUTPUT kOutput ) : COLOR0
{
	float3 f3BaseColor = tex2D( BaseSampler, kOutput.f2TexCoords1 );
	float3 f3BloomColor = tex2D( HighPassTexture, kOutput.f2TexCoords2 ) * g_f3BloomFactors.x;
	
	float fLuminosity = (f3BloomColor.r + f3BloomColor.g + f3BloomColor.b)/3.0;
	return float4( f3BaseColor + fLuminosity * f3BloomColor, 1.0 );
}

// These vertex shaders are included so the same implementation can be used for 1.1 -> 2.0
RECOMBINEOUTPUT VSRecombine( RECOMBINEINPUT kInput )
{
	RECOMBINEOUTPUT kOutput = (RECOMBINEOUTPUT)0;
	
	kOutput.f4Position = mul(float4(kInput.f4Position), mtxWorldViewProj);	
	kOutput.f2TexCoords1 = kInput.f2TexCoords;
	kOutput.f2TexCoords2 = kInput.f2TexCoords;
	
	return kOutput;
}

BLOOMOUTPUT_11 VSBlurPassX_11( BLOOMINPUT kInput )
{
	BLOOMOUTPUT_11 kOutput = (BLOOMOUTPUT_11)0;
	
	kOutput.f4Position = mul(float4(kInput.f4Position), mtxWorldViewProj);	
	kOutput.f2TexCoords1 = kInput.f2TexCoords + g_afOffsetXKS4[0];
	kOutput.f2TexCoords2 = kInput.f2TexCoords + g_afOffsetXKS4[1];
	kOutput.f2TexCoords3 = kInput.f2TexCoords + g_afOffsetXKS4[2];
	kOutput.f2TexCoords4 = kInput.f2TexCoords + g_afOffsetXKS4[3];
	return kOutput;
}

BLOOMOUTPUT_11 VSBlurPassY_11( BLOOMINPUT kInput )
{
	BLOOMOUTPUT_11 kOutput = (BLOOMOUTPUT_11)0;
	
	kOutput.f4Position = mul(float4(kInput.f4Position), mtxWorldViewProj);	
	kOutput.f2TexCoords1 = kInput.f2TexCoords + g_afOffsetYKS4[0];
	kOutput.f2TexCoords2 = kInput.f2TexCoords + g_afOffsetYKS4[1];
	kOutput.f2TexCoords3 = kInput.f2TexCoords + g_afOffsetYKS4[2];
	kOutput.f2TexCoords4 = kInput.f2TexCoords + g_afOffsetYKS4[3];
	return kOutput;
}

//------------------------------------------------------------------------------------------------
// TECHNIQUES
//------------------------------------------------------------------------------------------------

technique TBloom_T1
{
	pass HighPass
	{
        // Disable depth writing (just writing a quad)
        ZEnable        = FALSE;
        ZWriteEnable   = FALSE;

        // Disable alpha blending & testing - everything is opaque
        AlphaBlendEnable = FALSE;
        AlphaTestEnable	 = FALSE;

        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TexCoordIndex[3] = 3;
        TexCoordIndex[4] = 4;
        TexCoordIndex[5] = 5;
        TexCoordIndex[6] = 6;
        TexCoordIndex[7] = 7;
        
		PixelShader = compile ps_2_0 PSHighPass( );
		VertexShader = NULL;
	}
}

technique TBloom_T2
{
	pass BlurH
	{
        // Disable depth writing (just writing a quad)
        ZEnable        = FALSE;
        ZWriteEnable   = FALSE;

        // Disable alpha blending & testing - everything is opaque
        AlphaBlendEnable = FALSE;
        AlphaTestEnable	 = FALSE;

        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TexCoordIndex[3] = 3;
        TexCoordIndex[4] = 4;
        TexCoordIndex[5] = 5;
        TexCoordIndex[6] = 6;
        TexCoordIndex[7] = 7;
	
		PixelShader = compile ps_2_0 PSBlurH_KS13( );
		VertexShader = NULL;
	}
}

technique TBloom_T3
{
	pass BlurH
	{
        // Disable depth writing (just writing a quad)
        ZEnable        = FALSE;
        ZWriteEnable   = FALSE;

        // Disable alpha blending & testing - everything is opaque
        AlphaBlendEnable = FALSE;
        AlphaTestEnable	 = FALSE;

        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TexCoordIndex[3] = 3;
        TexCoordIndex[4] = 4;
        TexCoordIndex[5] = 5;
        TexCoordIndex[6] = 6;
        TexCoordIndex[7] = 7;
	
		PixelShader = compile ps_2_0 PSBlurVRecombine_KS13( );
		VertexShader = NULL;
	}
}

//------------------------------------------------------------------------------------------------

technique TBloom_T1_11
{
	pass BlurH
	{
        // Disable depth writing (just writing a quad)
        ZEnable        = FALSE;
        ZWriteEnable   = FALSE;

        // Disable alpha blending & testing - everything is opaque
        AlphaBlendEnable = FALSE;
        AlphaTestEnable	 = FALSE;

        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TexCoordIndex[3] = 3;
        TexCoordIndex[4] = 4;
        TexCoordIndex[5] = 5;
        TexCoordIndex[6] = 6;
        TexCoordIndex[7] = 7;
        
		PixelShader = compile ps_1_1 PSBlurH_11( );
		VertexShader = compile vs_1_1 VSBlurPassX_11( );
	}
}

technique TBloom_T2_11
{
	pass BlurVHighPass
	{
        // Disable depth writing (just writing a quad)
        ZEnable        = FALSE;
        ZWriteEnable   = FALSE;

        // Disable alpha blending & testing - everything is opaque
        AlphaBlendEnable = FALSE;
        AlphaTestEnable	 = FALSE;

        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TexCoordIndex[3] = 3;
        TexCoordIndex[4] = 4;
        TexCoordIndex[5] = 5;
        TexCoordIndex[6] = 6;
        TexCoordIndex[7] = 7;
	
		PixelShader = compile ps_1_1 PSBlurVHighPass_11( );
		VertexShader = compile vs_1_1 VSBlurPassY_11( );
	}
}

technique TBloom_T3_11
{
	pass Recombine
	{
        // Disable depth writing (just writing a quad)
        ZEnable        = FALSE;
        ZWriteEnable   = FALSE;

        // Disable alpha blending & testing - everything is opaque
        AlphaBlendEnable = FALSE;
        AlphaTestEnable	 = FALSE;

        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
        TexCoordIndex[3] = 3;
        TexCoordIndex[4] = 4;
        TexCoordIndex[5] = 5;
        TexCoordIndex[6] = 6;
        TexCoordIndex[7] = 7;
	
		PixelShader = compile ps_1_1 PSRecombine( );
		VertexShader = compile vs_1_1 VSRecombine( );
	}
}

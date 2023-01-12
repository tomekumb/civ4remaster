///------------------------------------------------------------------------------------------------
//  $Header: $
//------------------------------------------------------------------------------------------------
//  *****************   FIRAXIS GAME ENGINE   ********************
//
//  FILE:    Terrain Tile Splat Shader
//
//  AUTHOR:  Tom Whittaker - 02/09
//
//  PURPOSE: Splat Tile Terrain Shader - Base Texute + LM FOW 
//			 todotw: right now supports one base texture. Similar to aggregate
//
//  Listing: fxc /Tvs_1_1 /ETerrainVS /FcTerrainVS.lst Terrain.fx
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2003 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------

// Transformations
float4x4	mtxWorldViewProj	: WORLDVIEWPROJECTION;
float4x4    mtxWorld   : WORLD;
float4x4	mtxFOW     : GLOBAL;
float4x4    mtxLightmap: GLOBAL;
float		fDetailTexScaling:GLOBAL = 2.0f;
int			iTrilinearTextureIndex : GLOBAL = 0;
int			iMipStatus : GLOBAL = 2; //LINEAR
float 		fFrameTime : GLOBAL;

//------------------------------------------------------------------------------------------------
// VERTEX OUTPUT FORMATS
//------------------------------------------------------------------------------------------------ 
struct VS_INPUT
{
	float3 f3Position   : POSITION;
	float2 f2BaseTex    : TEXCOORD0;	// base 
	float2 fDetailTex   : TEXCOORD1;	// decal 
};

struct VS_OUTPUT_11
{
	float4	f4Position		: POSITION;

    float2	f2BaseTex		: TEXCOORD0;	// Base 
    float2	f2FOWTex		: TEXCOORD1;	// FOW 
	float2	f2LightMapTex	: TEXCOORD2;	// Lightmap 
	float2  f2Detail		: TEXCOORD3;    // terrain decal map
};


struct VS_OUTPUT_14
{
	float4	f4Position		: POSITION;
    float2	f2BaseTex		: TEXCOORD0;	// Base 
    float2	f2FOWTex		: TEXCOORD1;	// FOW 
	float2	f2LightMapTex	: TEXCOORD2;	// Lightmap 
	float2  f2Detail		: TEXCOORD3;    // terrain decal map
};

//------------------------------------------------------------------------------------------------
//                          VERTEX SHADER
//------------------------------------------------------------------------------------------------

VS_OUTPUT_11 VSTerrain_Tile_11( VS_INPUT vIn )
{
	VS_OUTPUT_11 vOut = (VS_OUTPUT_11)0;			
	
	//Transform position
	vOut.f4Position  = mul(float4(vIn.f3Position, 1), mtxWorldViewProj);	
    float3 worldPos = mul(float4(vIn.f3Position, 1), (float4x3)mtxWorld);			//todotw: if we're only going to need this for Fog combine the 2 and remove the transform

	// Copy over the texture coordinates
	vOut.f2BaseTex     = vIn.f2BaseTex;
	vOut.f2FOWTex      = mul(float4(worldPos,1),mtxFOW);				// fog of war
	vOut.f2LightMapTex = mul(float4(worldPos,1),mtxLightmap);			// Lightmap 
	vOut.f2Detail      = vIn.fDetailTex * fDetailTexScaling;	// Detail 
	
	return vOut;
}

VS_OUTPUT_14 VSTerrain_Tile_14( VS_INPUT vIn )
{
	VS_OUTPUT_14 vOut = (VS_OUTPUT_14)0;			
	
	//Transform position
	vOut.f4Position  = mul(float4(vIn.f3Position, 1), mtxWorldViewProj);	
    float3 P = mul(float4(vIn.f3Position, 1), (float4x3)mtxWorld);			//todotw: if we're only going to need this for Fog combine the 2 and remove the transform
	
	// Copy over the texture coordinates
	vOut.f2BaseTex     = vIn.f2BaseTex;
	vOut.f2FOWTex      = mul(float4(P,1),mtxFOW);				// fog of war
	vOut.f2LightMapTex = mul(float4(P,1),mtxLightmap);			// Lightmap 
	vOut.f2Detail      = vIn.fDetailTex * fDetailTexScaling;	// Detail 
		
	return vOut;
}

//------------------------------------------------------------------------------------------------
//                          PIXEL SHADER
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// TEXTURES
//------------------------------------------------------------------------------------------------  
texture TerrainBaseTexture0	   <string NTM = "shader";  int NTMIndex = 0;>;
texture TerrainDetailTexture   <string NTM = "shader";  int NTMIndex = 1;>;
texture TerrainLightmapTexture <string NTM = "shader";  int NTMIndex = 2;>;
texture TerrainFOWarTexture    <string NTM = "shader";  int NTMIndex = 3;>;
texture TerrainPlotFogTexture  <string NTM = "shader";  int NTMIndex = 4;>;

//------------------------------------------------------------------------------------------------
// SAMPLERS
//------------------------------------------------------------------------------------------------											//NONE!
sampler TerrainBase : register(s0) = sampler_state  { Texture = (TerrainBaseTexture0);  AddressU = Clamp; AddressV = Clamp; MagFilter = Linear; MipFilter = Linear; MinFilter = Linear; };
sampler TerrainBaseNoMips : register(s0) = sampler_state  { Texture = (TerrainBaseTexture0);  AddressU = Clamp; AddressV = Clamp; MagFilter = Linear; MipFilter = None; MinFilter = Linear; };
sampler TerrainFOWar = sampler_state  { Texture = (TerrainFOWarTexture);  AddressU = Wrap; AddressV = Wrap; MagFilter = Linear; MipFilter = Linear; MinFilter = Linear; };
sampler TerrainLightmap= sampler_state{ Texture = (TerrainLightmapTexture); AddressU = Clamp; AddressV = Clamp; MagFilter = Linear; MipFilter = Linear; MinFilter = Linear; };
sampler TerrainDetail = sampler_state { Texture = (TerrainDetailTexture  );  AddressU = Wrap; AddressV = Wrap; MagFilter = Linear; MipFilter = Linear; MinFilter = Linear; };
sampler TerrainPlotFog = sampler_state  { Texture = (TerrainPlotFogTexture);  AddressU = Clamp; AddressV = Clamp; MagFilter = Point; MipFilter = None; MinFilter = Point; };
sampler TerrainClouds = sampler_state { Texture = (TerrainDetailTexture  );  AddressU = Wrap; AddressV = Wrap; MagFilter = Linear; MipFilter = Linear; MinFilter = Linear; };

//------------------------------------------------------------------------------------------------ 
//      PSTerrain_Blender - Blends a 4 Base and an 3 Alpha textures 
//------------------------------------------------------------------------------------------------ 
float4 PSTerrain_SPLATTILE_LMFW_11 ( VS_OUTPUT_11 Input, uniform sampler TerrainBaseSampler, uniform bool bAlphaShader ) : COLOR 
{ 
        // Read all our base textures, the grid and FOW texture 
        float4 f4BaseTex = tex2D( TerrainBaseSampler,  Input.f2BaseTex  ); 
        float3 f3FOWTex   = tex2D( TerrainFOWar, Input.f2FOWTex ); 
        float3 f3Lightmap  = tex2D( TerrainLightmap, Input.f2LightMapTex); 
        float3 f3DetailTex = tex2D( TerrainDetail, Input.f2Detail); 

        // FinalColor = Base * Detail * Lightmap * Decal(A) * FOW       
        float4  f4FinalColor = 0.0f; 
        f4FinalColor = f4BaseTex; 
        f4FinalColor.rgb = (f4FinalColor.rgb* f3FOWTex.rgb + (f3Lightmap.rgb - 0.5f )* f3FOWTex.rgb) ;  // blend in detail map
        
        if(bAlphaShader)
			f4FinalColor.a = lerp(1, f4FinalColor.a, f3FOWTex.r);
        
        //f4FinalColor = tex2D( TerrainBase0,  Input.f2BaseTex  ); 
//      f4FinalColor.rgb += (f4DetailTex.rgb - 0.5f);   // blend in detail map 
//      f4FinalColor.rgb += (f4Lightmap.rgb - 0.5f);            // modulate by the diffuse,ambient, shadow term(no specular)
//      f4FinalColor.rgb *= f4FOWTex.rgb;               //FOW textures 

        return f4FinalColor; 
} 

float4 PSTerrain_SPLATTILE_LMFW_14 ( VS_OUTPUT_14 Input, uniform sampler TerrainBaseSampler, uniform bool bAlphaShader ) : COLOR
{
	// Read all our base textures, the grid and FOW texture
	float4 f4BaseTex = tex2D( TerrainBaseSampler,  Input.f2BaseTex  );
	float3 f3FOWTex   = tex2D( TerrainFOWar, Input.f2FOWTex );
	float3 f3Lightmap  = tex2D( TerrainLightmap, Input.f2LightMapTex);
	float3 f3DetailTex = tex2D( TerrainDetail, Input.f2Detail);

	// FinalColor = Base * Detail * Lightmap * Decal(A) * FOW	
	float4	f4FinalColor;// = 0.0f;

	// 7 instructions - no detail
	f4FinalColor = f4BaseTex;
	f4FinalColor.rgb = f4FinalColor.rgb + (f3Lightmap.rgb - 0.5f);	// modulate by the diffuse,ambient, shadow term(no specular)
	f4FinalColor.rgb *= f3FOWTex.rgb;				//FOW textures
	
	if(bAlphaShader)
		f4FinalColor.a = lerp(1, f4FinalColor.a, f3FOWTex.r);

	return f4FinalColor;
}

float4 PSTerrain_SPLATTILE_LMFW_20 ( VS_OUTPUT_14 Input, uniform sampler TerrainBaseSampler, uniform bool bAlphaShader ) : COLOR
{
	// Read all our base textures, the grid and FOW texture
	float4 f4BaseTex = tex2D( TerrainBaseSampler,  Input.f2BaseTex  );
	float3 f3FOWTex   = tex2D( TerrainFOWar, Input.f2FOWTex );
	float3 f3Lightmap  = tex2D( TerrainLightmap, Input.f2LightMapTex);
	float3 f3DetailTex = tex2D( TerrainDetail, Input.f2Detail);

	// FinalColor = Base * Detail * Lightmap * Decal(A) * FOW	
	float4	f4FinalColor;// = 0.0f;

	// 7 instructions - no detail
	f4FinalColor = f4BaseTex;
	//f4FinalColor.rgb = (f4FinalColor.rgb* f3FOWTex.rgb + (f3Lightmap.rgb - 0.5f )* f3FOWTex.rgb) ;	// blend in detail map
	//f4FinalColor.rgb = (f4FinalColor.rgb* f3FOWTex.rgb + (f3DetailTex.rgb - 0.5f )* f3FOWTex.rgb) ;	// blend in detail map

	//This won't work because of the HLSL compiler
	f4FinalColor.rgb = f4FinalColor.rgb + (f3DetailTex.rgb - 0.5f);	// blend in detail map
	f4FinalColor.rgb = f4FinalColor.rgb + (f3Lightmap.rgb - 0.5f);	// modulate by the diffuse,ambient, shadow term(no specular)
	//f4FinalColor.rgb *= f3FOWTex.rgb;				//FOW textures
	
	float4 f4CloudColor = 1.0f;
	float fCloudSpeed = fFrameTime * 0.01f;

	float2 cloudUV = float2(Input.f2BaseTex.x, Input.f2BaseTex.y);
	float2 cloudOffset = float2(fCloudSpeed, fCloudSpeed);

	float2 scroll = cloudUV + cloudOffset;
	float3 res = tex2D(TerrainClouds, frac(scroll));

	f4CloudColor.r = res.r;
	f4CloudColor.g = res.g;
	f4CloudColor.b = res.b;
	f4CloudColor.rgb *= 1.6f;

	if (f3FOWTex.r <= 0.1f) {
		f4FinalColor = f4CloudColor;
	} else if (f3FOWTex.r < 0.4f) {
		f4FinalColor = lerp(f4CloudColor, f4FinalColor, f3FOWTex.r);
	}
	else {
		f4FinalColor.rgb *= f3FOWTex.rgb;
	}
	
	if(bAlphaShader)
		f4FinalColor.a = lerp(1, f4FinalColor.a, f3FOWTex.r);
	
	// Return the result	
	return f4FinalColor;
}
//------------------------------------------------------------------------------------------------
//                          TECHNIQUES
//<bool UsesNIRenderState = true;>
//------------------------------------------------------------------------------------------------
Pixelshader PSArray20[2] =
{
	compile ps_2_0 PSTerrain_SPLATTILE_LMFW_20(TerrainBase, false),
	compile ps_2_0 PSTerrain_SPLATTILE_LMFW_20(TerrainBaseNoMips, false)
};

technique TerrainShader< string shadername= "TerrainShader"; int implementation=0;>
{
	pass P0
	{
		// Enable depth writing
		ZEnable				= TRUE;
		ZWriteEnable		= TRUE;
		ZFunc				= LESSEQUAL;

		// Disable alpha blending and testing	
		AlphaBlendEnable = true;
		AlphaTestEnable	 = true;
		AlphaRef         = 0;
		AlphaFunc        = GREATER;
		SrcBlend		 = SrcAlpha;
		DestBlend		 = InvSrcAlpha;

		// Set texture coordinate indices and	
		TexCoordIndex[0]	= 0;		
		TexCoordIndex[1]	= 1;		
		TexCoordIndex[2]	= 2;	
		TexCoordIndex[3]	= 3;	

		TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = 0;	
		TextureTransformFlags[2] = 0;	
		TextureTransformFlags[3] = 0;	

		// Set vertex and pixel shaders
		VertexShader = compile vs_1_1 VSTerrain_Tile_14();
		PixelShader	 = (PSArray20[iTrilinearTextureIndex]);
	}
}

Pixelshader PSArray14[2] =
{
	compile ps_1_4 PSTerrain_SPLATTILE_LMFW_14(TerrainBase, false),
	compile ps_1_4 PSTerrain_SPLATTILE_LMFW_14(TerrainBaseNoMips, false)
};

technique TerrainShader14< string shadername= "TerrainShader"; int implementation=1;>
{
	pass P0
	{
		// Enable depth writing
		ZEnable				= TRUE;
		ZWriteEnable		= TRUE;
		ZFunc				= LESSEQUAL;

		// Disable alpha blending and testing	
		AlphaBlendEnable = true;
		AlphaTestEnable	 = true;
		AlphaRef         = 0;
		AlphaFunc        = GREATER;
		SrcBlend		 = SrcAlpha;
		DestBlend		 = InvSrcAlpha;

		// Set texture coordinate indices and	
		TexCoordIndex[0]	= 0;		
		TexCoordIndex[1]	= 1;		
		TexCoordIndex[2]	= 2;	
		TexCoordIndex[3]	= 3;	

		TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = 0;	
		TextureTransformFlags[2] = 0;	
		TextureTransformFlags[3] = 0;

		// Set vertex and pixel shaders
		VertexShader = compile vs_1_1 VSTerrain_Tile_14();
		PixelShader	 = (PSArray14[iTrilinearTextureIndex]);
	}
}

Pixelshader PSArray11[2] =
{
	compile ps_1_1 PSTerrain_SPLATTILE_LMFW_11(TerrainBase, false),
	compile ps_1_1 PSTerrain_SPLATTILE_LMFW_11(TerrainBaseNoMips, false)
};

technique TerrainShader_11< string shadername= "TerrainShader"; int implementation=2;>
{
	pass P0
	{
		// Enable depth writing
		ZEnable				= TRUE;
		ZWriteEnable		= TRUE;
		ZFunc				= LESSEQUAL;

		// Disable alpha blending and testing	
		AlphaBlendEnable = true;
		AlphaTestEnable	 = true;
		AlphaRef         = 0;
		AlphaFunc        = GREATER;
		SrcBlend		 = SRCALPHA;
		DestBlend		 = INVSRCALPHA;

		// Set texture coordinate indices and	
		TexCoordIndex[0]	= 0;		
		TexCoordIndex[1]	= 1;		
		TexCoordIndex[2]	= 2;	
		TexCoordIndex[3]	= 3;	

		TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = 0;	
		TextureTransformFlags[2] = 0;	
		TextureTransformFlags[3] = 0;

		// Set vertex and pixel shaders
		VertexShader = compile vs_1_1 VSTerrain_Tile_11();
		PixelShader	 = (PSArray11[iTrilinearTextureIndex]);
	}
}


// Fixed Function Version
technique TerrainShader_FF_4TPP< string shadername= "TerrainShader"; int implementation=3;>
{
	pass P0
	{
		ZEnable        = true;
		ZWriteEnable   = true;
		ZFunc          = LESSEQUAL;
		
		// Disable alpha blending and testing	
		AlphaBlendEnable = true;
		AlphaTestEnable	 = true;
		AlphaRef         = 0;
		AlphaFunc        = GREATER;
		SrcBlend		 = SrcAlpha;
		DestBlend		 = InvSrcAlpha;

		// textures
		Sampler[0]    =   <TerrainBase>;
		Sampler[1]    =   <TerrainLightmap>;
		Sampler[2]    =   <TerrainFOWar>;
		
		MipFilter[0] = <iMipStatus>;
		
		TexCoordIndex[0] = 0;
		TexCoordIndex[1] = CAMERASPACEPOSITION;
		TexCoordIndex[2] = CAMERASPACEPOSITION;

		TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = Count3;	
		TextureTransformFlags[2] = Count3;	

		TextureTransform[0] = 0;
		TextureTransform[1] = <mtxLightmap>;	
		TextureTransform[2] = <mtxFOW>;

		// texture stage 0 - Base Texture
		ColorOp[0]       = SelectArg1;
		ColorArg1[0]     = Texture;
		AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;

		// texture stage 1 - lightmap
		ColorOp[1]       = SelectArg1;//Addsigned;//;
		ColorArg1[1]	 = Current;//Texture
		ColorArg2[1]     = Current;
		AlphaOp[1]		 = SelectArg1;
		AlphaArg1[1]	 = Current;

		// texture stage 2	- FoW
		ColorOp[2]       = Modulate;
		ColorArg1[2]     = Texture;
		ColorArg2[2]     = Current;
		AlphaOp[2]		 = SelectArg1;
		AlphaArg1[2]	 = Current;

		// texture stage 3 
		ColorOp[3]       = disable;
		AlphaOp[3]		 = disable;

		// shaders
		VertexShader     = NULL;
		PixelShader      = NULL;
	}
}


technique TerrainShader_FF_2TPP< string shadername= "TerrainShader"; int implementation=4;>
{
	pass P0
	{
		ZEnable        = TRUE;
		ZWriteEnable   = TRUE;
		ZFunc          = LESSEQUAL;

		
		// Disable alpha blending and testing	
		AlphaBlendEnable = true;
		AlphaTestEnable	 = true;
		AlphaRef         = 0;
		AlphaFunc        = Greater;
		SrcBlend		 = SrcAlpha;
		DestBlend		 = InvSrcAlpha;

		// textures
		Sampler[0]    =   <TerrainBase>;
		Sampler[1]    =   <TerrainFOWar>;
		
		MipFilter[0] = <iMipStatus>;

		TexCoordIndex[0] = 0;	
        TexCoordIndex[1] = CAMERASPACEPOSITION;	//fow
                
       	TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = Count3;	
                
        // transforms
        TextureTransform[0] = 0;
		TextureTransform[1] = <mtxFOW>;
		

		// texture stage 0 - Base Texture
		ColorOp[0]       = SelectArg1;
		ColorArg1[0]     = Texture;
		AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;

		// texture stage 2	- FoW
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


//------------------------------------------------------------------------------------------------
//                          TECHNIQUES - TerrainAlphaShader
//<bool UsesNIRenderState = true;>
//------------------------------------------------------------------------------------------------
Pixelshader PSAlphaArray20[2] =
{
	compile ps_2_0 PSTerrain_SPLATTILE_LMFW_20(TerrainBase, true),
	compile ps_2_0 PSTerrain_SPLATTILE_LMFW_20(TerrainBaseNoMips, true)
};

technique TerrainAlphaShader< string shadername= "TerrainAlphaShader"; int implementation=0;>
{
	pass P0
	{
		// Disable depth writing
		ZEnable				= TRUE;
		ZWriteEnable		= TRUE;
		ZFunc				= LESSEQUAL;

		// Disable alpha blending and testing	
		AlphaBlendEnable = true;
		AlphaTestEnable	 = true;
		AlphaRef         = 0;
		AlphaFunc        = GREATER;
		SrcBlend		 = SrcAlpha;
		DestBlend		 = InvSrcAlpha;

		// Set texture coordinate indices and	
		TexCoordIndex[0]	= 0;		
		TexCoordIndex[1]	= 1;		
		TexCoordIndex[2]	= 2;	
		TexCoordIndex[3]	= 3;	

		TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = 0;	
		TextureTransformFlags[2] = 0;	
		TextureTransformFlags[3] = 0;	

		// Set vertex and pixel shaders
		VertexShader = compile vs_1_1 VSTerrain_Tile_14();
		PixelShader	 = (PSAlphaArray20[iTrilinearTextureIndex]);
	}
}

Pixelshader PSAlphaArray14[2] =
{
	compile ps_1_4 PSTerrain_SPLATTILE_LMFW_14(TerrainBase, true),
	compile ps_1_4 PSTerrain_SPLATTILE_LMFW_14(TerrainBaseNoMips, true)
};

technique TerrainAlphaShader14< string shadername= "TerrainAlphaShader"; int implementation=1;>
{
	pass P0
	{
		// Enable depth writing
		ZEnable				= TRUE;
		ZWriteEnable		= TRUE;
		ZFunc				= LESSEQUAL;

		// Disable alpha blending and testing	
		AlphaBlendEnable = true;
		AlphaTestEnable	 = true;
		AlphaRef         = 0;
		AlphaFunc        = GREATER;
		SrcBlend		 = SrcAlpha;
		DestBlend		 = InvSrcAlpha;

		// Set texture coordinate indices and	
		TexCoordIndex[0]	= 0;		
		TexCoordIndex[1]	= 1;		
		TexCoordIndex[2]	= 2;	
		TexCoordIndex[3]	= 3;	

		TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = 0;	
		TextureTransformFlags[2] = 0;	
		TextureTransformFlags[3] = 0;

		// Set vertex and pixel shaders
		VertexShader = compile vs_1_1 VSTerrain_Tile_14();
		PixelShader	 = (PSAlphaArray14[iTrilinearTextureIndex]);
	}
}

Pixelshader PSAlphaArray11[2] =
{
	compile ps_1_1 PSTerrain_SPLATTILE_LMFW_11(TerrainBase, true),
	compile ps_1_1 PSTerrain_SPLATTILE_LMFW_11(TerrainBaseNoMips, true)
};

technique TerrainAlphaShader_11< string shadername= "TerrainAlphaShader"; int implementation=2;>
{
	pass P0
	{
		// Enable depth writing
		ZEnable				= TRUE;
		ZWriteEnable		= TRUE;
		ZFunc				= LESSEQUAL;

		// Disable alpha blending and testing	
		AlphaBlendEnable = true;
		AlphaTestEnable	 = true;
		AlphaRef         = 0;
		AlphaFunc        = GREATER;
		SrcBlend		 = SRCALPHA;
		DestBlend		 = INVSRCALPHA;

		// Set texture coordinate indices and	
		TexCoordIndex[0]	= 0;		
		TexCoordIndex[1]	= 1;		
		TexCoordIndex[2]	= 2;	
		TexCoordIndex[3]	= 3;	

		TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = 0;	
		TextureTransformFlags[2] = 0;	
		TextureTransformFlags[3] = 0;

		// Set vertex and pixel shaders
		VertexShader = compile vs_1_1 VSTerrain_Tile_11();
		PixelShader	 = (PSAlphaArray11[iTrilinearTextureIndex]);
	}
}


// Fixed Function Version
technique TerrainAlphaShader_FF_4TPP< string shadername= "TerrainAlphaShader"; int implementation=3;>
{
	pass P0
	{
		ZEnable        = true;
		ZWriteEnable   = true;
		ZFunc          = LESSEQUAL;
		
		// Disable alpha blending and testing	
		AlphaBlendEnable = true;
		AlphaTestEnable	 = true;
		AlphaRef         = 0;
		AlphaFunc        = GREATER;
		SrcBlend		 = SrcAlpha;
		DestBlend		 = InvSrcAlpha;

		// textures
		Sampler[0]    =   <TerrainBase>;
		Sampler[1]    =   <TerrainLightmap>;
		Sampler[2]    =   <TerrainFOWar>;
		
		MipFilter[0] = <iMipStatus>;
		
		TexCoordIndex[0] = 0;
		TexCoordIndex[1] = CAMERASPACEPOSITION;
		TexCoordIndex[2] = CAMERASPACEPOSITION;

		TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = Count3;	
		TextureTransformFlags[2] = Count3;	

		TextureTransform[0] = 0;
		TextureTransform[1] = <mtxLightmap>;	
		TextureTransform[2] = <mtxFOW>;

		// texture stage 0 - Base Texture
		ColorOp[0]       = SelectArg1;
		ColorArg1[0]     = Texture;
		AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;

		// texture stage 1 - lightmap
		ColorOp[1]       = SelectArg1;//Addsigned;//;
		ColorArg1[1]	 = Current;//Texture
		ColorArg2[1]     = Current;
		AlphaOp[1]		 = SelectArg1;
		AlphaArg1[1]	 = Current;

		// texture stage 2	- FoW
		ColorOp[2]       = Modulate;
		ColorArg1[2]     = Texture;
		ColorArg2[2]     = Current;
		AlphaOp[2]		 = SelectArg1;
		AlphaArg1[2]	 = Current;

		// texture stage 3 
		ColorOp[3]       = disable;
		AlphaOp[3]		 = disable;

		// shaders
		VertexShader     = NULL;
		PixelShader      = NULL;
	}
}


technique TerrainAlphaShader_FF_2TPP< string shadername= "TerrainAlphaShader"; int implementation=4;>
{
	pass P0
	{
		ZEnable        = TRUE;
		ZWriteEnable   = TRUE;
		ZFunc          = LESSEQUAL;

		
		// Disable alpha blending and testing	
		AlphaBlendEnable = true;
		AlphaTestEnable	 = true;
		AlphaRef         = 0;
		AlphaFunc        = Greater;
		SrcBlend		 = SrcAlpha;
		DestBlend		 = InvSrcAlpha;

		// textures
		Sampler[0]    =   <TerrainBase>;
		Sampler[1]    =   <TerrainFOWar>;
		
		MipFilter[0] = <iMipStatus>;

		TexCoordIndex[0] = 0;	
        TexCoordIndex[1] = CAMERASPACEPOSITION;	//fow
                
       	TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = Count3;	
                
        // transforms
        TextureTransform[0] = 0;
		TextureTransform[1] = <mtxFOW>;
		

		// texture stage 0 - Base Texture
		ColorOp[0]       = SelectArg1;
		ColorArg1[0]     = Texture;
		AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;

		// texture stage 2	- FoW
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
//  *****************   CIV4 ********************
//
//  FILE:    PlotIndicator.fx
//
//  AUTHOR:  Nat Duca (03-24-2005)
//			 Tom Whittaker 9.15.05 - simpipled Plot icons to 2 textures, simple draw call and not texturecompostiing
//
//  PURPOSE: Draw the plot widget with specified color, masked icon and border highlights
//
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2005 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------

dword borderColor: MATERIALEMISSIVE = 0xFF00FF00;
//------------------------------------------------------------------------------------------------
// TEXTURES
//------------------------------------------------------------------------------------------------  
texture IconOverlayTexture <string NTM = "base";>;
texture ButtonTexture <string NTM = "decal"; int NTMIndex = 0;>;
texture OverlayAlphaTexture<string NTM = "decal"; int NTMIndex = 1;>;

//------------------------------------------------------------------------------------------------
//                          SAMPLERS
//------------------------------------------------------------------------------------------------  
sampler IconOverlay = sampler_state
{
	Texture = (IconOverlayTexture);
	AddressU = Clamp;
	AddressV = Clamp;
	MagFilter = Linear;
	MipFilter = Linear;
	MinFilter = Linear; 
};

sampler IconButton = sampler_state 
{ 
	Texture = (ButtonTexture);
	AddressU = Clamp;
	AddressV = Clamp;
	MagFilter = Linear;	
	MipFilter = Linear;
	MinFilter = Linear; 
};
sampler IconOverlayAlpha = sampler_state 
{ 
	Texture = (OverlayAlphaTexture);
	AddressU = Clamp;
	AddressV = Clamp;
	MagFilter = Linear;	
	MipFilter = Linear;
	MinFilter = Linear; 
};


//------------------------------------------------------------------------------------------------
//                          TECHNIQUES
//------------------------------------------------------------------------------------------------
technique PlotIndicatorShader
<string shadername= "PlotIndicatorShader"; int implementation=0; bool UsesNIRenderState = true;>
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = true;
        ZWriteEnable   = true;
        ZFunc          = lessequal;
        
        //Alpha Testing
        AlphaBlendEnable= true;
        AlphaTestEnable	= true;
        AlphaREf		= 0;
        AlphaFunc		= greater;
        SrcBlend        = SRCALPHA;
        DestBlend       = INVSRCALPHA;
        
   		// set the quad texture to the icon
        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 0;
        
        Sampler[0] = <IconOverlay>;
		Sampler[1] = <IconButton>;
		Sampler[2] = <IconOverlayAlpha>;
                 
        TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = 0;
		TextureTransformFlags[2] = 0;
		
	    TextureFactor = <borderColor>;

		// texture stage 0 - Base Texture + TeamCOlor
        ColorOp[0]       = Modulate;
        ColorArg1[0]     = Texture;
        ColorArg2[0]	 = TFactor;
       	AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;

        // texture stage 1 - Decal
        ColorOp[1]       = BlendCurrentAlpha;
        ColorArg1[1]     = Texture;
        ColorArg2[1]     = Current;
       	AlphaOp[1]		 = SelectArg1;
		AlphaArg1[1]	 = Texture;

        // texture stage 2 - Decal
        ColorOp[2]       = SelectArg1;
        ColorArg1[2]     = Current;
       	AlphaOp[2]		 = SelectArg1;
		AlphaArg1[2]	 = Texture;
        
        ColorOp[3] = Disable;
        AlphaOp[3] = Disable;
        
        // shaders
        VertexShader     = NULL;
        PixelShader      = NULL;

	}
 }

// 2TP Version
//------------------------------------------------------------------------------------------------
technique TPlotIndicator_Shader2TPP
<string shadername= "PlotIndicatorShader"; int implementation=1; bool UsesNIRenderState = true;>
{
    pass P0
    {
        // Enable depth writing
        ZEnable        = true;
        ZWriteEnable   = true;
        ZFunc          = lessequal;
        
        //Alpha Testing
        AlphaBlendEnable= true;
        AlphaTestEnable	= true;
        AlphaREf		= 0;
        AlphaFunc		= greater;
        SrcBlend        = SRCALPHA;
        DestBlend       = INVSRCALPHA;
        
   		// set the quad texture to the icon
        TexCoordIndex[0] = 1;
        TexCoordIndex[1] = 0;
        
		Sampler[0] = <IconButton>;
		Sampler[1] = <IconOverlayAlpha>;
                 
        TextureTransformFlags[0] = 0;
		TextureTransformFlags[1] = 0;
		
	    TextureFactor = <borderColor>;

		// texture stage 0 - Base Texture + TeamCOlor
        ColorOp[0]       = Modulate;
        ColorArg1[0]     = Texture;
        ColorArg2[0]	 = TFactor;
       	AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;

        ColorOp[1]       = SelectArg1;
        ColorArg1[1]     = current;
       	AlphaOp[1]		 = SelectArg1;
		AlphaArg1[1]	 = Texture;
               
        ColorOp[2] = Disable;
        AlphaOp[2] = Disable;
        
        // shaders
        VertexShader     = NULL;
        PixelShader      = NULL;

	}
 }


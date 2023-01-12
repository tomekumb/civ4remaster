//  *****************   CIV4 ********************
//
//  FILE:    Symbols.fx
//
//  AUTHOR:  Tom Whittaker
//
//  PURPOSE: Draw the symbols icons
//
//------------------------------------------------------------------------------------------------
//  Copyright (c) 2005 Firaxis Games, Inc. All rights reserved.
//------------------------------------------------------------------------------------------------
float3x3 m_Yield1Matrix  : GLOBAL; //TEXTRANSFORMBASE; Texture Mat don't work with FF in GB!
float3x3 m_Yield2Matrix  : GLOBAL; //TEXTRANSFORMDARK;
float3x3 m_Yield3Matrix	 : GLOBAL; //TEXTRANSFORMDETAIL;
float4x4 mtxFOW     : GLOBAL;
dword dwAlphaColor: GLOBAL = 0x80000080;;

//------------------------------------------------------------------------------------------------
// TEXTURES
//------------------------------------------------------------------------------------------------  
texture baseTexture  <string NTM = "base";>;
texture darkTexture  <string NTM = "dark";>;
texture detailTexture<string NTM = "detail";>;
texture FOGTexture	 <string NTM = "shader";  int NTMIndex = 2;>;

//------------------------------------------------------------------------------------------------
//                          SAMPLERS
//------------------------------------------------------------------------------------------------  
sampler Yield1 = sampler_state
{
	Texture = (baseTexture);
	AddressU = Clamp;
	AddressV = Clamp;
	MagFilter = Linear;
	MipFilter = Linear;
	MinFilter = Linear; 
};

sampler Yield2 = sampler_state 
{ 
	Texture = (darkTexture);
	AddressU = Clamp;
	AddressV = Clamp;
	MagFilter = Linear;	
	MipFilter = Linear;
	MinFilter = Linear; 
};
sampler Yield3 = sampler_state 
{ 
	Texture = (detailTexture);
	AddressU = Clamp;
	AddressV = Clamp;
	MagFilter = Linear;	
	MipFilter = Linear;
	MinFilter = Linear; 
};

sampler Fog  = sampler_state  
{ 
	Texture = (FOGTexture);
	AddressU = Clamp;
	AddressV = Clamp;
	MagFilter = Linear;
	MipFilter = Linear; 
	MinFilter = Linear; 
};


//------------------------------------------------------------------------------------------------
//                          TECHNIQUES
//------------------------------------------------------------------------------------------------
technique SymbolShader
<string shadername= "SymbolShader"; int implementation=0; bool UsesNIRenderState = true;>
{
    pass P0
    {
		Lighting       = false;
    
        // Enable depth writing
        ZEnable        = false;
        ZWriteEnable   = false;
        ZFunc          = lessequal;
        
        //Alpha Testing
        AlphaBlendEnable= true;
        AlphaTestEnable	= true;
        AlphaREf		= 0;
        AlphaFunc		= greater;
        SrcBlend        = SRCALPHA;
        DestBlend       = INVSRCALPHA;
        
        //Samplers
        Sampler[0] = <Yield1>;
		Sampler[1] = <Yield2>;
		Sampler[2] = <Yield3>;
		Sampler[3] = <Fog>;

        TexCoordIndex[0] = 0;
        TexCoordIndex[1] = 1;
        TexCoordIndex[2] = 2;
	    TexCoordIndex[3] = CAMERASPACEPOSITION;	//fow

        TextureTransformFlags[0] = Count2;
		TextureTransformFlags[1] = Count2;
		TextureTransformFlags[2] = Count2;
		TextureTransformFlags[3] = Count3;
		
		TextureTransform[0] = <m_Yield1Matrix>;
		TextureTransform[1] = <m_Yield2Matrix>;
		TextureTransform[2] = <m_Yield3Matrix>;
		TextureTransform[3] = <mtxFOW>;
		
		TextureFactor = <dwAlphaColor>;//0x0000ff80;				//Blend Lerp Factor
		
		// texture stage 0 - Yield1
        ColorOp[0]       = SelectArg1;
        ColorArg1[0]     = Texture;
       	AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;

        // texture stage 1 - Yield2
        ColorOp[1]       = Add;
        ColorArg1[1]     = Texture;
        ColorArg2[1]     = Current;
       	AlphaOp[1]		 = Add;
		AlphaArg1[1]	 = Texture;
		AlphaArg2[1]	 = Current;

        // texture stage 2 - Yield3
        ColorOp[2]       = Add;
        ColorArg1[2]     = Texture;
        ColorArg2[2]     = Current;
       	AlphaOp[2]		 = Add;
		AlphaArg1[2]	 = Texture;
		AlphaArg2[2]	 = Current;

        
        // Texture state 3 - FOW
        ColorOp[3]       = SelectArg2;//disable;//Modulate;
        ColorArg1[3]     = Texture;
        ColorArg2[3]     = Current;
       	AlphaOp[3]		 = Modulate;
		AlphaArg1[3]	 = tfactor;
		AlphaArg2[3]	 = Current;
        
        // disble final stage
        ColorOp[4] = Disable;
        AlphaOp[4] = Disable;
        
        // shaders
        VertexShader     = NULL;
        PixelShader      = NULL;
	}
 }

// 2TP Version
//------------------------------------------------------------------------------------------------
technique TSymbolShader2TPP
<string shadername= "SymbolShader"; int implementation=1; bool UsesNIRenderState = true;>
{
    pass P0
    {
		Lighting       = false;
    
        // Enable depth writing
        ZEnable        = false;
        ZWriteEnable   = false;
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
        
		Sampler[0] = <Yield1>;
		Sampler[1] = <Yield2>;
                 
        TextureTransformFlags[0] = Count2;
		TextureTransformFlags[1] = Count2;
		
		TextureTransform[0] = <m_Yield1Matrix>;
		TextureTransform[1] = <m_Yield2Matrix>;
		
		TextureFactor = <dwAlphaColor>;				//Blend Lerp Factor
	
		// texture stage 0 - Yield1
        ColorOp[0]       = SelectArg1;
        ColorArg1[0]     = Texture;
       	AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;

        // texture stage 1 - Yield2
        ColorOp[1]       = Add;
        ColorArg1[1]     = Texture;
        ColorArg2[1]     = Current;
       	AlphaOp[1]		 = Add;
		AlphaArg1[1]	 = Texture;
		AlphaArg2[1]	 = Current;
               
        ColorOp[2] = Disable;
        AlphaOp[2] = Disable;
        
        // shaders
        VertexShader     = NULL;
        PixelShader      = NULL;
	}
	pass P1
	{
		Sampler[0] = <Yield3>;
		//Sampler[1] = <Fog>;
		
        TexCoordIndex[0] = 2;
	    //TexCoordIndex[1] = CAMERASPACEPOSITION;	//fow
		
		TextureTransformFlags[0] = Count2;
		//TextureTransformFlags[1] = Count3;
		
		TextureTransform[0] = <m_Yield3Matrix>;
		//TextureTransform[1] = <mtxFOW>;
		
	     // texture stage 0 - Yield3
		ColorOp[0]       = SelectArg1;
        ColorArg1[0]     = Texture;
       	AlphaOp[0]		 = SelectArg1;
		AlphaArg1[0]	 = Texture;
		
		ColorOp[1] = Disable;
        AlphaOp[1] = Disable;
		
		// Texture state 1 - FOW
        //ColorOp[1]       = SelectArg2;
        //ColorArg1[1]     = Texture;
        //ColorArg2[1]     = Current;
       	//AlphaOp[1]		 = Modulate;
		//AlphaArg1[1]	 = tfactor;
		//AlphaArg2[1]	 = Current;
	}
 }


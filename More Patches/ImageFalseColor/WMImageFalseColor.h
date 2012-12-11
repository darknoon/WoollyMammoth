//
//  WMImageFalseColor.h
//  WMViewer
//
//  Created by Warren Stringer


#import <Foundation/Foundation.h>

//For now, hardcoded to a gaussan filter

#import <WMGraph/WMGraph.h>

@class WMShader;
@class WMFramebuffer;
@class WMTexture2D;
@class WMStructuredBuffer;

@interface WMImageFalseColor : WMPatch {
    WMShader *shader;
	
	WMFramebuffer *fbo;
	WMTexture2D *texMono;
    WMTexture2D *texPal;
	
	//For quad
	WMStructuredBuffer *vertexBuffer;
	WMStructuredBuffer *indexBuffer;
	
	WMImagePort *inputImage;
	WMNumberPort *inputOffset;
	WMImagePort *outputImage;
}

@end

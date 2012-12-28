//
//  WMGraph.h
//  WMGraph
//
//  Created by Andrew Pouliot on 12/7/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#ifndef WMGraph_WMGraph_h
#define WMGraph_WMGraph_h

//Make sure we have GL included
#import <WMGraph/WMRenderCommon.h>

//WMLite headers

#import <WMGraph/DNKVC.h>
#import <WMGraph/DNMemoryInfo.h>
#import <WMGraph/DNTimingMacros.h>

#import <WMGraph/WMDisplayLink.h>
#import <WMGraph/WMView.h>

#import <WMGraph/EAGLContext+Extensions.h>
#import <WMGraph/GLKMath_cpp.h>
#import <WMGraph/NSValue+GLKVector.h>
#import <WMGraph/WMEAGLContext.h>
#import <WMGraph/WMFramebuffer.h>
#import <WMGraph/WMFrameCounter.h>
#import <WMGraph/WMGLStateObject.h>
#import <WMGraph/WMMathUtil.h>
#import <WMGraph/WMRenderObject.h>
#import <WMGraph/WMRenderObject+CreateWithGeometry.h>
#import <WMGraph/WMShader.h>
#import <WMGraph/WMStructuredBuffer.h>
#import <WMGraph/WMStructureDefinition.h>
#import <WMGraph/WMTexture2D.h>

//Graph-specific headers
#import <WMGraph/WMEngine.h>
#import <WMGraph/WMPatch.h>
#import <WMGraph/WMPatchCategories.h>
#import <WMGraph/WMPatchEventSource.h>
#import <WMGraph/WMAudioBuffer.h>
#import <WMGraph/WMViewController.h>
#import <WMGraph/WMComposition.h>
#import <WMGraph/WMCompositionSerialization.h>
#import <WMGraph/WMConnection.h>

//CoreVideo integration with CVOpenGLESTextureCache / CVOpenGLTextureCache
#import <WMGraph/WMCVTexture2D.h>

//Core patches
#import <WMGraph/WMAccelerometer.h>
#import <WMGraph/WMVideoCapture.h>
#import <WMGraph/WMClear.h>
#import <WMGraph/WMQuad.h>
#import <WMGraph/WMSphere.h>
#import <WMGraph/WMClear.h>
#import <WMGraph/WMImageFilter.h>
#import <WMGraph/WMImageLoader.h>
#import <WMGraph/WMImageOrientation.h>
#import <WMGraph/WMImageSize.h>
#import <WMGraph/WMRenderInImage.h>
#import <WMGraph/WMRenderOutput.h>
#import <WMGraph/WMSetRenderObject.h>
#import <WMGraph/WMSetShader.h>
#import <WMGraph/WMColorFromComponents.h>
#import <WMGraph/WMLFO.h>
#import <WMGraph/WMMathOp.h>
#import <WMGraph/WMSplitter.h>
#import <WMGraph/WMVectorFromComponents.h>
#if TARGET_OS_IPHONE
#import <WMGraph/WMVideoRecord.h>
#endif

//Port types
#import <WMGraph/WMPort.h>
#import <WMGraph/WMAudioPort.h>
#import <WMGraph/WMBooleanPort.h>
#import <WMGraph/WMBufferPort.h>
#import <WMGraph/WMColorPort.h>
#import <WMGraph/WMImagePort.h>
#import <WMGraph/WMIndexPort.h>
#import <WMGraph/WMNumberPort.h>
#import <WMGraph/WMRenderObjectPort.h>
#import <WMGraph/WMStringPort.h>
#import <WMGraph/WMVectorPort.h>
#import <WMGraph/WMTransformPort.h>

#endif

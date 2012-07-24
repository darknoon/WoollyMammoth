//
//  WMVideoRecord.h
//  WMEdit
//
//  Created by Andrew Pouliot on 9/4/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMPatch.h"

@interface WMVideoRecord : WMPatch

@property (nonatomic, readonly) WMRenderObjectPort *inputRenderable1;
@property (nonatomic, readonly) WMRenderObjectPort *inputRenderable2;
@property (nonatomic, readonly) WMRenderObjectPort *inputRenderable3;
@property (nonatomic, readonly) WMRenderObjectPort *inputRenderable4;

@property (nonatomic, readonly) WMBooleanPort *inputShouldRecord;

@property (nonatomic, readonly) WMIndexPort *inputWidth;
@property (nonatomic, readonly) WMIndexPort *inputHeight;
//This will determine the orientation at which the video should be recorded
@property (nonatomic, readonly) WMIndexPort *inputOrientation;

@property (nonatomic, readonly) WMAudioPort *inputAudio;

@property (nonatomic, readonly) WMBooleanPort *outputRecording;
@property (nonatomic, readonly) WMBooleanPort *outputSaving;
@property (nonatomic, readonly) WMNumberPort *outputRecordDuration;

@property (nonatomic, readonly) WMStringPort *outputMostRecentFilePath;

//Use this to show a preview of what will be recorded. Works even when
@property (nonatomic, readonly) WMImagePort *outputImage;


@end

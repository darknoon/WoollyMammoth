//
//  WMVideoRecord.h
//  WMEdit
//
//  Created by Andrew Pouliot on 9/4/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMPatch.h"

@interface WMVideoRecord : WMPatch {
}

@property (nonatomic, strong) WMRenderObjectPort *inputRenderable1;
@property (nonatomic, strong) WMRenderObjectPort *inputRenderable2;
@property (nonatomic, strong) WMRenderObjectPort *inputRenderable3;
@property (nonatomic, strong) WMRenderObjectPort *inputRenderable4;

@property (nonatomic, strong) WMStringPort *inputTempName;

@property (nonatomic, strong) WMBooleanPort *inputShouldRecord;

@property (nonatomic, strong) WMIndexPort *inputWidth;
@property (nonatomic, strong) WMIndexPort *inputHeight;
//This will determine the orientation at which the video should be recorded
@property (nonatomic, strong) WMIndexPort *inputOrientation;

@property (nonatomic, strong) WMAudioPort *inputAudio;

@property (nonatomic, strong) WMBooleanPort *outputRecording;
@property (nonatomic, strong) WMBooleanPort *outputSaving;

//Use this to show a preview of what will be recorded. Works even when
@property (nonatomic, strong) WMImagePort *outputImage;


@end

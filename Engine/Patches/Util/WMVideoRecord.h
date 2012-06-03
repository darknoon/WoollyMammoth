//
//  WMVideoRecord.h
//  WMEdit
//
//  Created by Andrew Pouliot on 9/4/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMPatch.h"

@interface WMVideoRecord : WMPatch {
	WMRenderObjectPort *inputRenderable1;
	WMRenderObjectPort *inputRenderable2;
	WMRenderObjectPort *inputRenderable3;
	WMRenderObjectPort *inputRenderable4;
	
	WMStringPort *inputTempName;
	
	WMBooleanPort *inputShouldRecord;
	
	WMIndexPort *inputWidth;
	WMIndexPort *inputHeight;
	//This will determine the orientation at which the video should be recorded
	WMIndexPort *inputOrientation;
	
	WMAudioPort *inputAudio;
	
	WMBooleanPort *outputRecording;
	WMBooleanPort *outputSaving;
	
	//Use this to show a preview of what will be recorded. Works even when
	WMImagePort *outputImage;
}


@end

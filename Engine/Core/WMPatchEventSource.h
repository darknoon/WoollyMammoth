//
//  WMPatchEventSource.h
//  PopVideo
//
//  Created by Andrew Pouliot on 6/18/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

@protocol WMPatchEventSource;

@protocol WMPatchEventDelegate <NSObject>

- (void)patchGeneratedUpdateEvent:(id <WMPatchEventSource>)patch atTime:(double)time;

@end

@protocol WMPatchEventSource <NSObject>

//Should not generate events when this is set
@property (nonatomic) BOOL eventDelegatePaused;

//Send events here
@property (nonatomic, weak) id <WMPatchEventDelegate> eventDelegate;

@end

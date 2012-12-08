//
//  DNPCParticleCascader.h
//  ParticleCascade
//
//  Created by Andrew Pouliot on 9/19/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DNPCParticleCascader : NSObject

- (id)initWithParticleCount:(int)count;

@property (nonatomic) BOOL touchIsDown;

@property (nonatomic) GLKVector2 inputPoint;

- (void)updateWithTime:(double)t dt:(double)dt;

- (void)render;

@end

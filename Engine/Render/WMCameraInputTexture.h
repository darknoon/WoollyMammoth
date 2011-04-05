//
//  WMCameraInputTexture.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 11/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMTextureAsset.h"

@interface WMCameraInputTexture : WMTextureAsset {
	BOOL active;
}

@property (nonatomic, assign) BOOL active;

- (GLuint)glTexture;

@end

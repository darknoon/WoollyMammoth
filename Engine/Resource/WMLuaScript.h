//
//  WMLuaScript.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/30/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMScriptingContext;
@class WMGameObject;

#import "WMAsset.h"

@interface WMLuaScript : WMAsset {
	NSString *scriptText;
	
}

- (BOOL)loadWithBundle:(NSBundle *)inBundle inScriptingContext:(WMScriptingContext *)inScriptingContext error:(NSError **)outError;
- (void)executeInScriptingContext:(WMScriptingContext *)inScriptingContext thisObject:(WMGameObject *)inThisObject;

@end

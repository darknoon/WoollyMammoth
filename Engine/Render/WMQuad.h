//
//  WMQuad.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderableDataSource.h"

//Just renders a quad, nothing special :)
@interface WMQuad : NSObject <WMRenderableDataSource> {
	GLuint vbo;
	GLuint ebo;
}

@end

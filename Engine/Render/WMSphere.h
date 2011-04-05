//
//  WMSphere.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/6/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderableDataSource.h"

struct WMSphereVertex;

//Should render a nice sphere. Right now does a janky one :P
@interface WMSphere : NSObject <WMRenderableDataSource> {
	GLuint vbo;
	GLuint ebo;
	
	float radius;
	float rhoStart;
	float rhoEnd;
	float phiStart;
	float phiEnd;
	int unum;
	int vnum;
}

@end

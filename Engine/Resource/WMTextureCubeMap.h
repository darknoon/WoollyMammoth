//
//  WMTextureCubeMap.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/7/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Texture2D.h"

@interface WMTextureCubeMap : Texture2D {

}

//Order (standard Open GL) is +x -x +y -y +z -z
- (id)initWithCubeMapImages:(NSArray *)inImages;

@end

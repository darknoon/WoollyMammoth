//
//  WMColorFromComponents.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMColorFromComponents.h"

#import "WMNumberPort.h"
#import "WMColorPort.h"

typedef struct {
	float r,g,b;
} COLOUR;

typedef struct {
	float h,s,l;
} HSL;

/// via http://paulbourke.net/texture_colour/convert/
COLOUR HSL2RGB(HSL c1)
{
	COLOUR c2,sat,ctmp;
	
	while (c1.h < 0)
		c1.h += 360;
	while (c1.h > 360)
		c1.h -= 360;
	
	if (c1.h < 120) {
		sat.r = (120 - c1.h) / 60.0;
		sat.g = c1.h / 60.0;
		sat.b = 0;
	} else if (c1.h < 240) {
		sat.r = 0;
		sat.g = (240 - c1.h) / 60.0;
		sat.b = (c1.h - 120) / 60.0;
	} else {
		sat.r = (c1.h - 240) / 60.0;
		sat.g = 0;
		sat.b = (360 - c1.h) / 60.0;
	}
	sat.r = MIN(sat.r,1);
	sat.g = MIN(sat.g,1);
	sat.b = MIN(sat.b,1);
	
	ctmp.r = 2 * c1.s * sat.r + (1 - c1.s);
	ctmp.g = 2 * c1.s * sat.g + (1 - c1.s);
	ctmp.b = 2 * c1.s * sat.b + (1 - c1.s);
	
	if (c1.l < 0.5) {
		c2.r = c1.l * ctmp.r;
		c2.g = c1.l * ctmp.g;
		c2.b = c1.l * ctmp.b;
	} else {
		c2.r = (1 - c1.l) * ctmp.r + 2 * c1.l - 1;
		c2.g = (1 - c1.l) * ctmp.g + 2 * c1.l - 1;
		c2.b = (1 - c1.l) * ctmp.b + 2 * c1.l - 1;
	}
	
	return(c2);
}

@implementation WMColorFromComponents

+ (NSString *)category;
{
    return WMPatchCategoryRender;
}

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCColorFromComponents"]];
	[pool drain];
}

- (id)initWithPlistRepresentation:(id)inPlist;
{
	self = [super initWithPlistRepresentation:inPlist];
	if (!self) return nil;
	
	NSString *identifer = [inPlist objectForKey:@"identifier"];
	if ([identifer isEqualToString:@"hsl"]) {
		mode = WMColorFromComponentsHSL;
	} else {
		mode = WMColorFromComponentsRGB;
	}
	
	return self;
}

- (BOOL)setPlistState:(id)inPlist;
{
	return [super setPlistState:inPlist];
}

- (id)plistState;
{
	return [super plistState];
}

- (BOOL)execute:(WMEAGLContext *)inContext time:(CFTimeInterval)time arguments:(NSDictionary *)args;
{
	HSL hsl;
	COLOUR color;
	switch (mode) {
		case WMColorFromComponentsHSL:
			hsl = (HSL){.h = input1.value * 360.0, .s = input2.value, .l = input3.value};
			color = HSL2RGB(hsl);
			outputColor.red = color.r;
			outputColor.green = color.g;
			outputColor.blue = color.b;
			outputColor.alpha = inputAlpha.value;
			return YES;
		case WMColorFromComponentsRGB:
			outputColor.red = input1.value;
			outputColor.green = input2.value;
			outputColor.blue = input3.value;
			outputColor.alpha = inputAlpha.value;
			return YES;
		default:
			return NO;
	}

}

@end

//
//  DNMemoryInfo.h
//  WMEdit
//
//  Created by Andrew Pouliot on 10/8/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <mach/mach.h>

//Sizes in bytes
typedef struct {
	long long free;
	long long used;
	long long pageSize;
} DNMemoryInfo;

extern BOOL DNMemoryGetInfo(DNMemoryInfo *infoPtr);
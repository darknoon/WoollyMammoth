//
//  WMPatchLuaBridge.m
//  WMEdit
//
//  Created by Andrew Pouliot on 10/13/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#include <stdio.h>

#import "WMPatch.h"
#import "WMPorts.h"


/*

 function setup()
 	addInputPort({type = "number", default = 0.5, min = 0.1, max = 1.0, name = "k"})
 	addOutputPort({type = "buffer", name = "buf"})
 end
 
 function main()
 	local k = inputPorts.k.value
 
 	local outBuffer = WMBuffer.new()
 	outBuffer[1] = {position = vec4(-k, -k, 0, 0)}
    outBuffer[2] = {position = vec4( k, -k, 0, 0)}
    outBuffer[3] = {position = vec4(-k,  k, 0, 0)}
    outBuffer[4] = {position = vec4( k,  k, 0, 0)}
    
	outputPorts.buf.value = outBuffer
 end
 
*/

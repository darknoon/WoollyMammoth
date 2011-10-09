//
//  DNMemoryInfo.m
//  WMEdit
//
//  Created by Andrew Pouliot on 10/8/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "DNMemoryInfo.h"


#import <mach/mach.h>
#import <mach/mach_host.h>


BOOL DNMemoryGetInfo(DNMemoryInfo *infoPtr) {
	if (!infoPtr) return NO;
	
	mach_port_t host_port;
	mach_msg_type_number_t host_size;
	vm_size_t pagesize;
	
	host_port = mach_host_self();
	host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
	host_page_size(host_port, &pagesize); 
	
	vm_statistics_data_t vm_stat;
	
	if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
		DLog(@"Failed to fetch vm statistics");
		return NO;
	}
	
	/* Stats in bytes */
	infoPtr->used = (vm_stat.active_count +
						  vm_stat.inactive_count +
						  vm_stat.wire_count) * pagesize;
	infoPtr->free = vm_stat.free_count * pagesize;
	infoPtr->pageSize = host_size;
	
	return YES;
}
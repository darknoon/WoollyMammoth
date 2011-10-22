//
//  DNTimingMacros.h
//
//  Created by Andrew Pouliot on 5/9/11.
//  Copyright 2011 Darknoon. All rights reserved.

struct __DNTimer {
	uint64_t startTimeTicks;
	double minTime;
	double maxTime;
	double avgTime;
	int count;
	BOOL reenterError;
};

#define DNTimerEnabled 1

#if DNTimerEnabled

#include <mach/mach_time.h>


#define DNTimerDefine(timerName) static struct __DNTimer __DNTimerDef##timerName = {.startTimeTicks = 0, .minTime = DBL_MAX, .maxTime = -1.0, .avgTime = 0.0}

#define DNTimerStart(timerName) {\
if (__DNTimerDef##timerName.reenterError) NSLog(@"TIMER CONCURRENCY ABUSE!"); \
__DNTimerDef##timerName.count++;\
__DNTimerDef##timerName.reenterError = YES;\
__DNTimerDef##timerName.startTimeTicks = mach_absolute_time();\
};

#define DNTimerEnd(timerName) {\
volatile uint64_t durationTicks = mach_absolute_time() - __DNTimerDef##timerName.startTimeTicks;\
mach_timebase_info_data_t info;\
mach_timebase_info(&info);\
double duration = (durationTicks * info.numer / info.denom) / 1000000000.0;\
if (!__DNTimerDef##timerName.reenterError) NSLog(@"TIMER CONCURRENCY ABUSE!"); \
__DNTimerDef##timerName.avgTime = ((__DNTimerDef##timerName.count - 1.0) / __DNTimerDef##timerName.count) * __DNTimerDef##timerName.avgTime + duration / __DNTimerDef##timerName.count;\
__DNTimerDef##timerName.minTime = MIN(__DNTimerDef##timerName.minTime, duration); \
__DNTimerDef##timerName.maxTime = MAX(__DNTimerDef##timerName.maxTime, duration); \
__DNTimerDef##timerName.reenterError = NO;}

#define DNTimerGetMinTime(timerName) __DNTimerDef##timerName.minTime
#define DNTimerGetAverageTime(timerName) __DNTimerDef##timerName.avgTime
#define DNTimerGetMaxTime(timerName) __DNTimerDef##timerName.maxTime

#define DNTimerGetStringMS(timerName) [NSString stringWithFormat:@"[%.3lf %.3lf %.3lf n=%d]ms", DNTimerGetMinTime(timerName) * 1000, DNTimerGetAverageTime(timerName) * 1000, DNTimerGetMaxTime(timerName) * 1000, DNTimerGetCount(timerName)]

#define DNTimerGetCount(timerName) __DNTimerDef##timerName.count


#else

#define DNTimerDefine(timerName)
#define DNTimerStart(timerName)
#define DNTimerEnd(timerName)
#define DNTimerGetMinTime(timerName) -1.0
#define DNTimerGetAverageTime(timerName) -1.0
#define DNTimerGetMaxTime(timerName) -1.0
#define DNTimerGetRecentTime(timerName) -1.0
#define DNTimerGetCount(timerName) -1
#define DNTimerGetStringMS(timerName) @"[TIMING DISABLED]"
#endif
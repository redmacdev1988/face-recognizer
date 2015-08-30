/*
 *  NIXDebugMacros.h
 *  
 *  Created by Peter Kolesnikov on 6/3/09.
 *  Copyright 2009 NixSolutions. All rights reserved.
 *
 */

// general debug macros
#ifdef NIX_DEBUG

#import "NIXLogManager.h"

// for uncluttered log:
#define LOG(fmt, ...) [[NIXLogManager sharedInstance] addLogStringWithMessage:fmt, ##__VA_ARGS__];

// for method logging:
#define MLOG(fmt, ...) [[NIXLogManager sharedInstance] addLogStringWithFunction:__PRETTY_FUNCTION__ line:-1 message:fmt, ##__VA_ARGS__];

// for detailed output:
#define DLOG(fmt, ...) [[NIXLogManager sharedInstance] addLogStringWithFunction:__PRETTY_FUNCTION__ line:__LINE__ message:fmt, ##__VA_ARGS__];

#define ASSERT(arg, fmt, ...) if(!(arg)) { DLOG(fmt, ##__VA_ARGS__); } assert(arg);

#define CRASH(fmt, ...) [[NSException exceptionWithName:@"FORCED CRASH!" reason:[NSString stringWithFormat:@"\nFUNCTION: %s\nLINE: %i\nREASON: %@"\
                        , __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:fmt, ##__VA_ARGS__]] userInfo:nil] raise]; 

#define BEGIN_TIMER NSDate *reftime = [NSDate date];
#define END_TIMER LOG(@"[%@ %@] elapsed = %f", self, NSStringFromSelector(_cmd), [[NSDate date] timeIntervalSinceDate:reftime]);

#else // #ifdef NIX_DEBUG

#define BEGIN_TIMER
#define END_TIMER

#define LOG(...)  
#define DLOG(...)
#define MLOG(fmt, ...)

#define ASSERT(arg, fmt, ...)

#define CRASH(fmt, ...)

#endif

//
//  NIXLogManager.m
//  RLEngine
//
//  Created by Yaroslav Motalov on 10/23/09.
//  Copyright 2009 nix. All rights reserved.
//

#import "NIXLogManager.h"
#import <unistd.h>

// This is a singleton class, see below
static NIXLogManager *sharedInstance = nil;

@implementation NIXLogManager

#pragma mark -
#pragma mark Initialization/dealloc

-(id) init {
	if ( self = [super init] ) {
		CFShow(@"NIXLogManager - init");
		stderr_desc = -1;
	}	
	return self;
}

- (void) dealloc {
	CFShow(@"NIXLogManager - dealloc");
	
	[super dealloc];
}

#pragma mark -
#pragma mark Realization

-(void)addLogStringWithMessage:(NSString*)firstObject, ... {
    va_list args;
    va_start(args, firstObject);
    NSString *tmpString = [[NSString alloc] initWithFormat:firstObject arguments:args];
    va_end(args);

	CFShow(tmpString);
	
	[tmpString release];
}

-(void)addLogStringWithFunction:(const char*)theFunctionName
							line:(NSInteger)theLine
						 message:(NSString*)firstObject, ... {
	NSMutableString *resultString;
	
	va_list args;
	va_start(args, firstObject);
	NSString *tmpString = [[[NSString alloc] initWithFormat:firstObject arguments:args] autorelease];
	va_end(args);
	
	if( theLine != -1) {
		resultString = [[NSMutableString alloc] initWithFormat:@"%s [Line %d]", theFunctionName, theLine];
	}
	else {
		resultString = [[NSMutableString alloc] initWithFormat:@"%s", theFunctionName];
	}
	
	if ( [tmpString length] ) {
		[resultString appendFormat:@" - %s", [tmpString UTF8String]];
	}


	CFShow(resultString);
	
	[resultString release];
}

-(BOOL) redirectLogToFile:(NSString*)fileName {
	if( stderr_desc == -1 && fileName ) {
		stderr_desc = dup(STDERR_FILENO);
		freopen([fileName UTF8String], "a", stderr);
		return YES;
	}
	return NO;
}

-(void) restoreLogToConsole {
	if( stderr_desc != -1 ) {
		fflush(stderr);
		dup2(stderr_desc,STDERR_FILENO);
		close(stderr_desc);
		stderr_desc = -1;
	}
}

#pragma mark -
#pragma mark Singleton object methods

// See "Creating a Singleton Instance" in the Cocoa Fundamentals Guide for more info

+(NIXLogManager *)sharedInstance {
    @synchronized(self) {
        if (sharedInstance == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedInstance;
}

+(id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

-(id)copyWithZone:(NSZone *)zone {
    return self;
}

-(id)retain {
    return self;
}

-(unsigned)retainCount {
    return UINT_MAX;  // denotes an object that cannot be released
}

-(void)release {
    //do nothing
}

-(id)autorelease {
    return self;
}

@end

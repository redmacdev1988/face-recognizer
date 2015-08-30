//
//  NIXLogManager.h
//  
//
//  Created by Yaroslav Motalov on 10/23/09.
//  Copyright 2009 nix. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Singleton class for handling logging also see NIXDebugMacros.h
@interface NIXLogManager : NSObject {
	int stderr_desc; //!< for saving strerr descriptor
}
+(NIXLogManager*)sharedInstance;

/*! After calling this method, all stderr messages will be redirected to file with given filename.
 @param fileName file to write log in
 
 @result returns YES if successful, otherwise NO */
-(BOOL)redirectLogToFile:(NSString*)fileName;

/*! Call this method to restore stderr */
-(void)restoreLogToConsole;

/*! Adds string to log.
 @param firstObject format of string
 @param ... parameters
*/
-(void)addLogStringWithMessage:(NSString*)firstObject, ...;

/*! Adds string to log.
 @param theFunctionName name of function which is calling this method. use __PRETTY_FUNCTION__
 @param theLine number of line. pass -1 if you don't want to see this.
 @param firstObject format of string
 
 @param ... parameters
*/
-(void)addLogStringWithFunction:(const char*)theFunctionName 
						   line:(NSInteger)theLine
						message:(NSString*)firstObject, ...;

@end

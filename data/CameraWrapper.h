//
//  CameraWrapper.h
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 4/16/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

//#import <opencv2/highgui/cap_ios.h> //for camera
#import "CvVideoCameraMod.h"

@interface CameraWrapper : NSObject
{
    //openCV necessities
    //CvVideoCamera * videoCamera; //openCV camera for detection, original
    CvVideoCameraMod * videoCamera;
    
    bool cameraIsCapturing;
}

//@property (nonatomic, retain) CvVideoCamera * videoCamera; //original
@property (nonatomic, retain) CvVideoCameraMod * videoCamera;

//@property (nonatomic, assign) id<CvVideoCameraDelegate> delegate; //declare a delegate to say we don't want to take care of it.
//let someone else take care of the delegate methods for CvVideoCameraMod

//initializations
-(id)init;

//hook this camera up to a UIView and assign a tag to it
-(void)setCameraView:(UIView*)parentView andTag:(int)tag;

//camera functionality
-(void)startCamera;
-(void)stopCamera;

-(void)setCvVideoCameraDelegate:(id)objThatWillProcessDelegateMethods;
@end

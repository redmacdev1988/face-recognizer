//
//  CvVideoCameraMod.h
//  prototypeClient
//
//  Created by Ricky Tsao on 2/15/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import <opencv2/highgui/cap_ios.h>


/*
 We need to extend protocl CvVideoCameraDelegateMod with its parent protocol CvVideoCameraDelegate.
we need this so that when our delegator uses
<id> CvVideoCameraDelegateMod there won't be a warning that says 
 "id<CvVideoCameraDelegateMod>" is incompatible with type id<> inherited from 'CvVideoCamera'
*/

@protocol CvVideoCameraDelegateMod <CvVideoCameraDelegate>

//-(void)photoCamera:(CvVideoCamera*)camera capturedImage:(UIImage*)newImage;
//all processImage messages is taken care of by the parent class's processImage method
@end

@interface CvVideoCameraMod : CvVideoCamera
{
    /*
    // Fps calculation
    CMTimeValue _lastFrameTimestamp;
    float *_frameTimes;
    int _frameTimesIndex;
    int _framesToAverage;
    
    float _captureQueueFps;
    float _fps;
    */
    
    AVCaptureStillImageOutput * stillImageOutput;
    
    id <CvVideoCameraDelegateMod> delegate;
    
}

@property(nonatomic, assign) id <CvVideoCameraDelegateMod> delegate;

@property(nonatomic, retain) AVCaptureStillImageOutput * stillImageOutput;
//@property (nonatomic, retain)  CALayer * customPreviewLayer;


-(id)initWithParentView:(UIView *)parent;
-(void)updateOrientation;
-(void)layoutPreviewLayer;

@end

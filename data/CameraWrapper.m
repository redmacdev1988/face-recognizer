//
//  CameraWrapper.m
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 4/16/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import "CameraWrapper.h"

@interface CameraWrapper ()

@end

@implementation CameraWrapper

@synthesize videoCamera;


-(id)init {
    
    self = [super init];
    if(self){
        cameraIsCapturing = false;
        [self util_CreateSelfCamera];
    }
    return self;
}

-(CvVideoCamera*)util_CreateSelfCamera {
    
    if(!videoCamera) {
        //autorelease the alloc, then the retain property will be removed via dealloc method's release
        
        //self. retains 1, alloc retains to 2
        self.videoCamera = [[CvVideoCameraMod alloc] init];
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
        self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetPhoto;
        self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoCamera.defaultFPS = 60;
        //cameraCaptureView.layer.borderColor = [UIColor colorWithRed:0.22 green:0.204 blue:0.192 alpha:1.0].CGColor;
        //cameraCaptureView.layer.borderWidth = 30.0f;
        
        DLOG(@"camera created!");
        return videoCamera;
        
    } else {
        DLOG(@"camera already exists!");
    }
    return nil;
}


-(void)setCameraView:(UIView*)parentView andTag:(int)tag {
   
    // Both shoot photo and video in a 4:3 fullscreen aspect ratio
    //we retain allocated image view. that image view will be deallocated after it gets added to subview
    //make sure to set AVCaptureSessionPresetPhoto for your defaultAVCaptureSessionPreset
    
    //if our video camera does not exist, let's create one
    if(videoCamera==nil) {
        
        //create videoCamera
        [self util_CreateSelfCamera];
    }
    
    //1) create the capture view
    UIImageView * cameraCaptureView = [[UIImageView alloc] initWithFrame:
                                       CGRectMake(0.0f,
                                                  0.0f,
                                                  768.0f,
                                                  1024.0f
                                                  )] ;
    cameraCaptureView.tag = tag;
    [cameraCaptureView setBackgroundColor:[UIColor blackColor]];
    
    //if the video camera was create successfully, let's start it
    if(videoCamera) {
        
        [videoCamera setParentView:cameraCaptureView];
        
        //add our capture view to our main view
        [parentView addSubview:cameraCaptureView];
        DLOG(@"SetUpCamera - Video Camera successfully set up and started..........  :)");
        
    } else {
        DLOG(@"SetUpCamera - Warning: video camera was not created.");
    }
    
    [cameraCaptureView release];
}







-(void)stopCamera {
    if(cameraIsCapturing) {
        DLOG(@"CAMERA IS CAPTURING, stopping Camera....");
        [videoCamera stop];
        cameraIsCapturing=false;
    }
}

-(void)startCamera {
    if(!cameraIsCapturing) {
        DLOG(@"NOT CAPTURING, starting Camera....");
        [videoCamera start];
        cameraIsCapturing = true;
    }
}

-(void)setCvVideoCameraDelegate:(id)objThatWillProcessDelegateMethods {
    self.videoCamera.delegate = objThatWillProcessDelegateMethods;
}

/*
#pragma mark ------------------- CvVideoCameraDelegate METHOD(S) ----------------------
//tell UIViewController to take care of processing images for us
-(void)processImage:(cv::Mat&)image
{
    DLOG(@"CameraWrapper - processImage");
    
    DLOG(@"CameraWrapper - processImage");
    if([self.videoCamera.delegate respondsToSelector:@selector(processImage:)])
    {
        [self.videoCamera.delegate processImage:image];
    }
}*/


-(void)dealloc
{
    DLOG(@"dealloc CameraWrapper");
    
    [videoCamera release]; //for the alloc
    self.videoCamera=nil; //count goes back to 0
    //0
    
    [super dealloc];
}


@end

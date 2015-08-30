//
//  CvVideoCameraMod.m
//  prototypeClient
//
//  Created by Ricky Tsao on 2/15/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import "CvVideoCameraMod.h"

#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)


@implementation CvVideoCameraMod

@synthesize stillImageOutput;
@synthesize delegate;

-(id)initWithParentView:(UIView *)parent
{
    if(self = [super initWithParentView:parent])
    {
        
    }
    return self;
}

- (void)updateOrientation
{
    //DLOG(@"Would be rotating now... but I stopped it! :)");
    customPreviewLayer.bounds = CGRectMake(0, 0, self.parentView.frame.size.width, self.parentView.frame.size.height);
    [self layoutPreviewLayer];
}

- (void)layoutPreviewLayer
{
    //DLOG(@"layout preview layer");
    if (self.parentView != nil)
    {
        CALayer* layer = customPreviewLayer;
        CGRect bounds = customPreviewLayer.bounds;
        int rotation_angle = 0;
        
        //DLOG(@"Would be rotating now... but I stopped it! :)");
        
        switch (defaultAVCaptureVideoOrientation)
        {
            case AVCaptureVideoOrientationLandscapeRight:
                rotation_angle = 90;
                break;
            case AVCaptureVideoOrientationPortraitUpsideDown:
                rotation_angle = 180;
                break;
            case AVCaptureVideoOrientationPortrait:
                //rotation_angle = 90;
                break;
            case AVCaptureVideoOrientationLandscapeLeft:
                rotation_angle = -90;
                break;
            default:
                break;
        }
        
        layer.position = CGPointMake(self.parentView.frame.size.width/2., self.parentView.frame.size.height/2.);
        layer.affineTransform = CGAffineTransformMakeRotation( DEGREES_RADIANS(rotation_angle) );
        layer.bounds = bounds;
    }
}


@end

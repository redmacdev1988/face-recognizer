//
//  MainMenuViewController.h
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 4/21/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import <UIKit/UIKit.h>


@class CameraWrapper;
@class DataModel;

@interface MainMenuViewController : UIViewController
{
    //children uiviewcontrolelrs will use only one camera
    CameraWrapper * cameraWrapper;
    
    //let's get the data model to be at this level
    DataModel * dataModel;
}

@property(nonatomic, retain) CameraWrapper * cameraWrapper;
@property(nonatomic, retain) DataModel * dataModel;

@end

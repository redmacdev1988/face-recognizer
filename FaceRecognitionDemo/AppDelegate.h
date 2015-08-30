//
//  AppDelegate.h
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 3/22/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainMenuViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    MainMenuViewController * mainMenuViewController;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) MainMenuViewController * mainMenuViewController;

@end

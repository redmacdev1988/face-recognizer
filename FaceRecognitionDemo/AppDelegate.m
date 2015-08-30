//
//  AppDelegate.m
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 3/22/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import "AppDelegate.h"
#import "MainMenuViewController.h"
#import "PortraitOnlyNavController.h"
#import "DataModel.h"

#import "FileOps.h"

@implementation AppDelegate

@synthesize mainMenuViewController;

-(void)setupAppearance {
    UIImage *minImage = [[UIImage imageNamed:@"slider_minimum.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
    UIImage *maxImage = [[UIImage imageNamed:@"slider_maximum.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
    UIImage *thumbImage = [UIImage imageNamed:@"sliderhandle.png"];
    
    [[UISlider appearance] setMaximumTrackImage:maxImage forState:UIControlStateNormal];
    [[UISlider appearance] setMinimumTrackImage:minImage forState:UIControlStateNormal];
    [[UISlider appearance] setThumbImage:thumbImage forState:UIControlStateNormal];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    //[self setupAppearance];
    
    DLOG(@"didFinishLaunchingWithOptions");
    
    // Initialize Authors View Controller
    mainMenuViewController = [[MainMenuViewController alloc] init];
    
    // Initialize Navigation Controller
    PortraitOnlyNavController * navigationController = [[PortraitOnlyNavController alloc] initWithRootViewController: mainMenuViewController];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // add the navigationController...and that's it. the view controllers are added by the nav ctrl.
    [self.window setRootViewController:navigationController];
    [self.window setBackgroundColor:[UIColor whiteColor]];
    [self.window makeKeyAndVisible];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    DLOG(@"AppDelegate.m - applicationWillResignActive");
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    DLOG(@"AppDelegate.m - applicationDidEnterBackground");
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    DLOG(@"AppDelegate.m - applicationWillEnterForeground");
}

//the structureByRef gets bind to the outside variable being passed in
-(void)test:(int&)passByRef
{
    DLOG(@"%p", &passByRef);
    passByRef = 66;
    
    int anotherInt = 243;
    passByRef = anotherInt;
    
    passByRef = *new int(6680);
}

-(void)test2:(int)passByValue {
    
    DLOG(@"%p", &passByValue);
    passByValue = 43;
}

-(void)test3:(int*)ptr {
    
    DLOG(@"%p", ptr);
    *ptr = 6680; //changes outside because we are passing a reference in
    //and having our pointer parameter point to it.
}

-(void)test4:(int*)ptr {
    
    DLOG(@"%p", ptr);
    *ptr = 6680; //changes outside because we are passing a reference in
    //and having our pointer parameter point to it.
    
    ptr = new int;
    *ptr = 243;
    
    DLOG(@"%p", ptr);
    DLOG(@"%u", *ptr);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    DLOG(@"AppDelegate.m - applicationDidBecomeActive");
    
    int variable = 897;
    
    DLOG(@"%p", &variable);
    
    [self test:variable];
    //[self test2:variable];
    
    
    DLOG(@"variable is: %u", variable);
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    DLOG(@"AppDelegate.m - applicationWillTerminate");
    
}

@end

//
//  PortraitOnlyNavController.m
//  TrainTicketiPadDemo
//
//  Created by Ricky Tsao on 4/21/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import "PortraitOnlyNavController.h"

@interface PortraitOnlyNavController ()

@end

@implementation PortraitOnlyNavController

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//we want to make navigation controller portrait only
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end

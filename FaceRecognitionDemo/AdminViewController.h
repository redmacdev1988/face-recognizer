//
//  AdminViewController.h
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 4/22/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AdminViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    UITableView * adminMenuTable;
	
	//pointer to the strings that is our main menu
	NSArray * adminMenuStrings;
    
    NSString * identity;
}

@property(nonatomic, retain) NSString * identity;
@property(nonatomic,retain) UITableView * adminMenuTable;
@property(nonatomic, retain) NSArray * adminMenuStrings;

-(id)init;
-(id)initWithIdentity:(NSString*)recognizedIdentity;


@end

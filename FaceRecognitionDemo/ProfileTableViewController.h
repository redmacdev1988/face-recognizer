//
//  ProfileTableViewController.h
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 6/11/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ProfilePickerDelegate <NSObject>
@required
-(void)selectedProfile:(NSString*)name;
@end


@interface ProfileTableViewController : UITableViewController
{
    
}

@property (nonatomic, strong) NSMutableArray * profileNames;
@property (nonatomic, retain) NSMutableArray * profileImageCounts;

@property (nonatomic, assign) id <ProfilePickerDelegate> delegate;


-(id)initWithStyle:(UITableViewStyle)style andList:(NSMutableArray*)newNames;
-(id)initWithStyle:(UITableViewStyle)style andList:(NSMutableArray*)newNames withCount:(NSMutableArray*)count;

@end

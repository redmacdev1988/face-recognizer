//
//  CustomViewBackground.h
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 5/13/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomViewBackground : UIView
{
    CGPoint startPoint;
    CGPoint endPoint;
}

-(id)initWithStartPointandRect:(CGRect)frame;

-(void)setToSecond;
-(void)setToThird;
@end

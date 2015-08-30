//
//  CustomViewBackground.m
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 5/13/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import "CustomViewBackground.h"

@implementation CustomViewBackground

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(id)initWithStartPointandRect:(CGRect)frame
{
    self = [self initWithFrame:frame];
    
    if(self){
        
        //startPoint = CGPointMake(start.x, start.y); //CGPointMake(0.0f, self.bounds.size.height);
        //endPoint = CGPointMake(self.bounds.size.width, 0.0f );//CGPointMake(end.x, end.y);
        startPoint = CGPointMake(0.0f, self.bounds.size.height);
        endPoint = CGPointMake(self.bounds.size.width, 0.0f);
    }
    
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    DLOG(@"CustomView: drawRect");
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    /*
    UIColor * redColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    
    CGContextSetFillColorWithColor(context, redColor.CGColor);
    CGContextFillRect(context, self.bounds);
    */
    UIColor * blueColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
    
    // START NEW
    CGRect paperRect = self.bounds;
    //DLOG(@"self.bounds x = %f, y = %f, width = %f, height = %f", self.bounds.origin.x, self.bounds.origin.y,
    //     self.bounds.size.width, self.bounds.size.height);
    
    CGRect strokeRect = CGRectInset(paperRect, 0.0, 0.0); //the border goes in or out
    CGContextSetStrokeColorWithColor(context, blueColor.CGColor);
    CGContextSetLineWidth(context, 10.0); //border
    CGContextStrokeRect(context, strokeRect);
    // END NEW
    
    /*
    UIColor * greenColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, greenColor.CGColor);
    CGContextSetLineWidth(context, 5.0);
    CGContextMoveToPoint(context, startPoint.x + 0.5, startPoint.y + 0.5);
    CGContextAddLineToPoint(context, endPoint.x + 0.5, endPoint.y + 0.5);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
     */
}

-(void)setToSecond
{
    startPoint = CGPointMake(self.bounds.size.width/2, self.bounds.size.height);
    endPoint = CGPointMake(self.bounds.size.width, 0.0f);
}

-(void)setToThird
{
    startPoint = CGPointMake(self.bounds.size.width, self.bounds.size.height);
    endPoint = CGPointMake(self.bounds.size.width, 0.0f);
}

@end

//
//  ANPopoverSlider.h
//  CustomSlider
//
//  Created by Gabriel  on 30/1/13.
//  Copyright (c) 2013 App Ninja. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ANPopoverView.h"

@protocol SliderDelegate <NSObject>
-(void)updateSliderValue:(float)value;
@end

@interface ANPopoverSlider : UISlider <SliderDelegate>
{
    

}

@property(nonatomic, assign) id <SliderDelegate> delegate;

@property (strong, nonatomic) ANPopoverView *popupView;

@property (nonatomic, readonly) CGRect thumbRect;

@end


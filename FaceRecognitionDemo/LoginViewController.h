
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ADVRoundProgressView.h"
#import "ANPopoverSlider.h"
#import "FileOps.h"
#import "iCarousel.h"
#import "CameraWrapper.h"
#import "DataModel.h"



@interface LoginViewController : UIViewController
<
UpdateViewDelegate,
UITextViewDelegate,
UIActionSheetDelegate,
SliderDelegate
>
{
    //data model
    CameraWrapper * loginCameraWrapper;
    DataModel * loginDataModel;
    
    //utility
    float approvalProgressValue;
    NSString * identityName;
    
    
    
    //timer to decrement the recognition percentage
    NSTimer * timer;
    int seconds;
    int secondsLeft;
}

//DATA MODEL
@property(nonatomic, retain) CameraWrapper * loginCameraWrapper;
@property(nonatomic, retain) DataModel * loginDataModel;

@property(nonatomic, retain) NSString * identityName;




//init
-(id)initWithCamera:(CameraWrapper*)newCamera andThreshold:(float)threshold;
-(id)initWithCamera:(CameraWrapper*)newCamera andDataModel:(DataModel*)model andThreshold:(float)threshold;

//timer
-(void)updateCounter:(NSTimer *)theTimer;
-(void)countdownTimer;

@end


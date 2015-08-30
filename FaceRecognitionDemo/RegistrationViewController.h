
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "ADVRoundProgressView.h"
#import "ANPopoverSlider.h"
#import "FileOps.h"
#import "iCarousel.h"
#import "CameraWrapper.h"
#import "DataModel.h"
#import "ProfileTableViewController.h"


@interface RegistrationViewController : UIViewController
<
UpdateViewDelegate,
UITextViewDelegate,
iCarouselDataSource, iCarouselDelegate,
UIActionSheetDelegate,
//SliderDelegate,
ProfilePickerDelegate,
CLLocationManagerDelegate
>
{
    //data model
    CameraWrapper * registerCameraWrapper;
    DataModel * registerDataModel;
    
    //views
    bool allFacesVisible;
    bool infoViewVisible;
    bool dashboardVisible;
    
    
    //for iCarousel
    iCarousel *carousel;
    UINavigationItem *navItem;
    BOOL wrap;
    NSMutableArray *items;
    
    //profiles inserted so far
    NSMutableArray * profileArray;
    
    //count
    NSMutableArray * profileImageCountArray;
    
    bool appendToExistingProfile;
    
    //training phase
    short phase;
    
    bool collectBox;
}

//DATA MODEL
@property(nonatomic, retain) CameraWrapper * registerCameraWrapper;
@property(nonatomic, retain) DataModel * registerDataModel;


-(void)showPopover:(id)sender;

-(id)init;
-(id)initWithCamera:(CameraWrapper*)newCamera;
-(id)initWithCamera:(CameraWrapper*)newCamera andDataModel:(DataModel*)model;

@end


//
//  MainMenuViewController.m
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 4/21/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import "MainMenuViewController.h"
#import "LoginViewController.h"
#import "RegistrationViewController.h"

#import "DataModel.h"

#define BORDER_BROWN [UIColor colorWithRed:0.306 green:0.118 blue:0.031 alpha:1.0]

#define UIIMAGEVIEW_CAMERA 999

#define UNKNOWN_PERSON_THRESHOLD 0.16


@interface MainMenuViewController ()
@end

@implementation MainMenuViewController

@synthesize cameraWrapper;
@synthesize dataModel;

#pragma mark ------------------- VIEW LIFE CYCLE ----------------------

-(void)dealloc{
    
    DLOG(@"MainMenuViewController - dealloc ");
    
    [cameraWrapper release];
    self.cameraWrapper=nil;
     DLOG(@"--------- CAMERA dealloced...");
    
    [self.dataModel release];
    self.dataModel=nil;
    DLOG(@"------------- DATA MODEL dealloced...");
    
    [super dealloc];
}

- (id)init {
    
    self = [super init];
    if (self) {
        DLOG(@"MainMenuViewController - init");
        // Custom initialization
        
        self.cameraWrapper = [[CameraWrapper alloc] init];
        //[cameraWrapper CreateSelfCamera];
        
        DLOG(@"+++++++++++ CAMERA created...");
        
        //our retained data model gets passed into uiviewcontroller's
        self.dataModel = [[DataModel alloc] init]; //autorelease this alloc
        DLOG(@"+++++++++++++++ DATA MODEL created...");
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    
    DLOG(@"MainMenuViewController - didReceiveMemoryWarning");
    [super didReceiveMemoryWarning];
    
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}




-(void)util_createUIButtonWithTagId:(int)buttonId
                            andRect:(CGRect)rect
                      andMethodName:(NSString*)methodName
                      andNormalImg:(NSString*)normImg
                    andHighlightImg:(NSString*)highImg
                      andParentView:(UIView*)parent {
    
    UIButton * btn = [UIButton buttonWithType: UIButtonTypeCustom]; //auto-released
    
    btn.userInteractionEnabled = YES;
    btn.frame = rect;
    
    [btn.titleLabel setFont:[UIFont boldSystemFontOfSize:12.0f]];
    
    //sets background image for normal state
    [btn setBackgroundImage:[UIImage imageNamed:
                                  normImg]
                        forState:UIControlStateNormal];
    
    //sets background image for highlighted state
    [btn setBackgroundImage:[UIImage imageNamed:
                                  highImg]
                        forState:UIControlStateHighlighted];
    
    
    [btn addTarget:self
               action:NSSelectorFromString(methodName)
     forControlEvents:UIControlEventTouchDown];
    
    
    [btn setBackgroundColor:[UIColor clearColor]];
    
    // For the border and rounded corners
    [[btn layer] setBorderColor:[BORDER_BROWN CGColor]];
    [[btn layer] setBorderWidth:5];
    [[btn layer] setCornerRadius:15];
    [btn setClipsToBounds: YES];
    [parent addSubview: btn];
    
}

- (void)viewDidLoad {
    
    DLOG(@"MainMenuVieWcontroller.m - viewDidLoad");
    [super viewDidLoad];
    
    
    [self util_createUIButtonWithTagId:nil andRect:CGRectMake((768 - 512)/3, 256.0f, 256.0f, 256.0f)
                         andMethodName:@"loginPage"
                          andNormalImg:@"login-blue.png"
                       andHighlightImg:@"login-highlighted.png"
                         andParentView:self.view];
    
    [self util_createUIButtonWithTagId:nil
                               andRect:CGRectMake(2*(768 - 512)/3 + 256.0f , 256.0f, 256.0f, 256.0f)
                         andMethodName:@"registerPage"
                          andNormalImg:@"register-green.png"
                       andHighlightImg:@"register-highlighted.png"
                         andParentView:self.view];
    
    
    
    ////////////////////////////////////////////////////////////////////////////
    UIButton * ordersBtn = [UIButton buttonWithType: UIButtonTypeCustom]; //auto-released
    
    ordersBtn.userInteractionEnabled = YES;
    ordersBtn.frame = CGRectMake( (768 - 512)/3 , 2*256.0f + (768 - 512)/3,
                                 256.0f, 256.0f);
    [ordersBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:12.0f]];
    
    //sets background image for normal state
    [ordersBtn setBackgroundImage:[UIImage imageNamed:
                                   @"order-red.png"]
                         forState:UIControlStateNormal];
    
    //setsbordersBtnbackground image for highlighted state
    [ordersBtn setBackgroundImage:[UIImage imageNamed:
                                   @"order-red.png"]
                         forState:UIControlStateHighlighted];
    
    
    [ordersBtn addTarget:self action: @selector(orderPage) forControlEvents: UIControlEventTouchUpInside];
    [ordersBtn setBackgroundColor:[UIColor clearColor]];
    
    // For the border and rounded corners
    [ordersBtn setClipsToBounds: YES];
    
    [[ordersBtn layer] setCornerRadius:15];
    ordersBtn.layer.borderWidth = 5;
    ordersBtn.layer.borderColor = [BORDER_BROWN CGColor];
    [self.view addSubview: ordersBtn];
    ////////////////////////////////////////////////////////////////////////////
    
    
    ////////////////////////////////////////////////////////////////////////////
    UIButton * managementBtn = [UIButton buttonWithType: UIButtonTypeCustom]; //auto-released
    
    managementBtn.userInteractionEnabled = YES;
    managementBtn.frame = CGRectMake( 2*(768 - 512)/3 + 256.0f , 2*256.0f + (768 - 512)/3,
                                     256.0f, 256.0f);
    [managementBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:12.0f]];
    
    //sets background image for normal state
    [managementBtn setBackgroundImage:[UIImage imageNamed:
                                       @"management.png"]
                             forState:UIControlStateNormal];
    
    //setsbordersBtnbackground image for highlighted state
    [managementBtn setBackgroundImage:[UIImage imageNamed:
                                       @"management.png"]
                             forState:UIControlStateHighlighted];
    
    [managementBtn addTarget:self action: @selector(managementPage) forControlEvents: UIControlEventTouchUpInside];
    [managementBtn setBackgroundColor:[UIColor clearColor]];
    
    // For the border and rounded corners
    [managementBtn setClipsToBounds: YES];
    
    [[managementBtn layer] setCornerRadius:15];
    managementBtn.layer.borderWidth = 5;
    managementBtn.layer.borderColor = [BORDER_BROWN CGColor];
    [self.view addSubview: managementBtn];
    
    ////////////////////////////////////////////////////////////////////////////

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"wood-ipad-wp.jpg"]];
	// Do any additional setup after loading the view.
}

#pragma mark ------------------- button responders ----------------------
-(void)loginPage
{
    DLOG(@"MainMenuViewController - loginPage");
    
    LoginViewController * loginPage =
    //[[LoginViewController alloc] initWithCamera:cameraWrapper andThreshold: UNKNOWN_PERSON_THRESHOLD];
    [[LoginViewController alloc] initWithCamera:cameraWrapper andDataModel:dataModel andThreshold:UNKNOWN_PERSON_THRESHOLD];
    
    [self.navigationController pushViewController:loginPage animated:YES];
    [loginPage release];
}

-(void)registerPage
{
    DLOG(@"MainMenuViewController.m - RegisterPage");
    
    unsigned long totalFaces = [dataModel getTotalFaces];
    unsigned long numOfProfiles = [dataModel getNumOfProfiles];
    
    DLOG(@"currently in our data model: there are %lu total faces...and %lu profiles", totalFaces, numOfProfiles);
    
    RegistrationViewController * registerPage =
    [[RegistrationViewController alloc] initWithCamera:cameraWrapper andDataModel:dataModel];
    
    [self.navigationController pushViewController:registerPage animated:YES];
    [registerPage release];
}

-(void)managementPage{
    DLOG(@"managementPage");
}

-(void)orderPage{
    DLOG(@"orderPage");

}
						
@end

//
//  ViewController.m
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 3/22/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import "LoginViewController.h"
#import "AdminViewController.h"

const int SECONDS_FOR_PROGRESS_DECREMENT = 1;
int m_selectedPerson = 0;

#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

#define UIIMAGEVIEW_CAMERA_CAPTUREVIEW 100
#define UIBUTTON_COLLECT_FACES 101
#define UIIMAGEVIEW_MALEFACE1 102
#define UIIMAGEVIEW_BIN 103
#define UILABEL_COLLECTED_FACES 104
#define UIBUTTON_RESET 105
#define UIBUTTON_TRAIN 106
#define UIBUTTON_RECOGNIZE 107
#define UIIMAGEVIEW_TRAININGBIN 108
#define UIIMAGEVIEW_RECOGNIZE_EYE 109

#define UITEXTVIEW_LOG 110
#define MY_PROGRESSVIEW 111
#define CUSTOM_ROUND_PROGRESSVIEW 112
#define UIBUTTON_ADD_FACE 113
#define UIBUTTON_REMOVE_FACE 114
#define UIBUTTON_SHOW_FACES 115
#define UIBUTTON_SAVE_DISK 116
#define UIBUTTON_LOAD_DISK 117
#define UIVIEW_CAROUSEL 118


#define UIBUTTON_THRESHOLD 120
#define CUSTOM_SLIDER_THRESHOLD 121
#define UIIMAGEVIEW_MASK 122
#define UILABEL_FACE_SCORE 123
#define UILABEL_THRESHOLD 124

#define UILABEL_FACE_IDENTITY 125

#define HAPPY_FACE @"~(^!^)~"

@interface LoginViewController ()

@end

@implementation LoginViewController

//model
@synthesize loginCameraWrapper;
@synthesize loginDataModel;

@synthesize identityName;



#pragma mark ------------------- VIEW LIFE CYCLE ----------------------


-(void)dealloc
{
    DLOG(@"dealloc start");
    
    //dont' remove data structure
    //[self resetAll:nil];
    
    DLOG(@"dealloc - removing observers");
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [loginCameraWrapper setCvVideoCameraDelegate:nil];
    self.loginCameraWrapper = nil;
    DLOG(@"camera cleaned...............ok!");
    
    self.loginDataModel.delegate = nil;
    self.loginDataModel = nil;
    DLOG(@"data model cleaned..........ok!");
    
    DLOG(@"dealloc complete..... %@", HAPPY_FACE);
    [super dealloc];
}

- (id)init{
    DLOG(@"LoginViewController.m - init - start");
    self = [super init];
    if (self)
    {
        //the data model
        
        self.identityName = @"";
    }
    return self;
}

-(id)initWithCamera:(CameraWrapper*)newCamera
{
    self=[self init];
    if(self)
    {
        self.loginCameraWrapper = newCamera; //retains outside camera
        [self.loginCameraWrapper setCvVideoCameraDelegate:self]; //set the Video Camera delegate
    }
    return self;
}

-(id)initWithCamera:(CameraWrapper*)newCamera andThreshold:(float)threshold
{
    self=[self initWithCamera:newCamera];
    if(self)
    {
        //set the new incoming threshold
        [self.loginDataModel setThreshold:threshold];
    }
    return self;
}

-(id)initWithCamera:(CameraWrapper*)newCamera andDataModel:(DataModel*)model andThreshold:(float)threshold
{
    //set the camera
    self=[self initWithCamera:newCamera];
    if(self)
    {
        //retain the outside data model
        self.loginDataModel = model;
        self.loginDataModel.delegate = self;
        
        //set the new incoming threshold
        [self.loginDataModel setThreshold:threshold];
    }
    return self;
}



- (void)viewDidLoad
{
    DLOG(@"LoginViewController.m - viewDidLoad");
    [super viewDidLoad];
    
    DLOG(@"HOME > %@", NSHomeDirectory());
    
    DLOG(@"viewDidLoad - observers added");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    approvalProgressValue = 0.0f;

    [self.loginCameraWrapper setCameraView:self.view andTag:UIIMAGEVIEW_CAMERA_CAPTUREVIEW];
    
    //recognize button
    [self addButtonToView:self.view
                  withTag:UIBUTTON_RECOGNIZE
                withTitle:nil
                 withRect:CGRectMake(600.0f, 900.0f, 0.0f, 0.0f)
           withMethodName:@"toggleRecognize:"
            withImageName:@"recognize.png"
    withSelectedImageName:@"recognize-selected.png"];

    
    UIColor *tintColor = [UIColor colorWithRed:0.03f green:0.64f blue:0.83f alpha:1.00f];
    ADVRoundProgressView * roundProgressLarge = [[ADVRoundProgressView alloc]
                             initWithFrame:CGRectMake(520.0f, 900.0f - 220.0f, 180.0f, 180.0f)];
    roundProgressLarge.tag = CUSTOM_ROUND_PROGRESSVIEW;
    
    [[ADVRoundProgressView appearance] setTintColor:tintColor];
    [self.view addSubview:roundProgressLarge];
    roundProgressLarge.progress = 0.0;
    roundProgressLarge.alpha = 0.0f;
    [roundProgressLarge release];
    
    [self createANSliderWithTag:CUSTOM_SLIDER_THRESHOLD
                 withMethodName:@"updateSliderValue:"
                  andParentView:self.view];
    
    //create mask so that users can align their faces properly
    UIImage * maskImg = [UIImage imageNamed:@"crosshair.png"];
    UIImageView * mask = [[UIImageView alloc] initWithImage:maskImg];
    [mask setFrame:CGRectMake((768.0f-maskImg.size.width)/2,
                              (1024.0f-maskImg.size.height)/2,
                              maskImg.size.width, maskImg.size.height)];
    mask.tag = UIIMAGEVIEW_MASK;
    mask.alpha = 0.5f;
    [self.view addSubview:mask];
    [mask release];
    
    //create similarity label to show what we are getting when evaluating face
    UILabel * faceScoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(400.0f, 70.0f, 460.0f, 160.0f)];
    faceScoreLabel.tag = UILABEL_FACE_SCORE;
	[faceScoreLabel setBackgroundColor: [UIColor clearColor]];
	faceScoreLabel.font = [UIFont fontWithName: @"Georgia" size: 140];
    faceScoreLabel.textAlignment = NSTextAlignmentLeft;
    faceScoreLabel.lineBreakMode = NSLineBreakByWordWrapping;
    faceScoreLabel.numberOfLines = 0;
	faceScoreLabel.text = @"NA";
    [faceScoreLabel setTextColor:[UIColor lightGrayColor]];
    faceScoreLabel.alpha = 0.6f;
	[self.view addSubview: faceScoreLabel];
	[faceScoreLabel release];

    UILabel * thresholdLabel = [[UILabel alloc] initWithFrame:CGRectMake(768-460.0f, 270.0f, 460.0f, 160.0f)];
    thresholdLabel.tag = UILABEL_THRESHOLD;
	[thresholdLabel setBackgroundColor: [UIColor clearColor]];
	thresholdLabel.font = [UIFont fontWithName: @"Georgia" size: 140];
    thresholdLabel.textAlignment = NSTextAlignmentCenter;
    thresholdLabel.lineBreakMode = NSLineBreakByWordWrapping;
    thresholdLabel.numberOfLines = 0;
	thresholdLabel.text = [NSString stringWithFormat:@"%.2f",loginDataModel.threshold];
    [thresholdLabel setTextColor:[UIColor orangeColor]];
    thresholdLabel.alpha = 1.0f;
	[self.view addSubview: thresholdLabel];
	[thresholdLabel release];
    
    UILabel * faceIdentityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 40.0f, 500.0f, 100.0f)];
    faceIdentityLabel.tag = UILABEL_FACE_IDENTITY;
	[faceIdentityLabel setBackgroundColor: [UIColor clearColor]];
	faceIdentityLabel.font = [UIFont fontWithName: @"Georgia" size: 68.0f];
    faceIdentityLabel.textAlignment = NSTextAlignmentLeft;
    faceIdentityLabel.lineBreakMode = NSLineBreakByWordWrapping;
    faceIdentityLabel.numberOfLines = 0;
	faceIdentityLabel.text = @"id:";
    [faceIdentityLabel setTextColor:[UIColor greenColor]];
    faceIdentityLabel.alpha = 1.0f;
	[self.view addSubview: faceIdentityLabel];
	[faceIdentityLabel release];

}


-(void)makeLoginUIAppear
{
    [self animateViewAlpha:self.view withTag:CUSTOM_ROUND_PROGRESSVIEW andDuration:0.2f andAlpha:1.0f];
    [self animateViewAlpha:self.view withTag:CUSTOM_SLIDER_THRESHOLD andDuration:0.2f andAlpha:1.0f];
    [self animateViewAlpha:self.view withTag:UIBUTTON_RECOGNIZE andDuration:0.2f andAlpha:1.0f];
}

-(void)viewWillAppear:(BOOL)animated
{
    DLOG(@"viewWillAppear - arriving LoginViewController...");
    [super viewWillAppear:animated];
    
    UIButton * recognizeBtn = (UIButton*)[self.view viewWithTag:UIBUTTON_RECOGNIZE];
    [recognizeBtn setAlpha:1.0f];
    
    [loginDataModel setModeToDetection];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    if(!loginCameraWrapper.videoCamera.running){
        [self.loginCameraWrapper startCamera];
        [self.loginCameraWrapper setCvVideoCameraDelegate:self];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.loginDataModel setModeToStop];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}
 
-(void)viewDidDisappear:(BOOL)animated
{
    DLOG(@"viewWillDisappear - leaving LoginViewController");   
    [super viewDidDisappear:animated];
    
    if(self.loginCameraWrapper.videoCamera.running){
        [self.loginCameraWrapper stopCamera];
        [self.loginCameraWrapper setCvVideoCameraDelegate:nil];
        DLOG(@"camera stopped, and CvVidoeCamera delegate niled");
    }
}

- (void)didReceiveMemoryWarning
{
     DLOG(@"LoginViewController - didReceiveMemoryWarning");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark ------------------- BUTTON RESPONDER(S) ----------------------


-(void)toggleRecognize:(id)sender
{
    UIButton * btn = (UIButton*)sender;
    
    if(btn.selected) //TURN RECOGNITION OFF
    {
        if([timer isValid])
        {
            DLOG(@"invalidate and nil timer");
            [timer invalidate]; timer=nil;
        }
        
        //animate progress bar off
        [self animateViewAlpha:self.view withTag:CUSTOM_ROUND_PROGRESSVIEW andDuration:0.2f andAlpha:0.0f];
        [self animateViewAlpha:self.view withTag: CUSTOM_SLIDER_THRESHOLD andDuration:0.2f andAlpha:0.0f];
        
        [btn setSelected:NO];
        
        UIImageView * recognizeEyeView = (UIImageView*)[self.view viewWithTag:UIIMAGEVIEW_RECOGNIZE_EYE];

        CATransform3D myTransform = [(CALayer*)[recognizeEyeView.layer presentationLayer] transform];
        [[recognizeEyeView layer] removeAnimationForKey:@"rotateAnimation"];
        [[recognizeEyeView layer] setTransform:myTransform];
        
        recognizeEyeView.alpha = 0.2f;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            ADVRoundProgressView * progressBar = (ADVRoundProgressView*)[self.view viewWithTag:CUSTOM_ROUND_PROGRESSVIEW];
            progressBar.progress = 0.0f;
            approvalProgressValue = 0.0f;
        });
        
        [loginDataModel setModeToDetection];
    }
    else //TURN RECOGNITION ON
    {
        secondsLeft = SECONDS_FOR_PROGRESS_DECREMENT;
        [self countdownTimer];
        
        //animate progress bar on
        //[self animateProgressBarOn];
        [self animateViewAlpha:self.view withTag:CUSTOM_ROUND_PROGRESSVIEW andDuration:0.2f andAlpha:1.0f];
        [self animateViewAlpha:self.view withTag:CUSTOM_SLIDER_THRESHOLD andDuration:0.2f andAlpha:1.0f];
        
        [btn setSelected:YES];
        
        if([loginDataModel modelIsValid])
        {
            UIImageView * recognize_eye = (UIImageView*)[self.view viewWithTag:UIIMAGEVIEW_RECOGNIZE_EYE];
            
            CABasicAnimation * rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
            rotateAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            rotateAnimation.fromValue = [NSNumber numberWithFloat:0];
            rotateAnimation.toValue = [NSNumber numberWithFloat:((360*M_PI)/180)];
            rotateAnimation.repeatCount = HUGE_VALF;
            rotateAnimation.duration = 4.0;
            rotateAnimation.removedOnCompletion = NO;
            rotateAnimation.fillMode = kCAFillModeForwards;
            rotateAnimation.autoreverses = NO;
   
            [[recognize_eye layer] addAnimation:rotateAnimation forKey:@"rotateAnimation"];
            
            recognize_eye.alpha = 1.0f;
            [loginDataModel setModeToRecognition];
        }
        //put a scrollbar
    }
}




-(void)resetAll:(id)sender
{
    DLOG(@"button pushed reset all");
    
    m_selectedPerson = 0;
    [loginDataModel resetAll];
    
    UILabel * numOfFacesLabel = (UILabel*)[self.view viewWithTag:UILABEL_COLLECTED_FACES];
    NSString * strNumber = [NSString stringWithFormat:@"%lu",[loginDataModel getTotalFaces]];
    [numOfFacesLabel setText:strNumber];

    DLOG(@"data reset success 数据复位成功...............%@", HAPPY_FACE);
  
    // Restart in Detection mode.
    [loginDataModel setModeToDetection];
}


#pragma mark ------------------- UI UTILITY METHOD(S) ----------------------
-(void)addButtonToView: (UIView*)parentView
               withTag:(int)tag
             withTitle:(NSString*)titleString
              withRect:(CGRect)rect
        withMethodName:(NSString*)methodName
         withImageName:(NSString*)imageName
 withSelectedImageName:(NSString*)selectedImageName
{
    UIButton * button = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    
    UIImage * img = [UIImage imageNamed:imageName];
    
    //make the rect take on the size of the image
    rect.size.width = img.size.width;
    rect.size.height = img.size.height;
    [button setFrame:rect];
    
    [button setImage:img forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:selectedImageName] forState:UIControlStateSelected];
    [button setImage:[UIImage imageNamed:selectedImageName] forState:UIControlStateHighlighted];
    button.contentMode = UIViewContentModeScaleToFill;
    
    button.tag = tag;
    
    //[button sizeToFit];
    [button addTarget:self
               action:NSSelectorFromString(methodName)
     forControlEvents:UIControlEventTouchDown];
    
    [parentView addSubview:button];
    
    [button release];
}


-(void)createANSliderWithTag:(int)tag
              withMethodName:(NSString*)methodName
               andParentView:(UIView*)parentView
{
    ANPopoverSlider * mySlider = [[ANPopoverSlider alloc] initWithFrame:CGRectMake(500.0f, 640.0f, 200.0f, 25.0f)];
    mySlider.tag = tag;
    mySlider.delegate = self;
    mySlider.alpha = 0.0f;
    
    mySlider.minimumValue = 0.0f;
    //set the maximum value
    mySlider.maximumValue = 100.0f;
    //set the initial value
    mySlider.value = loginDataModel.threshold * 100.0f;
    
    //set this to true if you want the changes in the sliders value
    //to generate continuous update events
    [mySlider setContinuous:false];
    
    [mySlider addTarget:self
                 action:NSSelectorFromString(methodName)
       forControlEvents:UIControlEventTouchDown];
    
    //add the slider to the view
    [parentView addSubview:mySlider];
    
    [mySlider release];
}


#pragma mark ------------------- NSTimer utility method(s) ----------------------
- (void)updateCounter:(NSTimer *)theTimer
{
    DLOG(@"updateCounter");
    
    if(secondsLeft > 0 ){
        secondsLeft-- ;
        
        seconds = (secondsLeft %3600) % 60;
        //myCounterLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
        
        DLOG(@"%d", seconds);
        
        if(seconds == 0){
            DLOG(@"decrement our progress!!");
            if(approvalProgressValue > 0.0f )
                approvalProgressValue-=0.05f;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                ADVRoundProgressView * progressBar = (ADVRoundProgressView*)[self.view viewWithTag:CUSTOM_ROUND_PROGRESSVIEW];
                progressBar.progress = approvalProgressValue;
            });
        }
    }
    else{
        secondsLeft = SECONDS_FOR_PROGRESS_DECREMENT;
    }
}

-(void)countdownTimer{
    
    DLOG(@"countdownTimer");
    secondsLeft = seconds = 0;
    
    if(timer!=nil)
    {
        DLOG(@"timer is valid, let's release it ...and then create another one");
        [timer invalidate]; timer=nil;
        //[timer release]; //gets auto-released in the pool
    }
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateCounter:) userInfo:nil repeats:YES];
    [pool release];
}

#pragma mark ------------------- slider utility method(s) ----------------------

-(void)updateSliderValue:(float)value
{
    DLOG(@"updateSliderValue");
    loginDataModel.threshold = value/100;
    
    if((loginDataModel.threshold < 0) || ( loginDataModel.threshold > 1.0f)) return;
    
    UILabel * thresholdLabel = (UILabel*)[self.view viewWithTag:UILABEL_THRESHOLD];
    dispatch_async(dispatch_get_main_queue(), ^{
        DLOG(@"Threshold changed to: %.2f", value/100);
        [thresholdLabel setText:[NSString stringWithFormat:@"%.2f", loginDataModel.threshold]];
    });
}


#pragma mark ------------------- animation utility method(s) ----------------------


//animates view to appear or disappear with alpha
-(void)animateViewAlpha:(UIView*)theView withTag:(int)tag andDuration:(float)duration andAlpha:(float)alpha
{
    UIView * view = [theView viewWithTag:tag];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:duration];
    
    [view setAlpha:alpha];
    [UIView commitAnimations];
}

//animates a view to move to and from a rect
-(void)animateViewRect:(UIView*)theView withRect:(CGRect)rect withTag:(int)tag andDuration:(float)duration
{
    UIView * view = (UITextView*)[theView viewWithTag:tag];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:duration];
    
    [view setFrame:rect];
    [UIView commitAnimations];
}




#pragma mark ------------------- observer method(s) ----------------------

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    DLOG(@"applicationDidEnterBackground - start");
    [loginCameraWrapper stopCamera];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    DLOG(@"applicationDidBecomeActive - start");
    [loginCameraWrapper startCamera];
}

#pragma mark ------------------- orientation method(s) ----------------------

//we want to make navigation controller portrait only
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark ------------------- CvVideoCameraDelegate method(s) ----------------------
- (void)processImage:(cv::Mat&)image
{
    [loginDataModel ProcessFace:image];
}

#pragma mark ------------------- UpdateViewDelegate delegate methods ----------------------

-(void)showMessageBox:(NSString*)title andMessage:(NSString*)msg andCancelTitle:(NSString*)cancelTitle
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView * warn = [[UIAlertView alloc] initWithTitle:title
                                                        message:msg
                                                       delegate:self
                                              cancelButtonTitle:cancelTitle
                                              otherButtonTitles:nil];
        [warn show]; [warn release];
    });
}

-(void)showSimilarity:(float)similarity
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel * faceScore = (UILabel*)[self.view viewWithTag:UILABEL_FACE_SCORE];
        faceScore.text = (similarity > 1.0f) ? @"NA":[NSString stringWithFormat:@"%.2f", similarity];
    });
}


-(void)showIdentityInt:(int)identity andName:(NSString *)name
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UILabel * identityLabel = (UILabel*)[self.view viewWithTag:UILABEL_FACE_IDENTITY];
        identityLabel.text = [NSString stringWithFormat:@"id: %u, %@",identity, name];
        
        identityName = identityLabel.text;
    });
}

- (void)incrementIdentityValue:(float)similarity
{
    //we only increment if its less than 100
    if(approvalProgressValue < 1.0f) {
        
        approvalProgressValue +=0.02f;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            ADVRoundProgressView * progressBar = (ADVRoundProgressView*)[self.view viewWithTag:CUSTOM_ROUND_PROGRESSVIEW];
            progressBar.progress = approvalProgressValue;
        });
    }
    else {
        if(approvalProgressValue >= 1.0f) {
            //stop our model's recognition
            [loginDataModel setModeToDetection];
            
            if([timer isValid])
            {
                [timer invalidate];
                timer=nil;
            }
            
            DLOG(@"APPROVED!");

            dispatch_async(dispatch_get_main_queue(), ^{
                //[self goToPrivateSection:identityName];
                [self showMessageBox:@"profile" andMessage:[NSString stringWithFormat:@"%@", [loginDataModel getRecognizedPerson]] andCancelTitle:@"ok"];
                [loginDataModel emptyRecognitionCount];
                
            });
            
        }
    }
}

-(void)goToPrivateSection:(NSString*)personID
{
    DLOG(@"opening door for: %@", personID);
    
    //go to purchase ticket window
    //  AdminViewController * adminController = [[AdminViewController alloc] init];
    
    
    
    AdminViewController * adminController = [[AdminViewController alloc] initWithIdentity:personID];
    [self.navigationController pushViewController:adminController animated:YES];
    [adminController release];
}

-(void)updateNumOfFacesLabel:(NSString*)strNumber{
    UILabel * numOfFacesLabel = (UILabel*)[self.view viewWithTag:UILABEL_COLLECTED_FACES];
    dispatch_async(dispatch_get_main_queue(), ^{
        [numOfFacesLabel setText:strNumber];
    });
}


-(void)animateTraining:(bool)flag
{
    if(!flag) //if false, we stop animation
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImageView * trainingBinView = (UIImageView*)[self.view viewWithTag:UIIMAGEVIEW_TRAININGBIN];
            [[trainingBinView layer] removeAnimationForKey:@"animatePulse"];
            trainingBinView.alpha = 0.2f;
        });
    }
    else //if true, we begin animation
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImageView * trainingBinView = (UIImageView*)[self.view viewWithTag:UIIMAGEVIEW_TRAININGBIN];
            CABasicAnimation * binPulseAnimation;
            binPulseAnimation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
            binPulseAnimation.duration=0.1;
            binPulseAnimation.repeatCount=HUGE_VALF;
            binPulseAnimation.autoreverses=YES;
            binPulseAnimation.fromValue=[NSNumber numberWithFloat:1.0];
            binPulseAnimation.toValue=[NSNumber numberWithFloat:0.9];
            [[trainingBinView layer] addAnimation:binPulseAnimation forKey:@"animatePulse"];
            trainingBinView.alpha = 1.0f;
        });
    }
}

-(void)setRecognizeButton:(bool)flag
{
    DLOG(@"LoginViewController.m - setRecognizeButton");
    UIButton * recognizeBtn = (UIButton*)[self.view viewWithTag:UIBUTTON_RECOGNIZE];
    DLOG(flag ? @"Yes" : @"No");
    
    if(flag) //turn the button on....as we are done.
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            DLOG(@"setRecognizeButton-------------------------> turning RECOGNIZE button ON");
            [recognizeBtn setEnabled:YES];
            [recognizeBtn setUserInteractionEnabled:YES];
            recognizeBtn.alpha = 1.0f;
        });
    }
    else //turn it OFF because we are currently training....
    {
         dispatch_async(dispatch_get_main_queue(), ^{
            DLOG(@"setRecognizeButton-----------------------------> turning RECOGNIZE button off");
            [recognizeBtn setEnabled:NO];
            recognizeBtn.alpha = 0.2f;
        });
    }

}


@end

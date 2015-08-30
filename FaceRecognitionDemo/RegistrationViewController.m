//
//  ViewController.m
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 3/22/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//


#import "RegistrationViewController.h"
#import "CustomViewBackground.h"
#import "ProfileTableViewController.h"

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
#define UIBUTTON_INFO 123

#define UIBUTTON_COLLECT_FACES_INTERVAL 124
#define CUSTOM_LINE 125
#define UILABEL_ALIGN_TEXT 126
#define UIVIEW_DIRECTIONS_WINDOW 127
#define UIBUTTON_STARTOVER 128
#define UITEXTFIELD_NAME 129
#define UILABEL_COMPASS_HEADINGLABEL 130
#define UIBUTTON_CONTINUE_COLLECTING 131

int FACE_COLLECT_PHASE_INTERVALS = 8;

#define NUMBER_OF_SECONDS_TO_COLLECT_FACES 3.0f

#define HAPPY_FACE @"~(^!^)~"

@interface RegistrationViewController ()

//popover
@property (nonatomic, strong) UIPopoverController *popController;
@property (nonatomic, retain ) NSMutableArray * profileArray;
@property (nonatomic, retain ) NSMutableArray * profileImageCountArray;

//VIEWS
@property (nonatomic, strong) iCarousel *carousel;
@property (nonatomic, strong) UINavigationItem *navItem;
@property (nonatomic, assign) BOOL wrap;
@property (nonatomic, strong) NSMutableArray *items;

//compass
@property (nonatomic,retain) CLLocationManager * locationManager;
@property (nonatomic, retain) CLHeading * currentHeading;

-(void)emptyOutCarousel;
-(NSMutableArray*)getProfilesFromSaved;
-(NSMutableArray*)getProfileImageCountFromSaved;
-(void)resetAll:(id)sender;
-(void)stopCollectingFaces;

@end

@implementation RegistrationViewController

//DATA
@synthesize registerCameraWrapper;
@synthesize registerDataModel;

//UI
@synthesize carousel;
@synthesize navItem;
@synthesize wrap;
@synthesize items;

//POPOVER
@synthesize profileArray;
@synthesize profileImageCountArray;


#pragma mark - VIEW LIFE CYCLE

-(void)dealloc
{
    DLOG(@"RegistrationViewController.m dealloc - start deallocating and cleanup");
    
    //it's a good idea to set these to nil here to avoid
	//sending messages to a deallocated viewcontroller
	carousel.delegate = nil;
	carousel.dataSource = nil;
    
    [self emptyOutCarousel]; //dont' empty out carousel
    
    self.items=nil; //items retained an NSMutableArray
    self.carousel = nil;
    
    DLOG(@"dealloc - removing observers");
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification object:nil];
    
    //clean up camera
    [self.registerCameraWrapper setCvVideoCameraDelegate:nil];
    self.registerCameraWrapper=nil;
    DLOG(@"dealloc - camera clean up............ok");
    
    //clean up data model
    self.registerDataModel=nil;
    self.registerDataModel.delegate = nil;
    
    self.locationManager = nil; //if we dont' set this to nil, it iwll continue to get delegate messages and mess us up in delegate method
    //- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
    self.locationManager.delegate = nil;
    self.currentHeading = nil;
    
    DLOG(@"dealloc - data model clean up............ok");
    
    DLOG(@"dealloc complete..... %@", HAPPY_FACE);
    [super dealloc];
}

- (void)viewDidLoad {
    
    DLOG(@"RegistrationViewController.m - viewDidLoad");
    [super viewDidLoad];
    
    DLOG(@"RegistrationViewController.m, HOME > %@", NSHomeDirectory());
    
    //FOR OUR COMPASS
    self.locationManager = [[[CLLocationManager alloc] init] autorelease];
    self.currentHeading = [[[CLHeading alloc] init] autorelease];
	self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	self.locationManager.headingFilter = 1;
	self.locationManager.delegate = self;
	[self.locationManager startUpdatingHeading];
   
    appendToExistingProfile = false;
    
    //NAV BUTTON
    /*
     UIBarButtonItem * toggleFacesItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
                                                                                target:self
                                                                                action:@selector(toggleAllFaces:)];
     */
    
    
    UIBarButtonItem * addNew = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                  target:self
                                                                             action:@selector(addNew:)];
    
    UIBarButtonItem * space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                      target:nil
                                                                                      action:nil];
    space.width = 50;
    
    UIBarButtonItem * clearItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                target:self
                                                                                action:@selector(clearFaceFolder:)];

    
    UIBarButtonItem * trainItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                target:self
                                                                                action:@selector(trainCollectedFaces)];
    trainItem.tag = UIBUTTON_TRAIN;
    
    //POPOVER FOR PROFILES
    UIBarButtonItem * addToExistingBtn = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                      target:self
                                      action:@selector(showPopover:)];
    
    //self.navigationItem.rightBarButtonItem = popoverButton;
    
    NSArray * actionButtonItems = @[  trainItem,
                                      space,
                                      space,
                                      addNew,
                                      space,
                                      addToExistingBtn,
                                      space,
                                      space,
                                      clearItem];
    
    //NAVIGATION BAR BUTTONS
    self.navigationItem.rightBarButtonItems = actionButtonItems;
    
    DLOG(@"RegistrationViewController.m, viewDidLoad - observers added");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];

  
    
    //the camera wrapper must be at the very bottom
    [self.registerCameraWrapper setCameraView:self.view andTag:UIIMAGEVIEW_CAMERA_CAPTUREVIEW];
    
    
    //set up data for our carousel
    self.items = [NSMutableArray array];
    
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
    
    //YELLOW CIRCLE AT THE MIDDLE OF THE SCREEN
    UIView * custom = [[UIView alloc] initWithFrame:CGRectMake(330.0f,460.0f,100.0f, 100.0f)];
    
    custom.tag = CUSTOM_LINE;
    [custom setBackgroundColor:[UIColor yellowColor]];
    [custom setAlpha:0.5f];
    [[custom layer] setCornerRadius:50.0f];
    
    UILabel * headingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 120.0f, 100.0f)];
    headingLabel.tag = UILABEL_COMPASS_HEADINGLABEL;
    headingLabel.font = [UIFont fontWithName: @"Georgia" size: 30];
    headingLabel.textAlignment = NSTextAlignmentLeft;
    headingLabel.lineBreakMode = NSLineBreakByWordWrapping;
    headingLabel.numberOfLines = 0;
    [custom addSubview:headingLabel];
    [headingLabel release];
    
    [self.view addSubview:custom];
    [custom release];
   
    [self addProfileEntryBox:self.view];
}


-(void)addProfileEntryBox:(UIView*)parentView {
    
    UIView * directionBox = [[UIView alloc] initWithFrame:CGRectMake(450.0f, 100.0f, 300.0f, 280.0f)];
    directionBox.tag = UIVIEW_DIRECTIONS_WINDOW;
    [directionBox setBackgroundColor:[UIColor lightGrayColor]];
    [parentView addSubview:directionBox];
    
    //insert uitextfield
    UITextField * nameTextField = [[UITextField alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 200.0f, 64.0f)];
    nameTextField.tag = UITEXTFIELD_NAME;
    [nameTextField setText:@"test"];
    nameTextField.borderStyle = UITextBorderStyleRoundedRect;
	nameTextField.textColor = [UIColor blackColor];
	
	nameTextField.font = [UIFont systemFontOfSize:20.0 ];
	nameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	
	nameTextField.keyboardType = UIKeyboardTypeDefault;
	nameTextField.returnKeyType = UIReturnKeyDone;
	nameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    UILabel * alignNoseText = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 280.0f, 280.0f)];
    alignNoseText.tag = UILABEL_ALIGN_TEXT;
    alignNoseText.font = [UIFont fontWithName: @"Georgia" size: 30];
    alignNoseText.textAlignment = NSTextAlignmentLeft;
    alignNoseText.lineBreakMode = NSLineBreakByWordWrapping;
    alignNoseText.numberOfLines = 0;

    
    //insert text
    NSString *text = [NSString stringWithFormat:@"Please rotate to 0 - 45° Then, press the camera button"];
    [alignNoseText setText:text];
    
    [directionBox addSubview:nameTextField];
    [directionBox addSubview:alignNoseText];
    
    
    //collect face button
    [self addButtonToView:directionBox
                  withTag:UIBUTTON_COLLECT_FACES_INTERVAL
                withTitle:nil
                 withRect:CGRectMake(200.0f, 200.0f, 10.0f, 30.0f)
           withMethodName:@"startCollectingFacesInIntervalsWithButton:"
            withImageName:@"collect.png"
    withSelectedImageName:@"collect-selected.png"];
    directionBox.alpha = 0.0f;
    
    [alignNoseText release];
    [nameTextField release];
    
    
    [directionBox release];
}




//when coming to registrations, we ALWAYS need to newly load our data structures.
-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    DLOG(@"viewDidAppear - arriving RegistrationViewController...");
    
    if ([self.registerDataModel isModeEnd]) {
        [self.registerDataModel setModeToDetection];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    if(!registerCameraWrapper.videoCamera.running) {
        
        [registerCameraWrapper startCamera];
        [registerCameraWrapper setCvVideoCameraDelegate:self];
        [self.registerDataModel setModeToDetection];
        DLOG(@"camera started, and CvVidoeCamera delegate set");
    }
    
    FileOps * file = [[FileOps alloc] init];
    
    unsigned long numOfFaces = [file getNumberOfFilesFromDiskFolder:@"faces"]; //file only
    
    [file release];
    
    //2) if there are images in there, then we should load it into our data structures
    if(numOfFaces > 0) {
        
        [registerDataModel updateStructuresWithDiskData]; //file and ds only
        
        //profiles for adding face images
        self.profileArray = [self getProfilesFromSaved]; //keys.txt file only
        DLOG(@"PROFILE ARRAY - received");
        
        //profile user count
        self.profileImageCountArray = [self getProfileImageCountFromSaved]; //ids.txt file only
        DLOG(@"PROFILE COUNT ARRAY - received");
    }

    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated {
    DLOG(@"viewWillDisappear - leaving RegisterViewController");
    //do your saving and such here
    DLOG(@"Let's stop all the face processing first");
    
    if(![self.registerDataModel isModeEnd]) {
        [self.registerDataModel setModeToStop];
    }

    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated {
    DLOG(@"viewDidDisappear - leaving RegisterViewController");
    
    if(self.registerCameraWrapper.videoCamera.running) {
        [self.registerCameraWrapper stopCamera];
        [self.registerCameraWrapper setCvVideoCameraDelegate:nil];
        DLOG(@"camera stopped, and CvVidoeCamera delegate niled");
    }
    [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning {
     DLOG(@"RegistrationViewcontroller.m - didReceiveMemoryWarning");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - PUBLIC METHODS
- (id)init {
    DLOG(@"RegistrationViewController.m - init - start");
    if (self = [super init])
    {
        self.profileArray = nil;
        phase = 0;
    }
    return self;
}

-(id)initWithCamera:(CameraWrapper*)newCamera {
    if(self=[self init]) {
        //the data model
        self.registerDataModel = [[[DataModel alloc] init] autorelease];
        self.registerDataModel.delegate = self;
        
        //the camera
        self.registerCameraWrapper = newCamera; //retains outside camera
        [self.registerCameraWrapper setCvVideoCameraDelegate:self]; //set the Video Camera delegate
    }
    return self;
}

-(id)initWithCamera:(CameraWrapper*)newCamera andDataModel:(DataModel*)model {
    if(self=[self init]) {
        //the data model
        self.registerDataModel = model; //retains outside model
        self.registerDataModel.delegate = self; //set data model delegate
        
        //initialize your profile array here!
        self.profileArray = [self getProfilesFromSaved];
        self.profileImageCountArray = [self getProfileImageCountFromSaved];
        
        //the camera
        self.registerCameraWrapper = newCamera; //retains outside camera
        [self.registerCameraWrapper setCvVideoCameraDelegate:self]; //set the Video Camera delegate
    }
    return self;
}

#pragma mark - BUTTON RESPONDER(S)

-(void)addNew:(id)sender {
    
    DLOG(@"adding new person");
    
    //DO ANIMATION FOR THE BOX
    if(!collectBox) {
        [self animateViewAlphaUsingParent:self.view
                              withTag:UIVIEW_DIRECTIONS_WINDOW
                          andDuration:0.5f andAlpha:1.0f];
    
        collectBox = true;
    }
    else
    {
        [self animateViewAlphaUsingParent:self.view
                                  withTag:UIVIEW_DIRECTIONS_WINDOW
                              andDuration:0.5f andAlpha:0.0f];
        collectBox= false;
    }
}


//when the train button is pressed
-(void)trainCollectedFaces {
    
    DLOG(@"train collected faces");
    
    FileOps * file = [[FileOps alloc] init];
    
    unsigned long numOfFaces = [file getNumberOfFilesFromDiskFolder:@"faces"]; //file only
    
    [file release];
    
    //2) if there are images in there, then we should load it into our data structures
    if(numOfFaces > 0) {
        
        //RELOAD ALL DATA STRUCTURES....we want correct preprocessed faces and face labels to match each other
        [registerDataModel updateStructuresWithDiskData]; //file and ds only
        
        //profiles for adding face images
        self.profileArray = [self getProfilesFromSaved]; //keys.txt file only
        DLOG(@"PROFILE ARRAY - received");
        
        //profile user count
        self.profileImageCountArray = [self getProfileImageCountFromSaved]; //ids.txt file only
        DLOG(@"PROFILE COUNT ARRAY - received");
    }
    
    [registerDataModel setModeToTraining];
}

//when the profiles button is pressed
- (void)showPopover:(id)sender {
    
    NSLog(@"show popover ");
    
    if (self.popController.popoverVisible) {
        
        NSLog(@"its visible, let's make it disappear");
        [self.popController dismissPopoverAnimated:YES];
        return;
    }
    
    //intiialize our profile table view controller with profile names and each profile's image count
    ProfileTableViewController * contentViewController = [[ProfileTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                                                                   andList:self.profileArray
                                                                                                  withCount:self.profileImageCountArray];
    contentViewController.delegate = self;
    UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:contentViewController];
    [contentViewController release];
    popController.popoverContentSize = CGSizeMake(300.0f, 600.0f);
    
    self.popController = popController;
    [self.popController presentPopoverFromBarButtonItem:sender
                               permittedArrowDirections:UIPopoverArrowDirectionUp
                                               animated:YES];
}

//when toggle all faces button is pressed
-(void)toggleAllFaces:(id)sender {
    
    //bring on the faces!
    if(!allFacesVisible){
        
        [self animateViewRect:self.view withRect:CGRectMake(0.0f, 700.0f, 768.0f, 150.0f)
                      withTag:UIVIEW_CAROUSEL andDuration:0.2];
        allFacesVisible=true;
    }
    //take teh faces away!
    else{
        
        [self animateViewRect:self.view withRect:CGRectMake(0.0f, 1024.0f + 100.0f, 768.0f, 150.0f)
                      withTag:UIVIEW_CAROUSEL andDuration:0.2];
        allFacesVisible=false;
    }
}

-(void)continueCollectingFaces{
    
    DLOG(@"continueCollectingImages");
    //set it to collect faces
    if(![registerDataModel isModeCollectingFaces]) {
        [registerDataModel setModeToCollectingFace];
    }
    
    //in 4 seconds, we stop collecting faces
    [NSTimer scheduledTimerWithTimeInterval:NUMBER_OF_SECONDS_TO_COLLECT_FACES
                                     target:self
                                   selector:@selector(stopCollectingFaces)
                                   userInfo:nil
                                    repeats:NO];
}


-(void)startCollectingFacesInIntervalsWithButton:(id)sender {
    
    //collect for how many seconds
    DLOG(@"start collecting faces for a few seconds");
    
    DLOG(@"WHEN WE SNAP, WE MUST CLEAR PREPROCESS AND FACELABEL STRUCTURES");
    
    if(phase==0) {
        [registerDataModel emptyFaceAndLabelStructures];
    }
    
    
    UIButton * btn = (UIButton*)[self.view viewWithTag:UIBUTTON_COLLECT_FACES_INTERVAL];
    [btn setEnabled:NO];
    
    float startDegree = phase * 45;
    float endDegree = startDegree + 45;
    
    int currentHeading = (int)self.currentHeading.magneticHeading;
    DLOG(@"%u", currentHeading);
    if((currentHeading < startDegree) || (currentHeading > endDegree)) {
        
        DLOG(@"NOT IN CORRECT HEADING. PLEASE ROTATE TO CORRECT HEADINGA");
        [btn setEnabled:YES];
        return;
    }
    
    //set it to collect faces
    if(![registerDataModel isModeCollectingFaces]) {
        [registerDataModel setModeToCollectingFace];
    }
    
    //in 4 seconds, we stop collecting faces
    [NSTimer scheduledTimerWithTimeInterval:NUMBER_OF_SECONDS_TO_COLLECT_FACES
                                     target:self
                                   selector:@selector(stopCollectingFaces)
                                   userInfo:nil
                                    repeats:NO];
}

#pragma mark - Pop Over Delegate method
-(void)selectedProfile:(NSString*)name {
    
    //get id by string name
    appendToExistingProfile = true;
    
    //set id of current user
    [registerDataModel setUserId:name];//original
    
    
    if (self.popController.popoverVisible) {
        [self.popController dismissPopoverAnimated:YES];
        [self startCollectingFacesInIntervalsWithButton:nil]; //simply adds faces to data structure
        return;
    }
}

#pragma mark - PRIVATE METHODS

-(void)clearFaceFolder:(id)sender {
    [profileArray removeAllObjects];
    [profileImageCountArray removeAllObjects];
    [registerDataModel clearAllDataOnDisk];
}

-(NSMutableArray*)getProfilesFromSaved {
    return [registerDataModel mutableArrayGetProfiles];
}

-(NSMutableArray*)getProfileImageCountFromSaved {
    return [registerDataModel arrayGetCountFromProfiles];
}

-(void)resetAll:(id)sender {
    DLOG(@"button pushed reset all");
    
    [registerDataModel resetAll];
    
    UILabel * numOfFacesLabel = (UILabel*)[self.view viewWithTag:UILABEL_COLLECTED_FACES];
    NSString * strNumber = [NSString stringWithFormat:@"%lu",[registerDataModel getTotalFaces]];
    [numOfFacesLabel setText:strNumber];
    DLOG(@"data reset success 数据复位成功...............%@", HAPPY_FACE);
    
    // Restart in Detection mode.
    [registerDataModel setModeToDetection];
}


-(void)stopCollectingFaces {
    DLOG(@"stop collecting faces");
    
    UIButton * btn = (UIButton*)[self.view viewWithTag:UIBUTTON_COLLECT_FACES_INTERVAL];
    [btn setEnabled:YES];
    
    //we continue collecting faces if its less than PHASE LIMIT
    if(++phase < FACE_COLLECT_PHASE_INTERVALS) {
        //READY FOR THE NEXT COLLECTION
        [registerDataModel setModeToDetection];
        
        UILabel * message = (UILabel*)[self.view viewWithTag:UILABEL_ALIGN_TEXT];
        int startingDeg = phase * 45;
        int endingDeg = startingDeg + 45;
        
        [message setText:[NSString stringWithFormat:@"Rotate between %u and %u. Then press the camera buttobn", startingDeg, endingDeg]];
        return;
    }
    
    //once PHASE LIMIT IS REACHED....we stop collecting, put up standard detection...and save it all
    //first let's remove the continue collecting button
   // UIButton * continueBtn = (UIButton*)[self.view viewWithTag:UIBUTTON_CONTINUE_COLLECTING];
    //[continueBtn removeFromSuperview];
    
    DLOG(@"+++++++++++++ INCREMENTED PERSON");
    UITextField * nameTextField = (UITextField*)[self.view viewWithTag:UITEXTFIELD_NAME];

    //STOP COLLECTION. SET TO STANDARD DETECTION
    [registerDataModel setModeToDetection];
    [registerDataModel incrementPersonIDIfNewAdd:[nameTextField text] andAppendExisting:appendToExistingProfile]; //move on to the next person IF its a new add.
    [registerDataModel saveFaceCollectionToDisk:appendToExistingProfile];
    
    //now we have all the user profiles from data model
    self.profileArray = [self getProfilesFromSaved];
    self.profileImageCountArray = [self getProfileImageCountFromSaved]; //MAKE SURE THE COUNT IS CORRECT HERE
    
    appendToExistingProfile = false;
    phase = 0;
    
    return;
}



#pragma mark - UI UTILITY METHOD(S)
-(void)addButtonToView: (UIView*)parentView
               withTag:(int)tag
             withTitle:(NSString*)titleString
              withRect:(CGRect)rect
        withMethodName:(NSString*)methodName
         withImageName:(NSString*)imageName
 withSelectedImageName:(NSString*)selectedImageName {
    
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

-(void)addCollectFacesIcon:(UIView*)parentView {
    
    // create UILabel for NUMBER of collected faces
	UILabel * labelCollectedFaces = [[UILabel alloc] initWithFrame:CGRectMake( 40.0f, 10.0f, 60.0f, 30.0f )];
	[labelCollectedFaces setBackgroundColor: [UIColor clearColor]];
	labelCollectedFaces.font = [ UIFont fontWithName: @"Georgia" size: 22];
    labelCollectedFaces.textAlignment = NSTextAlignmentCenter;
    labelCollectedFaces.lineBreakMode = NSLineBreakByWordWrapping;
    labelCollectedFaces.numberOfLines = 0;
    labelCollectedFaces.tag = UILABEL_COLLECTED_FACES;
	labelCollectedFaces.text = @"0";
    [labelCollectedFaces setTextColor:[UIColor blackColor]];
	[parentView addSubview: labelCollectedFaces];
	[labelCollectedFaces release];
}

#pragma mark  ANIMATION UTILITY METHOD(s)
//animates view to appear or disappear with alpha
-(void)animateViewAlphaUsingParent:(UIView*)theView withTag:(int)tag andDuration:(float)duration andAlpha:(float)alpha {
    
    UIView * view = [theView viewWithTag:tag];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:duration];
    
    [view setAlpha:alpha];
    [UIView commitAnimations];
}

//animates a view to move to and from a rect
-(void)animateViewRect:(UIView*)theView withRect:(CGRect)rect withTag:(int)tag andDuration:(float)duration {
    
    UIView * view = (UITextView*)[theView viewWithTag:tag];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [UIView beginAnimations:nil context:context];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:duration];
    
    [view setFrame:rect];
    [UIView commitAnimations];
}

#pragma mark - OBSERVER METHOD(s)

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    // Your server calls
    DLOG(@"RegistrationViewController.m - applicationDidEnterBackground");
    [registerCameraWrapper stopCamera];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    // Your server calls
    DLOG(@"RegistrationViewController.m - applicationDidBecomeActive");
    [registerCameraWrapper startCamera];
}

#pragma mark - ORIENTATION METHOD(S)

//we want to make navigation controller portrait only
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - CvVideoCameraDelegate method(s)
- (void)processImage:(cv::Mat&)image {
    [registerDataModel ProcessFace:image];
}

#pragma mark - iCarousel utility methods
//this basically adds the current index onto the items array
//then it adds that index onto carousel. So that when carousel is drawing
//it all out in viewForItemAtIndex, it looks at what index is in this array,
//then converst the cv::Mat in preprocessedFaces[i*2] to an uiimage and draw it
//as the view in viewForItemAtIndex.
-(void)addFaceToCarousel:(id)sender {
    
    NSInteger index = carousel.currentItemIndex;
    DLOG(@"Registration - addFaceToCarousel: %u", index);
    [items insertObject:@(carousel.numberOfItems) atIndex:index];
    [carousel insertItemAtIndex:index animated:YES];
}

-(void)removeFaceFromCarousel:(id)sender {
    
    if (carousel.numberOfItems > 0) {
        
        NSInteger index = carousel.currentItemIndex;
        [carousel removeItemAtIndex:index animated:YES];
        [items removeObjectAtIndex:index];
    }
}

//MUST use items to removeAllObjects, because items is used in numberOfItemsInCarousel
-(void)emptyOutCarousel {
    DLOG(@"emptying out carousel");
    
    if(carousel && (carousel.numberOfItems>0))
    {
        DLOG(@"removing %lu items from carousel", (unsigned long)[items count]);
        
        for ( int j = 0; j < [items count]; j++) {
            
            //remove any images in the carousel
            [carousel removeItemAtIndex:j animated:YES];
        }
        
        //finally we empty out our carousel item index
        [items removeAllObjects];
    }
}


#pragma mark - iCarousel delegate methods

-(void)clearFacesInCarousel {
    [self emptyOutCarousel];
}

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel {
    
    DLOG(@"numberOfItemsInCarousel: %lu", (unsigned long)[items count]);
    return [items count];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view {
    if ([items count] <= 0) { DLOG(@"items count is 0. returning nil"); return nil; }
    if([registerDataModel getTotalFaces] <=0) { DLOG(@"preprocessedFaces.size() is 0. returning nil"); return nil; }
    
    //will give me 0...1..2..3....1000...
    NSString * s = [items[index] stringValue];
    long i = [s integerValue];
    DLOG(@"viewForItemAtIndex - long is: %l", i);
    
    //gets the preprocessed face cv::Mat
    cv::Mat currentPreprocessedFaceMat = [registerDataModel getFaceIndex:i];
    
    //converts it to an UIImage to be added to our carousel
    UIImage * addToCarousel_PreprocessedFace = [UIImage UIImageFromCVMat:currentPreprocessedFaceMat];
    
    if ((addToCarousel_PreprocessedFace.size.width <= 0) || (addToCarousel_PreprocessedFace.size.height <= 0)) {
        DLOG(@"ERROR, returned processed face is invalid. cannot draw");
        return nil;
    }
    
    view = [[[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 70.0f, 70.0f)] autorelease];
    ((UIImageView *)view).image = addToCarousel_PreprocessedFace;
    view.contentMode = UIViewContentModeBottom;
    return view;
}

- (CATransform3D)carousel:(iCarousel *)pCarousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform {
    //implement 'flip3D' style carousel
    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * pCarousel.itemWidth);
}

- (CGFloat)carousel:(iCarousel *)pCarousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value {
    //customize carousel display
    switch (option) {
        case iCarouselOptionWrap: {
            //normally you would hard-code this to YES or NO
            return wrap;
        }
        case iCarouselOptionSpacing: {
            //add a bit of spacing between the item views
            return value * 1.05f;
        }
        case iCarouselOptionFadeMax: {
            if (pCarousel.type == iCarouselTypeCustom) {
                //set opacity based on distance from camera
                return 0.0f;
            }
            return value;
        }
        default: {
            return value;
        }
    }
}

#pragma Location Manager Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    self.currentHeading = newHeading;
    
    UILabel * headingLabel = (UILabel*)[self.view viewWithTag:UILABEL_COMPASS_HEADINGLABEL];
    headingLabel.text = [NSString stringWithFormat:@"%d°", (int)newHeading.magneticHeading];
}


- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
    if(self.currentHeading == nil) {
        return YES;
    } else {
        return NO;
    }
}


#pragma mark - UpdateViewDelegate delegate methods
-(void)showMessageBox:(NSString*)title andMessage:(NSString*)msg andCancelTitle:(NSString*)cancelTitle {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView * warn = [[UIAlertView alloc] initWithTitle:title
                                                        message:msg
                                                       delegate:self
                                              cancelButtonTitle:cancelTitle
                                              otherButtonTitles:nil];
        [warn show]; [warn release];
    });
}

-(void)updateNumOfFacesLabel:(NSString*)strNumber{
    UILabel * numOfFacesLabel = (UILabel*)[self.view viewWithTag:UILABEL_COLLECTED_FACES];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [numOfFacesLabel setText:strNumber];
    });
}

@end

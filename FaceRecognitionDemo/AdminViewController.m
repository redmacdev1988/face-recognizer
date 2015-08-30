//
//  AdminViewController.m
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 4/22/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import "AdminViewController.h"

@interface AdminViewController ()

@end

@implementation AdminViewController

@synthesize adminMenuStrings;
@synthesize adminMenuTable;
@synthesize identity;

-(void)dealloc
{
    [adminMenuStrings release];
    [adminMenuTable release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithIdentity:(NSString*)recognizedIdentity
{
    self = [self init];
    
    if(self){
        self.identity = recognizedIdentity;
    }

    return self;
}



-(void)viewWillAppear:(BOOL)animated
{
    
    DLOG(@"viewDidAppear - arriving AdminViewController...");
    DLOG(@"------------> APPROVED PERSON: %@", identity);
    [super viewWillAppear:animated];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    DLOG(@"viewDidAppear - did arrive at AdminViewController...");
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [super viewDidAppear:animated];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    DLOG(@"viewWillDisappear - arriving AdminViewController...");
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewWillDisappear:animated];
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    DLOG(@"viewDidDisappear - leaving AdminViewController...");
    [super viewDidDisappear:animated];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    
    
    if ( adminMenuStrings == nil ){
		//note - the strings are not allocated, thus, no need to release them individually
		adminMenuStrings = [[ NSArray alloc ] initWithObjects:
                            @"销售管理", @"您的收益", @"买了去上海的火车票", @"客户管理", @"在贵宾入住",
                            @"客户管理",@"在贵宾入住", @"秘密 111", @"秘密 8", @"秘密 9", @"秘密 1001", @"秘密 1010",
                            nil];
	}
	
    if(adminMenuTable==nil)
	{
		//NOTE - UITableViewStyleGrouped makes header stick with scrolling.
		//if its the Normal Style, the cells scroll beneath the header./////////////////////////////////////////////////////
		adminMenuTable = [[UITableView alloc] initWithFrame:CGRectMake(0,0,768,1024) style:UITableViewStylePlain];
		
		[adminMenuTable setBackgroundColor:[UIColor whiteColor]];
		[adminMenuTable setDelegate:self];
		[adminMenuTable setDataSource:self];
		adminMenuTable.rowHeight = 2 * 67.0f;
		
		//MAKING MENU TRANSPARENT - make table view have clear background so our background image shows up
		adminMenuTable.backgroundColor = [ UIColor whiteColor ];
		
		//the separatorColor variable colors the cell's border
		//if you DO NOT have this, cell will have a border with a default color showing.
		adminMenuTable.separatorColor = [UIColor colorWithRed:0.77254902f green:0.71372549f blue:0.65098039f alpha:1.0f];
        
        //NAVIGATION BAR SETTINGS - this is our main menu, we want to hid the navigational bar
        
        [self.view addSubview: adminMenuTable];
	}
    
    // change the back button to cancel and add an event handler
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"back to main menu"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(handleBackToMain:)];
    
    self.navigationItem.leftBarButtonItem = backButton;
    [backButton release];
}


- (void)handleBackToMain:(id)sender
{
    // pop to root view controller
    [self.navigationController popToRootViewControllerAnimated:YES];
}


-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString * CellIdentifier = @"Cell";
	
	UITableViewCell * cell = [ tableView dequeueReusableCellWithIdentifier:CellIdentifier ];
	
	if ( cell == nil )
	{
		cell = [ [ [ UITableViewCell alloc ] initWithStyle: UITableViewCellStyleSubtitle
										   reuseIdentifier: CellIdentifier ] autorelease ];
	}
	
	//display first section's strings
	if ( indexPath.section == 0 )
	{
		[ cell textLabel ].text = [ adminMenuStrings objectAtIndex: indexPath.row ];
	}
	
	//cell's text color
	cell.textLabel.textColor = [UIColor grayColor];
	//cell's selected text color
	cell.textLabel.highlightedTextColor = [UIColor blackColor];
	
	//how much we should indent the cell's text
	cell.indentationLevel = 1;
	
	//the cells that displays the text has a default background color that we need to get rid of to blend in
	//nicely with the rest of the table
	cell.textLabel.backgroundColor = [UIColor whiteColor];
	
	cell.textLabel.font = [ UIFont fontWithName: @"Georgia" size: 19 ];
	cell.textLabel.textColor = [UIColor blackColor];

	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	return cell;
}



//This function is where all the magic happens
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    //1. Setup the CATransform3D structure
    CATransform3D rotation;
    rotation = CATransform3DMakeRotation( (90.0*M_PI)/180, 0.0, 0.7, 0.4);
    rotation.m34 = 1.0/ -600;
    
    
    //2. Define the initial state (Before the animation)
    cell.layer.shadowColor = [[UIColor blackColor]CGColor];
    cell.layer.shadowOffset = CGSizeMake(10, 10);
    cell.alpha = 0;
    
    cell.layer.transform = rotation;
    cell.layer.anchorPoint = CGPointMake(0, 0.5);
    
    //!!!FIX for issue #1 Cell position wrong------------
    if(cell.layer.position.x != 0){
        cell.layer.position = CGPointMake(0, cell.layer.position.y);
    }
    
    //4. Define the final state (After the animation) and commit the animation
    [UIView beginAnimations:@"rotation" context:NULL];
    [UIView setAnimationDuration:0.8];
    cell.layer.transform = CATransform3DIdentity;
    cell.alpha = 1;
    cell.layer.shadowOffset = CGSizeMake(0, 0);
    [UIView commitAnimations];
}


//Helper function to get a random float
-(float)randomFloatBetween:(float)smallNumber and:(float)bigNumber {
    float diff = bigNumber - smallNumber;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}

-(UIColor*)colorFromIndex:(int)index
{
    UIColor *color;
    
    //Purple
    if(index % 3 == 0){
        color = [UIColor colorWithRed:0.93 green:0.01 blue:0.55 alpha:1.0];
        //Blue
    }else if(index % 3 == 1){
        color = [UIColor colorWithRed:0.00 green:0.68 blue:0.94 alpha:1.0];
        //Blk
    }else if(index % 3 == 2){
        color = [UIColor blackColor];
    }
    else if(index % 3 == 3){
        color = [UIColor colorWithRed:0.00 green:1.0 blue:0.00 alpha:1.0];
    }
    else
    {
        color = [UIColor colorWithRed:0.00 green:1.0 blue:0.00 alpha:1.0];
    }
    
    
    return color;
    
}



#pragma mark - ROW SELECTED, respond to starting the app, or getting about
-(void)tableView: (UITableView *)tableView
didSelectRowAtIndexPath: ( NSIndexPath *)indexPath
{
	DLOG( @"AdminThisAppViewController.m - didSelectRowAtIndexPath: %i", indexPath.row);
}

#pragma mark TABLE VIEW METHODS
#pragma mark # of sections in our main menu
-(NSInteger)numberOfSectionsInTableView: (UITableView*)tableView
{
	return 1;
}

#pragma mark Table View Methodes
-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return [adminMenuStrings count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.identity;
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

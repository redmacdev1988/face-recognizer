//
//  ProfileTableViewController.m
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 6/11/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import "ProfileTableViewController.h"

@interface ProfileTableViewController ()

@end

@implementation ProfileTableViewController

@synthesize profileNames;
@synthesize delegate;
@synthesize profileImageCounts;


-(void)dealloc
{
    [profileNames release];
    self.profileNames=nil;
    
    [super dealloc];
}


- (id)initWithStyle:(UITableViewStyle)style
{
    if ([super initWithStyle:style] != nil) {
        //Make row selections persist.
        self.clearsSelectionOnViewWillAppear = NO;
        self.profileNames = nil;
    }
    return self;
}

-(id)initWithStyle:(UITableViewStyle)style andList:(NSMutableArray*)newNames
{
    if(self = [self initWithStyle:style]){
        self.profileNames = (newNames) ? newNames : [[NSMutableArray alloc] init];
    }
    return self;
}

-(id)initWithStyle:(UITableViewStyle)style andList:(NSMutableArray*)newNames withCount:(NSMutableArray*)count
{
    if(self = [self initWithStyle:style andList:newNames]){
        self.profileImageCounts = (count) ? count : [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [profileNames count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    DLOG(@"index path: %u", indexPath.row);
    
    cell.textLabel.text = [profileNames objectAtIndex:indexPath.row];
    NSNumber * num = (NSNumber*)[profileImageCounts objectAtIndex:indexPath.row];
    
    long numberOfFaces = [num integerValue]/2;
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu",numberOfFaces];
    return cell;
}


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLOG(@"%u", [profileNames count]);
    NSString *selectedProfileName = [profileNames objectAtIndex:indexPath.row];
    DLOG(@"selected profile name: %@", selectedProfileName);
    
    
    UITableViewCell * cell = (UITableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
    DLOG(@"you've selected: %@",[cell textLabel].text);
    
    //Notify the delegate if it exists.
    if (delegate != nil) {
        [delegate selectedProfile:[cell textLabel].text];
    }
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

//
//  DataModel.h
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 4/16/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//
#import "UIImage-Extensions.h"

@protocol UpdateViewDelegate <NSObject>
@optional
-(void)showMessageBox:(NSString*)title andMessage:(NSString*)msg andCancelTitle:(NSString*)cancelTitle;

// register view controller
-(void)addFacesToCarousel;
-(void)clearFacesInCarousel;
-(void)updateNumOfFacesLabel:(NSString*)strNumber;

// login view controller
-(void)animateTraining:(bool)flag;
-(void)incrementIdentityValue:(float)similarity;
-(void)showSimilarity:(float)similarity;
-(void)setRecognizeButton:(bool)flag;
-(void)setTrainButton:(bool)flag;
-(void)showIdentityInt:(int)identity andName:(NSString*)name;
@end


@interface DataModel : NSObject {
    
    //our data structures
    cv::CascadeClassifier * faceCascadePtr;
    NSMutableArray * arrayOfCascadesNames;
    
    cv::Ptr<cv::FaceRecognizer> model;
    
    std::vector <cv::Mat> preprocessedFaces; //colored faces
    std::vector <cv::Mat> grayPreprocessedFaces; //gray faces
    
    cv::Mat old_prepreprocessedFace;
    
    int m_userId; //keep track of current user profile
    
    int m_curUsers;
    
    std::vector <int> faceLabels;
    std::vector <int> m_latestFaces;
    
    double old_time;
    
    id <UpdateViewDelegate> delegate;
    
    float threshold;
    
    NSMutableDictionary * nameKeyTable; //contains the "0" --> "ricky", "1" --> "zhuyu"..etc dictionary
   
    NSMutableDictionary * recognitionCount;
}

@property(nonatomic, assign) id <UpdateViewDelegate> delegate;
@property(nonatomic, retain) NSMutableArray * arrayOfCascadesNames;
@property(nonatomic, assign) float threshold;
@property(nonatomic, retain) NSMutableDictionary * nameKeyTable;
@property(nonatomic, retain) NSMutableDictionary * recognitionCount;


-(id)init;

-(cv::Ptr<cv::FaceRecognizer>)modelIsValid;

-(unsigned long)getTotalFaces;

//DEBUG: get a face image's index for carousel
-(cv::Mat)getFaceIndex:(unsigned long)index;

//clean out all data structures
-(void)resetAll;

//main processing method for taking in a cv::Mat image and processing it to see if it can detect a face
//used by UIViewControllers
-(bool)ProcessFace:(cv::Mat&)image;


///////used by Registration only//////////////////////

-(void)incrementPersonIDIfNewAdd:(NSString*)userIdName andAppendExisting:(bool)addToExisting;

-(void)setUserId:(NSString*)name; //sets the user id for adding faces for that specific id

-(void)saveFaceCollectionToDisk:(bool)appendNew; //saves newly collected face images to disk

-(void)clearAllDataOnDisk; //clear data in disk

-(NSMutableArray*)mutableArrayGetProfiles; //get data from faces/ids.txt

-(void)updateStructuresWithDiskData; //update preprocessedFaces and faceLabels with data from files on disk

-(void)emptyFaceAndLabelStructures;  //clears out face and label structures


////// used by Login only ////////////////////

-(NSString*)getRecognizedPerson; //looks at our dictionary and gives us the highest count name recognized

-(void)emptyRecognitionCount; //empty the name count recognition numbers.


///// OTHER ////////////

-(NSUInteger)getNumOfProfiles; //get number of profiles

-(NSMutableArray*)arrayGetCountFromProfiles; //array of count for profiles

//determining mode
-(bool)isModeTraining;
-(bool)isModeDetecting;
-(bool)isModeRecognizing;
-(bool)isModeCollectingFaces;
-(bool)isModeEnd;

//setting mode
-(void)setModeToTraining;
-(void)setModeToDetection;
-(void)setModeToRecognition;
-(void)setModeToCollectingFace;
-(void)setModeToStop;

@end

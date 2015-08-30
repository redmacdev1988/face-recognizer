//
//  DataModel.m
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 4/16/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import "DataModel.h"
#import "FileOps.h"

#import <vector>
#import <algorithm>

// Running mode for the Webcam-based interactive GUI program.
enum MODES {MODE_STARTUP=0, MODE_DETECTION, MODE_COLLECT_FACES, MODE_TRAINING, MODE_RECOGNITION, MODE_DELETE_ALL, MODE_END};
const char* MODE_NAMES[] = {"Startup", "Detection", "Collect Faces", "Training", "Recognition", "Delete All", "ERROR!"};

//we start at startup
MODES m_mode = MODE_STARTUP;

//const double FACE_ELLIPSE_CY = 0.40;
//const double FACE_ELLIPSE_W = 0.50;         // Should be atleast 0.5
//const double FACE_ELLIPSE_H = 0.80;         // Controls how tall the face mask is.

// Parameters controlling how often to keep new faces when collecting them. Otherwise, the training set could look to similar to each other!

//was 0.3
const double CHANGE_IN_IMAGE_FOR_COLLECTION = 0.01;      // How much the facial image should change before collecting a new face photo for training.

//was 1.0f
const double CHANGE_IN_SECONDS_FOR_COLLECTION = 0.1;       // How much time must pass before collecting a new face photo for training.

NSString * STRING_FACE_LABEL_FILENAME = @"facelabels.yml";

//private methods
@interface DataModel ()

-(void)alertWithTitle:(NSString*)title andMessage:(NSString*)msg andDelegate:(id)del andCancel:(NSString*)cancelMsg;
-(void)saveFaceLabelDataStructure:(std::vector<int>&)faceLabelDS toFolder:(NSString*)folder;


//private image processing methods
-(cv::Rect)detectObjectsCustom:(cv::Mat&)img //the image itself
withCascadeClassifier:(cv::CascadeClassifier&)cascade //cascade classifier to be used
withFaceVector:(std::vector<cv::Rect>)faces //array of faces to be passed in
withScaledWidth:(int)width //the scaled with of the image
withFlags:(int)flags //the flags set for what kind of search we do i.e biggest object, rough search...etc
withMinFeatureSize:(cv::Size)minFeatureSize
withSearchScaleFactor:(float)searchFactor
withMinNeighbors:(int)minNeighbors;

//given an image, detect the largest face in there
-(void)detectLargestObject:(cv::Mat&)srcImg
     withCascadeClassifier:(cv::CascadeClassifier&)cascade
                withinRect:(cv::Rect&)largestObject;

//draw a rectangular line
-(void)drawRect:(cv::Rect)faceRect aroundImage:(cv::Mat&)image withColor:(cv::Scalar)scalar;

-(double) getSimilarityWithMat:(cv::Mat&)A andMat:(cv::Mat)B;
-(cv::Mat)norm_0_255:(cv::Mat&)src;

//gray out a cv mat image
-(cv::Mat)grayCVMat:(cv::Mat&)colored;
-(void)equalizeCVMat:(cv::Mat&)image;
-(cv::Mat)resizeCVMat:(cv::Mat&)matImage withHeight:(int)height andWidth:(int)width;
-(void)bilateralFilterCVMat:(cv::Mat&)image;

-(cv::Mat)tan_triggs_preprocessingWithInputArray:(cv::InputArray)src
andAlpha:(float)alpha
andTau:(float)tau
andGamma:(float)gamma
andSigmaZero:(int)sigmaZero
andSigmaOne:(int)sigmaOne;

-(cv::Mat) getPreprocessedFace:(cv::Mat&) srcImg
withFaceWidth:(int) desiredFaceWidth
withCascadeClassifier:(cv::CascadeClassifier&)faceCascade
withFaceRect:(cv::Rect&)faceRect;

//reconstruct a mean face with cv mat
-(cv::Mat)reconstructFaceWithCVMat:(cv::Mat)paramPreprocessedFace;

//learn collected face images
-(cv::Ptr<cv::FaceRecognizer>)learnCollectedFacesWithFaces:(cv::vector<cv::Mat>&)paramPreprocessedFaces
withLabels:(cv::vector<int>&)paramFaceLabels
andStrAlgorithm:(NSString*)facerecAlgorithm;

-(void)saveStructureToExternalFile:(NSString*)fileName
            withFaceImageStructure:(std::vector<cv::Mat>&)faces
             andFaceLabelStructure:(std::vector<int>&)labels;

-(void)CreateFaceCascadeWithName:(NSString*)cascadeName;

@end

@implementation DataModel

@synthesize arrayOfCascadesNames;
@synthesize delegate;
@synthesize threshold;
@synthesize nameKeyTable;

@synthesize recognitionCount;

#pragma mark ------------------- standard utility methods ----------------------

-(void)dealloc
{

    DLOG(@"DEALLOCING DATA MODEL......");
    
    if(faceCascadePtr){
        delete faceCascadePtr; faceCascadePtr=NULL;
    }
    DLOG(@"deleted faceCascadePtr......");
    
    //retained an auto-release in init method. must release and nil here
    self.arrayOfCascadesNames=nil;
    
    m_latestFaces.clear();
    preprocessedFaces.clear();
    faceLabels.clear();
    DLOG(@"face data structures deleted......");
    
    threshold = -1;
    old_time = -1;
    
    [nameKeyTable removeAllObjects];
    [nameKeyTable release];
    
    [super dealloc];
}

-(id)init {
    if(self=[super init]) {
         //auto released
        self.arrayOfCascadesNames = [NSMutableArray arrayWithObjects:
                                     @"lbpcascade_frontalface",
                                     @"haarcascade_frontalface_default",
                                     @"haarcascade_frontalface_alt",
                                     @"haarcascade_frontalface_alt2",
                                     nil];
        
        [self CreateFaceCascadeWithName:[arrayOfCascadesNames objectAtIndex:2]];
        //add one person just so we can have a temp
        m_latestFaces.push_back(-1);
        self.threshold = -1.0f;
        
        m_userId = 0;
        m_curUsers = 0;
        
        //retains auto-released
        self.nameKeyTable = [NSMutableDictionary dictionary];
        self.recognitionCount = [NSMutableDictionary dictionary];
        
    }
    return self;
}



-(void)CreateFaceCascadeWithName:(NSString*)cascadeName {
    
    if(faceCascadePtr) {
        DLOG(@"cascadePtr exists, let's delete and NULL out cascadePtr");
        delete faceCascadePtr; faceCascadePtr=NULL;
    }
    
    DLOG(@"new-ing cascadePtr");
    faceCascadePtr = new cv::CascadeClassifier();
    
    //using haarcascade_frontalface_alt2
    NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:cascadeName ofType:@"xml"];
    
    DLOG(@"Face Cascade load: %@", faceCascadePath);
    faceCascadePtr->load([faceCascadePath UTF8String]);
}

//is our model valid and trained?
-(cv::Ptr<cv::FaceRecognizer>)modelIsValid { return model; }

//returns the original face from our preprocessed faces. even is original faces. odd is mirror.
-(cv::Mat)getFaceIndex:(unsigned long)index { return preprocessedFaces[index*2]; }


-(unsigned long)getTotalFaces{ return preprocessedFaces.size()/2; }

-(void)resetAll {
    
    DLOG(@"DataModel - RESET ALLLLLLLLLLL");
    
    DLOG(@"%u, %u", preprocessedFaces.size(), faceLabels.size());

    preprocessedFaces.clear();
    faceLabels.clear();
    old_prepreprocessedFace = cv::Mat();
    m_latestFaces.clear();
    [nameKeyTable removeAllObjects];

    m_userId = 0;
    m_curUsers = 0;
    
    //tell whatever view is showing our carousel to clear its faces
    //if([self.delegate respondsToSelector:@selector(clearFacesInCarousel)]) {
    //    [delegate clearFacesInCarousel];
   // }
    
    //[self clearFacesInCarouselOnDelegateView];
    //[self updateNumOfFacesLabelOnDelegateView];
}


#pragma mark ------------------- opencv utility methods ----------------------

//gray image processing
-(cv::Mat) getPreprocessedFace:(cv::Mat&) srcImg
withFaceWidth:(int) desiredFaceWidth
withCascadeClassifier:(cv::CascadeClassifier&)faceCascade
withFaceRect:(cv::Rect&)faceRect {
    
    //we need to return faceRect so that we can use it to draw it onto our original image
    //returned is the faceRect parameter
    [self detectLargestObject:srcImg
        withCascadeClassifier:*faceCascadePtr
                   withinRect:faceRect];
    
    if(faceRect.width <=0) {
        return cv::Mat();
    } else {
        //preprocess image
        int desiredFaceHeight = desiredFaceWidth;
        
        //get the detected face image
        cv::Mat detectedFaceImg = srcImg(faceRect);
     
        detectedFaceImg = [self resizeCVMat:detectedFaceImg withHeight:desiredFaceHeight andWidth:desiredFaceWidth];
        
        return detectedFaceImg;
    }
    return cv::Mat();
}


-(cv::Rect)detectObjectsCustom:(cv::Mat&)img //the image itself
                withCascadeClassifier:(cv::CascadeClassifier&)cascade //cascade classifier to be used
                withFaceVector:(std::vector<cv::Rect>)faces //array of faces to be passed in
                withScaledWidth:(int)width //the scaled with of the image
                withFlags:(int)flags //the flags set for what kind of search we do i.e biggest object, rough search...etc
                withMinFeatureSize:(cv::Size)minFeatureSize
                withSearchScaleFactor:(float)searchFactor
                withMinNeighbors:(int)minNeighbors {
    
    //possibly shrink the image, to run much faster
    cv::Mat inputImg;
    
    //gray it
    cv::Mat cvGrayImage;
    cvtColor(img, cvGrayImage, CV_BGR2GRAY);
    
    inputImg = cvGrayImage;
    
    //equalize it
    cv::Mat equalizedImg;
    cv::equalizeHist(inputImg, equalizedImg);
    
    //OKAY HERE'S THE PROBLEM.
    
    //detect MultiScale slows down considerably when
    //there is no face. Hence it locks when it processes.
    
    //When release this DataModel which detectMultiScale is
    //is processing, we get an error.
    
    // in order to avoid this method from being so complicated,
    //we can change the minSizeFeatureSize to 500,500 instead of say..50,50
    //which means we are detecting everything down to a face that's 50 by 50.
    
    //500 by 500 means we can detect faces that size...anything less, we do not take care of.
    
    // detect objects in the small grayscale image
    faceCascadePtr->detectMultiScale(equalizedImg,
                                     faces,
                                     searchFactor,
                                     minNeighbors,
                                     0|flags,
                                     minFeatureSize);
    
    if(faces.size()<=0) {
        return cv::Rect();
    }
    
    return faces[0];
}


//no image processing
-(void)detectLargestObject:(cv::Mat&)srcImg
     withCascadeClassifier:(cv::CascadeClassifier&)cascade
                withinRect:(cv::Rect&)largestObject {
    
    int flags = CV_HAAR_FIND_BIGGEST_OBJECT;// | CASCADE_DO_ROUGH_SEARCH;
    cv::Size minFeatureSize = cv::Size(450, 450);
    // How detailed should the search be. Must be larger than 1.0.
    float searchScaleFactor = 1.1f;
    // minNeighbors=2 means lots of good+bad detections, and minNeighbors=6 means only good detections are given but some are missed.
    int minNeighbors = 6;
    
    //VECTOR OF faces. When detectMultiScale detects faces,
    //it puts all of the faces into this vector
    std::vector<cv::Rect> faces;
    
    //we detected the current face
    const cv::Rect& currentFace = [self detectObjectsCustom:srcImg
                                      withCascadeClassifier:cascade
                                             withFaceVector:faces
                                            withScaledWidth:srcImg.cols
                                                  withFlags:flags
                                         withMinFeatureSize:minFeatureSize
                                      withSearchScaleFactor:searchScaleFactor
                                           withMinNeighbors:minNeighbors];
    
    if(currentFace.width<=0) { return; DLOG(@"currentFace.width is <=0"); }
    
    //returns parameter cv::Rect
    largestObject = currentFace;
}


-(cv::Mat)reconstructFaceWithCVMat:(cv::Mat)paramPreprocessedFace {
    
    if(model==NULL)return cv::Mat();
    
    try {
        // Get some required data from the FaceRecognizer model.
        cv::Mat eigenvectors = model->get<cv::Mat>("eigenvectors");
        
        cv::Mat averageFaceRow = model->get<cv::Mat>("mean");
        
        int faceHeight = paramPreprocessedFace.rows;
        
        // Project the input image onto the PCA subspace.
        cv::Mat projection = subspaceProject(eigenvectors,
                                             averageFaceRow,
                                             paramPreprocessedFace.reshape(1, 1));
        
        //printMatInfo(projection, "projection");
        
        // Generate the reconstructed face back from the PCA subspace.
        cv::Mat reconstructionRow = subspaceReconstruct(eigenvectors, averageFaceRow, projection);
        //UIImage * reRow = [UIImage UIImageFromCVMat:reconstructionRow];
        
        //printMatInfo(reconstructionRow, "reconstructionRow");
        
        // Convert the float row matrix to a regular 8-bit image. Note that we
        // shouldn't use "getImageFrom1DFloatMat()" because we don't want to normalize
        // the data since it is already at the perfect scale.
        
        // Make it a rectangular shaped image instead of a single row.
        cv::Mat reconstructionMat = reconstructionRow.reshape(1, faceHeight);
        //UIImage * reMat = [UIImage UIImageFromCVMat:reconstructionMat];
        
        // Convert the floating-point pixels to regular 8-bit uchar pixels.
        cv::Mat reconstructedFace = cv::Mat(reconstructionMat.size(), CV_8U);
        
        //UIImage * reFace = [UIImage UIImageFromCVMat:reconstructedFace];
        
        reconstructionMat.convertTo(reconstructedFace, CV_8U, 1, 0);
        //printMatInfo(reconstructedFace, "reconstructedFace");
        
        return reconstructedFace;
        
    }
    catch(cv::Exception e) {
        DLOG(@"Caught Exception in reconstructFace: %@", [NSString stringWithUTF8String:e.msg.c_str()]);
        return cv::Mat();
    }
}


-(void)drawRect:(cv::Rect)faceRect aroundImage:(cv::Mat&)image withColor:(cv::Scalar)scalar {
    
    //get the upper left point of our face coordinates
    cv::Point upLeftPoint(faceRect.x, faceRect.y);
    
    //get the bottom right point of our face coordinates
    cv::Point bottomRightPoint = upLeftPoint + cv::Point(faceRect.width, faceRect.height);
    cv::rectangle(image, upLeftPoint, bottomRightPoint, scalar, 4, 8, 0);
}


// Compare two images by getting the L2 error (square-root of sum of squared error).
//double getSimilarity(const Mat A, const Mat B)
-(double) getSimilarityWithMat:(cv::Mat&)A andMat:(cv::Mat)B {
    
    //UIImage * a = [UIImage UIImageFromCVMat:A];
    //UIImage * b = [UIImage UIImageFromCVMat:B];
    
    
    if (A.rows > 0 && A.rows == B.rows && A.cols > 0 && A.cols == B.cols) {
        // Calculate the L2 relative error between the 2 images.
        double errorL2 = norm(A, B, CV_L2);
        // Convert to a reasonable scale, since L2 error is summed across all pixels of the image.
        double similarity = errorL2 / (double)(A.rows * A.cols);
        return similarity;
    } else {
        //cout << "WARNING: Images have a different size in 'getSimilarity()'." << endl;
        DLOG(@"getSimilarityWithMat - WARNING: Images have a different size");
        return 100000000.0;  // Return a bad value
    }
}



#pragma mark ------------------- I/O methods ----------------------

//we pass in grayPreprocessedFaces for paramPreprocessedFaces
-(cv::Ptr<cv::FaceRecognizer>)learnCollectedFacesWithFaces:(cv::vector<cv::Mat>&)paramPreprocessedFaces
withLabels:(cv::vector<int>&)paramFaceLabels
andStrAlgorithm:(NSString*)facerecAlgorithm {
    
    DLOG(@"\nLearning the collected faces using the [ %@ ] algorithm ...", facerecAlgorithm);
    
    bool haveContribModule = cv::initModule_contrib();
    
    if(!haveContribModule) {
        DLOG(@"\nERROR: The 'contrib' module is needed for FaceRecognizer but has not been loaded into OpenCV!");
        return nil;
    }
    
    //model = cv::Algorithm::create<cv::FaceRecognizer>([facerecAlgorithm UTF8String]);
    model = cv::createEigenFaceRecognizer();

    if(model.empty()) {
        DLOG(@"\nERROR: The FaceRecognizer algorithm [ %@ ] is not available in your version of OpenCV. Please update to OpenCV v2.4.1 or newer.", facerecAlgorithm);
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docs = [paths objectAtIndex:0];
    NSString *trainedPath = [docs stringByAppendingPathComponent:@"trained.yml"];

    unsigned long numOfFaces = paramPreprocessedFaces.size();
    unsigned long numOfLabels = paramFaceLabels.size();
    
    DLOG(@"Training %u faces and %u labels: ", numOfFaces, numOfLabels);
    
    //we train on the gray preprocessed faces
    model->train(paramPreprocessedFaces, paramFaceLabels); //original
    
    //MODEL SAVING
    model->save([trainedPath UTF8String]);//save the model with current data structure
    
    DLOG(@"\nlearnCollectedFacesWithFaces - training complete...thank you for using FaceRecognizer. :)");
    return model;
}

//save a vector of cv::Mat 'faces' into 'fileName'
-(void)saveStructureToExternalFile:(NSString*)fileName
    withFaceImageStructure:(std::vector<cv::Mat> &)faces {
    
    //save our std::vector to file
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * docs = [paths objectAtIndex:0];
    NSString * path = [docs stringByAppendingPathComponent:fileName];
    DLOG(@"..saving structure to: %@", path);
    
    cv::FileStorage fileStorage([path UTF8String], cv::FileStorage::WRITE);
    
    fileStorage << "faces" << faces;
    fileStorage.release();
    
    DLOG(@"saveStructureToExternalFile - %u cv::Mats saved to %@", faces.size(), fileName);
}


//sort ascending
bool smallestToLargest( int i, int j ) {
    return i < j;
}

//save our face label structure 'labels' into 'fileName'
-(void)saveStructureToExternalFile:(NSString*)fileName
            withFaceLabelStructure:(std::vector<int>&)labels {

    //save our std::vector to file
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * docs = [paths objectAtIndex:0];
    NSString * path = [docs stringByAppendingPathComponent:fileName];
    DLOG(@"..saving structure to: %@", path);
    
    cv::FileStorage fileStorage([path UTF8String], cv::FileStorage::WRITE);
    
    //sort our face labels from smallest to largest...
    std::sort(faceLabels.begin(), faceLabels.end(), smallestToLargest );
    
    //then save it into our file
    fileStorage << "labels" << labels;
    fileStorage.release();
    
    DLOG(@"saveStructureToExternalFile - %u labels saved to %@", labels.size(), fileName);
}


//private
-(void)saveStructureToExternalFile:(NSString*)fileName
            withFaceImageStructure:(std::vector<cv::Mat>&)faces
             andFaceLabelStructure:(std::vector<int>&)labels {
    
    //save our std::vector to file
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * docs = [paths objectAtIndex:0];
    NSString * path = [docs stringByAppendingPathComponent:fileName];
    DLOG(@"..saving structure to: %@", path);

    cv::FileStorage fileStorage([path UTF8String], cv::FileStorage::WRITE);
    
    fileStorage << "faces" << faces;
    fileStorage << "labels" << labels;
    fileStorage.release();
    
    DLOG(@"saveStructureToExternalFile - %u cv::Mats saved to %@", faces.size(), fileName);
}


//load data from file and populate parameter std::vector LABELS with it
-(void)loadStructureFromExternalFile:(NSString*)fileName
               withFaceLabelStructure:(std::vector<int>&)labels {
    
    //save our std::vector to file
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * docs = [paths objectAtIndex:0];
    NSString * path = [docs stringByAppendingPathComponent:fileName];
    DLOG(@"..loading structure from: %@", path);
    
    cv::FileStorage fileStorage([path UTF8String], cv::FileStorage::READ);
    
    fileStorage["labels"] >> labels;
    fileStorage.release();
    
    DLOG(@"LOADED - %u face labels loaded to data structure and faceLabels", labels.size());
}

//load data from file and populate parameter std::vector FACES with it
-(void)loadStructureFromExternalFile:(NSString*)fileName
              withFaceImageStructure:(std::vector<cv::Mat>&)faces {
    
    //save our std::vector to file
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * docs = [paths objectAtIndex:0];
    NSString * path = [docs stringByAppendingPathComponent:fileName];
    DLOG(@"..loading structure from: %@", path);
    
    cv::FileStorage fileStorage([path UTF8String], cv::FileStorage::READ);
    
    //TODO....append to cv::Mat instead of direct copy
    fileStorage["faces"] >> faces; //reload all of our mats back into this temporary structure
    fileStorage.release();
    
    DLOG(@"LOADED - %u faces cv::Mats loaded from %@ to data structure preprocessedFaces: ", faces.size(), fileName);
}


//load data from file and populate parameter std::vector FACES AND LABELS with it
-(void)loadStructureFromExternalFile:(NSString*)fileName
            withFaceImageStructure:(std::vector<cv::Mat>&)faces
             andFaceLabelStructure:(std::vector<int>&)labels {
    
    //save our std::vector to file
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * docs = [paths objectAtIndex:0];
    NSString * path = [docs stringByAppendingPathComponent:fileName];
    DLOG(@"..loading structure from: %@", path);
    
    DLOG(@"address of preprocessedFaces: %p", &preprocessedFaces);
    DLOG(@"address of faces: %p", &faces);
    
    cv::FileStorage fileStorage([path UTF8String], cv::FileStorage::READ);
    
    fileStorage["faces"] >> faces; //reload all of our mats back into this temporary structure
    fileStorage["labels"] >> labels;
    fileStorage.release();
    
    DLOG(@"LOADED - faces and label cv::Mats loaded to data structure preprocessedFaces and faceLabels");
}


//1) clean out existing data structure
//2) fill up our existing data structure from content of custom.yml
//3) load all user profiles
-(void)updateStructuresWithDiskData {
    
    [self resetAll]; //clean out anything previous
    
    [self loadUsersNameTable]; //load user names
    
    if(nameKeyTable) {
        
        //when we load, we must load 0, 1, 2, 3...etc
        //the keys must be in order.
        
        for ( int i = 0; i < [nameKeyTable count]; i++) {
            
            //the keys are basically index..from 0...to n
            //we change the index to string, and plug it into our nameKeyTable to get the name
            NSString * key = [NSString stringWithFormat:@"%u",i];
            
            NSString * profileName = [nameKeyTable objectForKey:key];
            NSString * fileName = [NSString stringWithFormat:@"%@.yml", profileName];

            // create a temp vector
            std::vector<cv::Mat> tempVector;
            std::vector<int> tempLabels;
            
            [self loadStructureFromExternalFile:fileName withFaceImageStructure:tempVector andFaceLabelStructure:tempLabels];
            
            //have preprocessface append that vector
            preprocessedFaces.insert(preprocessedFaces.end(), tempVector.begin(), tempVector.end());
            faceLabels.insert(faceLabels.end(), tempLabels.begin(), tempLabels.end());
            
            if(faceLabels.size() != preprocessedFaces.size()) {
                DLOG(@"face labels and preprocessedFaces size not same. something is wrong");
            }
        }
    }
}


#pragma mark ------------------- image processing methods ----------------------


// Normalizes a given image into a value range between 0 and 255.
-(cv::Mat)norm_0_255:(cv::Mat&)src {
  
    // Create and return normalized image:
    cv::Mat dst;
    switch(src.channels()) {
        case 1:
            cv::normalize(src, dst, 0, 255, cv::NORM_MINMAX, CV_8UC1);
            break;
        case 3:
            cv::normalize(src, dst, 0, 255, cv::NORM_MINMAX, CV_8UC3);
            break;
        default:
            src.copyTo(dst);
            break;
    }
    return dst;
}


//
// Calculates the TanTriggs Preprocessing as described in:
//
// Tan, X., and Triggs, B. "Enhanced local texture feature sets for face
// recognition under difficult lighting conditions.". IEEE Transactions
// on Image Processing 19 (2010), 1635–650.
//
// Default parameters are taken from the paper.
//
/* //use like this:
 
 
 cv::Mat grayMat = [self grayCVMat:colorMat];
 //UIImage * grayTmp = [UIImage UIImageFromCVMat:grayMat];
 
 
 // DLOG(@"%u %u", grayMat.cols, grayMat.rows);
 //test it out here
 cv::Mat tanTriggedMat = [self tan_triggs_preprocessingWithInputArray:grayMat andAlpha:0.1 andTau:10.0 andGamma:0.2 andSigmaZero:1 andSigmaOne:2];
 //UIImage * tempTT = [UIImage UIImageFromCVMat:tanTriggedMat];
 
 
 tanTriggedMat = [self norm_0_255: tanTriggedMat];
 
 UIImage * tempNormed = [UIImage UIImageFromCVMat:tanTriggedMat];
 
 */
-(cv::Mat)tan_triggs_preprocessingWithInputArray:(cv::InputArray)src
andAlpha:(float)alpha
andTau:(float)tau
andGamma:(float)gamma
andSigmaZero:(int)sigmaZero
andSigmaOne:(int)sigmaOne {
    
    // Convert to floating point:
    cv::Mat X = src.getMat();
    X.convertTo(X, CV_32FC1);
    // Start preprocessing:
    cv::Mat I;
    cv::pow(X, gamma, I);
    // Calculate the DOG Image:
    {
        cv::Mat gaussian0, gaussian1;
        // Kernel Size:
        int kernel_sz0 = (3*sigmaZero);
        int kernel_sz1 = (3*sigmaOne);
        // Make them odd for OpenCV:
        kernel_sz0 += ((kernel_sz0 % 2) == 0) ? 1 : 0;
        kernel_sz1 += ((kernel_sz1 % 2) == 0) ? 1 : 0;
        
        cv::GaussianBlur(I, gaussian0,
                         cv::Size(kernel_sz0,kernel_sz0),
                         sigmaZero, sigmaZero,
                         cv::BORDER_CONSTANT);
        
        cv::GaussianBlur(I, gaussian1,
                         cv::Size(kernel_sz1,kernel_sz1),
                         sigmaOne, sigmaOne,
                         cv::BORDER_CONSTANT);
        cv::subtract(gaussian0, gaussian1, I);
    }
    
    {
        double meanI = 0.0;
        {
            cv::Mat tmp;
            cv::pow(cv::abs(I), alpha, tmp);
            meanI = mean(tmp).val[0];
            
        }
        I = I / cv::pow(meanI, 1.0/alpha);
    }
    
    {
        double meanI = 0.0;
        {
            cv::Mat tmp;
            cv::pow(cv::min(cv::abs(I), tau), alpha, tmp);
            meanI = cv::mean(tmp).val[0];
        }
        I = I / pow(meanI, 1.0/alpha);
    }
    
    // Squash into the tanh:
    {
        for(int r = 0; r < I.rows; r++) {
            for(int c = 0; c < I.cols; c++) {
                I.at<float>(r,c) = tanh(I.at<float>(r,c) / tau);
            }
        }
        I = tau * I;
    }
    return I;
}



-(void)bilateralFilterCVMat:(cv::Mat&)image {
    
    // Use the "Bilateral Filter" to reduce pixel noise by smoothing the image, but keeping the sharp edges in the face.
    cv::Mat filtered = cv::Mat(image.size(), CV_8UC3);
    cv::bilateralFilter(image, filtered, 0, 20.0, 2.0);
}

//http://docs.opencv.org/doc/tutorials/imgproc/histograms/histogram_equalization/histogram_equalization.html
/*
 It is a method that improves the contrast in an image, in order to stretch out the intensity range.
 To make it clearer, from the image above, you can see that the pixels seem clustered around the middle of the available range of intensities. What Histogram Equalization does is to stretch out this range.
 */
-(void)equalizeCVMat:(cv::Mat&)image {

    cv::equalizeHist(image, image);
}

-(cv::Mat)grayCVMat:(cv::Mat&)colored {
                        
    cv::Mat gray;
    
    //graying the image
    if (colored.channels() == 3)
    {
        cvtColor(colored, gray, CV_BGR2GRAY);
    }
    else if (colored.channels() == 4)
    {
        cvtColor(colored, gray, CV_BGRA2GRAY);
    }
    else
    {
        gray = colored;
    }
    
    return gray;
}

-(cv::Mat)resizeCVMat:(cv::Mat&)matImage withHeight:(int)height andWidth:(int)width
{
    cv::Size size = cv::Size(cvRound(height), cvRound(width));
    cv::resize(matImage, matImage, size);
    
    return matImage;
}

#pragma mark ------------------- 'access to delegate' methods ----------------------

-(void)showMessageOnDelegateView:(NSString*)title andMessage:(NSString*)message andCancelTitle:(NSString*)cancelTitle{
    //DLOG(@"DataModel.m - showMessageOnDelegateView");
    if([self.delegate respondsToSelector:@selector(showMessageBox:andMessage:andCancelTitle:)]) {
        [delegate showMessageBox:title andMessage:message andCancelTitle:cancelTitle];
    }
}

-(void)animateTrainingOnDelegateView:(bool)flag{
    //DLOG(@"DataModel.m - animateTrainingOnDelegateView");
    if([self.delegate respondsToSelector:@selector(animateTraining:)]) {
        [delegate animateTraining:flag];
    }
}

-(void)updateNumOfFacesLabelOnDelegateView{
    //DLOG(@"DataModel.m - updateNumOfFacesLabelOnDelegateView");
    if([self.delegate respondsToSelector: @selector(updateNumOfFacesLabel:)]) {
        [delegate updateNumOfFacesLabel:[NSString stringWithFormat:@"%lu", preprocessedFaces.size()/2]];
    }
}



-(void)incrementIdentityValueOnDelegateView:(double)similarity{
    //DLOG(@"DataModel.m - incrementIdentityValueOnDelegateView");
    if ([self.delegate respondsToSelector:@selector(incrementIdentityValue:)]) {
        [delegate incrementIdentityValue:similarity];
    }
}




-(void)showIdentity:(int)identity{
    
    NSString * identityID = [NSString stringWithFormat:@"%u", identity];
    NSString * identityName = [nameKeyTable objectForKey: identityID];
    
    DLOG(@"%@", identityName);
    
    if([self.delegate respondsToSelector:@selector(showIdentityInt:andName:)]){
        [delegate showIdentityInt:identity andName:identityName];
    }
}

-(void)showSimilarityDelegateView:(double)similarity {
    if ([self.delegate respondsToSelector:@selector(showSimilarity:)]) {
        [delegate showSimilarity:similarity];
    }
}


-(void)addFacesToCarouselOnDelegateView {
    if([self.delegate respondsToSelector: @selector(addFacesToCarousel)]) {
        [delegate addFacesToCarousel];
    }
}

-(void)clearFacesInCarouselOnDelegateView{
    //tell whatever view is showing our carousel to clear its faces
    if([self.delegate respondsToSelector:@selector(clearFacesInCarousel)]) {
        [delegate clearFacesInCarousel];
    }

}


-(void)setTrainButtonOnDelegateView:(bool)flag{
    //DLOG(@"DataModel.m - setTrainButtonOnDelegateView");
    if([delegate respondsToSelector:@selector(setTrainButton:)]){
        [delegate setTrainButton:flag];
    }
}

-(void)setRecognizeButtonOnDelegateView:(bool)flag{
    //DLOG(@"DataModel.m - setRecognizeButtonOnDelegateView");
    if([delegate respondsToSelector:@selector(setRecognizeButton:)]){
        [delegate setRecognizeButton:flag];
    }
}


#pragma mark ------------------- MODE methods ----------------------

-(cv::Ptr<cv::FaceRecognizer>)getModel{ return model; }
-(bool)isModeCollectingFaces{ return (m_mode == MODE_COLLECT_FACES); }
-(bool)isModeTraining{ return (m_mode == MODE_TRAINING); }
-(bool)isModeDetecting{ return (m_mode == MODE_DETECTION); }
-(bool)isModeRecognizing{ return (m_mode == MODE_RECOGNITION); }
-(bool)isModeEnd { return (m_mode==MODE_END); }

-(void)setModeToStop{m_mode=MODE_END;DLOG(@"End All Processing");}
-(void)setModeToTraining{ m_mode=MODE_TRAINING; DLOG(@"Now going to training mode");}
-(void)setModeToDetection{ m_mode = MODE_DETECTION; DLOG(@"Now going to detection mode");}
-(void)setModeToRecognition{ m_mode = MODE_RECOGNITION; DLOG(@"Now going to recognition mode");}
-(void)setModeToCollectingFace{ m_mode = MODE_COLLECT_FACES; DLOG(@"Now going to collecting faces mode");}


//used in registration only
-(void)doModeTraining {
    
    DLOG(@"------> TRAINING PREPROCESSED FACES AND FACE LABELS............");
    
    bool haveEnoughData = true;
    
    DLOG(@"faceLabels size is: %u, preprocessedFaces.size(): %u", faceLabels.size(), preprocessedFaces.size());
    
    if (preprocessedFaces.size() <= 0 || preprocessedFaces.size() != faceLabels.size()) {
        
        DLOG(@"\nWarning: Need some training data before it can be learnt! Collect more data ...警告：需要可以学到之前，一些培训资料！收集更多的数据...");
        haveEnoughData = false;
        [self showMessageOnDelegateView:@"警告 Warning" andMessage:@"收集更多的数据 Need some training data before it can be learnt! Collect more data" andCancelTitle:@"行"];
        [self setModeToDetection];
        return;
    }
    
    if (haveEnoughData) {
        
        //make sure we clear our gray faces vector from last time and start fresh
        grayPreprocessedFaces.clear();
        
        for(int i = 0; i < preprocessedFaces.size(); i++) {
            
            cv::Mat grayedMatImage = [self grayCVMat: preprocessedFaces[i]];
            
            //test it out here
            cv::Mat tanTriggedMat = [self tan_triggs_preprocessingWithInputArray:grayedMatImage andAlpha:0.1 andTau:10.0 andGamma:0.2 andSigmaZero:1 andSigmaOne:2];
            tanTriggedMat = [self norm_0_255: tanTriggedMat];
            grayPreprocessedFaces.push_back(tanTriggedMat);
        }
    
        //TRAIN GRAYSCALE
        //[self setRecognizeButtonOnDelegateView:false];

        [self setTrainButtonOnDelegateView:false];
        [self setModeToDetection];

        NSOperationQueue * operationQueue = [[NSOperationQueue new] autorelease];
        
        // Create a new NSOperation object using the NSInvocationOperation subclass.
        // Tell it to run the counterTask method.
        NSInvocationOperation * operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                                selector:@selector(trainFacesOpMethod)
                                                                                  object:nil];
        // Add the operation to the queue and let it to be executed.
        [operationQueue addOperation:operation];
        [operation release];
    }
}


//does training for all the collected images and ids in our preprocessedFaces data structure
//as well as
-(void)trainFacesOpMethod {
    
    //make sure preprcoessed faces has images and face labels have all the face ids in them
    
    if([self learnCollectedFacesWithFaces:grayPreprocessedFaces withLabels:faceLabels andStrAlgorithm:@"FaceRecognizer.Eigenfaces"]){
        [self showMessageOnDelegateView:@"信息" andMessage:@"培训完成...感谢您使用FaceRecognizer. Thank you for using FaceRecognizer." andCancelTitle:@"行"];
        //[self reEnableRecognizeButtonAfterTraining];
        [self setTrainButtonOnDelegateView:true];
    }
}

-(void)reEnableRecognizeButtonAfterTraining {
    
    [self setRecognizeButtonOnDelegateView:true];
}

-(void)doModeCollectFaces:(cv::Mat&)paramPreprocessedFace
            withFlashRect:(cv::Rect&)flashRect
                  onImage:(cv::Mat&)image {
    
    
    if(paramPreprocessedFace.data) {
        
        //note: face drawn inside of getPreprocessedFace if it existed
        
        //no drawing for you eyes around here...maybe in the future >:)
        
        //we already know we got a face, so let's collect
        double imageDiff = 10000000000.0;
        
        if (old_prepreprocessedFace.data)
        {
            imageDiff = [self getSimilarityWithMat:paramPreprocessedFace andMat:old_prepreprocessedFace];
        }
        
        // Also record when it happened.
        double current_time = (double)cv::getTickCount();
        double timeDiff_seconds = (current_time - old_time)/cv::getTickFrequency();
        
        // Only process the face if it is noticeably different from the previous frame and there has been noticeable time gap.
        if ((imageDiff > CHANGE_IN_IMAGE_FOR_COLLECTION) && (timeDiff_seconds > CHANGE_IN_SECONDS_FOR_COLLECTION))
        {
            // Also add the mirror image to the training set, so we have more training data, as well as to deal with faces looking to the left or right.
            cv::Mat mirroredFace;
            cv::flip(paramPreprocessedFace, mirroredFace, 1);
            
            //preprocessedFace is in blue now, let's transfer it to color
            
            UIImage * tmp = [UIImage UIImageFromCVMat:paramPreprocessedFace];
            cv::Mat colorMat = [UIImage cvMatFromUIImage:tmp fromBlueToColor:YES];
            
            
            //mirrored
            UIImage * mirroredTmp = [UIImage UIImageFromCVMat:mirroredFace];
            cv::Mat colorMirroredMat = [UIImage cvMatFromUIImage:mirroredTmp fromBlueToColor:YES];
            
            // we add the colored face images to the list of detected faces.
            preprocessedFaces.push_back(colorMat);
            preprocessedFaces.push_back(colorMirroredMat);
            
            
            faceLabels.push_back(m_userId);
            faceLabels.push_back(m_userId);
            
            // we add the GRAYSCALE face images to the list of detected faces.
            DLOG(@"preprocessedFaces.size: %lu", preprocessedFaces.size());
            DLOG(@"faceLabels.size: %lu", faceLabels.size());
            
            //let's not add face images to carousels
            //[self addFacesToCarouselOnDelegateView];
            
            // Keep a reference to the latest face of each person.
            m_latestFaces[0] = preprocessedFaces.size() - 2.0f;  // Point to the non-mirrored face.
            
            DLOG(@"Saved face %lu for person %d", (preprocessedFaces.size()/2), m_userId);
            
            DLOG(@"preprocessed faces is: %u, face labels is: %u", preprocessedFaces.size(), faceLabels.size());
            
            // Make a white flash on the face, so the user knows a photo has been taken.
            cv::Mat displayedFaceRegion = image(flashRect);
            displayedFaceRegion += CV_RGB(90,90,90);
            
            if([self.delegate respondsToSelector: @selector(updateNumOfFacesLabel:)]) {
                [delegate updateNumOfFacesLabel:[NSString stringWithFormat:@"%lu", preprocessedFaces.size()/2]];
            }
    
            // Keep a copy of the processed face, to compare on next iteration.
            old_prepreprocessedFace = paramPreprocessedFace;
            old_time = current_time;
        }
    }

}


//process when we are in recognition mode
-(void)doModeRecognition:(cv::Mat)paramPreprocessedFace {
    
    int identity = -1;
    
    //if ((preprocessedFaces.size() > 0) && (preprocessedFaces.size() == faceLabels.size())) {
    
    if (model && !model.empty()) {
        
        cv::Mat grayedPreprocessedFace = [self grayCVMat:paramPreprocessedFace];
        
        //test it out here
        cv::Mat tanTriggedMat = [self tan_triggs_preprocessingWithInputArray:grayedPreprocessedFace andAlpha:0.1 andTau:10.0 andGamma:0.2 andSigmaZero:1 andSigmaOne:2];
        tanTriggedMat = [self norm_0_255: tanTriggedMat];
        
        //reconstructFace should take grayscle ONLY: NOTE : FOR EIGENFACES AND FISHERFAC
        cv::Mat reconstructedFace = [self reconstructFaceWithCVMat:tanTriggedMat];
        
        double similarity = [self getSimilarityWithMat: tanTriggedMat andMat:reconstructedFace]; //tan triggs
        DLOG(@"similarity: %f", similarity);
        [self showSimilarityDelegateView:similarity];
        
        if (similarity < self.threshold) //WE HAVE A MATCH OF AN IDENTITY
        {
            try {
                identity = model->predict(tanTriggedMat);
                
                //LET'S PIGEONHOLE OUR IDENTITY. WHEN THE 100% TAKES PLACE, THE HIGHEST IDENTIY IS THE PERSON
                
                NSString * key = [NSString stringWithFormat:@"%u", identity];
                NSString * name = [nameKeyTable objectForKey:key];
                
                NSString * count = [recognitionCount objectForKey:name];
                int iCount = 0;
                
                if(count == nil)
                {
                    count = @"0";
                    [recognitionCount setObject:count forKey:name];
                    iCount = 0;
                }
                else
                {
                    iCount = (int)[count integerValue];
                    iCount++;
                }
                
                [recognitionCount setObject:[NSString stringWithFormat:@"%i", iCount] forKey:name];
                
                DLOG(@"---------------------------------> int id: %u, name: %@, count: %i",
                     identity, name, iCount);
            }
            catch(cv::Exception e) {
                e.formatMessage();
            }
            
            //tell our UIVIEWCONTROLLER to increment identity approval value (0 to 100) for similarity
            [self incrementIdentityValueOnDelegateView:similarity];
            
            //tell our UIVIEWCONTROLLER to show the identity of this person
            //[self showIdentity: identity];
        }
    }
}


#pragma mark ------------------- MAIN METHOD ----------------------

-(bool)ProcessFace:(cv::Mat&)image {
    
    // Run the face recognition system on the camera image. It will draw some things onto the given image, so make sure it is not read-only memory!
    if(m_mode==MODE_END) {
        
        DLOG(@"ProcessFace: END PROCESSING IMAGES");
        return false;
    }
    
    cv::Rect faceRect;
    //don't modify the original
    cv::Mat displayedFrame;
    image.copyTo(displayedFrame);
    //we work with displayedFrame from now on
    
    cv::Mat preprocessedFace = [self getPreprocessedFace:displayedFrame
                                                withFaceWidth:70
                                        withCascadeClassifier:*faceCascadePtr
                                                 withFaceRect:faceRect];
    //DRAW THE FACE!
    if(faceRect.height > 0){
        [self drawRect:faceRect aroundImage:image withColor:cv::Scalar(255, 0, 255)];
    }
    
    if (m_mode == MODE_RECOGNITION) {
        
        [self doModeRecognition: preprocessedFace];
    }
    else if (m_mode == MODE_TRAINING) {
        
        [self doModeTraining];
    }
    else if(m_mode == MODE_COLLECT_FACES) {
        
        [self doModeCollectFaces:preprocessedFace withFlashRect:faceRect onImage:image];
    }
    
    return true;
}


#pragma mark ------ private ------------

-(void)saveFaceLabelDataStructure:(std::vector<int>&)faceLabelDS toFolder:(NSString*)folder
{
    DLOG(@"faceLabels.size() is: %u", faceLabels.size());
    
    FileOps * myFile = [[FileOps alloc] init];
    NSMutableString * arrayIDs = [NSMutableString stringWithFormat:@""];
    
    for ( int j = 0 ; j < faceLabels.size(); j++)
    {
        NSString * strUsrID = [NSString stringWithFormat:@"%u,", faceLabels[j]];
        [arrayIDs appendString:strUsrID];
        //DLOG(@"%u arrayIDs is now: %@", j, arrayIDs);
    }
    
    [myFile saveAllUserIDasString:arrayIDs inFolder:@"faces"];
    [myFile release];
}

-(void)saveNameKeyDictionary:(NSMutableDictionary*)dict ToFolder:(NSString*)folder {
    FileOps * myFile = [[FileOps alloc] init];
    [myFile saveUserKeyTable:dict inFolder:folder];
    [myFile release];
}

-(NSMutableDictionary*)loadNameKeyDictionaryFromFolder:(NSString*)folder {
    FileOps * myFile = [[[FileOps alloc] init] autorelease];
    return [myFile dictLoadUserKeyTableFromFolder:folder];
}

-(void)alertWithTitle:(NSString*)title andMessage:(NSString*)msg andDelegate:(id)del andCancel:(NSString*)cancelMsg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView * warn = [[UIAlertView alloc] initWithTitle:title
                                                        message:msg
                                                       delegate:del
                                              cancelButtonTitle:cancelMsg
                                              otherButtonTitles:nil];
        [warn show]; [warn release];
    });
}





#pragma mark ------ REGISTRATION METHODS ------------

-(NSUInteger)getNumOfProfiles
{
    if(nameKeyTable)
        return [nameKeyTable count];
    else return -1;
}


//converts dictionary to array
-(NSMutableArray*)mutableArrayGetProfiles {
    NSMutableDictionary * dict = [self loadNameKeyDictionaryFromFolder:@"faces"];
    NSMutableArray * array = [NSMutableArray array]; //autoreleased
    
    for (NSString * key in [dict allKeys]) {
        DLOG(@"key: %@, value: %@", key, [dict objectForKey:key]);
        [array addObject:[dict objectForKey:key]];
    }
    return array;
}

//sets the current user ID for adding images into our data structure
//we setthis current user ID by looking through our dictionary by using name
-(void)setUserId:(NSString*)name {
    
    //TODO have user id match up with user name
    NSArray* arrayOfKeys = [nameKeyTable allKeysForObject:name];
    NSNumber * newId = (NSNumber*)[arrayOfKeys objectAtIndex:0];
    
    if(newId.intValue < m_curUsers) {
        m_userId = newId.intValue;
    }
    else {
        
        [delegate showMessageBox:@"error" andMessage:@"user id out of bounds" andCancelTitle:@"ok"];
        return;
    }
}

-(void)incrementPersonIDIfNewAdd:(NSString*)userIdName andAppendExisting:(bool)addToExisting {
    
    DLOG(@"incremented person ID");
    
    // whenever we increment the person ID, it means the previous person was saved already
    
    // "0" --> "name 1"
    // "1" -->  "name 2"
    // "x" --> "name y"
    
    if(addToExisting) {
        return;
    }
    else {
        //NEW PROFILE ADD
        [nameKeyTable setObject:userIdName forKey: [NSString stringWithFormat:@"%u", m_curUsers]];
        m_userId = ++m_curUsers;
    }
}


-(void)util_appendCollectedImagesToProfileUsingFileName:(NSString*)fileName toFaces:(std::vector<cv::Mat>&)faces
                                         andLabels:(std::vector<int>&)labels
{
    std::vector<cv::Mat> fileFaces;
    std::vector<int> fileLabels;
    
    //1) load in myFile.xml data into preprocessedFaces FIRST
    [self loadStructureFromExternalFile:fileName withFaceImageStructure:fileFaces andFaceLabelStructure:fileLabels];
    
    //2) load in the file data
    preprocessedFaces.insert(preprocessedFaces.end(), fileFaces.begin(), fileFaces.end());
    
    //have the collected new face labels be appended behind faceLabels
    faceLabels.insert(faceLabels.end(), fileLabels.begin(), fileLabels.end() );
    
    //3) have the collected new images/labels be appended behind preprocessedFaces/faceLabels
    preprocessedFaces.insert(preprocessedFaces.end(), faces.begin(), faces.end());
    
    //have the collected new face labels be appended behind faceLabels
    faceLabels.insert(faceLabels.end(), labels.begin(), labels.end() );
    
    //save it all back into the file
    [self saveStructureToExternalFile:fileName withFaceImageStructure:preprocessedFaces andFaceLabelStructure:faceLabels];
}


-(void)updateFaceLabels:(NSMutableDictionary*)dictNameTable {
    
    if(dictNameTable) {
        
        NSArray * keys = [dictNameTable allKeys];
        keys = [keys sortedArrayUsingComparator:^(id a, id b) {
            return [a compare:b options:NSNumericSearch];
        }];
        
        //CORRECTLY LOAD IN ALL FACE LABELS
        for (int i = 0 ; i < [keys count]; i++) {
            
            NSString * key = [keys objectAtIndex:i];
            NSString * name = [dictNameTable valueForKeyPath:key];
            NSString * fileName = [NSString stringWithFormat:@"%@.yml", name];
            
            //we have our fileName.yml
            std::vector<int>tempLabels;
            [self loadStructureFromExternalFile:fileName withFaceLabelStructure:tempLabels]; //load face labels of 0,1,2,3..faces
            faceLabels.insert(faceLabels.end(), tempLabels.begin(), tempLabels.end() ); //append to our face labels
        }
    } else {
        DLOG(@"Error, parameter is nil");
    }
}

-(void)saveFaceCollectionToDisk:(bool)appendToProfile {
    
    DLOG(@"current user is m_userId at: %u", m_userId);
    DLOG(@"pushed save faces from disk button");
    
    //save all images in our preprocessed vector into faces folder
    if(preprocessedFaces.size() <=0) {
        
        [self alertWithTitle:@"警告" andMessage:@"No faces to save. Please collect some faces first.(没有面临保存。请您先收集一些面孔。)" andDelegate:self andCancel:@"行"];
        return;
    }
    
    FileOps * myFile = [[[FileOps alloc] init] autorelease];
    
    if([myFile createDirectoryInSandbox:@"faces"]) {

        DLOG(@"preprocessedFaces.size() is: %u", preprocessedFaces.size());
        
        //in saving name key dictionary, make sure we save the number of face labels
        [self saveNameKeyDictionary:nameKeyTable ToFolder:@"faces"];
            
        int indexToGet = m_userId;
        //if its a new add
        if(!appendToProfile) {
            indexToGet = m_userId - 1;
        }
       
        //may return nil
        NSString * profileName = [nameKeyTable objectForKey:[NSString stringWithFormat:@"%i", indexToGet]];
        NSString * fileName;
        
        if(profileName) {
            
            fileName = [NSString stringWithFormat:@"%@.yml", profileName];
        
            [myFile listAllInFolder:@""];
            
            //now that we ensured the user took some photos we let's have temporary ds save the images that we just snapped
            std::vector<cv::Mat> preprocessedFacesTemp;
            std::vector<int> faceLabelsTemp;
            
            //save the newly collected pictures into temporary vector
            preprocessedFacesTemp = preprocessedFaces;
            
            //save the newly collected face labels into temporary vector
            faceLabelsTemp = faceLabels;
            
            //empty our preprocesedFaces so we can enter correct data
            preprocessedFaces.clear();
            faceLabels.clear();
            
            
            //1) if (.yml file exist, load into preprocessed file)
            if([myFile doesFile:fileName existInFolder:@""]) {
                
                [self util_appendCollectedImagesToProfileUsingFileName:fileName toFaces:preprocessedFacesTemp andLabels:faceLabelsTemp];
            }
            else {
                // now that we have all previous faces + new faces, we save it into into profileName.yml file
                [self saveStructureToExternalFile:fileName withFaceImageStructure:preprocessedFacesTemp andFaceLabelStructure:faceLabelsTemp];
            }
            
            //loop through all .yml files in our nameKeyTable, and append all the face labels so that we can get the correct ids.txt
            faceLabels.clear();
            
            [self updateFaceLabels:nameKeyTable];
            
            //WRITING OUT THE IDS.TXT
            if(faceLabels.size() > 0) {
                
                FileOps * myFile = [[FileOps alloc] init];
                NSMutableString * arrayIDs = [NSMutableString stringWithFormat:@""];
                for ( int j = 0 ; j < faceLabels.size(); j++) {
                    
                    NSString * strUsrID = [NSString stringWithFormat:@"%u,", faceLabels[j]];
                    [arrayIDs appendString:strUsrID];
                }
                [myFile saveAllUserIDasString:arrayIDs inFolder:@"faces"];
                [myFile release];
            }
            
            
            faceLabels.clear();
            preprocessedFaces.clear();
            
            [self alertWithTitle:@"警告"
                      andMessage:@"Collected faces saved to disk (保存到磁盘上收集的面孔)"
                     andDelegate:self
                       andCancel:@"行"];
            
        } //if a profile name is found
        else {
            DLOG(@"no profile name found");
        }
    }
    [myFile listAllInFolder:@"faces"];
}


//load all user profiles and set up our cur and userid
-(void)loadUsersNameTable
{
    FileOps * myFile = [[FileOps alloc] init];
    
    NSMutableDictionary * temp = [myFile dictLoadUserKeyTableFromFolder:@"faces"];
    
    if(temp!=nil)
    {
        self.nameKeyTable = temp;
    }
    
    //error check
    if([self.nameKeyTable count] <=0){
        [self showMessageOnDelegateView:@"No faces loaded" andMessage:@"Empty" andCancelTitle:@"ok"];
        [self setModeToDetection];
        [myFile release];
    }
    
    m_curUsers = m_userId = (int)[self getNumOfProfiles];
}

-(void)clearAllDataOnDisk
{
    FileOps * myFile = [[FileOps alloc] init];
    if([myFile removeAllFilesFromFolder:@"faces"])
    {
        [self showMessageOnDelegateView:@"警告" andMessage:@"disk cleared (磁盘清理) in folder faces" andCancelTitle:@"行"];
    }
    
    if([myFile removeAllFilesFromFolder:@""])
    {
        [self showMessageOnDelegateView:@"警告" andMessage:@"disk cleared (磁盘清理) in folder Documents" andCancelTitle:@"行"];
    }
    
    [self resetAll];
    [myFile release];
}

-(NSMutableArray*)arrayGetCountFromProfiles {
    
    FileOps * myFile = [[FileOps alloc] init];
    NSString * idStr = [myFile getStringFromIdsTxt:@"ids.txt"];
    
    NSMutableString * result;
    NSMutableArray * counts = [NSMutableArray array];
    
    if(idStr) {
        
        result = [NSMutableString stringWithString:idStr];
        DLOG(@"%@", result);
        
        NSUInteger occurrences;
        //key will give me 0, 1, 2, .....etc
        for ( NSString * key in [nameKeyTable allKeys] ) {
            
            //hence, we'll have 0,1,2......n (each key is a profile) and see how many occurrences of each.
            occurrences = [result replaceOccurrencesOfString:key
                                                  withString:key
                                                     options:NSLiteralSearch
                                                       range:NSMakeRange(0, [result length])];
            
            //occurrences is here, we should insert into nameKeyTable
            DLOG(@"(profile) key %@ has %u ocurrences",key, occurrences);
            [counts addObject: [NSNumber numberWithInteger:occurrences]];
        }
    }
    else {
        DLOG(@"no content in ids.txt. This means, there are currently, no profiles");
    }
    
    [myFile release];
    
    //we return all counts of all profiles
    return counts;
}

-(void)emptyFaceAndLabelStructures
{
    preprocessedFaces.clear();
    faceLabels.clear();
}

#pragma mark ------ OTHER ------------

-(NSString *)getRecognizedPerson {
    NSArray * allValues = [recognitionCount allValues];
    int max = [[allValues valueForKeyPath:@"@max.intValue"] intValue];
    
    //NSInteger index = [allValues indexOfObject:[NSString stringWithFormat:@"%i", max]];
    
    NSArray * arrayOfKeys = [recognitionCount allKeysForObject:[NSString stringWithFormat:@"%u", max]];
    
    if(arrayOfKeys) {
        return [arrayOfKeys objectAtIndex:0];
    }
    return nil;
}

-(void)emptyRecognitionCount{
    [recognitionCount removeAllObjects];
}


@end

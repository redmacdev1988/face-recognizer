//
//  FileOps.h
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 4/10/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileOps : NSObject
{
    NSFileManager *fileMgr;
    NSString *homeDir;
    NSString *filename;
    NSString *filepath;
}

@property(nonatomic,retain) NSFileManager *fileMgr;
@property(nonatomic,retain) NSString *homeDir;
@property(nonatomic,retain) NSString *filename;
@property(nonatomic,retain) NSString *filepath;


-(bool)createDirectoryInSandbox:(NSString*)directoryName;

-(NSString *) GetDocumentDirectory;


//saves image in your sandbox directory path
-(void) saveImage:(UIImage *)image
     withFileName:(NSString *)imageName
           ofType:(NSString *)extension
      inFolder:(NSString *)folderName;

-(void)saveUserKeyTable:(NSMutableDictionary*)dict inFolder:(NSString*)folderName;

-(NSMutableDictionary*)dictLoadUserKeyTableFromFolder:(NSString*)folderName;
-(NSMutableArray*)arrayLoadUserKeyTableFromFolder:(NSString*)folderName;

-(void)saveAllUserIDasString:(NSString*)str inFolder:(NSString*)folderName;
-(bool)loadAllFaceLabelsfromDisk:(NSString*)folderName andVectors:(std::vector<int>&)faceLabels;

//load image from our sandbox directory path
-(UIImage*)loadImage:(NSString*)imageName fromFolder:(NSString*)folderName;

-(bool)removeAllFilesFromFolder:(NSString*)folderName;

-(long)listAllInFolder:(NSString*)folderName;

-(NSString*)getStringFromIdsTxt:(NSString*)fileName;
-(void)logResultByFile:(NSString*)fileName;

-(bool)doesFile:(NSString*)fileName existInFolder:(NSString*)folderName;

-(unsigned long)getNumberOfFilesFromDiskFolder:(NSString*)folderName;


@end

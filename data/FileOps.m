//
//  FileOps.m
//  FaceRecognitionDemo
//
//  Created by Ricky Tsao on 4/10/14.
//  Copyright (c) 2014 Ricky Tsao. All rights reserved.
//

#import "FileOps.h"

@implementation FileOps

@synthesize fileMgr;
@synthesize homeDir;
@synthesize filename;
@synthesize filepath;


-(id)init {
    if(self = [super init]) {
        fileMgr = nil;
        homeDir = nil;
        filename = nil;
        filepath = nil;
        return self;
    }
    return nil;
}

-(bool)createDirectoryInSandbox:(NSString*)directoryName{
    
    NSError ** error = nil;

    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSString * documentDirectory = [self GetDocumentDirectory];
    
    NSMutableString * fullPath = [NSMutableString stringWithFormat:@"%@/%@", documentDirectory, directoryName];
    
    if(![fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:error])
    {
        if(error)
        {
            DLOG(@"createDirectoryInSandbox - localized error: %@", [*error localizedDescription]);
        }
        
        return false;
    }
   
    return true;
}

-(NSString *)GetDocumentDirectory {
    fileMgr = [NSFileManager defaultManager];
    homeDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    return homeDir;
}



-(bool)loadAllFaceLabelsfromDisk:(NSString*)folderName andVectors:(std::vector<int>&)faceLabels
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *filePath = [documentsDirectory
                          stringByAppendingPathComponent:@"faces/ids.txt"];
    
        if(!filePath)
        {
            DLOG(@"FileOps.m - loadAllUserIDfromFolder: file path not valid");
            return false;
        }
        
        
        //now we read in what we just wrote to double check
        NSString * answer = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        
        if(!answer)
        {
            DLOG(@"FileOps.m - loadAllUserIDfromFolder: answer not valid");
            return false;
        }
        
        //answer is valid
        NSArray * ids = [answer componentsSeparatedByString:@","];
        for (int i=0 ; i < [ids count]-1; i++)
        {
            NSString * str = (NSString*)[ids objectAtIndex:i];
            if(str && (str.length > 0))
            {
                //gives error empty string
                //DLOG(@"%u: %@",i, str);
                NSInteger userId = [str integerValue];
                faceLabels.push_back((int)userId);
            }
            //DLOG(@"face label size is: %u", faceLabels.size());
        }
    
    return true;
}


-(void)logResultByFile:(NSString*)fileName
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    
    NSString * filePath = [documentsDirectory
                          stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", fileName]];
    
    //now we read in what we just wrote to double check
    NSError ** error = nil;
    
    NSString * result = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error: error];
    if(result) {
        DLOG(@"contents of this file is: %@",result);
    }
 }

-(NSString*)getStringFromIdsTxt:(NSString*)fileName {
    
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * filePath = [documentsDirectory
                          stringByAppendingPathComponent:[NSString stringWithFormat:@"faces/%@", fileName]];
    
    //now we read in what we just wrote to double check
    NSError ** error = nil;
    NSString * result = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error: error];
    if (result)
        return result;
    else
        return nil;
}

-(void) saveAllUserIDasString:(NSString*)str
                     inFolder:(NSString*)folderName {
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    
    NSString * filePath = [documentsDirectory
                          stringByAppendingPathComponent:@"faces/ids.txt"];
    
    // Create an empty text file.
    if([fileManager createFileAtPath:filePath contents:nil attributes:nil]) {
        
        // Open a handle to it.
        NSFileHandle* pfile = [NSFileHandle fileHandleForWritingAtPath:filePath];
        
        //we write this id for normal face
        [pfile writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
        
        //now we read in what we just wrote to double check
        //NSData * data = [fileManager contentsAtPath: filePath];
        NSString * answer = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        DLOG(@"saveAllUserIDasString - Contents of ids.txt:|%@|",answer);
    }
    else {
        DLOG(@"empty text file not created");
    }
}

-(NSMutableDictionary*)dictLoadUserKeyTableFromFolder:(NSString*)folderName {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"faces/keys.txt"];
    
    //we need use dictionary here tecause key.txt is in dictionary format
    return [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
}


-(void)saveUserKeyTable:(NSMutableDictionary*)dict inFolder:(NSString*)folderName {
    
    NSFileManager  *fileManager = [NSFileManager defaultManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *filePath = [documentsDirectory
                          stringByAppendingPathComponent:@"faces/keys.txt"];
    
       
    // Create an empty text file.
    if([fileManager createFileAtPath:filePath contents:nil attributes:nil])
    {
        //this is where we write our dictionary to file
        [dict writeToFile:filePath atomically:YES];
        
        //now we read in what we just wrote to double check
        //NSData * data = [fileManager contentsAtPath: filePath];
        NSString * answer = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        DLOG(@"saveUserKeyTable - Contents of keys.txt:|%@|",answer);
    }
    else
    {
        DLOG(@"empty text file not created");
    }
}


-(void) saveImage:(UIImage *)image
     withFileName:(NSString *)imageName
           ofType:(NSString *)extension
      inFolder:(NSString *)folder {
    
    NSString * fullImageName = [NSString stringWithFormat:@"%@.%@", imageName, @"png"];
    //DLOG(@"FileOps.m -  saveImage method -  fullImageName: %@", fullImageName);
    
    NSString * fullDirectoryPath = [[NSString stringWithFormat:@"%@/%@", [self GetDocumentDirectory], folder]
                                    stringByAppendingPathComponent:fullImageName];
    //DLOG(@"FileOps.m - saveImage method - fullDirectoryPath: %@", fullDirectoryPath);
    
    if ([[extension lowercaseString] isEqualToString:@"png"]) {
        NSError ** savingError=nil;
        
        if([UIImagePNGRepresentation(image)
            writeToFile:fullDirectoryPath
            options:NSAtomicWrite error:savingError]) {
            DLOG(@"%@ written successfully to %@", fullImageName, fullDirectoryPath);
        }
        else {
            DLOG(@"saving error local description: %@",[*savingError localizedDescription]);
        }
    }
    else {
        DLOG(@"Image Save Failed\nExtension: (%@) is not recognized, use (PNG/JPG)", extension);
    }
}

-(UIImage*)loadImage:(NSString*)imageName fromFolder:(NSString*)folderName {
    
    NSString  *imagePath = [[NSString stringWithFormat:@"%@/%@", [self GetDocumentDirectory], folderName] stringByAppendingPathComponent:imageName];
    return [UIImage imageWithContentsOfFile:imagePath];
}

-(bool)removeAllFilesFromFolder:(NSString*)folderName
{
    NSError *error = nil;
    NSString * documentsDirectory = [NSString stringWithFormat:@"%@/%@",[self GetDocumentDirectory], folderName];
    
    //get all contents of that directory
    NSArray * directoryContents = [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&error];
     
    if (error == nil)
    {
        for (NSString *path in directoryContents)
        {
            NSError * removeError = nil;
            NSString * fullPath = [documentsDirectory stringByAppendingPathComponent:path];
            BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&removeError];
            DLOG(@"image removed at: %@", fullPath);
            if (!removeSuccess)
            {
                // Error handling
                DLOG(@"FileOps.m - removeAllFilesFromFolder removeItemAtPath's error: %@", [removeError localizedDescription]);
            }
        }
    }
    else
    {
        // Error handling
        DLOG(@"FileOps.m - removeAllFilesFromFolder contentsOfDirectoryAtPath's error: %@", [error localizedDescription]);
        return false;
    }
    return true;
}

-(long)listAllInFolder:(NSString*)folderName
{
    NSString * folderDirectory = [NSString stringWithFormat:@"%@/%@", [self GetDocumentDirectory], folderName];
    
    NSError * error=nil;
    NSArray * fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderDirectory error:&error];
   
    if(fileList) {
        
        DLOG(@"In directory %@, we have the following files:", folderDirectory);
        if([fileList count] <= 0) {
            DLOG(@"all empty");
            return 0;
        }
        
        for (NSString *s in fileList) {
            DLOG(@"%@", s);
        }
        
        DLOG(@"total of %u files.", [fileList count]);
        return [fileList count];
    }
    else{
        
        DLOG(@"FileOps.m - listAllInFolder, file list is nil: %@", [error localizedDescription]);
    }
    
    return -1;
}

-(bool)doesFile:(NSString*)fileName existInFolder:(NSString*)folderName
{
    NSString * folderDirectory = [NSString stringWithFormat:@"%@/%@", [self GetDocumentDirectory], folderName];
    
    NSError * error=nil;
    NSArray * fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderDirectory error:&error];
    
    if([fileList count] > 0) {
        for (NSString *s in fileList) {
            if ([s compare:fileName] == NSOrderedSame) {
                return true;
            }
        }
    }
    else {
        
        DLOG(@"FileOps.m - listAllInFolder, file list is nil: %@", [error localizedDescription]);
    }
    
    return false;
}

-(unsigned long)getNumberOfFilesFromDiskFolder:(NSString*)folderName
{
    NSString * folderDirectory = [NSString stringWithFormat:@"%@/%@", [self GetDocumentDirectory], folderName];
    
    NSError * error=nil;
    NSArray * fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderDirectory error:&error];
    
    if(fileList) {
        return [fileList count];
    }
    
    return 0;
}

@end

//
//  UIImage-Extensions.h
//
//  Created by Hardy Macia on 7/1/09.
//  Copyright 2009 Catamount Software. All rights reserved.
//


@interface UIImage (CS_Extensions)

- (UIImage *)imageAtRect:(CGRect)rect;
- (UIImage *)imageByScalingProportionallyToMinimumSize:(CGSize)targetSize;
- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize;
- (UIImage *)imageByScalingToSize:(CGSize)targetSize;
- (UIImage *)imageRotatedByRadians:(CGFloat)radians;
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
+ (UIImage *)fastImageWithContentsOfFile:(NSString*)path;
- (CGSize)sizeByScalingProportionallyToSize:(CGSize)targetSize;
-(UIImage*)rotate:(UIImageOrientation)orient;
-(UIImage*)rotateToPortrait;
-(CGRect)scaleSizeWithProportion:(CGSize)allow;
-(CGRect)scaleSizeWithProportion1:(CGSize)allow;
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;

-(UIImage*)cropFromRect:(CGRect)fromRect;

+(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;

//+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image fromBlueToColor:(bool)flag;

+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image;
@end;
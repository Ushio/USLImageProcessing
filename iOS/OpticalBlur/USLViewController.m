//
//  USLViewController.m
//  OpticalBlur
//
//  Created by ushiostarfish on 2014/02/22.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import "USLViewController.h"

#import <ImageIO/ImageIO.h>
#import "USLImageProcessor.h"
#import "USLOpticalBlurKernel+BuiltIn.h"

@implementation USLViewController
{
    IBOutlet UIImageView *_imageView;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGImageRef srcImage = ^{
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"image1.jpg" ofType:@""];
        NSURL *imageURL = [NSURL fileURLWithPath:imagePath];
        CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)imageURL, nil);
        CGImageRef srcImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
        CFRelease(imageSource);
        return srcImage;
    }();
    
    USLOpticalBlurKernel *kernel = [[USLOpticalBlurKernel alloc] initWithWidth:41 height:41];
    
    NSDate *date = [NSDate date];
    [kernel setGaussianWithRadius:50.0 iris:USLIrisTypeCircle];
    [USLImageProcessor opticalBlurWithCGImage:srcImage
                                       kernel:kernel.optimized
                              fechnerConstant:kFechnerConstantDefault
                              optimizeByScale:kOptimizeByScaleRecommend
                                      reciver:^(CGImageRef bluredImage) {
                                          _imageView.image = [UIImage imageWithCGImage:bluredImage];
                                      }];
    NSLog(@"elapsed %f", [[NSDate date] timeIntervalSinceDate:date]);
}
@end

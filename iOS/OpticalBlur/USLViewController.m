/*
 The MIT License (MIT)
 
 Copyright (c) 2014 Atsushi Yoshimura
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

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
    [kernel setGaussianWithRadius:50.0 iris:USLIrisTypePentagon];
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

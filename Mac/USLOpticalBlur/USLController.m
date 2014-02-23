//
//  USLController.m
//  USLOpticalBlur
//
//  Created by ushiostarfish on 2014/02/23.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import "USLController.h"

#import "USLOpticalBlurKernel+BuiltIn.h"
#import "USLImageProcessor.h"
#import "USLFunctions.h"

@implementation USLController
{
    IBOutlet NSWindow *_window;
    IBOutlet NSTextField *_pathTextField;
    IBOutlet NSTextField *_kernelSizeTextField;
    IBOutlet NSTextField *_blurRadiusTextField;
    IBOutlet NSTextField *_optimizeScaleTextField;
    IBOutlet NSTextField *_fechnerConstantTextField;
    
    IBOutlet NSSlider *_kernelSizeSlider;
    IBOutlet NSSlider *_blurRadiusSlider;
    IBOutlet NSSlider *_optimizeScaleSlider;
    IBOutlet NSSlider *_fechnerConstantSlider;
    IBOutlet NSSegmentedControl *_irisSegmentedControl;
    
    IBOutlet NSImageView *_srcImageView;
    IBOutlet NSImageView *_dstImageView;
    
    int _kernelSize;
    float _blurRadius;
    float _optimizeScale;
    float _fechnerConstant;
    USLIrisType _irisType;
    
    CGImageRef _image;
    NSBitmapImageRep *_processedImage;
}
- (void)awakeFromNib
{
    [self didChangeKernelSize:_kernelSizeSlider];
    [self didChangeBlurRadius:_blurRadiusSlider];
    [self didChangeOptimizeScale:_optimizeScaleSlider];
    [self didChangeFechnerConstantSlider:_fechnerConstantSlider];
    [self didChangeIrisSegmentedControl:_irisSegmentedControl];
}
- (IBAction)load:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel beginSheetModalForWindow:_window completionHandler:^(NSInteger result) {
        if(result == NSFileHandlingPanelOKButton)
        {
            NSURL *imageURL = openPanel.URL;
            CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)imageURL, nil);
            CGImageRef srcImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil);
            if(srcImage)
            {
                if(_image)
                    CGImageRelease(_image);
                
                _image = srcImage;
                _pathTextField.stringValue = imageURL.path;
                _srcImageView.image = [[NSImage alloc] initWithCGImage:_image
                                                                  size:NSMakeSize(CGImageGetWidth(_image),
                                                                                  CGImageGetHeight(_image))];
                [self updateImage];
            }
            CFRelease(imageSource);
        }
    }];
}
- (IBAction)write:(id)sender
{
    if(_processedImage)
    {
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        [savePanel beginSheetModalForWindow:_window completionHandler:^(NSInteger result) {
            if(result == NSFileHandlingPanelOKButton)
            {
                NSData *data = [_processedImage representationUsingType:NSJPEGFileType properties:nil];
                [data writeToURL:savePanel.URL atomically:YES];
            }
        }];
    }
}
- (IBAction)didChangeKernelSize:(NSSlider *)sender
{
    int value = roundf(remap(sender.floatValue, 0, 1, 1, 100));
    _kernelSize = value % 2 == 0? value + 1 : value;
    _kernelSizeTextField.stringValue = [NSString stringWithFormat:@"%d", _kernelSize];
    
    [self updateImage];
}
- (IBAction)didChangeBlurRadius:(NSSlider *)sender
{
    _blurRadius = remap(sender.floatValue, 0, 1, 1, 100);
    _blurRadiusTextField.stringValue = [NSString stringWithFormat:@"%.3f", _blurRadius];
    
    [self updateImage];
}
- (IBAction)didChangeOptimizeScale:(NSSlider *)sender
{
    _optimizeScale = sender.floatValue;
    _optimizeScaleTextField.stringValue = [NSString stringWithFormat:@"%.3f", _optimizeScale];
    
    [self updateImage];
}
- (IBAction)didChangeFechnerConstantSlider:(NSSlider *)sender
{
    _fechnerConstant = sender.floatValue;
    _fechnerConstantTextField.stringValue = [NSString stringWithFormat:@"%.3f", _fechnerConstant];
    
    [self updateImage];
}
- (IBAction)didChangeIrisSegmentedControl:(id)sender
{
    switch (_irisSegmentedControl.selectedSegment) {
        case 0:
            _irisType = USLIrisTypeCircle;
            break;
        case 1:
            _irisType = USLIrisTypePentagon;
            break;
        case 2:
            _irisType = USLIrisTypeHexagon;
            break;
    }
    [self updateImage];
}
- (void)updateImage
{
    if(_image)
    {
        USLOpticalBlurKernel *kernel = [[USLOpticalBlurKernel alloc] initWithWidth:_kernelSize
                                                                            height:_kernelSize];
        [kernel setGaussianWithRadius:_blurRadius iris:_irisType];
        [USLImageProcessor opticalBlurWithCGImage:_image
                                           kernel:kernel
                                  fechnerConstant:_fechnerConstant
                                  optimizeByScale:_optimizeScale reciver:^(CGImageRef bluredImage) {
                                      _processedImage = [[NSBitmapImageRep alloc] initWithCGImage:bluredImage];
                                      
                                      NSImage *image = [[NSImage alloc] init];
                                      [image addRepresentation:_processedImage];
                                      
                                      _dstImageView.image = image;
                                  }];
    }
}
@end

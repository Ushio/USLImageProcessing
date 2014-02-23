//
//  USLVImageBuffer8888.m
//  OpticalBlur
//
//  Created by ushiostarfish on 2014/02/22.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import "USLVImageBufferRGBX8888.h"

#import "USLFunctions.h"
#import "USLVImageBufferRGBFFF.h"

@implementation USLVImageBufferRGBX8888
{
    vImage_Buffer _vImageBuffer;
    CFMutableDataRef _data;
}
- (instancetype)initWithCGImage:(CGImageRef)image
{
    if(self = [super init])
    {
        size_t width = CGImageGetWidth(image);
        size_t height = CGImageGetHeight(image);
        size_t bytesPerRow = align16(4 * width);
        
        _data = CFDataCreateMutable(kCFAllocatorDefault, bytesPerRow * height);
        CFDataSetLength(_data, bytesPerRow * height);
        
        _vImageBuffer.data = CFDataGetMutableBytePtr(_data);
        _vImageBuffer.width = width;
        _vImageBuffer.height = height;
        _vImageBuffer.rowBytes = bytesPerRow;
        
        size_t bitsPerComponent = 8;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast;
        CGContextRef context = CGBitmapContextCreate(_vImageBuffer.data,
                                                     width,
                                                     height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorSpace,
                                                     bitmapInfo);
        CGContextSetBlendMode(context, kCGBlendModeCopy);
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
        CGContextRelease(context);
        context = NULL;
        CGColorSpaceRelease(colorSpace);
        colorSpace = NULL;
    }
    return self;
}
- (instancetype)initWithWidth:(size_t)width height:(size_t)height
{
    if(self = [super init])
    {
        size_t bytesPerRow = align16(4 * width);
        _data = CFDataCreateMutable(kCFAllocatorDefault, bytesPerRow * height);
        CFDataSetLength(_data, bytesPerRow * height);
        
        _vImageBuffer.data = CFDataGetMutableBytePtr(_data);
        _vImageBuffer.width = width;
        _vImageBuffer.height = height;
        _vImageBuffer.rowBytes = bytesPerRow;
    }
    return self;
}
- (instancetype)initWithRGBFFF:(USLVImageBufferRGBFFF *)image
{
    if(self = [super init])
    {
        size_t width = image.vImageBufferR->width;
        size_t height = image.vImageBufferR->height;
        size_t bytesPerRow = align16(4 * width);
        _data = CFDataCreateMutable(kCFAllocatorDefault, bytesPerRow * height);
        CFDataSetLength(_data, bytesPerRow * height);
        
        _vImageBuffer.data = CFDataGetMutableBytePtr(_data);
        _vImageBuffer.width = width;
        _vImageBuffer.height = height;
        _vImageBuffer.rowBytes = bytesPerRow;
        
        float minFloat[] = {0.0f, 0.0f, 0.0f, 0.0f};
        float maxFloat[] = {1.0f, 1.0f, 1.0f, 1.0f};
        vImageConvert_PlanarFToRGBX8888(image.vImageBufferR, image.vImageBufferG, image.vImageBufferB, 255, &_vImageBuffer, maxFloat, minFloat, kvImageNoFlags);
    }
    return self;
}
- (void)dealloc
{
    CFRelease(_data);
    _data = NULL;
}
- (vImage_Buffer *)vImageBuffer
{
    return &_vImageBuffer;
}
- (CFMutableDataRef)data
{
    return _data;
}
- (void)generateCGImageWithReciver:(void(^)(CGImageRef image))reciver
{
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData(_data);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = _vImageBuffer.rowBytes;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast;
    CGImageRef dstImage = CGImageCreate(_vImageBuffer.width,
                                        _vImageBuffer.height,
                                        bitsPerComponent,
                                        bitsPerPixel,
                                        bytesPerRow,
                                        colorSpace,
                                        bitmapInfo,
                                        dataProvider,
                                        NULL,
                                        NO,
                                        kCGRenderingIntentDefault);
    reciver(dstImage);
    CGImageRelease(dstImage);
    dstImage = NULL;
    CGColorSpaceRelease(colorSpace);
    colorSpace = NULL;
    CGDataProviderRelease(dataProvider);
    dataProvider = NULL;
}
@end

//
//  USLOpticalBlurKernel.m
//  BlurDemo
//
//  Created by ushiostarfish on 2014/02/16.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import "USLOpticalBlurKernel.h"

@implementation USLOpticalBlurKernel
{
    float *_kernel;
    int _width;
    int _height;
}
- (instancetype)initWithWidth:(int)width height:(int)height
{
    if(self = [super init])
    {
        _kernel = (float *)malloc(sizeof(float) * width * height);
        _width = width;
        _height = height;
    }
    return self;
}
- (void)dealloc
{
    free(_kernel);
}
- (float *)kernel
{
    return _kernel;
}
- (int)width
{
    return _width;
}
- (int)height
{
    return _height;
}
- (instancetype)optimized
{
    // 左右がどのくらい落とせるか調べる
    int hEconomize = 0;
    int vCount = _width / 2;
    for(int i = 0 ; i < vCount ; ++i)
    {
        BOOL isZeroALL = YES;
        
        // 左右２段ともに0で埋まっているかどうか調べる
        int colurmLeft = i;
        int colurmRight = _width - 1 - i;
        for(int y = 0 ; y < _height ; ++y)
        {
            float valueLeft = _kernel[y * _width + colurmLeft];
            float valueRight = _kernel[y * _width + colurmRight];
            
            if(fabsf(valueLeft) > FLT_EPSILON)
            {
                isZeroALL = NO;
                break;
            }
            if(fabsf(valueRight) > FLT_EPSILON)
            {
                isZeroALL = NO;
                break;
            }
        }
        
        if(isZeroALL == NO)
        {
            break;
        }
        
        ++hEconomize;
    }
    
    // 上下がどのくらい落とせるか調べる
    int vEconomize = 0;
    int hCount = _height / 2;
    for(int i = 0 ; i < hCount ; ++i)
    {
        BOOL isZeroALL = YES;
        
        // 上下２段ともに0で埋まっているかどうか調べる
        int rowUpper = i;
        int rowLower = _height - 1 - i;
        for(int x = 0 ; x < _width ; ++x)
        {
            float valueUpper = _kernel[rowUpper * _width + x];
            float valueLower = _kernel[rowLower * _width + x];
            
            if(fabsf(valueUpper) > FLT_EPSILON)
            {
                isZeroALL = NO;
                break;
            }
            if(fabsf(valueLower) > FLT_EPSILON)
            {
                isZeroALL = NO;
                break;
            }
        }
        
        if(isZeroALL == NO)
        {
            break;
        }
        
        ++vEconomize;
    }
    
    int newWidth = _width - hEconomize * 2;
    int newHeight = _height - vEconomize * 2;
    USLOpticalBlurKernel *optimized = [[USLOpticalBlurKernel alloc] initWithWidth:newWidth height:newHeight];
    float *newKernel = optimized.kernel;
    for(int y = 0 ; y < newHeight ; ++y)
    {
        for(int x = 0 ; x < newWidth ; ++x)
        {
            int sampleX = hEconomize + x;
            int sampleY = vEconomize + y;
            
            newKernel[y * newWidth + x] = _kernel[sampleY * _width + sampleX];
        }
    }
    return optimized;
}
@end

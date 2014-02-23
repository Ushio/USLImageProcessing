//
//  USLOpticalBlurKernel+BuiltIn.m
//  BlurDemo
//
//  Created by ushiostarfish on 2014/02/16.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import "USLOpticalBlurKernel+BuiltIn.h"

static float gaussian(float x, float sigma)
{
    return (1.0f / sqrtf(2.0f * M_PI * sigma * sigma)) * expf(- (x * x) / (2.0f * sigma * sigma));
}
static float remap(float value, float inputMin, float inputMax, float outputMin, float outputMax)
{
    return (value - inputMin) * ((outputMax - outputMin) / (inputMax - inputMin)) + outputMin;
}

@implementation USLOpticalBlurKernel(BuiltIn)
- (void)setGaussianWithRadius:(float)radius
{
    float *kernel = self.kernel;
    int h = self.height;
    int w = self.width;
    int offsetx = w / 2;
    int offsety = h / 2;
    for(int y = 0 ; y < h ; ++y)
    {
        float yvalue = y - offsety;
        
        for(int x = 0 ; x < w ; ++x)
        {
            float xvalue = x - offsetx;
            
            float distanceFromOrigin = sqrtf(xvalue * xvalue + yvalue * yvalue);
            kernel[y * w + x] = gaussian(distanceFromOrigin, radius * 0.5f) * 100.0f;
        }
    }
}
- (void)normalize
{
    float *kernel = self.kernel;
    int h = self.height;
    int w = self.width;
    
    float sum = 0;
    for(int y = 0 ; y < h ; ++y)
    {
        for(int x = 0 ; x < w ; ++x)
        {
            sum += kernel[y * w + x];
        }
    }
    
    // バイアス
    sum *= 0.9;
    
    for(int y = 0 ; y < h ; ++y)
    {
        for(int x = 0 ; x < w ; ++x)
        {
            kernel[y * w + x] /= sum;
        }
    }
}
- (void)setGaussianWithRadius:(float)radius iris:(USLIrisType)iris
{
    [self setGaussianWithRadius:radius];
    switch (iris) {
        case USLIrisTypeCircle:
            [self filterWithCircle];
            break;
        case USLIrisTypeHeart:
            [self filterWithHeart];
            break;
    }
    [self normalize];
}
- (void)filterWithCircle
{
    float *kernel = self.kernel;
    int h = self.height;
    int w = self.width;
    for(int y = 0 ; y < h ; ++y)
    {
        float yvalue = remap(y, 0, h - 1, -1, 1);
        for(int x = 0 ; x < w ; ++x)
        {
            float xvalue = remap(x, 0, w - 1, -1, 1);
            
            float distanceFromOrigin = sqrtf(xvalue * xvalue + yvalue * yvalue);
            if(distanceFromOrigin > 1.0)
            {
                kernel[y * w + x] = 0.0f;
            }
        }
    }
}
- (void)filterWithHeart
{
    float *kernel = self.kernel;
    int h = self.height;
    int w = self.width;
    for(int y = 0 ; y < h ; ++y)
    {
        float yvalue = remap(y, 0, h - 1, -1, 1);
        for(int x = 0 ; x < w ; ++x)
        {
            float xvalue = remap(x, 0, w - 1, -1, 1);
            
            float plusMinus = sqrtf(1.0f - xvalue * xvalue);
            float yMin = powf(xvalue * xvalue, 1.0f / 3.0f) - plusMinus;
            float yMax = powf(xvalue * xvalue, 1.0f / 3.0f) + plusMinus;
            
            yMin = (yMin - 0.25f) / 1.5f;
            yMax = (yMax - 0.25f) / 1.5f;
            
            if(yvalue < yMin || yMax < yvalue)
            {
                kernel[y * w + x] = 0.0f;
            }
        }
    }
}

@end
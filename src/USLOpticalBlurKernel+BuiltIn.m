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

#import "USLOpticalBlurKernel+BuiltIn.h"

#import <CoreGraphics/CoreGraphics.h>
#import "USLFunctions.h"
static float gaussian(float x, float sigma)
{
    return (1.0f / sqrtf(2.0f * M_PI * sigma * sigma)) * expf(- (x * x) / (2.0f * sigma * sigma));
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
        case USLIrisTypePentagon:
            [self filterWithPolygon:5];
        case USLIrisTypeHexagon:
            [self filterWithPolygon:6];
            break;
    }
    [self normalize];
}
- (void)filterWithCircle
{
    float *kernel = self.kernel;
    int h = self.height;
    int w = self.width;
    
    size_t bytesPerRow = 4 * w;
    NSMutableData *buffer = [NSMutableData dataWithLength:bytesPerRow * h];
    size_t bitsPerComponent = 8;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast;
    CGContextRef context = CGBitmapContextCreate(buffer.mutableBytes,
                                                 w,
                                                 h,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 bitmapInfo);
    {
        CGFloat components[] = {1.0f, 1.0f, 1.0f, 1.0f};
        CGColorRef color = CGColorCreate(colorSpace, components);
        CGContextSetFillColorWithColor(context, color);
        CGColorRelease(color);
        color = NULL;
        
        CGRect ellipseRect = CGRectInset(CGRectMake(0, 0, w, h), 1, 1);
        CGContextFillEllipseInRect(context, ellipseRect);
    }
    
//    CGImageRef img = CGBitmapContextCreateImage(context);
//    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:img];
//    CGImageRelease(img);
//    NSData *data = [rep representationUsingType:NSJPEGFileType properties:nil];
//    [data writeToFile:@"/Users/ushiostarfish/Programing/BlurMore/test.jpg" atomically:NO];
    
    CGContextRelease(context);
    context = NULL;
    CGColorSpaceRelease(colorSpace);
    colorSpace = NULL;
    
    uint8_t *head = (uint8_t *)buffer.mutableBytes;
    for(int y = 0 ; y < h ; ++y)
    {
        for(int x = 0 ; x < w ; ++x)
        {
            uint8_t mask = head[y * bytesPerRow + x * 4];
            kernel[y * w + x] *= remap(mask, 0, 255, 0, 1);
        }
    }
}

- (void)filterWithPolygon:(int)N
{
    float *kernel = self.kernel;
    int h = self.height;
    int w = self.width;
    
    size_t bytesPerRow = 4 * w;
    NSMutableData *buffer = [NSMutableData dataWithLength:bytesPerRow * h];
    size_t bitsPerComponent = 8;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast;
    CGContextRef context = CGBitmapContextCreate(buffer.mutableBytes,
                                                 w,
                                                 h,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 bitmapInfo);
    {
        CGFloat components[] = {1.0f, 1.0f, 1.0f, 1.0f};
        CGColorRef color = CGColorCreate(colorSpace, components);
        CGContextSetFillColorWithColor(context, color);
        CGColorRelease(color);
        color = NULL;

        float centerx = w * 0.5f;
        float centery = h * 0.5f;
        float radius = MIN(w, h) * 0.5f;
        
        CGContextTranslateCTM(context, centerx, centery);
        CGContextRotateCTM(context, -0.2f);
        CGMutablePathRef path = CGPathCreateMutable();
        for(int i = 0 ; i < N + 1 ; ++i)
        {
            float r = remap(i, 0.0f, N, 0.0f, M_PI * 2.0f);
            float x = cosf(r) * radius;
            float y = sinf(r) * radius;
            if(i == 0)
            {
                CGPathMoveToPoint(path, NULL, x, y);
            }
            else
            {
                float pc = remap((float)i - 1, 0.0f, N, 0.0f, M_PI * 2.0f);
                float px = cosf(pc) * radius;
                float py = sinf(pc) * radius;
                
                float vx0 = -py;
                float vy0 = px;
                float d0 = sqrtf(vx0 * vx0 + vy0 * vy0);
                vx0 /= d0;
                vy0 /= d0;
                
                float vx1 = -y;
                float vy1 = x;
                float d1 = sqrtf(vx1 * vx1 + vy1 * vy1);
                vx1 /= d1;
                vy1 /= d1;
                
                CGPathAddCurveToPoint(path, NULL,
                                      px + vx0 * radius * 0.2f, py + vy0 * radius * 0.2f,
                                      x - vx1 * radius * 0.2f, y - vy1 * radius * 0.2f,
                                      x, y);
            }
        }
        CGContextAddPath(context, path);
        CGPathRelease(path);
        CGContextFillPath(context);
    }
//    CGImageRef img = CGBitmapContextCreateImage(context);
//    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:img];
//    CGImageRelease(img);
//    NSData *data = [rep representationUsingType:NSJPEGFileType properties:nil];
//    [data writeToFile:@"/Users/ushiostarfish/Programing/BlurMore/test.jpg" atomically:NO];
    
    CGContextRelease(context);
    context = NULL;
    CGColorSpaceRelease(colorSpace);
    colorSpace = NULL;
    
    uint8_t *head = (uint8_t *)buffer.mutableBytes;
    for(int y = 0 ; y < h ; ++y)
    {
        for(int x = 0 ; x < w ; ++x)
        {
            uint8_t mask = head[y * bytesPerRow + x * 4];
            kernel[y * w + x] *= remap(mask, 0, 255, 0, 1);
        }
    }
}

@end
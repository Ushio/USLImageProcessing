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

#import "USLImageProcessor.h"
#import "USLVImageBufferRGBX8888.h"
#import "USLVImageBufferRGBFFF.h"
#import "USLFunctions.h"
@implementation USLImageProcessor
+ (void)opticalBlurWithCGImage:(CGImageRef)srcImage
                        kernel:(USLOpticalBlurKernel *)kernel
               fechnerConstant:(float)fechnerConstant
               optimizeByScale:(float)optimizeByScale
                       reciver:(void(^)(CGImageRef bluredImage))reciver
{
    if(fabsf(optimizeByScale - 1.0f) < FLT_EPSILON)
    {
        USLVImageBufferRGBX8888 *srcRGBA8888 = [[USLVImageBufferRGBX8888 alloc] initWithCGImage:srcImage];
    
        USLVImageBufferRGBFFF *willBlur = [[USLVImageBufferRGBFFF alloc] initWithVImageBufferRGBX8888:srcRGBA8888];
        USLVImageBufferRGBFFF *didBlur = [[USLVImageBufferRGBFFF alloc] initWithWidth:willBlur.vImageBufferR->width
                                                                               height:willBlur.vImageBufferR->height];
        
        [USLImageProcessor intensityToPhysicalQuantity:willBlur fechnerConstant:fechnerConstant];
        [USLImageProcessor convolveRGBFFFWith:willBlur dst:didBlur kernel:kernel];
        [USLImageProcessor physicalQuantityToIntensity:didBlur fechnerConstant:fechnerConstant];
        
        USLVImageBufferRGBX8888 *dstRGBA8888 = [[USLVImageBufferRGBX8888 alloc] initWithRGBFFF:didBlur];
        [dstRGBA8888 generateCGImageWithReciver:reciver];
    }
    else
    {
        USLVImageBufferRGBX8888 *srcRGBA8888 = [[USLVImageBufferRGBX8888 alloc] initWithCGImage:srcImage];
        USLVImageBufferRGBX8888 *oSrcRGBA8888 = [[USLVImageBufferRGBX8888 alloc] initWithWidth:(size_t)roundf(srcRGBA8888.vImageBuffer->width * optimizeByScale)
                                                                                        height:(size_t)roundf(srcRGBA8888.vImageBuffer->height * optimizeByScale)];
        [USLImageProcessor scaleRGBX8888With:srcRGBA8888 dst:oSrcRGBA8888];
        
        USLVImageBufferRGBFFF *willBlur = [[USLVImageBufferRGBFFF alloc] initWithVImageBufferRGBX8888:oSrcRGBA8888];
        USLVImageBufferRGBFFF *didBlur = [[USLVImageBufferRGBFFF alloc] initWithWidth:willBlur.vImageBufferR->width
                                                                               height:willBlur.vImageBufferR->height];
        
        [USLImageProcessor intensityToPhysicalQuantity:willBlur fechnerConstant:fechnerConstant];
        [USLImageProcessor convolveRGBFFFWith:willBlur dst:didBlur kernel:kernel];
        [USLImageProcessor physicalQuantityToIntensity:didBlur fechnerConstant:fechnerConstant];
        
        USLVImageBufferRGBX8888 *oDstRGBA8888 = [[USLVImageBufferRGBX8888 alloc] initWithRGBFFF:didBlur];
        USLVImageBufferRGBX8888 *dstRGBA8888 = [[USLVImageBufferRGBX8888 alloc] initWithWidth:srcRGBA8888.vImageBuffer->width
                                                                                       height:srcRGBA8888.vImageBuffer->height];
        [USLImageProcessor scaleRGBX8888With:oDstRGBA8888 dst:dstRGBA8888];
        [dstRGBA8888 generateCGImageWithReciver:reciver];
    }
}
+ (void)scaleRGBX8888With:(USLVImageBufferRGBX8888 *)src dst:(USLVImageBufferRGBX8888 *)dst
{
    vImage_Error error;
    error = vImageScale_ARGB8888(src.vImageBuffer,
                                 dst.vImageBuffer,
                                 NULL,
                                 kvImageNoFlags);
    VIMAGE_ERROR_HADNLE(error);
}
+ (void)convolveRGBFFFWith:(USLVImageBufferRGBFFF *)src dst:(USLVImageBufferRGBFFF *)dst kernel:(USLOpticalBlurKernel *)kernel
{
    vImage_Buffer *srcvImageBuffers[] = {src.vImageBufferR, src.vImageBufferG, src.vImageBufferB};
    vImage_Buffer *dstvImageBuffers[] = {dst.vImageBufferR, dst.vImageBufferG, dst.vImageBufferB};
    for(int i = 0 ; i < 3 ; ++i)
    {
        vImage_Buffer *srcBuffer = srcvImageBuffers[i];
        vImage_Buffer *dstBuffer = dstvImageBuffers[i];
        vImage_Error error;
        error = vImageConvolve_PlanarF(srcBuffer,
                                       dstBuffer,
                                       NULL, 0, 0,
                                       kernel.kernel,
                                       kernel.width, kernel.height,
                                       0.0f,
                                       kvImageEdgeExtend);
        VIMAGE_ERROR_HADNLE(error);
    }
}

/**
 * ヴェーバー‐フェヒナーの法則による変換
 * E = C * log(R)
 */
+ (void)intensityToPhysicalQuantity:(USLVImageBufferRGBFFF *)image fechnerConstant:(float)fechnerConstant
{
    // R = 10^(E/C)
    float divide = 1.0f / fechnerConstant;
    vImage_Buffer *vImageBuffers[] = {image.vImageBufferR, image.vImageBufferG, image.vImageBufferB};
    int length = (int)vImageBuffers[0]->width;
    float *bottom = malloc(sizeof(float) * length);
    float fill = 10.0f;
    vDSP_vfill(&fill, bottom, 1, length);
    
    for(int i = 0 ; i < 3 ; ++i)
    {
        vImage_Buffer *buffer = vImageBuffers[i];
        int length = (int)buffer->width;
        for(int y = 0 ; y < buffer->height ; ++y)
        {
            float *rowHead = (float *)((uint8_t *)buffer->data + buffer->rowBytes * y);
            vDSP_vsmul(rowHead, 1, &divide, rowHead, 1, length);
            vvpowf(rowHead, rowHead, bottom, &length);
        }
    }
}
+ (void)physicalQuantityToIntensity:(USLVImageBufferRGBFFF *)image fechnerConstant:(float)fechnerConstant
{
    // E = C * log(R)
    vImage_Buffer *vImageBuffers[] = {image.vImageBufferR, image.vImageBufferG, image.vImageBufferB};
    int length = (int)vImageBuffers[0]->width;
    for(int i = 0 ; i < 3 ; ++i)
    {
        vImage_Buffer *buffer = vImageBuffers[i];
        for(int y = 0 ; y < buffer->height ; ++y)
        {
            float *rowHead = (float *)((uint8_t *)buffer->data + buffer->rowBytes * y);
            vvlog10f(rowHead, rowHead, &length);
            vDSP_vsmul(rowHead, 1, &fechnerConstant, rowHead, 1, length);
        }
    }
}
@end

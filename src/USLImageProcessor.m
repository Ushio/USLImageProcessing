//
//  USLImageProcessor.m
//  OpticalBlur
//
//  Created by ushiostarfish on 2014/02/22.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

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

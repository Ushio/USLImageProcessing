//
//  USLVImageBufferRGBFFF.m
//  OpticalBlur
//
//  Created by ushiostarfish on 2014/02/22.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import "USLVImageBufferRGBFFF.h"
#import "USLVImageBufferRGBX8888.h"
#import "USLFunctions.h"

@implementation USLVImageBufferRGBFFF
{
    vImage_Buffer _vImageBufferR;
    vImage_Buffer _vImageBufferG;
    vImage_Buffer _vImageBufferB;
    NSMutableData *_data;
}
- (instancetype)initWithVImageBufferRGBX8888:(USLVImageBufferRGBX8888 *)src
{
    if(self = [super init])
    {
        size_t width = src.vImageBuffer->width;
        size_t height = src.vImageBuffer->height;
        size_t rowBytes = align16(sizeof(float) * width);
        size_t buffersize = rowBytes * height;
        _data = [NSMutableData dataWithLength:buffersize * 3];
        
        vImage_Buffer *vImageBuffers[] = {&_vImageBufferR, &_vImageBufferG, &_vImageBufferB};
        for(int i = 0 ; i < 3 ; ++i)
        {
            vImage_Buffer *buffer = vImageBuffers[i];
            buffer->data = (uint8_t *)_data.mutableBytes + i * buffersize;
            buffer->height = height;
            buffer->width = width;
            buffer->rowBytes = rowBytes;
        }
        
        size_t srcRowBytes = src.vImageBuffer->rowBytes;
        uint8_t *srcHead = (uint8_t *)src.vImageBuffer->data;
        float divide = 1.0f / 255.0f;
        for(int i = 0 ; i < 3 ; ++i)
        {
            vImage_Buffer *buffer = vImageBuffers[i];
            for(int y = 0 ; y < buffer->height ; ++y)
            {
                uint8_t *srcRowHead = srcHead + srcRowBytes * y + i;
                float *dstRowHead = (float *)((uint8_t *)buffer->data + buffer->rowBytes * y);
                vDSP_vfltu8(srcRowHead, 4, dstRowHead, 1, width);
                vDSP_vsmul(dstRowHead, 1, &divide, dstRowHead, 1, width);
            }
        }
    }
    return self;
}
- (instancetype)initWithWidth:(size_t)width height:(size_t)height
{
    if(self = [super init])
    {
        size_t rowBytes = align16(sizeof(float) * width);
        size_t buffersize = rowBytes * height;
        _data = [NSMutableData dataWithLength:buffersize * 3];
        
        vImage_Buffer *vImageBuffers[] = {&_vImageBufferR, &_vImageBufferG, &_vImageBufferB};
        for(int i = 0 ; i < 3 ; ++i)
        {
            vImage_Buffer *buffer = vImageBuffers[i];
            buffer->data = (uint8_t *)_data.mutableBytes + i * buffersize;
            buffer->height = height;
            buffer->width = width;
            buffer->rowBytes = rowBytes;
        }
    }
    return self;
}
- (vImage_Buffer *)vImageBufferR
{
    return &_vImageBufferR;
}
- (vImage_Buffer *)vImageBufferG
{
    return &_vImageBufferG;
}
- (vImage_Buffer *)vImageBufferB
{
    return &_vImageBufferB;
}
@end

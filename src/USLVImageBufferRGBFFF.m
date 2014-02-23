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

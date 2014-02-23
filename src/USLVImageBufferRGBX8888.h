//
//  USLVImageBuffer8888.h
//  OpticalBlur
//
//  Created by ushiostarfish on 2014/02/22.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

/**
 * vImageのバッファ管理クラス
 */
@class USLVImageBufferRGBFFF;
@interface USLVImageBufferRGBX8888 : NSObject
- (instancetype)initWithCGImage:(CGImageRef)image;
- (instancetype)initWithWidth:(size_t)width height:(size_t)height;
- (instancetype)initWithRGBFFF:(USLVImageBufferRGBFFF *)image;

- (vImage_Buffer *)vImageBuffer;
- (CFMutableDataRef)data;
- (void)generateCGImageWithReciver:(void(^)(CGImageRef image))reciver;
@end

//
//  USLVImageBufferRGBFFF.h
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
@class USLVImageBufferRGBX8888;
@interface USLVImageBufferRGBFFF : NSObject
- (instancetype)initWithVImageBufferRGBX8888:(USLVImageBufferRGBX8888 *)src;
- (instancetype)initWithWidth:(size_t)width height:(size_t)height;

- (vImage_Buffer *)vImageBufferR;
- (vImage_Buffer *)vImageBufferG;
- (vImage_Buffer *)vImageBufferB;
@end

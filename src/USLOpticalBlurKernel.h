//
//  USLOpticalBlurKernel.h
//  BlurDemo
//
//  Created by ushiostarfish on 2014/02/16.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 光学的ブラーに仕様する畳み込み演算カーネル
 * カーネルは奇数のサイズでなければならない
 */
@interface USLOpticalBlurKernel : NSObject
- (instancetype)initWithWidth:(int)width height:(int)height;
- (float *)kernel;
- (int)width;
- (int)height;
- (instancetype)optimized;
@end

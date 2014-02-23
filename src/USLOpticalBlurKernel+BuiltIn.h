//
//  USLOpticalBlurKernel+BuiltIn.h
//  BlurDemo
//
//  Created by ushiostarfish on 2014/02/16.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import "USLOpticalBlurKernel.h"

/**
 * 絞り形状
 */
typedef enum
{
    USLIrisTypeCircle = 0,
    USLIrisTypePentagon,
    USLIrisTypeHexagon,
} USLIrisType;

/**
 * 光学的ブラーに仕様する畳み込み演算カーネル便利セッター
 */
@interface USLOpticalBlurKernel (BuiltIn)
/**
 * @param radius ぼかし具合 ピクセル単位であり、標準偏差x2の位置でもある
 * @param iris 絞り形状
 */
- (void)setGaussianWithRadius:(float)radius iris:(USLIrisType)iris;
@end

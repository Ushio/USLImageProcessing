//
//  USLImageProcessor.h
//  OpticalBlur
//
//  Created by ushiostarfish on 2014/02/22.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "USLOpticalBlurKernel.h"

static const float kFechnerConstantDefault = 0.3f;
static const float kOptimizeByScaleRecommend = 0.75f;

@interface USLImageProcessor : NSObject
/**
 * 光学的ブラーを実行します
 *
 * @param srcImage 処理対象の画像
 * @param kernel 畳み込み演算のカーネル
 * @param fechnerConstant ヴェーバー‐フェヒナーの法則の定数
 * @param optimizeByScale 処理速度向上のため、畳み込み演算の前にどの程度スケーリングするか
 * @param reciver 処理結果画像を受け取るblocks。処理は非同期ではなく、あくまで同期的に行われる
 */
+ (void)opticalBlurWithCGImage:(CGImageRef)srcImage
                        kernel:(USLOpticalBlurKernel *)kernel
               fechnerConstant:(float)fechnerConstant
               optimizeByScale:(float)optimizeByScale
                       reciver:(void(^)(CGImageRef bluredImage))reciver;
@end

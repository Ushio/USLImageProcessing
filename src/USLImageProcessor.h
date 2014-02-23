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

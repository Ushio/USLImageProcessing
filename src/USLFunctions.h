//
//  USLFunction.h
//  OpticalBlur
//
//  Created by ushiostarfish on 2014/02/22.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#pragma once

#include <stdio.h>

/**
 * 16バイトアラインメントが必要な数を計算する
 */
size_t align16(size_t size);

/**
 * 線形に値をマッピングする
 */
float remap(float value, float inputMin, float inputMax, float outputMin, float outputMax);

/**
 * ベーシックなエラー処理
 */
#define ENABLE_ERROR_HANDLE 1

#if ENABLE_ERROR_HANDLE
#define VIMAGE_ERROR_HADNLE(error) if(error != kvImageNoError){ NSLog(@"[vImage Error] code : %d, file = %s, line = %d", (int)error, __FILE__, __LINE__); NSCAssert(0, @""); }
#else
#define VIMAGE_ERROR_HADNLE(error) if(error != kvImageNoError){};
#endif
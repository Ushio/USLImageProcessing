//
//  USLFunctions.c
//  OpticalBlur
//
//  Created by ushiostarfish on 2014/02/22.
//  Copyright (c) 2014年 Ushio. All rights reserved.
//

#include "USLFunctions.h"

size_t align16(size_t size)
{
	if(size == 0)
		return 0;
    
	return (((size - 1) >> 4) << 4) + 16;
}

float remap(float value, float inputMin, float inputMax, float outputMin, float outputMax)
{
    return (value - inputMin) * ((outputMax - outputMin) / (inputMax - inputMin)) + outputMin;
}
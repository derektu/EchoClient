//
// Created by Derek on 13/6/21.
// Copyright (c) 2013 DerekTu. All rights reserved.
//
#ifndef __Stat_H_
#define __Stat_H_

// data structure to hold 統計資料
//
typedef struct Stat
{
    int     sampleCount;        // sample數量
    double  meanValue;          // 平均值
    double  minValue;           // 最小值
    double  maxValue;           // 最大值
} Stat;


#endif //__Stat_H_

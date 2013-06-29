//
// Created by Derek on 13/6/20.
// Copyright (c) 2013 DerekTu. All rights reserved.


#import <Foundation/Foundation.h>

#import "Stat.h"

// 用來統計最近N筆(packet傳送速度)
//
@interface StatCalculator : NSObject

// 需要統計的最大筆數, 當超過這個數目時, 舊的資料會被discard
//
@property (nonatomic,assign) int maxSampleCount;

// 計算平均值時扣除上下percentage (for truncated mean), default is 0.
@property (nonatomic,assign) double trimRange;

- (id)initWithMaxSampleCount:(int)maxSampleCount;

- (id)initWithMaxSampleCount:(int)maxSampleCount trimRange:(double)trimRange;

// 加入一筆sample
//  - 此時Stat就會開始重新計算
//
- (void)addSample:(double)value;

// addSample: NSNumber variant
//
- (void)addSampleAsNSNumber:(NSNumber*)value;

// 取得統計資料
//
@property (nonatomic,assign) Stat stat;

// 取得最近幾筆
//  n = 0: 最後第一筆
//  n = 1: 最後第二筆
//
- (double)getLatestSampleValue:(int)lastN;

@end
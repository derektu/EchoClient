//
// Created by Derek on 13/6/25.
// Copyright (c) 2013 DerekTu. All rights reserved.


#import <Foundation/Foundation.h>

@class StatCalculator;

@interface BaseEchoService()

// Override property status: change to R/W
//
@property ConnectStatus connectStatus;
@property (nonatomic,strong)StatCalculator* statCalculator;
@property (nonatomic,strong)NSTimer* timer;
@property (nonatomic) Stat emptyStat;

// The following are 'protected' methods that can be used by derived class.
//
- (void)updateConnectStatus:(ConnectStatus)status;
- (void)updateConnectStatus:(ConnectStatus)status withError:(NSError*)error;

- (void)fireError:(NSError*)error;

- (void)startEcho;
- (void)stopEcho;

- (void)addSample:(double)value;

@end
//
// Created by Derek on 13/6/25.
// Copyright (c) 2013 DerekTu. All rights reserved.


#import <BlocksKit/NSTimer+BlocksKit.h>
#import "BaseEchoService.h"
#import "BaseEchoServicePrivateProperty.h"
#import "StatCalculator.h"

static const double DEFAULT_ECHOFREQUENCY = 1000;
static const int DEFAULT_SAMPLECOUNT = 1800;
static const double DEFAULT_TRIMRANGE = 0.0;

@implementation BaseEchoService

@synthesize server;
@synthesize port;
@synthesize echoFrequency;
@synthesize maxSampleCount;
@synthesize trimRange;
@synthesize delegate;
@synthesize connectStatus;

- (id)init
{
    self = [super init];
    if (self) {
        // initialize default properties
        //
        self.echoFrequency = DEFAULT_ECHOFREQUENCY;
        self.maxSampleCount = DEFAULT_SAMPLECOUNT;
        self.trimRange = DEFAULT_TRIMRANGE;
    }
    return self;
}

- (BOOL)connect
{
    if (self.connectStatus != CS_None)
        return NO;

    if ([self.server isEqualToString:@""] || self.port == 0)
        return NO;

    if (self.echoFrequency == 0)
        self.echoFrequency = DEFAULT_ECHOFREQUENCY;

    NSAssert(self.timer == nil, @"Timer should be cleared");
    NSAssert(self.statCalculator == nil, @"StatCalculator should be cleared");

    return [self doConnect];
}

- (void)disconnect
{
    // Only allow in Connected or Connecting state
    //
    if (self.connectStatus != CS_Connected && self.connectStatus != CS_Connecting)
        return;

    [self stopEcho];
    [self doDisconnect];
}

- (Stat)stat
{
    if (self.statCalculator == nil)
        return self.emptyStat;
    else
        return self.statCalculator.stat;
}

- (double)getLatestSampleValue:(int)lastN
{
    if (self.statCalculator == nil)
        return 0;
    else
        return [self.statCalculator getLatestSampleValue:lastN];
}

#pragma mark - Internal implementation

- (void)updateConnectStatus:(ConnectStatus)status
{
    self.connectStatus = status;
    [self fireConnectionStatusChange:nil];
}

- (void)updateConnectStatus:(ConnectStatus)status withError:(NSError*)error
{
    self.connectStatus = status;
    [self fireConnectionStatusChange:error];
}

- (void)fireConnectionStatusChange:(NSError*)error
{
    if (self.delegate != nil)
        [self.delegate service:self didUpdateConnectStatus:self.connectStatus withError:error];
}

- (void)fireError:(NSError*)error
{
    if (self.delegate != nil)
        [self.delegate service:self didEncounterError:error];
}

- (void)fireStatUpdate
{
    if (self.delegate != nil)
        [self.delegate serviceDidUpdateStat:self];
}

- (void)startEcho
{
    NSAssert(self.connectStatus == CS_Connected, @"startEcho must be called when socket is connected.");
    NSAssert(self.timer == nil, @"startEcho must be called with a null timer");
    NSAssert(self.statCalculator == nil, @"startEcho must be called with a null statCalculator");

    // Create stat calculator
    //
    self.statCalculator = [[StatCalculator alloc] initWithMaxSampleCount:self.maxSampleCount trimRange:self.trimRange];

    // Start a timer
    //
    self.timer = [NSTimer timerWithTimeInterval:self.echoFrequency / 1000.0
                                          block:^(NSTimeInterval time) {
                                              [self onTimerAction];
                                          }
                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopEcho
{
    self.statCalculator = nil;

    // Stop timer
    //
    [self.timer invalidate];
    self.timer = nil;
}

// Called periodically (via timer)
//  - send packet to Echo service
//
- (void)onTimerAction
{
    // TODO: race condition: 如果在stopEcho之後 pending timer fire的話(?), 可以用這個來保護
    //
    if (self.connectStatus != CS_Connected)
        return;

    [self doSendEchoMessage];
}

- (void)addSample:(double)value
{
    if (self.statCalculator) {
        [self.statCalculator addSample:value];

        // Notify client about stat update
        //
        [self fireStatUpdate];
    }
}

#pragma mark - BaseEchoService virtual function implementation

- (BOOL)doConnect
{
    // derived should override this method
    //
    NSLog(@"BaseEchoService.doConnect is called !! Derived class should override this API.");
    return NO;
}

- (void)doDisconnect
{
    // derived should override this method
    //
    NSLog(@"BaseEchoService.doDisconnect is called !! Derived class should override this API.");
}

- (void)doSendEchoMessage
{
    // derived should override this method
    //
    NSLog(@"BaseEchoService.doSendEchoMessage is called !! Derived class should override this API.");
}


@end
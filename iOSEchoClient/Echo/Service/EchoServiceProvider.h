//
// Created by Derek on 13/6/25.
// Copyright (c) 2013 DerekTu. All rights reserved.


#import <Foundation/Foundation.h>

#import "Stat.h"

@protocol EchoServiceProvider;          // forward declaration
@protocol EchoServiceProviderDelegate;  // forward declaration

// Connect state transition
//  None -> Connecting -> None/Connected
//
// Disconnect state transition
//  Connecting/Connected -> Disconnecting -> None
//
typedef enum ConnectStatus {
    CS_None = 0,                // Not connected
    CS_Connecting = 1,
    CS_Connected = 2,
    CS_Disconnecting = 3,
} ConnectStatus;

// Delegate interface used by EchoService to notify its client about status update
//  NOTE: the delegate can be called on background thread !!
//
@protocol EchoServiceProviderDelegate <NSObject>
@required
// notify when connect status change
//  'error' is optional, to indicate connect or disconnect error
//
-(void)service:(id<EchoServiceProvider>)service didUpdateConnectStatus:(ConnectStatus)status withError:(NSError*)error;

// notify when an error occurs during connected status.
//  TODO: the connection is still kept alive (??)
//
-(void)service:(id<EchoServiceProvider>)service didEncounterError:(NSError*)error;

// service has updated stat.
//  client should call service.stat to get latest statistics
//
-(void)serviceDidUpdateStat:(id<EchoServiceProvider>)service;

@end

// EchoServiceProvider protocol
// this outline the interaction between client and echo server
//
@protocol EchoServiceProvider <NSObject>

// Echo server location
//
@property (nonatomic,copy) NSString* server;

// Echo server port
//
@property (nonatomic) int port;

// Number of milli-seconds to send echo packet to server, default = 1000
//
@property (nonatomic) double echoFrequency;

// Max sample count (the last N packets), default = 1800 (30 minutes)
//
@property (nonatomic) int maxSampleCount;

// trimRange for sampling (to eliminate boundary samples), default = 0
//
@property (nonatomic) double trimRange;

// The delegate property
//
@property (nonatomic,weak) id<EchoServiceProviderDelegate> delegate;

// Return current connection status
//
@property (readonly)ConnectStatus connectStatus;

// Return current stat data
//
@property (readonly)Stat stat;

// Return the latest sample value
//  lastN = 0: return the last sample value (最近一個)
//  lastN = 1: return the one prior to last sample value (最近第二個)
//
- (double) getLatestSampleValue:(int)lastN;

// Connect to service
//  return NO if status is incorrect (e.g. missing server/port, etc.)
//  return YES if implementation will move into 'connecting' status. Client should wait
//  for service:didUpdateConnectStatus:withError callback to determine when the connection
//  is established.
//
- (BOOL) connect;

// Disconnect from service
//
- (void) disconnect;

@end
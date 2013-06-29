//
// Created by Derek on 13/6/25.
// Copyright (c) 2013 DerekTu. All rights reserved.


#import <socket.IO/SocketIOPacket.h>
#import "SocketIOEchoService.h"
#import "SocketIO.h"
#import "BaseEchoServicePrivateProperty.h"


@interface SocketIOEchoService() <SocketIODelegate>

@property (nonatomic,strong)SocketIO* socket;

@end

@implementation SocketIOEchoService

- (BOOL)doConnect
{
    NSAssert(self.socket == nil, @"Socket should be cleared");

    self.socket = [[SocketIO alloc] initWithDelegate:self];
    [self.socket connectToHost:self.server onPort:self.port];

    [self updateConnectStatus:CS_Connecting];

    return YES;
}

- (void)doDisconnect
{
    NSAssert(self.socket != nil, @"Socket should be valid");

    [self.socket disconnect];

    [self updateConnectStatus:CS_Disconnecting];
}


- (void)doSendEchoMessage
{
    NSDate* now = [NSDate date];
    NSString* message = [NSString stringWithFormat:@"%f", now.timeIntervalSinceReferenceDate];
    [self.socket sendMessage:message];
}

- (void)parseServiceMessage:(NSString*)message
{
    // Note 目前didReceiveMessage是從底層thread轉到UI thread來才收到的, 所以measure的時間上可能會有點差異
    //
    double value = [message doubleValue];
    if (value == 0.0) {
        NSLog(@"receive non-double value!\n");
        return;
    }

    NSDate* dateSent = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:value];
    NSDate* dateNow = [NSDate date];
    NSTimeInterval elapse = [dateNow timeIntervalSinceDate:dateSent];

    NSLog(@"packet echo time(ms)=[%d]", (int)(elapse * 1000));

    [self addSample:elapse * 1000];
}

#pragma mark - SocketIODelegate implementation

- (void)socketIODidConnect:(SocketIO*)socket
{
    NSLog(@"socketIO.didConnect");

    NSAssert(self.connectStatus == CS_Connecting, @"should be in connecting state");

    [self updateConnectStatus:CS_Connected];

    // start to echo after connection is established
    //
    [self startEcho];
}


- (void)socketIO:(SocketIO*)socket failedToConnectWithError:(NSError*)error
{
    NSLog(@"socketIO.failedToConnectWithError:[%@]", error);

    NSAssert(self.connectStatus == CS_Connecting, @"should be in connecting state");

    self.socket = nil;

    [self updateConnectStatus:CS_None withError:error];
}

- (void)socketIO:(SocketIO*)socket onError:(NSError*)error
{
    NSLog(@"socketIO.onError:[%@]", error);

    if (self.connectStatus == CS_Connecting){
        // Error occurs during connecting
        //
        self.socket = nil;
        [self updateConnectStatus:CS_None];
    }
    else {
        // for other cases, simply fire an error event
        //
        [self fireError:error];
    }
}

- (void)socketIODidDisconnect:(SocketIO*)socket disconnectedWithError:(NSError*)error
{
    // TODO: for some unknown reason, there is always an error during disconnect. Maybe a bug of SocketIO client library ?
    //
    NSLog(@"socketIO.didDisconnect. Error=[%@]\n", error);

    self.socket.delegate = nil;
    self.socket = nil;

    [self updateConnectStatus:CS_None withError:error];
}

- (void)socketIO:(SocketIO*)socket didReceiveMessage:(SocketIOPacket*)packet
{
    [self parseServiceMessage:packet.data];
}

@end
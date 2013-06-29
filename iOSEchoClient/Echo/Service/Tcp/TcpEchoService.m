//
// Created by Derek on 13/6/25.
// Copyright (c) 2013 DerekTu. All rights reserved.


#import "TcpEchoService.h"
#import "GCDAsyncSocket.h"
#import "BaseEchoServicePrivateProperty.h"

@interface TcpEchoService() <GCDAsyncSocketDelegate>
{
    dispatch_queue_t _socketQueue;
    int _packetSeqNo;
}
@property (strong,nonatomic) GCDAsyncSocket* socket;
@end

@implementation TcpEchoService

- (id)init
{
    self = [super init];
    if (self) {
        _socketQueue = dispatch_queue_create(NULL, NULL);
    }

    return self;
}

- (void)dealloc
{
    if (_socketQueue != nil)
        dispatch_release(_socketQueue);
}


- (BOOL)doConnect
{
    NSAssert(self.socket == nil, @"Socket should be cleared");

    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];

    NSError *err = nil;
    if (![self.socket connectToHost:self.server onPort:self.port error:&err])
    {
        self.socket = nil;
        return NO;
    }

    [self updateConnectStatus:CS_Connecting];
    return YES;
}

- (void)doDisconnect
{
    NSAssert(self.socket != nil, @"Socket should be valid");

    // stop echo
    //
    [self stopEcho];

    self.socket.delegate = nil;
    [self.socket disconnect];

    // For socket implementation, currently there is no Disconnecting stage
    // since we have already nil the delegate before disconnect.
    //
    [self updateConnectStatus:CS_None];
}

- (void)doSendEchoMessage
{
    NSDate* now = [NSDate date];
    NSString* message = [NSString stringWithFormat:@"%f\r\n", now.timeIntervalSinceReferenceDate];
    NSData* packet = [message dataUsingEncoding:NSUTF8StringEncoding];

    int seqNo = [self getNextPacketSeqNo];
    [self.socket writeData:packet withTimeout:-1 tag:seqNo];

    // we can issue the 'corresponding' read beforehand
    //
    [self.socket readDataToLength:packet.length withTimeout:-1 tag:seqNo];
}

// Return an unique packet seq no
//
- (int)getNextPacketSeqNo
{
    @synchronized (self) {
        return ++_packetSeqNo;
    }
}

- (void)parseServiceMessage:(NSString*)message
{
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

#pragma mark - GCDAsyncSocketDelegate implementation

- (void)socket:(GCDAsyncSocket*)sock didConnectToHost:(NSString*)host port:(uint16_t)port
{
    NSLog(@"socket.didConnectToHost");

    NSAssert(self.connectStatus == CS_Connecting, @"should be in connecting state");

    [self updateConnectStatus:CS_Connected];

    // start to echo after connection is established
    //
    [self startEcho];
}

- (void)socketDidDisconnect:(GCDAsyncSocket*)sock withError:(NSError*)err
{
    NSLog(@"socket.didDisconnect. Error=[%@]", err);

    // 1. If connection fails, socketDidDisconnect will be called.
    // 2. this is NOT called during disconnect(), since we have nil the delegate beforehand
    //
    if (self.connectStatus == CS_Connecting) {
        self.socket = nil;
        [self updateConnectStatus:CS_None withError:err];
    }
}

- (void)socket:(GCDAsyncSocket*)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"socket.didWriteDataWithTag:[%ld]", tag);
}

- (void)socket:(GCDAsyncSocket*)sock didReadData:(NSData*)data withTag:(long)tag
{
    char* buffer = (char*)data.bytes;
    NSAssert(buffer[data.length-2] == 13, @"end with \r");
    NSAssert(buffer[data.length-1] == 10, @"end with \n");

    buffer[data.length-2] = 0;
    NSString* message = [NSString stringWithUTF8String:buffer];

    NSLog(@"socket.didReadData. Packet=[%@] tag=[%ld]", message, tag);

    [self parseServiceMessage:message];
}


@end
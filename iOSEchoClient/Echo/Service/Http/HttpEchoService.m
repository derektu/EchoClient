//
// Created by Derek on 13/6/28.
// Copyright (c) 2013 DerekTu. All rights reserved.


#import "HttpEchoService.h"
#import "AFHTTPClient.h"
#import "BaseEchoServicePrivateProperty.h"

@interface HttpEchoService()
@property (strong, nonatomic) AFHTTPClient* httpClient;
@end

@implementation HttpEchoService

- (BOOL)doConnect
{
    NSAssert(self.httpClient == nil, @"HttpClient should be cleared");

    self.httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:self.getBaseUrl]];

    // Note: no connecting login
    //
    [self updateConnectStatus:CS_Connected];

    [self startEcho];
    return YES;
}

- (void)doDisconnect
{
    NSAssert(self.httpClient != nil, @"HttpClient should be valid");

    // stop echo
    //
    [self stopEcho];

    self.httpClient = nil;

    // Note: no disconnecting login
    //
    [self updateConnectStatus:CS_None];
}

- (void)doSendEchoMessage
{
    NSDate* now = [NSDate date];
    NSString* message = [NSString stringWithFormat:@"%f", now.timeIntervalSinceReferenceDate];

    [self.httpClient getPath:[self getEchoRequestPath:message]
                  parameters:nil
                     success:^(AFHTTPRequestOperation* operation, id responseObject) {
                         NSString* message = [[NSString alloc] initWithData:responseObject
                                                                   encoding:NSUTF8StringEncoding];

                         [self parseEchoMessage:message];
                     }
                     failure:^(AFHTTPRequestOperation* operation, NSError* error) {
                         NSLog(@"EchoRequest fail:[%@]", error);
                         [self fireError:error];
                     }];
}

- (NSString*) getBaseUrl
{
    // BaseUrl = http://<server>:<port>
    //
    return [NSString stringWithFormat:@"http://%@:%d", self.server, self.port];
}

- (NSString*) getEchoRequestPath:(NSString*)echo
{
    // RequestUrl = http://<server>:<port>/echo?stringtoecho
    //  this API retunr the "?stringtoecho" part
    //
    return [NSString stringWithFormat:@"/echo?%@", echo];
}

- (void)parseEchoMessage:(NSString*)message
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

@end
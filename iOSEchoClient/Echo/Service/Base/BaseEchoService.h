//
// Created by Derek on 13/6/25.
// Copyright (c) 2013 DerekTu. All rights reserved.


#import <Foundation/Foundation.h>
#import "EchoServiceProvider.h"

// Base class to implement skeleton of a EchoServiceProvider
//
@interface BaseEchoService : NSObject<EchoServiceProvider>

// Derived class should override this method
// this is called during 'connect' method
//
-(BOOL)doConnect;

// Derived class should override this method
// this is called during 'disconnect' method
//
-(void)doDisconnect;

// Derived class should override this method
// this is called during background echo timer
//
-(void)doSendEchoMessage;


@end
//
//  EchoTestTableViewController.h
//  NetworkTest2
//
//  Created by Derek on 13/6/20.
//  Copyright (c) 2013年 DerekTu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EchoServiceProvider.h"

@interface EchoViewController : UITableViewController

@property (nonatomic,strong) NSString* server;
@property (nonatomic) int port;

// Interact with this service instance
//
@property (nonatomic,strong) id<EchoServiceProvider> echoService;

@end

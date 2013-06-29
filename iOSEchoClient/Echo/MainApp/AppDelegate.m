//
//  AppDelegate.m
//  NetworkTest2
//
//  Created by Derek on 13/6/20.
//  Copyright (c) 2013年 DerekTu. All rights reserved.
//

#import "AppDelegate.h"
#import "EchoViewController.h"
#import "SocketIOEchoService.h"
#import "TcpEchoService.h"
#import "HttpEchoService.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"EchoView" bundle:nil];

    // SocketIO
    EchoViewController* echoViewController1 = [storyboard instantiateViewControllerWithIdentifier:@"EchoView"];
    echoViewController1.server = @"127.0.0.1";
    echoViewController1.port = 7070;
    echoViewController1.echoService = [[SocketIOEchoService alloc]init];
    echoViewController1.title = NSLocalizedString(@"SIO", nil);
//    echoViewController1.tabBarItem.image = [UIImage imageNamed:@"first"];

    // Tcp
    EchoViewController* echoViewController2 = [storyboard instantiateViewControllerWithIdentifier:@"EchoView"];
    echoViewController2.server = @"127.0.0.1";
    echoViewController2.port = 7071;
    echoViewController2.echoService = [[TcpEchoService alloc]init];
    echoViewController2.title = NSLocalizedString(@"TCP", nil);
//    echoViewController2.tabBarItem.image = [UIImage imageNamed:@"second"];

    // Http
    //
    EchoViewController* echoViewController3 = [storyboard instantiateViewControllerWithIdentifier:@"EchoView"];
    echoViewController3.server = @"127.0.0.1";
    echoViewController3.port = 7070;
    echoViewController3.echoService = [[HttpEchoService alloc]init];
    echoViewController3.title = NSLocalizedString(@"HTTP", nil);

    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[echoViewController1, echoViewController2, echoViewController3];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];

    // stay awake
    //
    [UIApplication sharedApplication].idleTimerDisabled = YES;

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

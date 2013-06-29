//
//  EchoViewController.m
//  NetworkTest2
//
//  Created by Derek on 13/6/20.
//  Copyright (c) 2013年 DerekTu. All rights reserved.
//

#import "EchoViewController.h"
#import "BlocksKit.h"
#import "SocketIOEchoService.h"
#import "TcpEchoService.h"

// Default Server/Port setting
//
static NSString* const DEFAULT_SERVER = @"127.0.0.1";
static const int DEFAULT_PORT = 7070;

// default values for Echo service
//
static const int DEFAULT_ECHOFREQUENCY = 1000;
static const int DEFAULT_SAMPLECOUNT = 1000;
static const int DEFAULT_TRIMRANGE = 10.0;       // 5%

// tag to identify SERVER/PORT
//
typedef enum
{
   TAG_TEXTSERVER = 101,
   TAG_TEXTPORT = 102,
} ControlTag;

// Table view section
//
typedef enum
{
    SECTION_SERVER = 0,
    SECTION_ACTION = 1,
    SECTION_STATISTICS = 2
} TableViewSection;

@interface EchoViewController () <EchoServiceProviderDelegate>
@property (nonatomic,strong) IBOutlet UITextField* textServer;
@property (nonatomic,strong) IBOutlet UITextField* textPort;
@property (nonatomic,strong) IBOutlet UILabel* labelAction;
@property (nonatomic,strong) IBOutlet UILabel* labelCount;
@property (nonatomic,strong) IBOutlet UILabel* labelAverage;
@property (nonatomic,strong) IBOutlet UILabel* labelMin;
@property (nonatomic,strong) IBOutlet UILabel* labelMax;
@property (nonatomic,strong) IBOutlet UILabel* labelActivityIndicatorPosition;
@property (nonatomic,strong) IBOutletCollection(UILabel) NSArray* arrayLatestSamples;
@property (nonatomic,strong) UIActivityIndicatorView* connectActivityView;
@property (nonatomic,strong) UIColor* colorActionButtonBackground;
@property (nonatomic) BOOL serviceStarted;
@end

@implementation EchoViewController

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // TODO
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.textServer.text = self.server;
    self.textPort.text = [NSString stringWithFormat:@"%d", self.port];

    self.echoService.delegate = self;

    [self initKeyboardDismissHandler];

    [self adjustLatestSampleLabels];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    // TODO: 如果我們在這裡把view release的話, 那當viewDidLoad時我們就必須根據連線狀態initialize view
    // (enable/disable, update statistics label, etc.), 流程上蠻複雜的 !!
    //
}

- (void)dealloc
{
    if (self.echoService)
        self.echoService.delegate = nil;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_ACTION) {
        //
        [self actionButtonClicked];

        // deselect
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == SECTION_ACTION) {
        cell.backgroundColor = self.colorActionButtonBackground;
    }
}

#pragma mark - EchoServiceDelegate implementation

- (void)service:(id<EchoServiceProvider>)service didUpdateConnectStatus:(ConnectStatus)status withError:(NSError*)error
{
    NSLog(@"didUpdateConnectStatus:[%d] Error=[%@]", service.connectStatus, error);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.serviceStarted) {
            if (status != CS_Connecting)
                [self stopConnectActivityView];

            if (status == CS_None) {
                // error occurs during connecting stage
                //
                [self action_ConnectError:error];
            }
        }
    });
}

- (void)service:(id<EchoServiceProvider>)service didEncounterError:(NSError*)error
{
    NSLog(@"didEncounterError:[%@]", error);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self action_Error:error];
    });
}

- (void)serviceDidUpdateStat:(id<EchoServiceProvider>)service
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateStatistics];
    });
}


#pragma mark - View command handling

// Called when textServer/textPort text changes
//
- (IBAction)textFieldTextChanged:(UITextField*)sender
{
    // update self.server/self.port
    //  - 如果因為memory不夠而view被unload的話, 則下次view load起來時我們會直接用self.server/port來initialize
    //
    if (sender.tag == TAG_TEXTSERVER)
        self.server = sender.text;
    else
        self.port = [sender.text intValue];
}

// Called when user press Enter on textServer/textPort
//
- (IBAction)textFieldEndOnExit:(UITextField*)sender
{
    // dismiss keyboard
    //
    [sender resignFirstResponder];
}

// Called to install a tap gesture to automatically dismiss keyboard
//
- (void)initKeyboardDismissHandler
{
    UITapGestureRecognizer* recognizer =
            [[UITapGestureRecognizer alloc]
                    initWithTarget:self
                            action:@selector(hideKeyboard)];

    recognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:recognizer];
}

// Called when tap gesture occurs
//
- (void)hideKeyboard
{
    [self.textServer resignFirstResponder];
    [self.textPort resignFirstResponder];
}

- (void)clearStatistics
{
    self.labelCount.text = @"0";
    self.labelAverage.text = @"0";
    self.labelMin.text = @"0";
    self.labelMax.text = @"0";

    for (UILabel* label in self.arrayLatestSamples)
        label.text = @"0";
}

- (void)updateStatistics
{
    Stat stat = self.echoService.stat;

    self.labelCount.text = [NSString stringWithFormat:@"%d", stat.sampleCount];
    self.labelAverage.text = [NSString stringWithFormat:@"%.2f", stat.meanValue];
    self.labelMin.text = [NSString stringWithFormat:@"%.2f", stat.minValue];
    self.labelMax.text = [NSString stringWithFormat:@"%.2f", stat.maxValue];

    for (int i = 0; i < self.arrayLatestSamples.count; i++) {
        UILabel* label = self.arrayLatestSamples[i];
        label.text = [NSString stringWithFormat:@"%.2f", [self.echoService getLatestSampleValue:i]];
    }
}


// Called when user press 'Action' cell (Start/Stop)
//
- (void)actionButtonClicked
{
    if (!self.serviceStarted) {
        // Check value of self.server/self.port
        //
        if ([self.server isEqualToString:@""]) {
            [UIAlertView showAlertViewWithTitle:@"Error" message:@"請輸入[Server]欄位" cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            return;
        }

        if (self.port == 0) {
            [UIAlertView showAlertViewWithTitle:@"Error" message:@"請輸入[Port]欄位" cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            return;
        }

        [self action_ConnectServer:self.server port:self.port];
    }
    else {
        [self action_DisconnectServer];
    }
}

//
-(void)action_ConnectServer:(NSString*)server port:(int)port
{
    // Connnect Echo Service
    //
    self.echoService.server = server;
    self.echoService.port = port;
    self.echoService.echoFrequency = DEFAULT_ECHOFREQUENCY;
    self.echoService.maxSampleCount = DEFAULT_SAMPLECOUNT;
    self.echoService.trimRange = DEFAULT_TRIMRANGE;

    if (!self.echoService.connect) {
        [UIAlertView showAlertViewWithTitle:@"Error" message:@"無法連線到server." cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
        return;
    }

    [self startConnectActivityView];

    [self updateUI:YES];

    self.serviceStarted = YES;
}

-(void)action_DisconnectServer
{
    // disconect Echo service
    //
    [self.echoService disconnect];

    [self updateUI:NO];

    self.serviceStarted = NO;
}


// Called when error occurs during connection
//
- (void)action_ConnectError:(NSError*)error
{
    [UIAlertView showAlertViewWithTitle:@"Error"
                                message:[NSString stringWithFormat:@"無法連線到server.\n錯誤訊息=[%@]", error]
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil handler:nil];

    [self updateUI:NO];

    self.serviceStarted = NO;
}

// Called when error occurs after connection is established
//
- (void)action_Error:(NSError*)error
{
    NSLog(@"socket error occurs=[%@]", error);

    // TODO: where to put on screen ?
    //
}

// Update UI based on Start/Stop status
//  started = YES: 開始連線
//
- (void)updateUI:(BOOL)started
{
    if (started) {
        self.textServer.enabled = NO;
        self.textPort.enabled = NO;

        // change Action button to "Stop"
        //
        self.labelAction.text = @"Stop";

        // clear statistics data
        //
        self.labelCount.text = @"0";
        self.labelAverage.text = @"0";
        self.labelMin.text = @"0";
        self.labelMax.text = @"0";

        // stay awake
        //
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }
    else {
        // change Action button to "Start"
        //  Note: this is incorrect. A better way is to wait until connection status become CS_None
        //
        self.labelAction.text = @"Start";

        self.textServer.enabled = YES;
        self.textPort.enabled = YES;

        // restore awake setting
        //
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}

// Display spin wheel during connecting
//
- (void)startConnectActivityView
{
    if (self.connectActivityView == nil) {
        // find the location of labelActivityIndicatorPosition
        //
        CGRect rcFrame = [self.labelActivityIndicatorPosition frame];

        // make it a square
        //
        CGRect rcIndicator = CGRectMake(rcFrame.origin.x, rcFrame.origin.y, rcFrame.size.height, rcFrame.size.height);
        self.connectActivityView = [[UIActivityIndicatorView alloc] initWithFrame:rcIndicator];
        self.connectActivityView.hidesWhenStopped = YES;
        self.connectActivityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;

        // add activityView. Note we use labelActivityIndicatorPosition.superView since they are siblings
        //
        [self.labelActivityIndicatorPosition.superview addSubview:self.connectActivityView];
    }

    [self.connectActivityView startAnimating];
}

- (void)stopConnectActivityView
{
    if (self.connectActivityView != nil) {
        [self.connectActivityView stopAnimating];
    }
}

- (void)adjustLatestSampleLabels
{
    // IB無法保證在IBOutletCollection內的items的順序, 所以在此我們自己根據tag來排序
    //
    NSArray* arrT = [self.arrayLatestSamples
            sortedArrayUsingComparator:^(UILabel* label1, UILabel* label2){
                int tag1 = label1.tag;
                int tag2 = label2.tag;

                if (tag1 < tag2)
                    return NSOrderedAscending;
                else if (tag1 > tag2)
                    return NSOrderedDescending;
                else
                    return NSOrderedSame;
            }];

    self.arrayLatestSamples = arrT;
}

@end

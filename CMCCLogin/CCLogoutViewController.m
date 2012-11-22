//
//  CCLogoutViewController.m
//  CMCCLogin
//
//  Created by messense on 12-11-22.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import "CCLogoutViewController.h"
#import "CCAppDelegate.h"
#import "CCLoginStateViewController.h"
#import "CMCCLoginHelper.h"

@interface CCLogoutViewController ()

@end

@implementation CCLogoutViewController

@synthesize cmcc;

- (id)initWithAppDelegate:(CCAppDelegate *)appd withCmcc:(CMCCLoginHelper *)cm withLoginView:(CCLoginViewController *)login {
    self = [super initWithNibName:@"CCLogoutViewController" bundle:nil];
    if (self) {
        app = appd;
        cmcc = cm;
        loginView = login;
        svc = [[CCLoginStateViewController alloc] init];
    }
    
    return self;
}

- (IBAction)logout:(NSButton *)sender {
    [self performSelectorInBackground:@selector(logoutInBackground:)
                           withObject:nil];
    [[svc stateText] setStringValue:@"正在退出..."];
    [[svc stateText] displayIfNeeded];
    [app setBoxContentView:svc];
}

- (void)logoutInBackground:(id)unused {
    @autoreleasepool {
        [cmcc logout];
        [self performSelectorOnMainThread:@selector(updateWithState:)
                               withObject:@"退出登录成功."
                            waitUntilDone:NO];
    }
}

- (void)updateWithState:(NSString *)state {
    [[svc stateText] setStringValue:state];
    [[svc stateText] displayIfNeeded];
    sleep(1);
    [app setBoxContentView:(NSViewController *)loginView];
}

@end

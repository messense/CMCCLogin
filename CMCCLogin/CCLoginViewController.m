//
//  CCLoginViewController.m
//  CMCCLogin
//
//  Created by messense on 12-11-22.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import "CCLoginViewController.h"
#import "CCLogoutViewController.h"
#import "CCAppDelegate.h"

@interface CCLoginViewController ()

@end

@implementation CCLoginViewController

- (id)initWithAppDelegate:(id)appd withCmcc:(CMCCLoginHelper *)cm {
    self = [super initWithNibName:@"CCLoginViewController" bundle:nil];
    if (self) {
        app = appd;
        cmcc = cm;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [_phone setObjectValue:[defaults objectForKey:@"wlanusername"]];
        if ([defaults boolForKey:@"keeppassword"]) {
            [_password setObjectValue:[defaults objectForKey:@"wlanpassword"]];
        }
        [_keeppassword setState:[defaults boolForKey:@"keeppassword"]];
        logoutView = [[CCLogoutViewController alloc] initWithAppDelegate:app
                                                                withCmcc:cmcc
                                                           withLoginView:self];
    }
    
    return self;
}

- (IBAction)login:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [cmcc setPhone:[defaults objectForKey:@"wlanusername"]];
    [cmcc setPassword:[defaults objectForKey:@"wlanpassword"]];
    [self performSelectorInBackground:@selector(loginInBackground:) withObject:nil];
    svc = [[CCLoginStateViewController alloc] init];
    [app setBoxContentView:svc];
}

- (void)loginInBackground:(id)unused {
    @autoreleasepool {
        if ([cmcc login]) {
            [self performSelectorOnMainThread:@selector(updateWithStateAndOK:)
                                   withObject:@"正在登录...\n登录成功."
                                waitUntilDone:NO];
        } else {
            [self performSelectorOnMainThread:@selector(updateWithStateAndFail:)
                                   withObject:@"正在登录...\n登录失败."
                                waitUntilDone:NO];
        }
    }
}

- (void)updateWithStateAndOK:(NSString *)state {
    [[svc stateText] setStringValue:state];
    [[svc stateText] displayIfNeeded];
    sleep(1);
    [app setBoxContentView:logoutView];
}

- (void)updateWithStateAndFail:(NSString *)state {
    [[svc stateText] setStringValue:state];
    [[svc stateText] displayIfNeeded];
    sleep(1);
    [app setBoxContentView:self];
}

@end

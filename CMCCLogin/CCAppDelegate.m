//
//  CCAppDelegate.m
//  CMCCLogin
//
//  Created by messense on 12-11-21.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import "CCAppDelegate.h"
#import "CMCCLoginHelper.h"
#import "Reachability.h"

#import <CoreWLAN/CoreWLAN.h>

@interface CCAppDelegate () {
    __block CMCCLoginHelper *cmcc;
}

@end

@implementation CCAppDelegate

@synthesize window = _window;

+ (void)initialize {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@"" forKey:@"wlanusername"];
    [dict setObject:@"" forKey:@"wlanpassword"];
    [dict setObject:@"" forKey:@"keeppassword"];
    [dict setObject:@"" forKey:@"wlanacname"];
    [dict setObject:@"" forKey:@"usenotification"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark IBAction

- (IBAction)showPreferenceWindow:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:nil];
}

- (IBAction)loginToCMCC:(id)sender {
    if ([cmcc online]) {
        [self showUserNotification:@"CMCC已经登录."];
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults objectForKey:@"wlanusername"] length] <= 0 || [[defaults objectForKey:@"wlanpassword"] length] <= 0) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"请先配置账号和密码!"
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@""];
        [alert runModal];
        [self showPreferenceWindow:self];
        return;
    }
    [self showUserNotification:@"正在登录CMCC"];
    [cmcc setPhone:[defaults objectForKey:@"wlanusername"]];
    [cmcc setPassword:[defaults objectForKey:@"wlanpassword"]];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        BOOL succeed = NO;
        if ([cmcc login]) {
            succeed = YES;
        }
        NSString *str = succeed ? @"登录 CMCC 成功." : @"登录 CMCC 失败";
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self toggleServiceState:str];
        });
    });
}

- (IBAction)logoutOfCMCC:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults objectForKey:@"wlanusername"] length] <= 0 || [[defaults objectForKey:@"wlanpassword"] length] <= 0) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"请先配置账号和密码!"
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@""];
        [alert runModal];
        [self showPreferenceWindow:self];
    }
    [self showUserNotification:@"正在断开CMCC"];
    if (![cmcc acname]) {
        [cmcc setAcname:[defaults objectForKey:@"wlanacname"]];
        NSLog(@"No acname provided, use ACNAME stored in UserDefaults %@", [defaults objectForKey:@"wlanacname"]);
    } else {
        [defaults setObject:[cmcc acname] forKey:@"wlanacname"];
        NSLog(@"Stored current WLAN ACNAME: %@", [cmcc acname]);
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        BOOL succeed = NO;
        if ([cmcc logout]) {
            succeed = YES;
        }
        NSString *str = succeed ? @"断开 CMCC 成功." : @"断开 CMCC 失败";
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self toggleServiceState:str];
        });
    });
}

- (IBAction)exitApplication:(id)sender {
    [NSApp terminate:nil];
}

- (IBAction)showAboutPanel:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:nil];
}

#pragma mark - 
#pragma mark Application Delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupStatusItem];
    [self sleepAndWakeNotifications];
    // Reachability check
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCMCCNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    cmccReachability = [Reachability reachabilityForLocalWiFi];
    [cmccReachability startNotifier];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    cmcc = [[CMCCLoginHelper alloc] initWithPhoneAndPassword:[defaults objectForKey:@"wlanusername"] password:[defaults objectForKey:@"wlanpassword"]];
    [defaults synchronize];
    if ([[defaults objectForKey:@"wlanusername"] length] <= 0 || [[defaults objectForKey:@"wlanpassword"] length] <= 0) {
        [self showPreferenceWindow:nil];
        return;
    }
    if ([defaults boolForKey:@"autologinwhenstart"]) {
        [self loginToCMCC:nil];
    }
    
}

- (void)setupStatusItem {
    statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:23.0];
    statusBarItem.image = [NSImage imageNamed:@"status_item_icon"];
    statusBarItem.menu = statusBarMenu;
    [statusBarItem setHighlightMode:YES];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"autologoutwhenexit"] && [[defaults objectForKey:@"wlanusername"] length] > 0 && [[defaults objectForKey:@"wlanpassword"] length] > 0 && [cmcc online]) {
        BOOL succeed = NO;
        if ([cmcc logout]) {
            succeed = YES;
        }
        NSString *str = succeed ? @"断开 CMCC 成功." : @"断开 CMCC 失败";
        [self toggleServiceState:str];
    }
    return NSTerminateNow;
}

- (void)toggleServiceState:(id)note {
    [self showUserNotification:note];
}

#pragma mark - THUserNotificationCenter delegate

- (void)showUserNotification:(NSString *)note {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"usenotification"]) {
        THUserNotification *notification = [THUserNotification notification];
        notification.title = @"CMCC登录器";
        notification.informativeText = note;
        //设置通知提交的时间
        notification.deliveryDate = [NSDate dateWithTimeIntervalSinceNow:1];
        THUserNotificationCenter *center = [THUserNotificationCenter notificationCenter];
        //删除已经显示过的通知(已经存在用户的通知列表中的)
        [center removeAllDeliveredNotifications];
        //递交通知
        [center deliverNotification:notification];
        //设置通知的代理
        [center setDelegate:self];
    }
}

- (void)userNotificationCenter:(THUserNotificationCenter *)center didActivateNotification:(THUserNotification *)notification {
    [self showPreferenceWindow:nil];
}


- (void)userNotificationCenter:(THUserNotificationCenter *)center didDeliverNotification:(THUserNotification *)notification {
    // do nothing
}


- (BOOL)userNotificationCenter:(THUserNotificationCenter *)center shouldPresentNotification:(THUserNotification *)notification {
    return NO;
}

#pragma mark -
#pragma mark Sleep and Wake Notification

- (void) receiveSleepNote: (NSNotification*) note {
    [self logoutOfCMCC:self];
}

- (void) receiveWakeNote: (NSNotification*) note {
    [self loginToCMCC:self];
}

- (void) sleepAndWakeNotifications {
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveSleepNote:)
                                                               name: NSWorkspaceWillSleepNotification object: NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWakeNote:)
                                                               name: NSWorkspaceDidWakeNotification object: NULL];
}

#pragma mark -
#pragma mark Wi-Fi Status

- (void)checkCMCCNetworkStatus:(NSNotification *)notice {
    NetworkStatus cmccStatus = [cmccReachability currentReachabilityStatus];
    if (cmccStatus != ReachableViaWiFi) {
        [cmcc setOnline:NO];
        [self toggleServiceState:@"没有连接到 CMCC 无线网络，请检查！"];
    } else {
        NSString *ssid = [self currentWiFiSSID];
        if (![ssid isEqualToString:@"CMCC"]) {
            [cmcc setOnline:NO];
            [self showUserNotification:@"没有连接到 CMCC 无线网洛，无法登录."];
        } else {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"autologinwhenstart"]) {
                [self loginToCMCC:nil];
            }
        }
    }
}

- (NSString *)currentWiFiSSID {
    CWInterface *wifi = [CWInterface interface];
    if (wifi) {
        NSString *ssid = wifi.ssid;
        NSLog(@"Current WiFi SSID: %@", ssid);
        return ssid;
    }
    return nil;
}

@end

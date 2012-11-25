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

@implementation CCAppDelegate

@synthesize window = _window;

- (id)init {
    self = [super init];
    if (self) {
        _loaded = NO;
    }
    return self;
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

- (IBAction)exitApplication:(id)sender {
    [NSApp terminate:nil];
}

- (IBAction)showAboutPanel:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:nil];
}

- (IBAction)toggleService:(id)sender {
    if (![cmcc online]) {
        [self loginToCMCC];
    } else {
        [self logoutOfCMCC];
    }
}

- (void)loginToCMCC {
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
        [cmcc login];
    });
}

- (void)logoutOfCMCC {
    if (![cmcc online]) {
        [self showUserNotification:@"CMCC已经下线."];
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
    }
    [self showUserNotification:@"正在下线CMCC"];
    if (![cmcc acname]) {
        [cmcc setAcname:[defaults objectForKey:@"wlanacname"]];
        NSLog(@"No acname provided, use ACNAME stored in UserDefaults %@", [defaults objectForKey:@"wlanacname"]);
    } else {
        [defaults setObject:[cmcc acname] forKey:@"wlanacname"];
        NSLog(@"Stored current WLAN ACNAME: %@", [cmcc acname]);
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [cmcc logout];
    });
}

#pragma mark - 
#pragma mark Application Delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupStatusItem];
    [self sleepAndWakeNotifications];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(toggleServiceState:) name:CMCCLoginNotification object:nil];
    [nc addObserver:self selector:@selector(toggleServiceState:) name:CMCCLogoutNotification object:nil];
    // Reachability check
    [nc addObserver:self selector:@selector(checkCMCCNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    cmccReachability = [Reachability reachabilityForLocalWiFi];
    [cmccReachability startNotifier];
    hostReachability = [Reachability reachabilityWithHostname:@"www.baidu.com"];
    [hostReachability startNotifier];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    cmcc = [[CMCCLoginHelper alloc] initWithPhoneAndPassword:[defaults objectForKey:@"wlanusername"] password:[defaults objectForKey:@"wlanpassword"]];
    [defaults synchronize];
    if ([[defaults objectForKey:@"wlanusername"] length] <= 0 || [[defaults objectForKey:@"wlanpassword"] length] <= 0) {
        [self showPreferenceWindow:nil];
        return;
    }
    // CMCC Network check
    [self checkCMCCNetworkStatus:nil];
    // Auto login
    if ([defaults boolForKey:@"autologinwhenstart"] && ![cmcc online]) {
        NetworkStatus cmccStatus = [cmccReachability currentReachabilityStatus];
        NetworkStatus hostStatus = [hostReachability currentReachabilityStatus];
        if ([[self currentWiFiSSID] isEqualToString:@"CMCC"] && cmccStatus == ReachableViaWiFi && hostStatus == ReachableViaWiFi) {
            [self toggleService:nil];
        } else {
            [self showUserNotification:@"没有成功连接到 CMCC 无线网洛，无法登录."];
        }
    }
    _loaded = YES;
}

- (void)setupStatusItem {
    statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:23.0];
    statusBarItem.image = [NSImage imageNamed:@"status_item_icon_offline"];
    statusBarItem.alternateImage = [NSImage imageNamed:@"status_item_icon_alt"];
    statusBarItem.menu = statusBarMenu;
    [statusBarItem setHighlightMode:YES];
}

- (void)logoutOfCMCCWhenExit {
    NSLog(@"Terminate application now");
    [NSApp replyToApplicationShouldTerminate:YES];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutOfCMCCWhenExit) name:CMCCLogoutNotification object:nil];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"autologoutwhenexit"] && [[defaults objectForKey:@"wlanusername"] length] > 0 && [[defaults objectForKey:@"wlanpassword"] length] > 0 && [cmcc online]) {
        [self logoutOfCMCC];
        return NSTerminateLater;
    }
    return NSTerminateNow;
}

- (void)toggleServiceState:(NSNotification *)notification {
    if ([[notification name] isEqualToString:CMCCLoginNotification]) {
        if ([cmcc online]) {
            statusBarItem.image = [NSImage imageNamed:@"status_item_icon"];
            [loginMenuItem setTitle:@"下线 CMCC"];
            loginMenuItem.image = [NSImage imageNamed:@"status_offline"];
            [infoMenuItem setTitle:[NSString stringWithFormat:@"%@ 已登录", cmcc.phone]];
            infoMenuItem.image = [NSImage imageNamed:@"status_online"];
            [self showUserNotification:@"CMCC 登录成功."];
        } else {
            [self showUserNotification:@"CMCC 登录失败."];
        }
    } else if ([[notification name] isEqualToString:CMCCLogoutNotification]) {
        if ([cmcc online]) {
            [self showUserNotification:@"CMCC 下线失败."];
        } else {
            statusBarItem.image = [NSImage imageNamed:@"status_item_icon_offline"];
            [loginMenuItem setTitle:@"登录 CMCC"];
            loginMenuItem.image = [NSImage imageNamed:@"status_online"];
            [infoMenuItem setTitle:@"未登录账号"];
            infoMenuItem.image = [NSImage imageNamed:@"status_offline"];
            [self showUserNotification:@"CMCC 下线成功."];
        }
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![[cmcc phone] isEqualToString:[defaults objectForKey:@"wlanusername"]] || ![[cmcc password] isEqualToString:[defaults objectForKey:@"wlanpassword"]]) {
        [self loginToCMCC];
    }
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
    [self logoutOfCMCC];
}

- (void) receiveWakeNote: (NSNotification*) note {
    [self loginToCMCC];
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

- (void)checkCMCCNetworkStatus:(NSNotification *)notification {
    NetworkStatus cmccStatus = [cmccReachability currentReachabilityStatus];
    NetworkStatus hostStatus = [hostReachability currentReachabilityStatus];
    if (cmccStatus != ReachableViaWiFi) {
        [cmcc setOnline:NO];
        [self showUserNotification:@"没有连接到 CMCC 无线网络，请检查！"];
    } else {
        NSString *ssid = [self currentWiFiSSID];
        if (![ssid isEqualToString:@"CMCC"]) {
            [cmcc setOnline:NO];
            [self showUserNotification:@"没有连接到 CMCC 无线网洛，无法登录."];
        } else {
            // 检查是否是网络非正常断开导致，测试是否已经登录到了CMCC
            if (hostStatus == ReachableViaWiFi) {
                if ([CMCCLoginHelper alreadyOnline]) {
                    [cmcc setOnline:YES];
                    [self showUserNotification:@"CMCC 连接已恢复正常."];
                    [[NSNotificationCenter defaultCenter] postNotificationName:CMCCLoginNotification object:nil];
                } else {
                    if (_loaded && [[NSUserDefaults standardUserDefaults] boolForKey:@"autorelogin"]) {
                        [self toggleService:nil];
                    } else {
                        if (_loaded) {
                            [self showUserNotification:@"CMCC 已断开."];
                            //[[NSNotificationCenter defaultCenter] postNotificationName:CMCCLogoutNotification object:nil];
                        }
                    }
                }
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

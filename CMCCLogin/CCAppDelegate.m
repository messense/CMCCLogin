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

@interface CCAppDelegate() {
    NSStatusItem * statusBarItem;
    Reachability *cmccReachability;
    Reachability *hostReachability;
    BOOL _loaded;
    BOOL _manualStopped;
    CMCCLoginHelper *cmcc;
}

@end

@implementation CCAppDelegate

@synthesize window = _window;

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
    if (!cmcc.online) {
        [self loginToCMCC];
        _manualStopped = NO;
    } else {
        [self logoutOfCMCC];
        _manualStopped = YES;
    }
}

- (void)loginToCMCC {
    if (cmcc.online) {
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
    cmcc.phone = [defaults objectForKey:@"wlanusername"];
    cmcc.password = [defaults objectForKey:@"wlanpassword"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [cmcc login];
    });
}

- (void)logoutOfCMCC {
    if (!cmcc.online) {
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
    if (!cmcc.acname) {
        cmcc.acname = [defaults objectForKey:@"wlanacname"];
        NSLog(@"No acname provided, use ACNAME stored in UserDefaults %@", [defaults objectForKey:@"wlanacname"]);
    } else {
        [defaults setObject:cmcc.acname forKey:@"wlanacname"];
        NSLog(@"Stored current WLAN ACNAME: %@", cmcc.acname);
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [cmcc logout];
    });
}

#pragma mark - 
#pragma mark Application Delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _loaded = NO;
    _manualStopped = NO;
    [self setupStatusItem];
    [self sleepAndWakeNotifications];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(toggleServiceState:)
               name:CMCCLoginNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(toggleServiceState:)
               name:CMCCLogoutNotification
             object:nil];
    // Reachability check
    cmccReachability = [Reachability reachabilityForLocalWiFi];
    [cmccReachability startNotifier];
    hostReachability = [Reachability reachabilityWithHostname:@"www.baidu.com"];
    [hostReachability startNotifier];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    cmcc = [[CMCCLoginHelper alloc] initWithPhoneAndPassword:[defaults objectForKey:@"wlanusername"]
                                                    password:[defaults objectForKey:@"wlanpassword"]];

    if ([[defaults objectForKey:@"wlanusername"] length] <= 0 || [[defaults objectForKey:@"wlanpassword"] length] <= 0) {
        [self showPreferenceWindow:nil];
        return;
    }
    // CMCC Network check
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self checkCMCCNetworkStatus:nil];
    });
    // Auto login
    if ([defaults boolForKey:@"autologinwhenstart"] && ![cmcc online]) {
        NetworkStatus cmccStatus = [cmccReachability currentReachabilityStatus];
        NetworkStatus hostStatus = [hostReachability currentReachabilityStatus];
        if ([[self currentWiFiSSID] isEqualToString:@"CMCC"] && cmccStatus == ReachableViaWiFi && hostStatus == ReachableViaWiFi) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                [self toggleService:nil];
            });
        } else {
            [self showUserNotification:@"没有成功连接到 CMCC 无线网洛，无法登录."];
        }
    }
    // Reachability Observer
    [nc addObserver:self
           selector:@selector(checkCMCCNetworkStatus:)
               name:kReachabilityChangedNotification
             object:nil];
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(logoutOfCMCCWhenExit)
                                                 name:CMCCLogoutNotification object:nil];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"autologoutwhenexit"] && [[defaults objectForKey:@"wlanusername"] length] > 0 && [[defaults objectForKey:@"wlanpassword"] length] > 0 && cmcc.online) {
        [self logoutOfCMCC];
        return NSTerminateLater;
    }
    return NSTerminateNow;
}

- (void)toggleServiceState:(NSNotification *)notification {
    if ([[notification name] isEqualToString:CMCCLoginNotification]) {
        if (cmcc.online) {
            [self changeStatusBarState:YES];
            [self showUserNotification:@"CMCC 登录成功."];
        } else {
            [self showUserNotification:@"CMCC 登录失败."];
        }
    } else if ([[notification name] isEqualToString:CMCCLogoutNotification]) {
        if (cmcc.online) {
            [self showUserNotification:@"CMCC 下线失败."];
        } else {
            [self changeStatusBarState:NO];
            [self showUserNotification:@"CMCC 下线成功."];
        }
    }
}

- (void)changeStatusBarState:(BOOL)online {
    if (online) {
        statusBarItem.image = [NSImage imageNamed:@"status_item_icon"];
        [loginMenuItem setTitle:@"下线 CMCC"];
        loginMenuItem.image = [NSImage imageNamed:@"status_offline"];
        [infoMenuItem setTitle:[NSString stringWithFormat:@"%@ 已登录", cmcc.phone]];
        infoMenuItem.image = [NSImage imageNamed:@"status_online"];
    } else {
        statusBarItem.image = [NSImage imageNamed:@"status_item_icon_offline"];
        [loginMenuItem setTitle:@"登录 CMCC"];
        loginMenuItem.image = [NSImage imageNamed:@"status_online"];
        [infoMenuItem setTitle:@"未登录账号"];
        infoMenuItem.image = [NSImage imageNamed:@"status_offline"];
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![cmcc.phone isEqualToString:[defaults objectForKey:@"wlanusername"]] || ![cmcc.password isEqualToString:[defaults objectForKey:@"wlanpassword"]]) {
        [self loginToCMCC];
    }
    [defaults synchronize];
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
        //设置通知的代理
        [center setDelegate:self];
        //删除已经显示过的通知(已经存在用户的通知列表中的)
        [center removeAllDeliveredNotifications];
        //递交通知
        [center deliverNotification:notification];
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

- (void)receiveSleepNote: (NSNotification*)note {
    [self logoutOfCMCC];
}

- (void)receiveWakeNote: (NSNotification*)note {
    [self loginToCMCC];
}

- (void)sleepAndWakeNotifications {
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveSleepNote:)
                                                               name: NSWorkspaceWillSleepNotification
                                                             object: nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWakeNote:)
                                                               name: NSWorkspaceDidWakeNotification
                                                             object: nil];
}

#pragma mark -
#pragma mark Wi-Fi Status

- (void)checkCMCCNetworkStatus:(NSNotification *)notification {
    NetworkStatus cmccStatus = [cmccReachability currentReachabilityStatus];
    NetworkStatus hostStatus = [hostReachability currentReachabilityStatus];
    if (cmccStatus != ReachableViaWiFi) {
        cmcc.online = NO;
        if (_loaded && !_manualStopped)
            [self showUserNotification:@"没有连接到 CMCC 无线网络，请检查！"];
        [self changeStatusBarState:NO];
        // disable login
        [loginMenuItem setEnabled:NO];
    } else {
        NSString *ssid = [self currentWiFiSSID];
        if (![ssid isEqualToString:@"CMCC"]) {
            cmcc.online = NO;
            if (_loaded && !_manualStopped)
                [self showUserNotification:@"没有连接到 CMCC 无线网洛，无法登录."];
            [self changeStatusBarState:NO];
            // disable login
            [loginMenuItem setEnabled:NO];
        } else {
            // 检查是否是网络非正常断开导致，测试是否已经登录到了CMCC
            if (hostStatus == ReachableViaWiFi) {
                // enable login
                [loginMenuItem setEnabled:YES];
                if ([CMCCLoginHelper alreadyOnline]) {
                    cmcc.online = YES;
                    if (_loaded && !_manualStopped)
                        [self showUserNotification:@"CMCC 连接已恢复正常."];
                    [self changeStatusBarState:YES];
                } else {
                    if (_loaded && !_manualStopped && [[NSUserDefaults standardUserDefaults] boolForKey:@"autorelogin"]) {
                        [self toggleService:nil];
                    } else {
                        if (_loaded) {
                            if (!_manualStopped)
                                [self showUserNotification:@"CMCC 已断开."];
                            [self changeStatusBarState:NO];
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

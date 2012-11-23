//
//  CCAppDelegate.m
//  CMCCLogin
//
//  Created by messense on 12-11-21.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import "CCAppDelegate.h"
#import "CMCCLoginHelper.h"

@interface CCAppDelegate () {
    CMCCLoginHelper *cmcc;
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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupStatusItem];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    cmcc = [[CMCCLoginHelper alloc] initWithPhoneAndPassword:[defaults objectForKey:@"wlanusername"] password:[defaults objectForKey:@"wlanpassword"]];
    [defaults synchronize];
    
}

- (void)setupStatusItem {
    statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:23.0];
    statusBarItem.image = [NSImage imageNamed:@"status_item_icon"];
    statusBarItem.menu = statusBarMenu;
    [statusBarItem setHighlightMode:YES];
}

- (IBAction)showPreferenceWindow:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [_window makeKeyAndOrderFront:nil];
}

- (IBAction)loginToCMCC:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"wlanusername"] || ![defaults objectForKey:@"wlanpassword"]) {
        [self showPreferenceWindow:self];
    }
    [cmcc setPhone:[defaults objectForKey:@"wlanusername"]];
    [cmcc setPassword:[defaults objectForKey:@"wlanpassword"]];
    [self performSelectorInBackground:@selector(loginInBackground)
                           withObject:nil];
}

- (IBAction)logoutOfCMCC:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"wlanusername"] || ![defaults objectForKey:@"wlanpassword"]) {
        [self showPreferenceWindow:self];
    }
    if (![cmcc acname]) {
        [cmcc setAcname:[defaults objectForKey:@"wlanacname"]];
    } else {
        [defaults setObject:[cmcc acname] forKey:@"wlanacname"];
    }
    [self performSelectorInBackground:@selector(logoutInBackground)
                           withObject:nil];
}

- (IBAction)exitApplication:(id)sender {
    [NSApp terminate:nil];
}

- (IBAction)showAboutPanel:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:nil];
}

- (void)loginInBackground {
    @autoreleasepool {
        if ([cmcc login]) {
            [self performSelectorOnMainThread:@selector(toggleServiceState:)
                                   withObject:@"登录CMCC成功."
                                waitUntilDone:NO];
        } else {
            [self performSelectorOnMainThread:@selector(toggleServiceState:)
                                   withObject:@"登录CMCC失败."
                                waitUntilDone:NO];
        }
    }
}

- (void)logoutInBackground {
    @autoreleasepool {
        [cmcc logout];
        [self performSelectorOnMainThread:@selector(toggleServiceState:)
                               withObject:@"退出登录成功."
                            waitUntilDone:NO];
    }
}

- (void)toggleServiceState:(id)note {
    [self showUserNotification:note];
}

#pragma mark -
#pragma mark - THUserNotificationCenter delegate

- (void)userNotificationCenter:(THUserNotificationCenter *)center didActivateNotification:(THUserNotification *)notification {
    [self showPreferenceWindow:nil];
}


- (void)userNotificationCenter:(THUserNotificationCenter *)center didDeliverNotification:(THUserNotification *)notification {
    // do nothing
}


- (BOOL)userNotificationCenter:(THUserNotificationCenter *)center shouldPresentNotification:(THUserNotification *)notification {
    return NO;
}


@end

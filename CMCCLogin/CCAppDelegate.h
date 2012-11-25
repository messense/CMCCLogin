//
//  CCAppDelegate.h
//  CMCCLogin
//
//  Created by messense on 12-11-21.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "THUserNotification.h"

@class Reachability;
@class CMCCLoginHelper;

@interface CCAppDelegate : NSObject <NSApplicationDelegate, THUserNotificationCenterDelegate, NSWindowDelegate> {
    IBOutlet NSMenu *statusBarMenu;
    NSStatusItem * statusBarItem;
    Reachability *cmccReachability;
    Reachability *hostReachability;
    BOOL _loaded;
    __block CMCCLoginHelper *cmcc;
    IBOutlet NSMenuItem *infoMenuItem;
    IBOutlet NSMenuItem *loginMenuItem;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)toggleService:(id)sender;
- (IBAction)showPreferenceWindow:(id)sender;
- (void)loginToCMCC;
- (void)logoutOfCMCC;
- (IBAction)exitApplication:(id)sender;
- (IBAction)showAboutPanel:(id)sender;

- (void)checkCMCCNetworkStatus:(NSNotification *)notice;

@end

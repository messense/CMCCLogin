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

@interface CCAppDelegate : NSObject <NSApplicationDelegate, THUserNotificationCenterDelegate> {
    IBOutlet NSMenu *statusBarMenu;
    NSStatusItem * statusBarItem;
    Reachability *cmccReachability;
    Reachability *hostReachability;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)showPreferenceWindow:(id)sender;
- (IBAction)loginToCMCC:(id)sender;
- (IBAction)logoutOfCMCC:(id)sender;
- (IBAction)exitApplication:(id)sender;
- (IBAction)showAboutPanel:(id)sender;

- (void)checkCMCCNetworkStatus:(NSNotification *)notice;

@end

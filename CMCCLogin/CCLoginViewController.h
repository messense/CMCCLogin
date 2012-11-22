//
//  CCLoginViewController.h
//  CMCCLogin
//
//  Created by messense on 12-11-22.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CMCCLoginHelper.h"
#import "CCLoginStateViewController.h"

@class CCLogoutViewController;

@class CCAppDelegate;

@interface CCLoginViewController : NSViewController {
    CMCCLoginHelper *cmcc;
    CCLoginStateViewController *svc;
    CCAppDelegate *app;
    CCLogoutViewController *logoutView;
}

@property (unsafe_unretained) IBOutlet NSTextField *phone;
@property (unsafe_unretained) IBOutlet NSSecureTextField *password;
@property (unsafe_unretained) IBOutlet NSButton *keeppassword;

- (id)initWithAppDelegate:(CCAppDelegate *)appd withCmcc:(CMCCLoginHelper *)cm;

- (IBAction)login:(id)sender;

@end

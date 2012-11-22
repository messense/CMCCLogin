//
//  CCLogoutViewController.h
//  CMCCLogin
//
//  Created by messense on 12-11-22.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CMCCLoginHelper;
@class CCAppDelegate;
@class CCLoginViewController;
@class CCLoginStateViewController;

@interface CCLogoutViewController : NSViewController {
    CMCCLoginHelper *cmcc;
    CCLoginStateViewController *svc;
    CCLoginViewController *loginView;
    CCAppDelegate *app;
}

@property (readwrite, strong) CMCCLoginHelper *cmcc;

- (IBAction)logout:(NSButton *)sender;

- (id)initWithAppDelegate:(CCAppDelegate *)appd withCmcc:(CMCCLoginHelper *)cm withLoginView:(CCLoginViewController *)login;

@end

//
//  CCAppDelegate.h
//  CMCCLogin
//
//  Created by messense on 12-11-21.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CMCCLoginHelper;

@interface CCAppDelegate : NSObject <NSApplicationDelegate> {
    CMCCLoginHelper *cmcc;
}

@property (assign) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextField *phone;
@property (unsafe_unretained) IBOutlet NSSecureTextField *password;
@property (readwrite) CMCCLoginHelper *cmcc;
@property (unsafe_unretained) IBOutlet NSButton *keeppassword;

- (IBAction)connectWlan:(NSButton *)sender;
- (IBAction)disconnectWlan:(NSButton *)sender;

@end

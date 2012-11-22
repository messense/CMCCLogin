//
//  CCAppDelegate.m
//  CMCCLogin
//
//  Created by messense on 12-11-21.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import "CCAppDelegate.h"
#import "CMCCLoginHelper.h"
#import "CCLoginViewController.h"

@interface CCAppDelegate () {
    CMCCLoginHelper *cl;
    NSViewController *vc;
}

@property (strong) CMCCLoginHelper *cl;
@property NSViewController *vc;

@end

@implementation CCAppDelegate

@synthesize cl;
@synthesize vc;

+ (void)initialize {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@"" forKey:@"wlanusername"];
    [dict setObject:@"" forKey:@"wlanpassword"];
    [dict setObject:@"" forKey:@"keeppassword"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    cl = [[CMCCLoginHelper alloc] initWithPhoneAndPassword:[defaults objectForKey:@"wlanusername"] password:[defaults objectForKey:@"wlanpassword"]];
    vc = [[CCLoginViewController alloc] initWithAppDelegate:self
                                                   withCmcc:cl];
    [self setBoxContentView:vc];
}

- (void)setBoxContentView:(NSViewController *)viewController {
    BOOL ended = [_window makeFirstResponder:_window];
    if (!ended) {
        NSBeep();
        return;
    }
    NSView *v = [viewController view];
    NSSize oldSize = [[_box contentView] frame].size;
    NSSize newSize = [v frame].size;
    float deltaWidth = newSize.width - oldSize.width;
    float deltaHeight = newSize.height - oldSize.height;
    NSRect windowFrame = [_window frame];
    windowFrame.size.height += deltaHeight;
    windowFrame.origin.y -= deltaHeight;
    windowFrame.size.width += deltaWidth;
    [_box setContentView:nil];
    [_window setFrame:windowFrame
              display:YES
              animate:YES];
    [_box setContentView:v];
}

@end

//
//  CCAppDelegate.m
//  CMCCLogin
//
//  Created by messense on 12-11-21.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import "CCAppDelegate.h"
#import "CMCCLoginHelper.h"

@implementation CCAppDelegate

@synthesize cmcc;

+ (void)initialize {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@"" forKey:@"wlanusername"];
    [dict setObject:@"" forKey:@"wlanpassword"];
    [dict setObject:@"" forKey:@"keeppassword"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [_phone setObjectValue:[defaults objectForKey:@"wlanusername"]];
    if ([defaults boolForKey:@"keeppassword"]) {
        [_password setObjectValue:[defaults objectForKey:@"wlanpassword"]];
    }
    [_keeppassword setState:[defaults boolForKey:@"keeppassword"]];
    cmcc = [[CMCCLoginHelper alloc] initWithPhoneAndPassword:[defaults objectForKey:@"wlanusername"] password:[defaults objectForKey:@"wlanpassword"]];
}

- (IBAction)connectWlan:(NSButton *)sender {
    [self saveDefaults];
    [cmcc login];
}

- (IBAction)disconnectWlan:(NSButton *)sender {
    [self saveDefaults];
    [cmcc logout];
}

- (void)saveDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[_phone objectValue] forKey:@"wlanusername"];
    [defaults setObject:[_password objectValue] forKey:@"wlanpassword"];
    [defaults setBool:[_keeppassword state] forKey:@"keeppassword"];
    [cmcc setPhone:[_phone objectValue]];
    [cmcc setPassword:[_password objectValue]];
}

@end

//
//  CMCCLoginHelper.h
//  CMCCLogin
//
//  Created by messense on 12-11-21.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const CMCCLoginNotification;
extern NSString *const CMCCLogoutNotification;

@interface CMCCLoginHelper : NSObject {
    NSString *phone;
    NSString *password;
    NSString *userip;
    NSString *acname;
    NSMutableData *bodyData;
    BOOL online;
}

@property (readwrite, copy) NSString *phone;
@property (readwrite, copy) NSString *password;
@property (readwrite, copy) NSString *userip;
@property (readwrite, copy) NSString *acname;
@property (readwrite, copy) NSMutableData *bodyData;
@property (assign) BOOL online;

- (id)initWithPhoneAndPassword:(NSString *)ph password:(NSString *)pwd;
- (BOOL)login;
- (BOOL)logout;

+ (NSString *)localIP;
+ (NSURL *)redirectUrl;
+ (BOOL)alreadyOnline;

@end

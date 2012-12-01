//
//  CMCCLoginHelper.h
//  CMCCLogin
//
//  Created by messense on 12-11-21.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const CMCCLoginNotification;
extern NSString * const CMCCLogoutNotification;

@interface CMCCLoginHelper : NSObject

@property (nonatomic, copy) NSString *phone;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *userip;
@property (nonatomic, copy) NSString *acname;
@property (nonatomic, assign) BOOL online;

- (id)initWithPhoneAndPassword:(NSString *)ph password:(NSString *)pwd;
- (BOOL)login;
- (BOOL)logout;

+ (NSString *)localIP;
+ (NSURL *)redirectUrl;
+ (BOOL)alreadyOnline;

@end

//
//  CMCCLoginHelper.m
//  CMCCLogin
//
//  Created by messense on 12-11-21.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import "CMCCLoginHelper.h"

@implementation CMCCLoginHelper

@synthesize phone;
@synthesize password;
@synthesize userip;
@synthesize acname;
@synthesize bodyData;
@synthesize online;

#pragma mark -
#pragma mark 实例方法

- (id)init {
    self = [super init];
    if (self) {
        self.userip = [[self class] localIP];
        self.online = NO;
    }
    return self;
}

- (id)initWithPhoneAndPassword:(NSString *)ph password:(NSString *)pwd {
    self = [super init];
    if (self) {
        [self setPhone:ph];
        [self setPassword:pwd];
        self.userip = [[self class] localIP];
        self.online = NO;
    }
    return self;
}

- (BOOL)login {
    if (![self phone] || ![self password]) {
        NSLog(@"No phone or password provided.");
        return NO;
    }
    // try to get wlanuserip and wlanacname
    NSURL *redirectUrl = [[self class] redirectUrl];
    NSString *tmpstr1 = [[redirectUrl query] stringByReplacingOccurrencesOfString:@"wlanuserip=" withString:@""];
    NSString *tmpstr2 = [tmpstr1 stringByReplacingOccurrencesOfString:userip withString:@""];
    self.acname = [tmpstr2 stringByReplacingOccurrencesOfString:@"&wlanacname=" withString:@""];
    // try to login
    NSURL *loginUrl = [NSURL URLWithString:@"http://221.176.1.140/wlan/login.do"];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:loginUrl
                                                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                   timeoutInterval:10.0f];
    [req setHTTPMethod:@"POST"];
    NSString *post = [NSString stringWithFormat:@"wlanuserip=%@&wlanacname=%@&wlanacip=&loginmode=static&wlanacssid=CMCC&issaveinfo=&portion=CMCC&uaID=PCUA0002&obsReturnAccount=&Token=First&staticusername=%@&staticpassword=%@", self.userip, self.acname, self.phone, self.password];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *length = [NSString stringWithFormat:@"%ld", [postData length]];
    [req setValue:length forHTTPHeaderField:@"Content-Length"];
    [req setValue:@"application/x-www-form-urlencoded;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [req setHTTPBody:postData];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    [NSURLConnection sendSynchronousRequest:req
                                         returningResponse:&response
                                                     error:&error];
    BOOL succeed = [[[self class] redirectUrl] isEqualTo:[NSURL URLWithString:@"http://www.baidu.com/"]];
    if (error || !succeed) {
        return NO;
    }
    self.online = YES;
    return YES;
}

- (BOOL)logout {
    NSURL *logoutUrl = [NSURL URLWithString:@"http://221.176.1.140/wlan/logout.do"];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:logoutUrl
                                                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                   timeoutInterval:10.0f];
    [req setHTTPMethod:@"POST"];
    NSString *post = [NSString stringWithFormat:@"wlanuserip=%@&wlanacname=%@&wlanacip=&loginmode=static&logintime=&remaintime=&areacode=&productid=&effecttime=&expiretime=&keystr=&cf=&wlanacssid=CMCC&issaveinfo=&portion=cmcc&uaID=PCUA0002&logouttype=TYPESUBMIT&username=%@", self.userip, self.acname, self.phone];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *length = [NSString stringWithFormat:@"%ld", [postData length]];
    [req setValue:length forHTTPHeaderField:@"Content-Length"];
    [req setValue:@"application/x-www-form-urlencoded;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [req setHTTPBody:postData];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    [NSURLConnection sendSynchronousRequest:req
                          returningResponse:&response
                                      error:&error];
    BOOL succeed = [[[self class] redirectUrl] isEqualTo:[NSURL URLWithString:@"http://www.baidu.com/"]];
    if (error || succeed) {
        return NO;
    }
    self.online = NO;
    return YES;
}

#pragma mark -
#pragma mark 静态方法

+ (NSString *)localIP {
    NSHost *host = [NSHost currentHost];
    NSArray *ips = [host addresses];
    for(NSString *ip in ips) {
        if (![ip hasPrefix:@"127."] && [[ip componentsSeparatedByString:@"."] count] == 4) {
            return ip;
        }
    }
    return @"";
}

+ (NSURL *)redirectUrl {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.baidu.com"]
                                                        cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                    timeoutInterval:10.0f];
    [req setHTTPMethod:@"HEAD"];
    NSError *error = nil;
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:req
                          returningResponse:&response
                                      error:&error];
    if (error) {
        return nil;
    }
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    return [httpResponse URL];
}

@end

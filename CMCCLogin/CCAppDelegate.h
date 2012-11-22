//
//  CCAppDelegate.h
//  CMCCLogin
//
//  Created by messense on 12-11-21.
//  Copyright (c) 2012年 messense. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CCAppDelegate : NSObject <NSApplicationDelegate> {

}

@property (assign) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSBox *box;

- (void)setBoxContentView:(NSViewController *)viewController;

@end

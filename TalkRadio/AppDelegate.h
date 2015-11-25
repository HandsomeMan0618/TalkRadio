//
//  AppDelegate.h
//  TalkRadio
//
//  Created by lion on 3/8/13.
//  Copyright (c) 2013 lion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TalkRadioViewController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    TalkRadioViewController* radioViewController;
    NSMutableArray* arrays;
}

@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSViewController* radioViewController;
@property (strong) NSMutableArray* arrays;

-(void)initShowInfo;
-(void)initStationInfo;

@end

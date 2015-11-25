//
//  TalkRadioView.h
//  TalkRadio
//
//  Created by lion on 3/10/13.
//  Copyright (c) 2013 lion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TalkRadioData.h"

@interface TalkRadioView : NSView {
    IBOutlet NSImageView* bgImgView;
    IBOutlet NSImageView* showBgImgView;
    IBOutlet NSImageView* showImgView;
    IBOutlet NSTextField* showText;
    IBOutlet NSTextField* stationText;
    IBOutlet NSImageView* playBgView;
}

@property(assign) NSImageView* bgImgView;
@property(assign) NSImageView* showBgImgView;
@property(assign) NSImageView* showImgView;
@property(assign) NSImageView* playBgView;
@property(assign) NSTextField* showText;
@property(assign) NSTextField* stationText;

-(void)setTalkRadioData:(TalkRadioData*)radioData;
-(void)initView;

@end

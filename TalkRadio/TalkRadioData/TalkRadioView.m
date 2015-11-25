//
//  TalkRadioView.m
//  TalkRadio
//
//  Created by lion on 3/10/13.
//  Copyright (c) 2013 lion. All rights reserved.
//

#import "TalkRadioView.h"

@implementation TalkRadioView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

-(void)setTalkRadioData:(TalkRadioData*)radioData
{
    [self.showImgView setImage:radioData.radioImage];
    if (radioData.radioType == RADIO_SHOW)
    {
        self.showText.stringValue = radioData.showName;
        self.stationText.stringValue = radioData.stationName;
    }
    else
    {
        self.showText.stringValue = radioData.stationName;
        self.stationText.stringValue = radioData.stationDesc;
    }

    [self.showBgImgView setImage:[NSImage imageNamed:@"showCellBackground_normal.png"]];
}

-(void)initView
{
    [self.showBgImgView setImage:[NSImage imageNamed:@"showCellBackground_normal.png"]];
    [self.playBgView setImage:[NSImage imageNamed:@"play_bg.png"]];
    [self.bgImgView setImage:[NSImage imageNamed:@"bg.png"]];
}

@end

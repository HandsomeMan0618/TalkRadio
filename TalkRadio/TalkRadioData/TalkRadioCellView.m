//
//  TalkRadioCellView.m
//  TalkRadio
//
//  Created by lion on 3/10/13.
//  Copyright (c) 2013 lion. All rights reserved.
//

#import "TalkRadioCellView.h"

@implementation TalkRadioCellView


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

-(void) setRadioCell:(TalkRadioData*)radioData
{
    self.imageView.image = radioData.radioImage;
    
    if (radioData.radioType == RADIO_SHOW)
    {
        self.textField.stringValue = radioData.showName;
        self.propertyText.stringValue = [NSString stringWithFormat:@"Weekdays, %@ %@ to %@", radioData.stationName, radioData.strStartHour, radioData.strEndHour];
        self.propertyText.textColor = NSColor.blackColor;
        [self.broadcastText setHidden:NO];
    }
    else
    {
        self.textField.stringValue = radioData.stationName;
        self.propertyText.textColor = NSColor.redColor;
        self.propertyText.stringValue = radioData.stationDesc;
        self.propertyText.textColor = NSColor.redColor;
        [self.broadcastText setHidden:YES];
    }
}

-(void) setBroadCastingState:(BOOL)bState
{
    if (bState == YES)
    {
        [self.broadcastText setHidden:NO];
        self.cellBgView.image = [NSImage imageNamed:@"showCellBackground_selected.png"];
    }
    else
    {
        [self.broadcastText setHidden:YES];
        self.cellBgView.image = [NSImage imageNamed:@"showCellBackground_normal.png"];
    }
}

@end

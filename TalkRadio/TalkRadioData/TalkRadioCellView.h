//
//  TalkRadioCellView.h
//  TalkRadio
//
//  Created by lion on 3/10/13.
//  Copyright (c) 2013 lion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TalkRadioData.h"

@interface TalkRadioCellView : NSTableCellView {
@private
    IBOutlet NSImageView* cellBgView;
    IBOutlet NSTextField* propertyText;
    IBOutlet NSTextField* broadcastText;
}

@property(assign) NSImageView* cellBgView;
@property(assign) NSTextField* propertyText;
@property(assign) NSTextField* broadcastText;

-(void) setRadioCell:(TalkRadioData*)radioData;
-(void) setBroadCastingState:(BOOL)bState;

@end

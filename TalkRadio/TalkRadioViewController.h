//
//  TalkRadioViewController.h
//  TalkRadio
//
//  Created by lion on 3/8/13.
//  Copyright (c) 2013 lion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TalkRadioView.h"
#import "Radio.h"

@interface TalkRadioViewController : NSViewController<RadioDelegate> {
    IBOutlet TalkRadioView* talkRadioView;
    IBOutlet NSButton* playBtn;
    IBOutlet NSSlider* volSlider;
    IBOutlet NSProgressIndicator* stateIndicator;
    IBOutlet NSTextField* stateLabel;
    NSMutableArray* radioArray;
    NSAlert* errorAlert;
    
    Radio* _talkRadio;
    RadioState radioState;
}

@property(strong) NSMutableArray* radioArray;

-(void) initRadioData:(NSMutableArray*)array;

-(IBAction) onPlay:(id)sender;
-(IBAction) onVolumeChange:(id)sender;
-(IBAction) onRefresh:(id)sender;

-(void) setActiveTalkRadio:(NSString*)radioURL;
-(BOOL) createConnectionWithPath:(NSString *)thePath;
-(NSInteger) openAlert:(NSString*)alertTitle Message:(NSString*)alertMsg;

@end



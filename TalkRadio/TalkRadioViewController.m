//
//  TalkRadioViewController.m
//  TalkRadio
//
//  Created by lion on 3/8/13.
//  Copyright (c) 2013 lion. All rights reserved.
//

#import "TalkRadioViewController.h"
#import "TalkRadioData.h"
#import "TalkRadioCellView.h"
#import "MMSRadio.h"
#import "HTTPRadio.h"

@interface TalkRadioViewController ()

@end

@implementation TalkRadioViewController

static NSInteger m_nRadioIndex = 0;

@synthesize radioArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        radioArray = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void)loadView
{
    [super loadView];
    [talkRadioView initView];
    
    for (int n = 0 ; n < [self.radioArray count]; n ++) {
        TalkRadioData* radioData = (TalkRadioData*)[self.radioArray objectAtIndex:n];
        if (radioData.isNow)
        {
            [talkRadioView setTalkRadioData:radioData];
            [self setActiveTalkRadio:radioData.url];
            m_nRadioIndex = 0;
            break;
        }
    }
    
    [playBtn setState:0];
    [stateIndicator setHidden:YES];
}

-(void)dealloc
{
    [super dealloc];
    [radioArray release];
}

-(IBAction)onPlay:(id)sender
{
    if (playBtn.state == 1)
    {
        NSLog(@"play talk radio");
        if(_talkRadio)
        {
            [_talkRadio setDelegate:self];
            [_talkRadio play];
            [_talkRadio setVolume:volSlider.floatValue];
        }
        
        stateLabel.stringValue = @"Connecting...";
    }
    else
    {
        NSLog(@"stop talk radio");
        if(_talkRadio)
        {
            [_talkRadio pause];
        }
        
        stateLabel.stringValue = @"Click to play";
        [stateIndicator stopAnimation:nil];
        [stateIndicator setHidden:YES];
    }
}

-(IBAction)onVolumeChange:(id)sender
{
    if (_talkRadio)
        [_talkRadio setVolume:volSlider.floatValue];
}

-(IBAction) onRefresh:(id)sender
{
    for (int n = 0 ; n < [self.radioArray count]; n ++) {
        TalkRadioData* radioData = (TalkRadioData*)[self.radioArray objectAtIndex:n];
        if (radioData.radioType == RADIO_SHOW)
            [radioData setIsNow:[radioData createConnectionWithPath:radioData.url]];
    }
    
    [talkRadioView reloadData];
}

-(void)setActiveTalkRadio:(NSString*)radioURL
{
    if(_talkRadio) {
        [_talkRadio shutdown];
        [_talkRadio release];
        _talkRadio = nil;
    }
    
    if([radioURL hasPrefix:@"mms"]) {
        _talkRadio = [[MMSRadio alloc] initWithURL:[NSURL URLWithString:radioURL]];
    } else {
        _talkRadio = [[HTTPRadio alloc] initWithURL:[NSURL URLWithString:radioURL]];
    }
    
    radioState = kRadioStateStopped;
}

-(void) initRadioData:(NSMutableArray*)array
{
    self.radioArray = array;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    if ([tableView.identifier isEqualToString:@"ShowTableView"])
    {
        // Since this is a single-column table view, this would not be necessary.
        // But it's a good practice to do it in order by remember it when a table is multicolumn.
        if( [tableColumn.identifier isEqualToString:@"ShowRadio"] )
        {
            TalkRadioCellView *mainCellView = [tableView makeViewWithIdentifier:@"ShowMainCellView" owner:self];
            TalkRadioData* radioData = (TalkRadioData*)[self.radioArray objectAtIndex:row];
            [mainCellView setRadioCell:radioData];
            if (radioData.radioType == RADIO_STATION)
            {
                NSLog(@"index = %d, station name : %@, Type : Station", (int)row, radioData.stationName);
                [mainCellView.broadcastText setHidden:YES];
                [mainCellView.cellBgView setImage:[NSImage imageNamed:@"showCellBackground_normal.png"]];
            }
            else
            {
                NSLog(@"index = %d, show name : %@, Type : show", (int)row, radioData.showName);
                [mainCellView.broadcastText setHidden:!radioData.isNow];
                if (radioData.isNow)
                    [mainCellView.cellBgView setImage:[NSImage imageNamed:@"showCellBackground_selected.png"]];
                else
                    [mainCellView.cellBgView setImage:[NSImage imageNamed:@"showCellBackground_normal.png"]];
            }
                        
            return  mainCellView;
        }
    }

    return cellView;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    int nCount = (int)[self.radioArray count];
    NSLog(@"show and station count : %d", nCount);
    return nCount;
}

-(NSInteger) openAlert:(NSString*)alertTitle Message:(NSString*)alertMsg
{
    NSAlert *testAlert = [NSAlert alertWithMessageText:alertTitle
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"%@", alertMsg];
    [testAlert setDelegate:(id<NSAlertDelegate>)self];
    NSInteger result = [testAlert runModal];
    return result;
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    // We don't want to change the selection if the user clicked in the fill color area
    NSInteger row = [tableView clickedRow];

    TalkRadioData* radioData = [radioArray objectAtIndex:row];
    
    if (radioData.radioType == RADIO_SHOW)
        NSLog(@"index = %d, show name : %@, Type : Show", (int)row, radioData.showName);
    else
        NSLog(@"index = %d, station name : %@, Type : Station", (int)row, radioData.stationName);
    
    if (radioData.isNow == NO)
    {
        NSString* alertMsg = [NSString stringWithFormat:@"%@ show is available Weekdays, %@ to %@ GMT + 08:00. Please check back at that time", radioData.showName, radioData.strStartHour, radioData.strEndHour];
        NSString* alertTitle = @"Show currently not broadcasting";
        
        [self openAlert:alertTitle Message:alertMsg];
        
        return [tableView selectedColumnIndexes];
    }

    m_nRadioIndex = row;
    [talkRadioView setTalkRadioData:radioData];
    [self setActiveTalkRadio:radioData.url];
    [playBtn setState:0];
    stateLabel.stringValue = @"Click to play";
    [stateIndicator stopAnimation:nil];
    [stateIndicator setHidden:YES];

    return proposedSelectionIndexes;
}

#pragma mark -
#pragma mark MMSRadioDelegate Methods

- (void)radioStateChanged:(Radio *)radio
{
    RadioState state = [_talkRadio radioState];
    if(state == kRadioStateConnecting)
    {
        stateLabel.stringValue = @"Connecting...";
        [stateIndicator stopAnimation:nil];
        [stateIndicator startAnimation:nil];
        [stateIndicator setHidden:NO];
    } else if(state == kRadioStateBuffering)
    {
        stateLabel.stringValue = @"Buffering...";
        [stateIndicator stopAnimation:nil];
        [stateIndicator startAnimation:nil];
        [stateIndicator setHidden:NO];
    } else if(state == kRadioStatePlaying)
    {
        stateLabel.stringValue = @"Click to Stop";
        [stateIndicator stopAnimation:nil];
        [stateIndicator setHidden:YES];
    } else if(state == kRadioStateStopped)
    {
        stateLabel.stringValue = @"Click to play";
        [stateIndicator stopAnimation:nil];
        [stateIndicator setHidden:YES];
    } else if(state == kRadioStateError) {

        NSString* strError = @"";
        RadioError error = [_talkRadio radioError];
        if(error == kRadioErrorAudioQueueBufferCreate) {
            strError = @"Audio buffers could not be created.";
        } else if(error == kRadioErrorAudioQueueCreate) {
            strError = @"Audio queue could not be created.";
        } else if(error == kRadioErrorAudioQueueEnqueue) {
            strError = @"Audio queue enqueue failed.";
        } else if(error == kRadioErrorAudioQueueStart) {
            strError = @"Audio queue could not be started.";
        } else if(error == kRadioErrorFileStreamGetProperty) {
            strError = @"File stream get property failed.";
        } else if(error == kRadioErrorFileStreamOpen) {
            strError = @"File stream could not be opened.";
        } else if(error == kRadioErrorPlaylistParsing) {
            strError = @"Playlist could not be parsed.";
        } else if(error == kRadioErrorDecoding) {
            strError = @"Audio decoding error.";
        } else if(error == kRadioErrorNetworkError) {
            strError = @"Network connection error.";
        }
        NSString* strTitle = @"Error";
        [self openAlert:strTitle Message:strError];
    }
    
    radioState = state;
}

- (void)radioMetadataReady:(Radio *)radio
{
    
}

- (void)radioTitleChanged:(Radio *)radio
{
    
}

@end

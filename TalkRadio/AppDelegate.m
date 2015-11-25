//
//  AppDelegate.m
//  TalkRadio
//
//  Created by lion on 3/8/13.
//  Copyright (c) 2013 lion. All rights reserved.
//

#import "AppDelegate.h"
#import "TalkRadioData.h"

@interface  AppDelegate()

@end

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    radioViewController = [[TalkRadioViewController alloc] initWithNibName:@"TalkRadioViewController" bundle:nil];
    
    arrays = [[NSMutableArray alloc] init];
    
    [self initShowInfo];
    [self initStationInfo];
    
    [radioViewController initRadioData:arrays];
    [self.window.contentView addSubview:radioViewController.view];
    radioViewController.view.frame = ((NSView*)self.window.contentView).bounds;
}

-(void)initShowInfo
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"shows" ofType:@"plist"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSLog(@"The file exists");
    } else {
        NSLog(@"The file does not exist");
    }
    
    NSDictionary *dic = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSArray *array = [dic objectForKey:@"shows"];
    NSDictionary* element;
    
    for (element in array)
    {
        TalkRadioData* radioData = [[TalkRadioData alloc] initWidthDictionary:element];
        [arrays addObject:radioData];
    }
    
//    [dic release];
//    [array release];
//    [element release];
}

-(void)initStationInfo
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"stations" ofType:@"plist"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSLog(@"The file exists");
    } else {
        NSLog(@"The file does not exist");
    }
    
    NSDictionary *dic = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSArray *array = [dic objectForKey:@"stations"];
    NSDictionary* element;
    for (element in array)
    {
        TalkRadioData* radioData = [[TalkRadioData alloc] initWidthDictionary:element];
        [arrays addObject:radioData];
    }
    
//    [dic release];
//    [array release];
//    [element release];
}

-(void)dealloc
{
    [arrays release];
}

@end
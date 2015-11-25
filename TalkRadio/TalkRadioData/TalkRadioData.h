//
//  TalkRadioData.h
//  TalkRadio
//
//  Created by lion on 3/8/13.
//  Copyright (c) 2013 lion. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    RADIO_SHOW = 0,
    RADIO_STATION
} RADIO_TYPE;

#define KEY_START_HOUR      @"startHour"
#define KEY_END_HOUR        @"endHour"
#define KEY_URL             @"url"
#define KEY_DAYS            @"days"
#define KEY_SHOW_NAME       @"showName"
#define KEY_STATION_NAME    @"stationName"
#define KEY_TYPE            @"type"
#define KEY_IMAGE_NAME      @"imageName"
#define KEY_STATION_DESC    @"stationDesc"

@interface TalkRadioData : NSObject
{
    NSImage* radioImage;
    NSString* showName;
    NSString* stationName;
    NSString* strStartHour;
    NSString* strEndHour;
    int startHour;
    int endHour;
    int days;
    NSString* url;
    NSString* stationDesc;
    RADIO_TYPE radioType;
    BOOL isNow;
    
    float startTime;
    float endTime;
}

@property(nonatomic, retain)NSImage* radioImage;
@property(nonatomic, retain)NSString* showName;
@property(nonatomic, retain)NSString* stationName;
@property(nonatomic, retain)NSString* stationDesc;
@property(nonatomic, retain)NSString* strStartHour;
@property(nonatomic, retain)NSString* strEndHour;
@property(nonatomic)int startHour;
@property(nonatomic)int endHour;
@property(nonatomic)int days;
@property(nonatomic, retain)NSString* url;
@property(nonatomic, assign)RADIO_TYPE radioType;
@property(nonatomic)BOOL isNow;

-(id)initWidthDictionary:(NSDictionary*)dic;
- (BOOL) createConnectionWithPath:(NSString *)thePath;

@end

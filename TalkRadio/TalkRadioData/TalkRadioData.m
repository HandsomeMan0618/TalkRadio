//
//  TalkRadioData.m
//  TalkRadio
//
//  Created by lion on 3/8/13.
//  Copyright (c) 2013 lion. All rights reserved.
//

#import "TalkRadioData.h"

@implementation TalkRadioData

@synthesize radioImage, showName, startHour, endHour, stationName, url, days, radioType, isNow, strStartHour, strEndHour;

-(id)initWidthDictionary:(NSDictionary*)dic;
{
    if ((self = [super init]))
    {
        NSString* strType = [dic valueForKey:KEY_TYPE];
        if ([strType isEqualToString:@"show"])
            self.radioType = RADIO_SHOW;
        else
            self.radioType = RADIO_STATION;
        
        NSString* imageName = [dic valueForKey:KEY_IMAGE_NAME];
        self.radioImage = [NSImage imageNamed:imageName];
        
        if (self.radioType == RADIO_SHOW)
        {
            self.showName = [dic valueForKey:KEY_SHOW_NAME];
            self.startHour = [[dic valueForKey:KEY_START_HOUR] intValue];
            if (self.startHour > 12)
                self.strStartHour = [NSString stringWithFormat:@"%d PM", self.startHour - 12];
            else if(self.startHour == 12)
                self.strStartHour = [NSString stringWithFormat:@"%d PM", self.startHour];
            else
                self.strStartHour = [NSString stringWithFormat:@"%d AM", self.startHour];
            self.endHour = [[dic valueForKey:KEY_END_HOUR] intValue];
            if (self.endHour > 12)
                self.strEndHour = [NSString stringWithFormat:@"%d PM", self.endHour - 12];
            else if(self.endHour==12)
                self.strEndHour = [NSString stringWithFormat:@"%d PM", self.endHour];
            else
                self.strEndHour = [NSString stringWithFormat:@"%d AM", self.endHour];
            self.stationName = [dic valueForKey:KEY_STATION_NAME];
            self.url = [dic valueForKey:KEY_URL];
            self.days = [[dic valueForKey:KEY_DAYS] boolValue];
            self.stationDesc = @"";
            self.isNow = [self createConnectionWithPath:self.url];
            NSLog(@"Listing URL");
            NSLog(self.url);
        }
        else
        {
            self.showName = @"";
            self.startHour = 0;
            self.endHour = 0;
            self.stationName = [dic valueForKey:KEY_STATION_NAME];
            self.url = [dic valueForKey:KEY_URL];
            self.days = 0;
            self.stationDesc = [dic valueForKey:KEY_STATION_DESC];
            self.isNow = YES;
        }
    }
    
    return  self;
}

- (BOOL) createConnectionWithPath:(NSString *)thePath
{
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:thePath]
                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
    
    /* Finds out if the request response is found in the shared cache.
     If so, displays the elapsed time in gray to indicate a cache hit. */
    
       // float timeZone = [[todaydate descriptionWithFormat:@"ZZ"] floatValue] / 100;
    NSDateFormatter *date_formater=[[NSDateFormatter alloc]init];
    [date_formater setDateFormat:@"Z"];
    NSString * tz=[date_formater stringFromDate:[NSDate date]];
    float timeZone = ([[NSTimeZone localTimeZone] secondsFromGMT])/3600;
    
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSHourCalendarUnit fromDate:now];
    NSInteger time = [components hour];
    
    
    
    // Converting current time to EST
    NSInteger timeShift = [[NSTimeZone timeZoneWithAbbreviation: @"EST"]secondsFromGMTForDate: now] / 3600; //-5;
    
    float estTime = time - timeZone + timeShift;
    

    
    NSURLCache *sharedCache = [NSURLCache sharedURLCache];
    NSCachedURLResponse *response = [sharedCache cachedResponseForRequest:theRequest];
    
    
    NSLog(@"Eastern time is %f",estTime);
    
	if ( estTime >= self.startHour && estTime < self.endHour ) {
		return YES;
	}
	
    return NO;

    
    
   /* if (response)
    {
        NSLog(@"success");
        return YES;
    }
    else
    {
        NSLog(@"fail");
        return NO;
    }*/
}

@end

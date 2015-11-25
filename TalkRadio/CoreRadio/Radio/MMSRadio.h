//
//  MMSRadio.h
//  Radio
//
//  Copyright 2011 Yakamoz Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Radio.h"
#import "avcodec.h"
#import "avformat.h"

@class Reachability;

@interface MMSRadio : Radio {
@private
    dispatch_queue_t _decodeQueue;
    
    AVFormatContext *_formatCtx;
    AVCodecContext *_codecCtx;
    
    int _audioStreamID;
    int _bufferFailures;
    BOOL _connected;
    BOOL _decodeError;
    BOOL _connectionError;
	UInt16 *_decodeBuffer;
    
    Reachability *_reachability;
    NSTimer *_connectionTimer;
#if _IPHONE_
    UIBackgroundTaskIdentifier _bgTask;
#endif
}

@end

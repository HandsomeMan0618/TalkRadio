//
//  HTTPRadio.h
//  Radio
//
//  Copyright 2011 Yakamoz Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Radio.h"
#import "PlaylistParserProtocol.h"

typedef enum {
    kPlaylistNone = 0,
    kPlaylistM3U,
    kPlaylistPLS,
    kPlaylistXSPF
} PlaylistType;

typedef enum {
    kHTTPStatePlaylistParsing = 0,
    kHTTPStateAudioStreaming
} HTTPState;

@interface HTTPRadio : Radio {
@public
    NSString *_httpUserAgent;
    NSUInteger _httpTimeout;
    
@private
    NSURLConnection *_urlConnection;
    NSMutableData *_audioData;
    NSMutableData *_playlistData;
    NSMutableData *_metaData;
    NSDictionary *_streamHeaders;
    NSString *_contentType;
    
    int _metadataInterval;
    int _metadataLength;
    int _streamCount;
    int _bitrateInBytes;
    int _bufferFailures;
    BOOL _icyStartFound;
    BOOL _icyEndFound;
    BOOL _icyHeadersParsed;
    BOOL _connectionError;
    
    NSTimer *_connectionTimer;
#if _IPHONE_
    NSBackgroundTaskIdentifier _bgTask;
#endif
    
    BOOL _highQualityFormat;
    AudioStreamBasicDescription _hqASBD;
    
    PlaylistType _playlistType;
    NSObject<PlaylistParserProtocol> *_playlistParser;
    
    HTTPState _httpState;
}

@property (nonatomic, copy) NSString *httpUserAgent;
@property (nonatomic, assign) NSUInteger httpTimeout;

@end

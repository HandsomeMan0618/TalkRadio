//
//  MMSRadio.m
//  Radio
//
//  Copyright 2011 Yakamoz Labs. All rights reserved.
//

#import "MMSRadio.h"
#import "AudioPacket.h"
#import "Reachability.h"

@interface MMSRadio(Private)
- (void)handlePlayCallback:(AudioQueueRef)inAudioQueue buffer:(AudioQueueBufferRef) inBuffer;
- (void)onReachabilityChanged:(NSNotification *)notification;
- (void)connect;
- (void)startDecoding;
- (void)setupQueue;
- (void)dismissQueue;
- (void)primeQueueBuffers;
- (void)startQueue;
- (void)setState:(RadioState) state;
- (void)cleanup;
- (void)connectionTimerFired;
- (void)onBackground:(NSNotification *)notification;
- (void)onForeground:(NSNotification *)notification;
@end

int QuitDecoding = 0;

static void PlayCallback(void *inUserData, AudioQueueRef inAudioQueue, AudioQueueBufferRef inBuffer) {
    MMSRadio *radio = (MMSRadio *)inUserData;
    [radio handlePlayCallback:inAudioQueue buffer:inBuffer];
}

static void interruptionListenerCallback(void *inUserData, UInt32 interruptionState) {
#if _IPHONE_
    MMSRadio *radio = (MMSRadio *)inUserData;
	if(interruptionState == kAudioSessionBeginInterruption) {
        [radio pause];
	} else if(interruptionState == kAudioSessionEndInterruption && [radio isPaused]) {
        AudioSessionSetActive(true);
        [radio play];
	}
#endif
}

static int DecodeInterruptCallback(void) {
    return QuitDecoding;
}
const AVIOInterruptCB int_cb = { DecodeInterruptCallback, NULL };

@implementation MMSRadio

- (id)initWithURL:(NSURL *)url {
    if(![[url scheme] isEqualToString:@"mms"] &&
       ![[url scheme] isEqualToString:@"mmsh"]) {
        return nil;
    }
    
    NSURL *newURL = [[[NSURL alloc] initWithScheme:@"mmst" host:[url host] path:[url path]] autorelease];
    self = [super initWithURL:newURL];
    if(self) {
        _decodeQueue = dispatch_queue_create("decodeQueue", NULL);
        
        _formatCtx = NULL;
        _codecCtx = NULL;
        _audioStreamID = -1;
        _bufferFailures = 0;
        _connected = NO;
        _decodeError = NO;
        _connectionError = NO;
        _reachability = nil;
        _connectionTimer = nil;
		
		_decodeBuffer = malloc(AVCODEC_MAX_AUDIO_FRAME_SIZE);
		memset(_decodeBuffer, 0, AVCODEC_MAX_AUDIO_FRAME_SIZE);
		
        static BOOL ffmpegInitialized = NO;
        if(!ffmpegInitialized) {
            ffmpegInitialized = YES;
            avcodec_register_all();//kgh avcodec_init();
            av_register_all();
        }
        
        _playerState.audioFormat.mFormatID = kAudioFormatLinearPCM;
        _playerState.audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        
#if _IPHONE_
        _bgTask = UIBackgroundTaskInvalid;
#endif
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
#if _IPHONE_
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        AudioSessionInitialize(NULL, NULL, interruptionListenerCallback, self);
        
        UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
        AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
        AudioSessionSetActive(true);
#endif
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    dispatch_release(_decodeQueue);
    
    if(_connectionTimer) {
        [_connectionTimer invalidate];
        [_connectionTimer release];
        _connectionTimer = nil;
    }
    
    if(_codecCtx) {
        avcodec_close(_codecCtx);
    }
    if(_formatCtx) {
        av_close_input_file(_formatCtx);
    }
    
    [_reachability release];
    
    free(_decodeBuffer);
    
    [super dealloc];
}

- (void)shutdown {
    _shutdown = YES;
    if(!_playerState.paused) {
        [self pause];
    }
    
    [self retain];
    dispatch_async(_decodeQueue, ^{
        [self cleanup];
    });
}

- (void)play {
    if(_playerState.playing) {
        return;
    }
    
    QuitDecoding = 0;
    _decodeError = NO;
    _connectionError = NO;
    _bufferFailures = 0;
    
    if(!_connected) {
        [self setState:kRadioStateConnecting];
        [self connect];
    } else {
        if(_shutdown) {
            DLog(@"we're shutting down");
            return;
        }
        
        [self setState:kRadioStateBuffering];
        _playerState.paused = NO;
        _playerState.playing = YES;
        
        _playerState.audioFormat.mSampleRate = _codecCtx->sample_rate;
        _playerState.audioFormat.mChannelsPerFrame = _codecCtx->channels;
        _playerState.audioFormat.mBitsPerChannel = 16;
        _playerState.audioFormat.mFramesPerPacket = _codecCtx->frame_size;
        _playerState.audioFormat.mBytesPerFrame = _playerState.audioFormat.mChannelsPerFrame * _playerState.audioFormat.mBitsPerChannel/8; 
        _playerState.audioFormat.mBytesPerPacket = _playerState.audioFormat.mBytesPerFrame * _playerState.audioFormat.mFramesPerPacket;
        // calculate buffer size so that there is 0.5 seconds of data in one buffer
        int packetsForTime = (_playerState.audioFormat.mSampleRate / _playerState.audioFormat.mFramesPerPacket) * 0.5;
        _playerState.bufferSize = packetsForTime * _playerState.audioFormat.mBytesPerPacket;
        
        [self setupQueue];
        [self startDecoding];
    }
}

- (void)pause {
    if(_playerState.paused) {
        return;
    }
    
    _playerState.playing = NO;
    _playerState.paused = YES;
    
    QuitDecoding = 1;
    
    if(_playerState.started) {
        [self dismissQueue];
        _playerState.started = NO;
        _playerState.totalBytes = 0.0;
        
        dispatch_sync(_playerState.lockQueue, ^(void) {
            [_playerState.audioQueue removeAllPackets];
        });
    }
    
    if(_decodeError) {
        _radioError = kRadioErrorDecoding;
        [self setState:kRadioStateError];
    } else if(_connectionError) {
        _radioError = kRadioErrorNetworkError;
        [self setState:kRadioStateError];
    } else {
        [self setState:kRadioStateStopped];
    }
}


#pragma mark -
#pragma mark Private Methods
- (void)handlePlayCallback:(AudioQueueRef) inAudioQueue buffer:(AudioQueueBufferRef) inBuffer {
    if(_playerState.paused) {
        return;
    }
    
    __block int maxBytes = inBuffer->mAudioDataBytesCapacity;
    __block int dataWritten = 0;
    inBuffer->mAudioDataByteSize = 0;
    
    dispatch_sync(_playerState.lockQueue, ^(void) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        AudioPacket *audioPacket = [_playerState.audioQueue peak];
        while(audioPacket) {
            if((dataWritten + [audioPacket remainingLength]) > maxBytes) {
                int dataNeeded = (maxBytes - dataWritten);
                [audioPacket copyToBuffer:(inBuffer->mAudioData+dataWritten) size:dataNeeded];
                dataWritten += dataNeeded;
                break;
            } else {
                int dataNeeded = [audioPacket remainingLength];
                [audioPacket copyToBuffer:(inBuffer->mAudioData+dataWritten) size:dataNeeded];
                
                audioPacket = [_playerState.audioQueue pop];
                [audioPacket release];
                dataWritten += dataNeeded;
                audioPacket = [_playerState.audioQueue peak];
            }
        }
        
        inBuffer->mAudioDataByteSize = dataWritten;
        
        if(inBuffer->mAudioDataByteSize > 0) {
            OSStatus result = AudioQueueEnqueueBuffer(inAudioQueue, inBuffer, 0, NULL);
            if(result != noErr) {
                DLog(@"could not enqueue buffer");
                
                _radioError = kRadioErrorAudioQueueEnqueue;
                [self setState:kRadioStateError];
            }
            
            if(_bufferFailures >= 1) {
                _bufferFailures--;
            }
        } else {
            _bufferFailures++;
            if(_bufferFailures >= NUM_AQ_BUFS && !_playerState.buffering) {
                DLog(@"all buffers empty, buffering");
                _playerState.totalBytes = 0.0;
                _bufferFailures = 0;
                _playerState.buffering = YES;
                [self setState:kRadioStateBuffering];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    _connectionTimer = [[NSTimer scheduledTimerWithTimeInterval:60.0 
                                                                         target:self 
                                                                       selector:@selector(connectionTimerFired) 
                                                                       userInfo:nil 
                                                                        repeats:NO] retain];
                });                
            }
        }
        
        [pool drain];
    });
}

- (void)onReachabilityChanged:(NSNotification *)notification {
    if(_reachability) {
        if(_playerState.started && ![_reachability isReachable]) {
#if _IPHONE_
            if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
                DLog(@"connection dropped while radio is in background");
                if(_bgTask == UIBackgroundTaskInvalid) {
                    _bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(_bgTask != UIBackgroundTaskInvalid) {
                                [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
                                _bgTask = UIBackgroundTaskInvalid;
                            }
                        });
                    }];
                }
            }
#endif
        }
    }
}

- (void)connect {
    if(_connected) {
        return;
    }
    
    dispatch_async(_decodeQueue, ^(void) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        const char *url = [[_url description] cStringUsingEncoding:NSUTF8StringEncoding];
        
        if(avformat_open_input(&_formatCtx, url, NULL, NULL) != 0) {
            // if current scheme is mmst then try again with scheme mmsh (will use port 80)
            if([[_url scheme] isEqualToString:@"mmst"]) {
                NSURL *newURL = [[NSURL alloc] initWithScheme:@"mmsh" host:[_url host] path:[_url path]];
                [_url release];
                _url = [newURL retain];
                [newURL release];
                
                url = [[_url description] cStringUsingEncoding:NSUTF8StringEncoding];
                if(avformat_open_input(&_formatCtx, url, NULL, NULL) != 0) {
                    DLog(@"FFMPEG cannot open stream");
                    _radioError = kRadioErrorFileStreamOpen;
                    [self setState:kRadioStateError];
                    return;
                }
            } else {
                DLog(@"FFMPEG cannot open stream");
                _radioError = kRadioErrorFileStreamOpen;
                [self setState:kRadioStateError];
                return;
            }
        }
        
        DLog(@"FFMPEG connected to stream: %@", [_url scheme]);
        if(av_find_stream_info(_formatCtx) < 0) {
            DLog(@"Cannot find stream info");
            _radioError = kRadioErrorFileStreamOpen;
            [self setState:kRadioStateError];
            return;
        }
        
        for(int i = 0; i < _formatCtx->nb_streams; i++ ) {
            if(_formatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO) {
                _audioStreamID = i;
                break;
            }
        }
        
        if(_audioStreamID == -1) {
            DLog(@"Audio stream not found");
            _radioError = kRadioErrorFileStreamOpen;
            [self setState:kRadioStateError];
            return;
        }
        
        _codecCtx = _formatCtx->streams[_audioStreamID]->codec;
        AVCodec *codec = avcodec_find_decoder(_codecCtx->codec_id);
        if(!codec) {
            DLog(@"Cannot find codec");
            _radioError = kRadioErrorFileStreamOpen;
            [self setState:kRadioStateError];
            return;
        }
        
        _formatCtx->interrupt_callback = int_cb;//by kgh
        
        int s = avcodec_open(_codecCtx, codec);
        if(s < 0) {
            NSLog(@"Cannot open codec");
            _radioError = kRadioErrorFileStreamOpen;
            [self setState:kRadioStateError];
            return;
        }
        
        _connected = YES;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            _reachability = [[Reachability reachabilityForInternetConnection] retain];
            [_reachability startNotifier];
        });
        
        DLog(@"Codec opened: %@ - %@", [NSString stringWithUTF8String:codec->name], [NSString stringWithUTF8String:codec->long_name]);
        DLog(@"sample rate: %d", _codecCtx->sample_rate);
        DLog(@"channels: %d", _codecCtx->channels);
        DLog(@"frames per packet: %d", _codecCtx->frame_size);
        
//        avio_set_interrupt_cb(DecodeInterruptCallback);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self play];
        });
        
        [pool drain];
    });
}

- (void)startDecoding {
    dispatch_async(_decodeQueue, ^(void) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        AVPacket packet;
        int last_packet = 0;
        int decodeErrorCount = 0;
        
        if(_shutdown) {
            DLog(@"we're shutting down");
            return;
        }
        
        do {
            do {
                if(av_read_frame(_formatCtx, &packet) < 0) {
                    last_packet = 1;
                }
                
                if(packet.stream_index != _audioStreamID) {
                    av_free_packet(&packet);
                }
            } while (packet.stream_index != _audioStreamID && !last_packet);
            
            // do not try to decode the last packet if it's not from this stream
            if(last_packet && (packet.stream_index != _audioStreamID)) {
                break;
            }
            
            UInt8 *packetPtr = packet.data;
            int bytes_remaining = packet.size;
            int dataSize;
            int decodedSize;
			
            while(bytes_remaining > 0 && !_playerState.paused) {
                dataSize = AVCODEC_MAX_AUDIO_FRAME_SIZE;
                decodedSize = avcodec_decode_audio3(_codecCtx, (int16_t *)_decodeBuffer, &dataSize, &packet);
                
                if(decodedSize < 0) {
                    packet.size = 0;
                    decodeErrorCount++;
                    if(decodeErrorCount > 4) {
                        _decodeError = YES;
                        [self pause];
                    }
                    
                    break;
                }
                
                DLog(@"decoded");
                bytes_remaining -= decodedSize;
                packetPtr += decodedSize;
                
                if(dataSize <= 0) {
                    continue;
                }
                
                _playerState.totalBytes += dataSize;
                
                dispatch_sync(_playerState.lockQueue, ^(void) {
                    NSData *data = [[NSData alloc] initWithBytes:_decodeBuffer length:dataSize];
                    AudioPacket *audioPacket = [[AudioPacket alloc] initWithData:data];
                    [_playerState.audioQueue addPacket:audioPacket];
                    [data release];
                    [audioPacket release];
                });
                
                if(!_playerState.started && 
                   !_playerState.paused &&
                   !_shutdown &&
                   _playerState.totalBytes > (_playerState.bufferInSeconds * _playerState.bufferSize)) {
                    _playerState.buffering = NO;
                    
                    [self primeQueueBuffers];
                    [self startQueue];
                }
                
                // enqueue audio buffers again after buffering
                if(_playerState.started &&
                   !_playerState.paused &&
                   _playerState.buffering &&
                   !_shutdown &&
                   _playerState.totalBytes > (_playerState.bufferInSeconds * _playerState.bufferSize)) {
                    DLog(@"starting playback again");
                    if(_connectionTimer) {
                        DLog(@"Canceling connection timer");
                        [_connectionTimer invalidate];
                        [_connectionTimer release];
                        _connectionTimer = nil;
                    }
                    
                    [self primeQueueBuffers];
                    _playerState.buffering = NO;
                    [self setState:kRadioStatePlaying];
                }
            }
            
            if(packet.data) {
                av_free_packet(&packet);
            }
        } while (!last_packet && !_playerState.paused);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            DLog(@"connection dropped");
            _connected = NO;
            
            if(_codecCtx) {
                avcodec_close(_codecCtx);
                _codecCtx = NULL;
            }
            
            if(_formatCtx) {
                av_close_input_file(_formatCtx);
                _formatCtx = NULL;
            }
        });
        
        [pool drain];
    });
}

- (void)setupQueue {
    if(_playerState.queue == NULL) {
#if _IPHONE_
        AudioSessionSetActive(true);
#endif
        
        // create audio queue
        OSStatus err = AudioQueueNewOutput(&_playerState.audioFormat, PlayCallback, self, NULL, kCFRunLoopCommonModes, 0, &_playerState.queue);
        if(err != noErr) {
            DLog(@"audio queue could not be created");
            _radioError = kRadioErrorAudioQueueCreate;
            [self setState:kRadioStateError];
            return;
        }
        
        // create audio buffers
        for(int t = 0; t < NUM_AQ_BUFS; ++t) {
            err = AudioQueueAllocateBuffer(_playerState.queue, _playerState.bufferSize, &_playerState.queueBuffers[t]);
            if(err) {
                DLog(@"Error: AudioQueueAllocateBuffer %4.4s %d", &err, err);
                _radioError = kRadioErrorAudioQueueBufferCreate;
                [self setState:kRadioStateError];
                return;
            }
        }
    }
}

- (void)dismissQueue {
    if(_playerState.queue) {
        if(_playerState.playing) {
            AudioQueueStop(_playerState.queue, YES);
            _playerState.playing = NO;
        }
        
        if(_reachability) {
            [_reachability stopNotifier];
            [_reachability release];
            _reachability = nil;
        }
        
        AudioQueueDispose(_playerState.queue, YES);
        _playerState.queue = NULL;
        
#if _IPHONE_
        AudioSessionSetActive(false);
#endif
    }
}

- (void)primeQueueBuffers {
    for(int t = 0; t < NUM_AQ_BUFS; ++t) {
        PlayCallback(self, _playerState.queue, _playerState.queueBuffers[t]);
	}
}

- (void)startQueue {
    if(!_playerState.started) {
        AudioQueueSetParameter(_playerState.queue, kAudioQueueParam_Volume, _playerState.gain);
        OSStatus result = AudioQueueStart(_playerState.queue, NULL);
        if(result == noErr) {
            _playerState.started = YES;
            _playerState.playing = YES;
            
            [self setState:kRadioStatePlaying];
        } else {
            _radioError = kRadioErrorAudioQueueStart;
            [self setState:kRadioStateError];
        }
    }
}
         
 - (void)setState:(RadioState)state {
     if(state == _radioState) {
         return;
     }
     
     _radioState = state;
     if(_radioState == kRadioStateError) {
         _playerState.playing = NO;
         _playerState.paused = NO;
         _playerState.buffering = NO;
         _playerState.started = NO;
         _playerState.totalBytes = 0.0;
         
         if(_playerState.queue) {
             if(_playerState.playing) {
                 AudioQueueStop(_playerState.queue, YES);
                 _playerState.playing = NO;
             }
             
             AudioQueueDispose(_playerState.queue, YES);
             _playerState.queue = NULL;
#if _IPHONE_
             AudioSessionSetActive(false);
#endif
         }
     }
     
     dispatch_async(dispatch_get_main_queue(), ^(void) {
         if(_delegate && [_delegate respondsToSelector:@selector(radioStateChanged:)]) {
             [_delegate radioStateChanged:self];
         }
     });
     
     if(_radioState == kRadioStatePlaying || _radioState == kRadioStateError) {
#if _IPHONE_
         if(_bgTask) {
             DLog(@"Ending background task");
             [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
             _bgTask = UIBackgroundTaskInvalid;
         }
#endif
     }
 }

- (void)cleanup {
    [self release];
}

- (void)connectionTimerFired {
    [_connectionTimer release];
    _connectionTimer = nil;
    
    _connectionError = YES;
    [self pause];
}

- (void)onBackground:(NSNotification *)notification {
    if(_radioState == kRadioStateConnecting || _radioState == kRadioStateBuffering) {
        DLog(@"radio is buffering while entering background");
#if _IPHONE_
        if(_bgTask == UIBackgroundTaskInvalid) {
            _bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(_bgTask != UIBackgroundTaskInvalid) {
                        [[UIApplication sharedApplication] endBackgroundTask:_bgTask];
                        _bgTask = UIBackgroundTaskInvalid;
                    }
                });
            }];
        }
#endif
    }
}

- (void)onForeground:(NSNotification *)notification {
#if _IPHONE_
    if(_bgTask != UIBackgroundTaskInvalid) {
		[[UIApplication sharedApplication] endBackgroundTask:_bgTask];
		_bgTask = UIBackgroundTaskInvalid;
	}
#endif
}

@end

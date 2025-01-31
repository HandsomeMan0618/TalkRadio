//
//  AudioQueue.m
//  Radio
//
//  Copyright 2011 Yakamoz Labs. All rights reserved.
//

#import "AudioQueue.h"
#import "AudioPacket.h"

@implementation AudioQueue

- (id)init {
    self = [super init];
    if(self) {
        _audioPackets = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [_audioPackets release];
    [super dealloc];
}

- (AudioPacket *)pop {
    AudioPacket *packet = nil;
    packet = [_audioPackets lastObject];
    if(packet) {
        [packet retain];
        [_audioPackets removeLastObject];
    }
    
    return packet;
}

- (AudioPacket *)peak {
    return [_audioPackets lastObject];
}

- (void)addPacket:(AudioPacket *)packet {
    [_audioPackets insertObject:packet atIndex:0];
}

- (void)removeAllPackets {
    [_audioPackets removeAllObjects];
}

- (NSUInteger)count {
    return [_audioPackets count];
}

@end

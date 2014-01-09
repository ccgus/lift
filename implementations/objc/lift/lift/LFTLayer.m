//
//  LFTLayer.m
//  lift
//
//  Created by August Mueller on 1/7/14.
//  Copyright (c) 2014 Flying Meat Inc. All rights reserved.
//

#import "LFTLayer.h"
#import "LFTDatabaseAdditions.h"
@implementation LFTLayer

- (id)init {
	self = [super init];
	
    if (self != nil) {
		_opacity    = 1.0;
        _locked     = NO;
        _blendMode  = @"normal";
        _visible    = YES;
	}
    
	return self;
}



- (void)readFromDatabase:(FMDatabase*)db {
    
    
    /* Optional stuff */
    
    NSString *visible   = [db stringForLayerAttribute:@"visible" withId:[self layerId]];
    if (visible) {
        [self setVisible:[visible boolValue]];
    }
    
    NSString *locked    = [db stringForLayerAttribute:@"locked" withId:[self layerId]];
    if (locked) {
        [self setLocked:[locked boolValue]];
    }
    
    NSString *blendMode = [db stringForLayerAttribute:@"blendMode" withId:[self layerId]];
    if (blendMode) {
        [self setBlendMode:blendMode];
    }
    
    NSString *opacity   = [db stringForLayerAttribute:@"opacity" withId:[self layerId]];
    if (opacity) {
        [self setOpacity:[opacity doubleValue]];
    }
    
}



- (CGImageRef)CGImage {
    return nil;
}


@end

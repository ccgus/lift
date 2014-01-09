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
        
        _layerId    = [[[NSUUID UUID] UUIDString] lowercaseString];
        
	}
    
	return self;
}


NSString *LFTLayerVisibleDatabaseTag    = @"visible";
NSString *LFTLayerLockedDatabaseTag     = @"locked";
NSString *LFTLayerBlendModeDatabaseTag  = @"blendMode";
NSString *LFTLayerOpacityDatabaseTag    = @"opacity";

- (void)readFromDatabase:(FMDatabase*)db {
    
    
    /* Optional stuff */
    
    NSString *visible   = [db stringForLayerAttribute:LFTLayerVisibleDatabaseTag withId:[self layerId]];
    if (visible) {
        [self setVisible:[visible boolValue]];
    }
    
    NSString *locked    = [db stringForLayerAttribute:LFTLayerLockedDatabaseTag withId:[self layerId]];
    if (locked) {
        [self setLocked:[locked boolValue]];
    }
    
    NSString *blendMode = [db stringForLayerAttribute:LFTLayerBlendModeDatabaseTag withId:[self layerId]];
    if (blendMode) {
        [self setBlendMode:blendMode];
    }
    
    NSString *opacity   = [db stringForLayerAttribute:LFTLayerOpacityDatabaseTag withId:[self layerId]];
    if (opacity) {
        [self setOpacity:[opacity doubleValue]];
    }
    
}

- (void)writeToDatabase:(FMDatabase*)db {
    
    
    [db setLayerAttribute:LFTLayerVisibleDatabaseTag   value:@([self visible])  withId:[self layerId]];
    [db setLayerAttribute:LFTLayerLockedDatabaseTag    value:@([self locked])   withId:[self layerId]];
    [db setLayerAttribute:LFTLayerBlendModeDatabaseTag value:[self blendMode]   withId:[self layerId]];
    [db setLayerAttribute:LFTLayerOpacityDatabaseTag   value:@([self opacity])  withId:[self layerId]];
    
    
    
}

- (CGImageRef)CGImage {
    return nil;
}


@end

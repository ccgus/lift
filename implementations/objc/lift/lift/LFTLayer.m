//
//  LFTLayer.m
//  lift
//
//  Created by August Mueller on 1/7/14.
//  Copyright (c) 2014 Flying Meat Inc. All rights reserved.
//

#import "LFTLayer.h"
#import "LFTDatabaseAdditions.h"

@interface LFTLayer ()

@property (strong) NSMutableDictionary *atts;

@end

@implementation LFTLayer

- (id)init {
	self = [super init];
	
    if (self != nil) {
		_opacity    = 1.0;
        _locked     = NO;
        _blendMode  = @"normal";
        _visible    = YES;
        
        _layerId    = [[[NSUUID UUID] UUIDString] lowercaseString];
        
        _atts       = [NSMutableDictionary dictionary];
        
	}
    
	return self;
}


NSString *LFTLayerVisibleDatabaseTag    = @"visible";
NSString *LFTLayerLockedDatabaseTag     = @"locked";
NSString *LFTLayerBlendModeDatabaseTag  = @"blendMode";
NSString *LFTLayerOpacityDatabaseTag    = @"opacity";

- (void)setValue:(id)value forAttribute:(NSString*)attributeName {
    
    /* Optional stuff */
    
    if ([attributeName isEqualToString:LFTLayerVisibleDatabaseTag]) {
        if ([value isKindOfClass:[NSNumber class]]) {
            [self setVisible:[value boolValue]];
        }
        else {
            NSLog(@"Invalid class for LFTLayerVisibleDatabaseTag tag %@", NSStringFromClass([value class]));
        }
        return;
    }
    
    if ([attributeName isEqualToString:LFTLayerLockedDatabaseTag]) {
        if ([value isKindOfClass:[NSNumber class]]) {
            [self setLocked:[value boolValue]];
        }
        else {
            NSLog(@"Invalid class for LFTLayerLockedDatabaseTag tag %@", NSStringFromClass([value class]));
        }
        return;
    }
    
    if ([attributeName isEqualToString:LFTLayerBlendModeDatabaseTag]) {
        if ([value isKindOfClass:[NSString class]]) {
            [self setBlendMode:value];
        }
        else {
            NSLog(@"Invalid class for LFTLayerBlendModeDatabaseTag tag %@", NSStringFromClass([value class]));
        }
        return;
    }
    
    if ([attributeName isEqualToString:LFTLayerOpacityDatabaseTag]) {
        if ([value isKindOfClass:[NSNumber class]]) {
            [self setOpacity:[value doubleValue]];
        }
        else {
            NSLog(@"Invalid class for LFTLayerOpacityDatabaseTag tag %@", NSStringFromClass([value class]));
        }
        return;
    }
    
    [self addAttribute:value withKey:attributeName];
}


- (void)readFromDatabase:(FMDatabase*)db {
    
    
    FMResultSet *rs = [db executeQuery:@"select name, value from layer_attributes where id = ?", [self layerId]];
    
    while ([rs next]) {
        [self setValue:[rs objectForColumnIndex:1] forAttribute:[rs stringForColumnIndex:0]];
    }
}

- (void)writeToDatabase:(FMDatabase*)db {
    
    [db executeUpdate:@"delete from layers where id = ?", [self layerId]];
    [db executeUpdate:@"delete from layer_attributes where id = ?", [self layerId]];
    
    
    [db setLayerAttribute:LFTLayerVisibleDatabaseTag   value:@([self visible])  withId:[self layerId]];
    [db setLayerAttribute:LFTLayerLockedDatabaseTag    value:@([self locked])   withId:[self layerId]];
    [db setLayerAttribute:LFTLayerBlendModeDatabaseTag value:[self blendMode]   withId:[self layerId]];
    [db setLayerAttribute:LFTLayerOpacityDatabaseTag   value:@([self opacity])  withId:[self layerId]];
    
    for (NSString *key in [_atts allKeys]) {
        id value = [_atts objectForKey:key];
        [db setLayerAttribute:key value:value withId:[self layerId]];
    }
}

- (CGImageRef)CGImage {
    return nil;
}

- (void)addAttribute:(id)attribute withKey:(NSString*)key {
    [_atts setValue:attribute forKey:key];
}

- (NSDictionary*)attributes {
    return _atts;
}

- (void)writeToDebugString:(NSMutableString*)s depth:(NSInteger)d {
    
    for (NSInteger i = 0; i < d; i++) {
        [s appendString:@"-"];
    }
    
    [s appendFormat:@"%@ %@ %@ %@\n", self, [self layerName], [self layerUTI], [self layerId]];
    
}

@end

//
//  LFTLayer.m
//  lift
//
//  Created by August Mueller on 1/7/14.
//  Copyright (c) 2014 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LFTLayer.h"
#import "LFTDatabaseAdditions.h"
#import "LFTImage.h"

@interface LFTLayer ()

@property (strong) NSMutableDictionary *atts;
@property (assign) CGImageRef image;
@property (assign) CGImageRef composite;

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

- (void)dealloc {
    if (_image) {
        CGImageRelease(_image);
    }
}



NSString *LFTLayerVisibleDatabaseTag        = @"visible";
NSString *LFTLayerLockedDatabaseTag         = @"locked";
NSString *LFTLayerBlendModeDatabaseTag      = @"blendMode";
NSString *LFTLayerOpacityDatabaseTag        = @"opacity";
NSString *LFTLayerFrameDatabaseTag          = @"frame";
NSString *LFTLayerCompositeDatabaseTag      = @"composite";
NSString *LFTLayerCompositeUTIDatabaseTag   = @"composite-uti";


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
    if ([attributeName isEqualToString:LFTLayerFrameDatabaseTag]) {
        if ([value isKindOfClass:[NSString class]]) {
            [self setFrame:NSRectFromString(value)];
        }
        else {
            NSLog(@"Invalid class for LFTLayerFrameDatabaseTag tag %@", NSStringFromClass([value class]));
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
    
    rs = [db executeQuery:@"select data from layers where id = ?", [self layerId]];
    if ([rs next]) {
        
        NSData *data = [rs dataForColumnIndex:0];
        
        [self setLayerData:data];
        
        [rs close];
        
    }
}

- (NSData*)layerImageData {
    
    if (_layerData) {
        return _layerData;
    }
    
    if (![self dataImage]) {
        return nil;
    }
    
    if (![self layerUTI]) {
        NSLog(@"No layer UTI given for layerImageData");
        return nil;
    }
    
    
    NSData *ret = [LFTImage dataFromImage:[self dataImage] withUTI:[self layerUTI]];
    
    if (!ret) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(@"Could not create layer data for %@ from layerImageData", self);
    }
    
    return ret;
    
    
}


- (NSData*)compositeImageData {
    
    if (_compositeData) {
        return _compositeData;
    }
    
    if (![self compositeImage]) {
        return nil;
    }
    
    if (![self compositeUTI]) {
        NSLog(@"No composite UTI given for compositeImageData");
        return nil;
    }
    
    
    NSData *ret = [LFTImage dataFromImage:[self compositeImage] withUTI:[self compositeUTI]];
    
    if (!ret) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(@"Could not create composite data for %@ from compositeImage", self);
    }
    
    return ret;
}

- (void)writeToDatabase:(FMDatabase*)db {
    
    [db executeUpdate:@"delete from layers where id = ?", [self layerId]];
    [db executeUpdate:@"delete from layer_attributes where id = ?", [self layerId]];
    
    NSData *imageData = [self layerImageData];
    
    if (!imageData) {
        NSLog(@"Warning: no data given for layer %@", self);
    }
    
    [db executeUpdate:@"insert into layers (id, parent_id, uti, name, data) values (?,?,?,?,?)", [self layerId], [self parentLayerId], [self layerUTI], [self layerName], imageData];
    
    [db setLayerAttribute:LFTLayerFrameDatabaseTag value:NSStringFromRect([self frame]) withId:[self layerId]];
    
    [db setLayerAttribute:LFTLayerVisibleDatabaseTag   value:@([self visible])  withId:[self layerId]];
    [db setLayerAttribute:LFTLayerLockedDatabaseTag    value:@([self locked])   withId:[self layerId]];
    [db setLayerAttribute:LFTLayerBlendModeDatabaseTag value:[self blendMode]   withId:[self layerId]];
    [db setLayerAttribute:LFTLayerOpacityDatabaseTag   value:@([self opacity])  withId:[self layerId]];
    
    NSData *compositeData = [self compositeImageData];
    if (compositeData) {
        [db setLayerAttribute:LFTLayerCompositeDatabaseTag   value:compositeData withId:[self layerId]];
        [db setLayerAttribute:LFTLayerCompositeUTIDatabaseTag value:[self compositeUTI] withId:[self layerUTI]];
    }
    
    for (NSString *key in [_atts allKeys]) {
        id value = [_atts objectForKey:key];
        [db setLayerAttribute:key value:value withId:[self layerId]];
    }
}
    
- (CGImageRef)dataImage {
    
    if (!_image) {
        
        if (_layerData) {
            CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)_layerData, (__bridge CFDictionaryRef)[NSDictionary dictionary]);
            
            if (!imageSourceRef) {
                NSLog(@"Could not make an image from layer %@ / %@", [self layerName], [self layerId]);
            }
            else {
                _image = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, (__bridge CFDictionaryRef)[NSDictionary dictionary]);
                
                CFRelease(imageSourceRef);
                
                if (!_image) {
                    NSLog(@"Invalid image data for %@ - lenght of %ld", [self layerName], [[self layerImageData] length]);
                }
            }
        }
        else {
            NSLog(@"Missing image data for %@", self);
        }
    }
    
    return _image;
}

- (void)setDataImage:(CGImageRef)img {
    if (_image != img) {
        
        if (_image) {
            CGImageRelease(_image);
        }
        
        _image = CGImageRetain(img);
    }
}

- (CGImageRef)compositeImage {
    return _composite;
}

- (void)setCompositeImage:(CGImageRef)img {
    if (_composite != img) {
        
        if (_composite) {
            CGImageRelease(_composite);
        }
        
        _composite = CGImageRetain(img);
    }
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

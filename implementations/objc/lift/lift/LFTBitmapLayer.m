//
//  LFTBitmapLayer.m
//  lift
//
//  Created by August Mueller on 1/7/14.
//  Copyright (c) 2014 Flying Meat Inc. All rights reserved.
//

#import "LFTBitmapLayer.h"
#import "LFTDatabaseAdditions.h"

@interface LFTBitmapLayer ()

@property (assign) CGImageRef image;

@end

@implementation LFTBitmapLayer

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setLayerUTI:(id)kUTTypeTIFF];
	}
	return self;
}


- (void)dealloc {
    if (_image) {
        CGImageRelease(_image);
    }
}


NSString *LFTLayerFrameDatabaseTag    = @"frame";

- (void)readFromDatabase:(FMDatabase*)db {

    [super readFromDatabase:db];
    
    NSString *frame = [db stringForLayerAttribute:LFTLayerFrameDatabaseTag withId:[self layerId]];
    
    if (!frame) {
        #pragma message "FIXME: return an error here."
        NSLog(@"no frame in the database when reading %@!", [self layerName]);
        return;
    }

    [self setFrame:NSRectFromString(frame)];
    
    #pragma message "FIXME: throw errors instead of asserts."
    assert([self frame].size.width  > 0);
    assert([self frame].size.height > 0);
    
    
    FMResultSet *rs = [db executeQuery:@"select data from layers where id = ?", [self layerId]];
    if ([rs next]) {
        
        NSData *data = [rs dataForColumnIndex:0];
        
        CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, (__bridge CFDictionaryRef)[NSDictionary dictionary]);
        
        if (!imageSourceRef) {
            #pragma message "FIXME: return an error?"
            NSLog(@"Could not make an image from layer %@ / %@", [self layerName], [self layerId]);
            return;
        }
        
        _image = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, (__bridge CFDictionaryRef)[NSDictionary dictionary]);
        
        CFRelease(imageSourceRef);
        
        [rs close];
        
        if (!_image) {
            #pragma message "FIXME: return an error"
            NSLog(@"Invalid image data for %@ - lenght of %ld", [self layerName], [data length]);
            return;
        }
        
    }
    else {
        NSBeep();
        NSLog(@"Could not read the image data for %@!", [self layerName]);
        return;
    }
    
    
}

- (void)writeToDatabase:(FMDatabase *)db {
    [super writeToDatabase:db];
    
    assert([self CGImage]);
    
    if (![self CGImage]) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(@"empty image");
        return;
    }
    
    NSDictionary *compOptions = @{(id)kCGImagePropertyTIFFCompression: @(NSTIFFCompressionLZW)};
    NSDictionary *props       = @{(id)kCGImagePropertyTIFFDictionary: compOptions};
    
    NSMutableData *layerData = [NSMutableData data];
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)layerData, kUTTypeTIFF, 1, (__bridge CFDictionaryRef)props);
    
    if (!imageDestination) {
        NSLog(@"%s:%d", __FUNCTION__, __LINE__);
        NSLog(@"Could not make image destination for saving to database");
        return;
    }
    
    CGImageDestinationAddImage(imageDestination, [self CGImage], (__bridge CFDictionaryRef)props);
    CGImageDestinationFinalize(imageDestination);
    CFRelease(imageDestination);
    
    [db executeUpdate:@"insert into layers (id, parent_id, uti, name, data) values (?,?,?,?,?)", [self layerId], [self parentLayerId], [self layerUTI], [self layerName], layerData];
    
    [db setLayerAttribute:LFTLayerFrameDatabaseTag value:NSStringFromRect([self frame]) withId:[self layerId]];
    
}

- (CGImageRef)CGImage {
    return _image;
}

- (void)setCGImage:(CGImageRef)img {
    if (_image != img) {
        
        if (_image) {
            CGImageRelease(_image);
        }
        
        _image = CGImageRetain(img);
    }
}

@end

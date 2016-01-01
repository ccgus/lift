//
//  LFTImage.m
//  lift
//
//  Created by August Mueller on 1/7/14.
//  Copyright (c) 2014 Flying Meat Inc. All rights reserved.
//

#import "LFTImage.h"
#import "FMDatabaseQueue.h"
#import "FMDatabaseAdditions.h"
#import "LFTDatabaseAdditions.h"
#import <Cocoa/Cocoa.h>
#import <sqlite3.h>

NSString *LFTImageSizeDatabaseTag       = @"imageSize";
NSString *LFTImageDPITag                = @"dpi";
NSString *LFTImageBitsPerPixelTag       = @"bitsPerPixel";
NSString *LFTImageBitsPerComponentTag   = @"bitsPerComponent";
NSString *LFTImageColorProfileTag       = @"iccColorProfile";
NSString *LFTImageCreatorSoftwareTag    = @"creatorSoftware";

NSString *kUTTypeLiftImage      = @"org.liftimage.lift";
NSString *kUTTypeLiftGroupLayer = @"org.liftimage.grouplayer";


@interface LFTImage ()

@property (strong) FMDatabaseQueue *q;
@property (strong) NSURL *databaseURL;
@property (strong) LFTGroupLayer *baseGroup;

@property (strong) NSMutableDictionary *atts;
@property (assign) CGImageRef compositeImage;

@end

@implementation LFTImage

- (id)init {
	self = [super init];
	if (self != nil) {
		_dpi = NSMakeSize(72, 72);
        _baseGroup = [[LFTGroupLayer alloc] init];
        [_baseGroup setIsBase:YES];
        
        
        _atts       = [NSMutableDictionary dictionary];
        
	}
	return self;
}


+ (instancetype)imageWithContentsOfURL:(NSURL*)u error:(NSError**)err {
    
    LFTImage *img = [[self alloc] init];
    
    [img setDatabaseURL:u];
    
    if (![img openImage]) {
        [img close];
        
        if (err) {
            *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: @"Could not open database"}];
        }
        
        return nil;
    }
    
    if (![img databaseIsValid]) {
        [img close];
        
        if (err) {
            *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: @"Database is invalid"}];
        }
        
        return nil;
    }
    
    if (![img read:err]) {
        
        [img close];
        return nil;
    }
    
    return img;
}

- (void)dealloc {
    
    [self close];
    
    if (_colorSpace) {
        CGColorSpaceRelease(_colorSpace);
    }
    
    if (_compositeImage) {
        CGImageRelease(_compositeImage);
    }
    
}


- (void)close {
    
    if (_q) {
        [_q close];
    }
    
    _q = nil;
    
}

- (BOOL)openImage {
    
    assert(_databaseURL);
    assert(!_q);
    
    _q = [FMDatabaseQueue databaseQueueWithPath:[_databaseURL path]];
    
    __block BOOL opened = NO;
    
    [_q inDatabase:^(FMDatabase *db) {
        opened = YES;
    }];
    
    return opened;
}

- (void)setupTables {
    
    [_q inDatabase:^(FMDatabase *db) {
        
        /*
        if (FMIsSandboxed()) {
            // need to turn off journaling for sandboxing.
            FMResultSet *journalStatement = [_storeDb executeQuery:@"PRAGMA journal_mode=MEMORY"];
            while ([journalStatement next]) { ; } // for some reason, sqlite needs this.
        }
        */
        
        FMResultSet *rs = [db executeQuery:@"select name from SQLITE_MASTER where name = 'image_attributes'"];
        if (![rs next]) {
            
            [db stringForQuery:[NSString stringWithFormat:@"PRAGMA page_size = %d", 8192]];
            
            [db beginTransaction];
            
            [db executeUpdate:@"create table image_attributes (name text, value blob)"];
            [db executeUpdate:@"create table layers (id text, parent_id text, sequence integer, uti text, name text, data blob)"];
            [db executeUpdate:@"create table layer_attributes ( id text, name text, value blob)"];
            
            if ([db lastErrorCode] != SQLITE_OK) {
                NSLog(@"Can't create the lift database at %@", [self databaseURL]);
            }
            
            [db commit];
            
        }
        else {
            [rs close];
        }
        
    }];
}

- (BOOL)databaseIsValid {

    __block BOOL databaseIsOK = NO;

    [_q inDatabase:^(FMDatabase *db) {
        
        if (![db tableExists:@"image_attributes"]) {
            debug(@"missing image_attributes table");
            return;
        }
        
        if (![db tableExists:@"layers"]) {
            debug(@"missing layers table");
            return;
        }
        
        if (![db tableExists:@"layer_attributes"]) {
            debug(@"missing layer_attributes table");
            return;
        }
        
        databaseIsOK = YES;
        
    }];
    
    return databaseIsOK;
}





- (void)setValue:(id)value forAttribute:(NSString*)attributeName {
    
    if ([attributeName isEqualToString:LFTImageSizeDatabaseTag]) {
        assert([value isKindOfClass:[NSString class]]);
        [self setImageSize:NSSizeFromString(value)];
    }
    else if ([attributeName isEqualToString:LFTImageColorProfileTag]) {
        assert([value isKindOfClass:[NSData class]]);
        NSData *profileData = value;
        
        CGColorSpaceRef cs = CGColorSpaceCreateWithICCProfile((__bridge CFDataRef)profileData);
        
        if (cs) {
            [self setColorSpace:cs];
            CGColorSpaceRelease(cs);
        }
        else {
            NSLog(@"%s:%d", __FUNCTION__, __LINE__);
            NSLog(@"Could not turn color profile icc data into a colorspace");
        }
    }
    else if ([attributeName isEqualToString:LFTImageBitsPerPixelTag]) {
        assert([value isKindOfClass:[NSNumber class]]);
        [self setBitsPerPixel:[value integerValue]];
    }
    else if ([attributeName isEqualToString:LFTImageBitsPerComponentTag]) {
        assert([value isKindOfClass:[NSNumber class]]);
        [self setBitsPerComponent:[value integerValue]];
    }
    else if ([attributeName isEqualToString:LFTImageDPITag]) {
        assert([value isKindOfClass:[NSString class]]);
        [self setDpi:NSSizeFromString(value)];
    }
    else if ([attributeName isEqualToString:LFTImageCreatorSoftwareTag]) {
        assert([value isKindOfClass:[NSString class]]);
        [self setCreatorSoftware:value];
    }
    else {
        [self addAttribute:value withKey:attributeName];
    }
    
    
}




- (BOOL)read:(NSError**)err {


    __block BOOL goodRead = YES;

    [_q inDatabase:^(FMDatabase *db) {
        
        
        FMResultSet *rs = [db executeQuery:@"select name, value from image_attributes"];
        
        while ([rs next]) {
            [self setValue:[rs objectForColumnIndex:1] forAttribute:[rs stringForColumnIndex:0]];
        }

        if ([self imageSize].width <= 0 || [self imageSize].height <= 0) {
            if (err) {
                NSString *errorString = [NSString stringWithFormat:@"Invalid image size: %@", NSStringFromSize([self imageSize])];
                *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: errorString}];
            }
            goodRead = NO;
            return;
        }
        
        
        if (![self colorSpace]) {
            if (err) {
                *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: @"Missing or invalid color profile in database"}];
            }
            goodRead = NO;
            return;
        }
        
        if (_bitsPerComponent < 1) {
            
            if (err) {
                *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: @"Bits per component tag is missing or invalid"}];
            }
            goodRead = NO;
            return;
        }
        
        if (_bitsPerPixel < 1) {
            
            if (err) {
                *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: @"Bits per pixel tag is missing or invalid"}];
            }
            goodRead = NO;
            return;
        }
        
        [_baseGroup setLayerName:[NSString stringWithFormat:@"%@'s base group", [_databaseURL lastPathComponent]]];
        
        [_baseGroup readFromDatabase:db];
        
    }];
    
    return goodRead;
}

- (BOOL)writeToURL:(NSURL*)url  error:(NSError**)err {
    
    if ([self imageSize].width < 1 || [self imageSize].height < 1) {
        if (err) {
            *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid image size"}];
        }
        
        return NO;
    }
    
    
    [self setDatabaseURL:url];
    
    if (![self openImage]) {
        [self close];
        
        if (err) {
            *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: @"Could not open database for writing"}];
        }
        
        return NO;
    }
    
    [self setupTables];
    
    [_q inTransaction:^(FMDatabase *db, BOOL *rollback) {
    
        [db setImageAttribute:LFTImageSizeDatabaseTag withValue:NSStringFromSize([self imageSize])];
        
        NSData *iccData = CFBridgingRelease(CGColorSpaceCopyICCProfile([self colorSpace]));
        if (iccData) {
            [db setImageAttribute:LFTImageColorProfileTag withValue:iccData];
        }
        
        
        [db setImageAttribute:LFTImageBitsPerComponentTag withValue:@([self bitsPerComponent])];
        [db setImageAttribute:LFTImageBitsPerPixelTag withValue:@([self bitsPerPixel])];
        [db setImageAttribute:LFTImageDPITag withValue:NSStringFromSize([self dpi])];
        [db setImageAttribute:LFTImageCreatorSoftwareTag withValue:[self creatorSoftware]];
        
        for (NSString *key in [_atts allKeys]) {
            id value = [_atts objectForKey:key];
            [db setImageAttribute:key withValue:value];
        }
        
        if (_compositeImage) {
            NSData *d  = [LFTImage dataFromImage:_compositeImage withUTI:(id)kUTTypeTIFF];
            [db setImageAttribute:@"composite" withValue:d];
            [db setImageAttribute:@"composite-uti" withValue:(id)kUTTypeTIFF];
            
        }
        
        
        [_baseGroup writeToDatabase:db];
    }];
    
    
    
    return YES;
}


- (void)addAttribute:(id)attribute withKey:(NSString*)key {
    [_atts setValue:attribute forKey:key];
}

- (NSDictionary*)attributes {
    return _atts;
}

- (LFTGroupLayer*)baseGroupLayer {
    return _baseGroup;
}


- (CGImageRef)composite {
    return _compositeImage;
}

- (void)setComposite:(CGImageRef)composie {
    
    if (_compositeImage != composie) {
        if (_compositeImage) {
            CGImageRelease(_compositeImage);
        }
        
        _compositeImage = composie;
        
        if (_compositeImage) {
            CGImageRetain(_compositeImage);
        }
    }
}


- (void)setColorSpace:(CGColorSpaceRef)cs {
    
    if (_colorSpace != cs) {
        if (_colorSpace) {
            CGColorSpaceRelease(_colorSpace);
        }
        
        _colorSpace = cs;
        
        if (_colorSpace) {
            CGColorSpaceRetain(_colorSpace);
        }
    }
}

- (CGColorSpaceRef)colorSpace {
    return _colorSpace;
}


+ (NSData*)dataFromImage:(CGImageRef)img withUTI:(NSString*)uti {
    
    NSData *serializedImage   = nil;
    NSDictionary *compOptions = @{(id)kCGImagePropertyTIFFCompression: @(NSTIFFCompressionLZW)};
    NSDictionary *props       = @{(id)kCGImagePropertyTIFFDictionary: compOptions};
    
    NSMutableData *imageData = [NSMutableData data];
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, (__bridge CFStringRef)uti, 1, (__bridge CFDictionaryRef)props);
    
    if (imageDestination) {
        
        CGImageDestinationAddImage(imageDestination, img, (__bridge CFDictionaryRef)props);
        CGImageDestinationFinalize(imageDestination);
        CFRelease(imageDestination);
        
        serializedImage = imageData;
    }
    
    return serializedImage;
    
}

- (NSString*)debugDescription {
    NSMutableString *s = [NSMutableString string];
    
    [_baseGroup writeToDebugString:s depth:0];
    
    return s;
}


@end

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
    
    #pragma message "FIXME: move the attribute loads into here,and then checks below."
    if ([attributeName isEqualToString:LFTImageSizeDatabaseTag]) {
        return;
    }
    if ([attributeName isEqualToString:LFTImageColorProfileTag]) {
        return;
    }
    if ([attributeName isEqualToString:LFTImageBitsPerPixelTag]) {
        return;
    }
    if ([attributeName isEqualToString:LFTImageBitsPerComponentTag]) {
        return;
    }
    if ([attributeName isEqualToString:LFTImageDPITag]) {
        return;
    }
    
    if ([attributeName isEqualToString:LFTImageCreatorSoftwareTag]) {
        assert([value isKindOfClass:[NSString class]]);
        [self setCreatorSoftware:value];
        return;
    }
    
    
    [self addAttribute:value withKey:attributeName];
}




- (BOOL)read:(NSError**)err {


    __block BOOL goodRead = YES;

    [_q inDatabase:^(FMDatabase *db) {
        
        
        FMResultSet *rs = [db executeQuery:@"select name, value from image_attributes"];
        
        while ([rs next]) {
            [self setValue:[rs objectForColumnIndex:1] forAttribute:[rs stringForColumnIndex:0]];
        }

        
        
        NSString *canvasSizeS = [db stringForImageAttribute:LFTImageSizeDatabaseTag];
        
        if (!canvasSizeS) {
            if (err) {
                *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: @"No image size in database"}];
            }
            goodRead = NO;
            return;
        }
        
        NSSize size = NSSizeFromString(canvasSizeS);
        
        if (size.width <= 0 || size.height <= 0) {
            if (err) {
                NSString *errorString = [NSString stringWithFormat:@"Invalid image size: %@", NSStringFromSize(size)];
                *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: errorString}];
            }
            goodRead = NO;
            return;
        }
        
        [self setImageSize:size];
        
        NSData *profileData = [db dataForImageAttribute:LFTImageColorProfileTag];
        if (!profileData) {
            if (err) {
                *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: @"Missing color profile in database"}];
            }
            goodRead = NO;
            return;
        }
        
        // echo "insert into image_attributes(name, value) values('iccColorProfile', x'"$(hexdump -v -e '1/1 "%02x"' /System/Library/ColorSync/Profiles/sRGB\ Profile.icc)"');"
        CGColorSpaceRef cs = CGColorSpaceCreateWithICCProfile((__bridge CFDataRef)profileData);
        
        if (!cs) {
            
            if (err) {
                *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: @"Could not turn color profile icc data into a colorspace"}];
            }
            goodRead = NO;
            return;
        }
        
        [self setColorSpace:cs];
        
        
        _bitsPerComponent = [db intForImageAttribute:LFTImageBitsPerComponentTag];
        if (!_bitsPerComponent) {
            
            if (err) {
                *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: @"Bits per component tag is missing or invalid"}];
            }
            goodRead = NO;
            return;
        }
        
        _bitsPerPixel = [db intForImageAttribute:LFTImageBitsPerPixelTag];
        if (!_bitsPerPixel) {
            
            if (err) {
                *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: @"Bits per pixel tag is missing or invalid"}];
            }
            goodRead = NO;
            return;
        }
        
        NSSize dpi = NSSizeFromString([db stringForImageAttribute:LFTImageDPITag]);
        if (dpi.width > 0 && dpi.height > 0) {
            [self setDpi:dpi];
        }
        
        
        [_baseGroup setLayerName:[NSString stringWithFormat:@"%@'s base group", [_databaseURL lastPathComponent]]];
        
        [_baseGroup readFromDatabase:db];
        
    }];
    
    return goodRead;
}

- (BOOL)writeToURL:(NSURL*)url  error:(NSError**)err {
    
    [self setDatabaseURL:url];
    
    if (![self openImage]) {
        [self close];
        
        if (err) {
            *err = [NSError errorWithDomain:kUTTypeLiftImage code:1 userInfo:@{NSLocalizedDescriptionKey: @"Could not open database for writing"}];
        }
        
        return NO;
    }
    
    [self setupTables];
    
    
    #pragma message "FIXME: make sure our size and such are valid."
    
    
    [_q inDatabase:^(FMDatabase *db) {
    
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

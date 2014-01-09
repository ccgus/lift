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

NSString *LFTImageSizeDatabaseTag       = @"imageSize";
NSString *LFTImageDPITag                = @"dpi";
NSString *LFTImageBitsPerPixelTag       = @"bitsPerPixel";
NSString *LFTImageBitsPerComponentTag   = @"bitsPerComponent";
NSString *LFTImageColorProfileTag       = @"iccColorProfile";
NSString *LFTImageCreatorSoftwareTag    = @"creatorSoftware";


@interface LFTImage ()

@property (strong) FMDatabaseQueue *q;
@property (strong) NSURL *databaseURL;
@property (strong) LFTGroupLayer *baseGroup;


@end

@implementation LFTImage

- (id)init {
	self = [super init];
	if (self != nil) {
		_dpi = NSMakeSize(72, 72);
        _baseGroup = [[LFTGroupLayer alloc] init];
        [_baseGroup setIsBase:YES];
	}
	return self;
}


+ (instancetype)imageWithContentsOfURL:(NSURL*)u error:(NSError**)err {
    
    LFTImage *img = [[self alloc] init];
    
    [img setDatabaseURL:u];
    
    if (![img openImage]) {
        [img close];
        
        if (err) {
            *err = [NSError errorWithDomain:@"org.liftimage.lift" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Could not open database"}];
        }
        
        return nil;
    }
    
    if (![img databaseIsValid]) {
        [img close];
        
        if (err) {
            *err = [NSError errorWithDomain:@"org.liftimage.lift" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Database is invalid"}];
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
    if (_colorSpace) {
        CGColorSpaceRelease(_colorSpace);
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



- (BOOL)read:(NSError**)err {


    __block BOOL goodRead = YES;

    [_q inDatabase:^(FMDatabase *db) {
        
        NSString *canvasSizeS = [db stringForImageAttribute:LFTImageSizeDatabaseTag];
        
        if (!canvasSizeS) {
            if (err) {
                *err = [NSError errorWithDomain:@"org.liftimage.lift" code:1 userInfo:@{NSLocalizedDescriptionKey: @"No image size in database"}];
            }
            goodRead = NO;
            return;
        }
        
        NSSize size = NSSizeFromString(canvasSizeS);
        
        if (size.width <= 0 || size.height <= 0) {
            if (err) {
                NSString *errorString = [NSString stringWithFormat:@"Invalid image size: %@", NSStringFromSize(size)];
                *err = [NSError errorWithDomain:@"org.liftimage.lift" code:1 userInfo:@{NSLocalizedDescriptionKey: errorString}];
            }
            goodRead = NO;
            return;
        }
        
        [self setImageSize:size];
        
        NSData *profileData = [db dataForImageAttribute:LFTImageColorProfileTag];
        if (!profileData) {
            if (err) {
                *err = [NSError errorWithDomain:@"org.liftimage.lift" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Missing color profile in database"}];
            }
            goodRead = NO;
            return;
        }
        
        // echo "insert into image_attributes(name, value) values('iccColorProfile', x'"$(hexdump -v -e '1/1 "%02x"' /System/Library/ColorSync/Profiles/sRGB\ Profile.icc)"');"
        CGColorSpaceRef cs = CGColorSpaceCreateWithICCProfile((__bridge CFDataRef)profileData);
        
        if (!cs) {
            
            if (err) {
                *err = [NSError errorWithDomain:@"org.liftimage.lift" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Could not turn color profile icc data into a colorspace"}];
            }
            goodRead = NO;
            return;
        }
        
        [self setColorSpace:cs];
        
        
        _bitsPerComponent = [db intForImageAttribute:LFTImageBitsPerComponentTag];
        if (!_bitsPerComponent) {
            
            if (err) {
                *err = [NSError errorWithDomain:@"org.liftimage.lift" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Bits per component tag is missing or invalid"}];
            }
            goodRead = NO;
            return;
        }
        
        _bitsPerPixel = [db intForImageAttribute:LFTImageBitsPerComponentTag];
        if (!_bitsPerPixel) {
            
            if (err) {
                *err = [NSError errorWithDomain:@"org.liftimage.lift" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Bits per pixel tag is missing or invalid"}];
            }
            goodRead = NO;
            return;
        }
        
        NSSize dpi = NSSizeFromString([db stringForImageAttribute:LFTImageDPITag]);
        if (dpi.width > 0 && dpi.height > 0) {
            [self setDpi:dpi];
        }
        
        
        /* Optional Stuff */
        
        [self setCreatorSoftware:[db stringForImageAttribute:LFTImageCreatorSoftwareTag]];
        
        
        [_baseGroup setLayerName:[NSString stringWithFormat:@"%@'s base group", [_databaseURL lastPathComponent]]];
        
        [_baseGroup readFromDatabase:db];
        
        
        
        
        
        
    }];
    
    return goodRead;
}

- (LFTGroupLayer*)baseGroupLayer {
    return _baseGroup;
}

@end

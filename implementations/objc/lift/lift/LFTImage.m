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

@interface LFTImage ()

@property (strong) FMDatabaseQueue *q;
@property (strong) NSURL *databaseURL;


@end

@implementation LFTImage

+ (instancetype)imageWithContentsOfURL:(NSURL*)u {
    
    
    LFTImage *img = [[self alloc] init];
    
    [img setDatabaseURL:u];
    
    if (![img openImage]) {
        [img close];
        return nil;
    }
    
    return img;
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
    
    if ([self databaseIsValid]) {
        
    }
    else {
        [self setupTables];
    }
    
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

- (void)read {
    [_q inDatabase:^(FMDatabase *db) {
    
    }];
}

@end

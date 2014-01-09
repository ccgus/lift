//
//  LFTLayer.h
//  lift
//
//  Created by August Mueller on 1/7/14.
//  Copyright (c) 2014 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface LFTLayer : NSObject {
    
}

@property (strong) NSString *layerId;
@property (strong) NSString *parentLayerId;
@property (strong) NSString *layerUTI;
@property (strong) NSString *layerName;
@property (strong) NSString *blendMode;

@property (assign) BOOL visible;
@property (assign) BOOL locked;

@property (assign) CGFloat opacity;

@property (assign) NSRect frame;

- (void)readFromDatabase:(FMDatabase*)db;
- (void)writeToDatabase:(FMDatabase*)db;

- (CGImageRef)CGImage;

@end

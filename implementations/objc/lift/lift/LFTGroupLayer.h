//
//  LFTGroupLayer.h
//  lift
//
//  Created by August Mueller on 1/7/14.
//  Copyright (c) 2014 Flying Meat Inc. All rights reserved.
//

#import "LFTLayer.h"

@interface LFTGroupLayer : LFTLayer

@property (assign) BOOL isBase;

- (NSArray*)layers;

- (void)addLayer:(LFTLayer*)l;

@end

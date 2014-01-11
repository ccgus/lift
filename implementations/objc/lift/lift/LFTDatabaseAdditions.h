//
//  LFTDatabaseAdditions.h
//  lift
//
//  Created by August Mueller on 1/9/14.
//  Copyright (c) 2014 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface FMDatabase (LFTDatabaseAdditions)

- (NSString*)stringForImageAttribute:(NSString*)attName;

- (BOOL)boolForImageAttribute:(NSString*)attName;

- (int)intForImageAttribute:(NSString*)attName;

- (CGFloat)floatForImageAttribute:(NSString*)attName;

- (NSData*)dataForImageAttribute:(NSString*)attName;

- (void)setImageAttribute:(NSString*)attName withValue:(id)value;


- (NSString*)stringForLayerAttribute:(NSString*)attName withId:(NSString*)layerId;

- (BOOL)boolForLayerAttribute:(NSString*)attName withId:(NSString*)layerId;

- (int)intForLayerAttribute:(NSString*)attName withId:(NSString*)layerId;

- (CGFloat)floatForLayerAttribute:(NSString*)attName withId:(NSString*)layerId;

- (NSData*)dataForLayerAttribute:(NSString*)attName withId:(NSString*)layerId;

- (void)setLayerAttribute:(NSString*)attName value:(id)value withId:(NSString*)layerId;




@end

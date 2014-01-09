//
//  LFTDatabaseAdditions.m
//  lift
//
//  Created by August Mueller on 1/9/14.
//  Copyright (c) 2014 Flying Meat Inc. All rights reserved.
//

#import "LFTDatabaseAdditions.h"
#import "FMDatabaseAdditions.h"

@implementation FMDatabase (LFTDatabaseAdditions)

- (NSString*)stringForImageAttribute:(NSString*)attName  {
    return [self stringForQuery:@"select value from image_attributes where name = ?", attName];
}

- (BOOL)boolForImageAttribute:(NSString*)attName {
    return [self boolForQuery:@"select value from image_attributes where name = ?", attName];
}

- (int)intForImageAttribute:(NSString*)attName {
    return [self intForQuery:@"select value from image_attributes where name = ?", attName];
}

- (CGFloat)floatForImageAttribute:(NSString*)attName {
    return [self doubleForQuery:@"select value from image_attributes where name = ?", attName];
}

- (NSData*)dataForImageAttribute:(NSString*)attName  {
    return [self dataForQuery:@"select value from image_attributes where name = ?", attName];
}

- (void)setImageAttribute:(NSString*)attName withValue:(id)value  {
    
    [self executeUpdate:@"delete from image_attributes where name = ?", attName];
    
    if (value) {
        [self executeUpdate:@"insert into image_attributes (name, value) values (?,?)", attName, value];
    }
}

- (NSString*)stringForLayerAttribute:(NSString*)attName withId:(NSString*)layerId  {
    return [self stringForQuery:@"select value from layer_attributes where name = ? and id = ?", attName, layerId];
}

- (BOOL)boolForLayerAttribute:(NSString*)attName withId:(NSString*)layerId {
    return [self boolForQuery:@"select value from layer_attributes where name = ? and id = ?", attName, layerId];
}

- (int)intForLayerAttribute:(NSString*)attName withId:(NSString*)layerId {
    return [self intForQuery:@"select value from layer_attributes where name = ? and id = ?", attName, layerId];
}

- (CGFloat)floatForLayerAttribute:(NSString*)attName withId:(NSString*)layerId {
    return [self doubleForQuery:@"select value from layer_attributes where name = ? and id = ?", attName, layerId];
}

- (NSData*)dataForLayerAttribute:(NSString*)attName withId:(NSString*)layerId  {
    return [self dataForQuery:@"select value from layer_attributes where name = ? and id = ?", attName, layerId];
}

- (void)setLayerAttribute:(NSString*)attName value:(id)value withId:(NSString*)layerId  {
    
    [self executeUpdate:@"delete from layer_attributes where name = ? and id = ?", attName, layerId];
    
    if (value) {
        [self executeUpdate:@"insert into layer_attributes (id, name, value) values (?,?,?)", layerId, attName, value];
    }
}

@end

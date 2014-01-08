//
//  LFTImage.h
//  lift
//
//  Created by August Mueller on 1/7/14.
//  Copyright (c) 2014 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef debug
    #define debug NSLog
#endif

@interface LFTImage : NSObject

+ (id)imageWithContentsOfURL:(NSURL*)u;

@end

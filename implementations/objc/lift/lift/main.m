//
//  main.m
//  lift
//
//  Created by August Mueller on 1/7/14.
//  Copyright (c) 2014 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Lift.h"
#import "LFTImage.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        NSString *testImagePath = [@"~/Projects/lift/liftimages/radial gradient.lift" stringByExpandingTildeInPath];
        
        LFTImage *img = [LFTImage imageWithContentsOfURL:[NSURL fileURLWithPath:testImagePath] error:nil];
        
        debug(@"img: '%@'", img);
    }
    return 0;
}


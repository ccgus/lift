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


static NSSize maxSize;
static CGColorSpaceRef firstColorspaceWeCameAcross;

CGImageRef createCGImageFromPath(NSString *path) {
    
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], nil);
    
    if (!imageSourceRef) {
        printf("ERR: Could not create CGImageSourceRef from %s\n", [path UTF8String]);
        return nil;
    }
    
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, (__bridge CFDictionaryRef)[NSDictionary dictionary]);
    
    CFRelease(imageSourceRef);
    
    if (!imageRef) {
        printf("ERR: Could not make %s into an image\n", [path UTF8String]);
        return nil;
    }
    
    if (!firstColorspaceWeCameAcross) {
        firstColorspaceWeCameAcross = CGColorSpaceRetain(CGImageGetColorSpace(imageRef));
    }
    
    return imageRef;
    
}

void addImagesFromFolder(NSString *folder, LFTGroupLayer *groupToAddTo) {
    
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:nil]) {
        
        if ([file hasPrefix:@"."]) {
            continue;
        }
        
        NSString *fullPathToFile = [folder stringByAppendingPathComponent:file];
        
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPathToFile isDirectory:&isDir] && isDir) {
            
            LFTGroupLayer *newGroup = [[LFTGroupLayer alloc] init];
            [newGroup setLayerName:file];
            
            [groupToAddTo addLayer:newGroup];
            
            addImagesFromFolder(fullPathToFile, newGroup);
        }
        else {
            
            NSError *outErr;
            NSString *uti = [[NSWorkspace sharedWorkspace] typeOfFile:fullPathToFile error:&outErr];
            
            if (!uti) {
                NSLog(@"%@", outErr);
                continue;
            }
            
            CGImageRef img = createCGImageFromPath(fullPathToFile);
            
            if (img) {
                
                NSRect r = NSMakeRect(0, 0, CGImageGetWidth(img), CGImageGetHeight(img));
                
                LFTLayer *layer = [[LFTLayer alloc] init];
                
                [layer setLayerUTI:uti];
                [layer setLayerName:file];
                [layer setFrame:r];
                [layer setDataImage:img];
                
                maxSize.width  = MAX(r.size.width, maxSize.width);
                maxSize.height = MAX(r.size.height, maxSize.height);
                
                [groupToAddTo addLayer:layer];
            }
        }
    }
}

int main(int argc, const char * argv[]) {

    @autoreleasepool {
        
        if (argc < 3) {
            printf("Usage: lift <somefile.lift> <somefolder>\n");
            return 1;
        }
        
        NSString *liftPath = [NSString stringWithFormat:@"%s", argv[1]];
        NSString *path     = [NSString stringWithFormat:@"%s", argv[2]];
        
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
            printf("Argumet 2 must be a folder");
            return 2;
        }
        
        maxSize = NSZeroSize;
        
        LFTImage *image = [[LFTImage alloc] init];
        
        addImagesFromFolder(path, [image baseGroupLayer]);
        
        [image setImageSize:maxSize];
        [image setBitsPerComponent:8];
        [image setBitsPerPixel:32];
        [image setColorSpace:firstColorspaceWeCameAcross];
        CGColorSpaceRelease(firstColorspaceWeCameAcross);
        
        debug(@"%@", [image debugDescription]);
        
        NSError *outErr = nil;
        if (![image writeToURL:[NSURL fileURLWithPath:liftPath] error:&outErr]) {
            NSLog(@"Could not write to: %@", liftPath);
            NSLog(@"%@", outErr);
            return 5;
        }
        
        
    }
    return 0;
}


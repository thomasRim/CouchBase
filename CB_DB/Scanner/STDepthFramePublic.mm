//
//  STDepthFramePublic.m
//  Scanner
//
//  Created by Kamil Budzynski on 19.06.2015.
//  Copyright (c) 2015 Orthogenic Laboratories. All rights reserved.
//

#import "STDepthFramePublic.h"

@implementation STDepthFramePublic
@synthesize depthFrame = _depthFrame;

- (float *) depthInMillimeters{
    NSLog(@"mili");

    return [super depthInMillimeters];
    return self.depthFrame.depthInMillimeters;
    if (!newDepthInMillimeters) {
        int nOfDepthPoints = self.depthFrame.width + self.depthFrame.height;
        newDepthInMillimeters = (float *)malloc(sizeof(float) * nOfDepthPoints);
        for(int i = 0; i < nOfDepthPoints; i++){
            newDepthInMillimeters[i] = 900.0f;
        }
    }
    
    //newDepthFrame.depthInMillimeters = array;
    return newDepthInMillimeters;
}



- (id) initWithSTDepthFrame:(STDepthFrame *) newDepthFrame{
    NSLog(@"ini");

    self = [super init];
    if (self) {
        NSLog(@"frame init");
        self.depthFrame = newDepthFrame;
        
        NSLog(@"width %d %d", self.depthFrame.width, [self width]);
        
    }
    return self;
}

- (int) width{
    NSLog(@"wid");
    return [super width];
    return [self.depthFrame width];
}

- (int) height{
    NSLog(@"hei");
    return [super height];
    return self.depthFrame.height;
}

- (uint16_t *) shiftData{
    NSLog(@"shif");
    return [super shiftData];
    return self.depthFrame.shiftData;
}

- (STDepthFrame *) halfResolutionDepthFrame{
    NSLog(@"half");
    return [super halfResolutionDepthFrame];
    return self.depthFrame.halfResolutionDepthFrame;
}

- (NSTimeInterval) timestamp{
    NSLog(@"times");
    return [super timestamp];
    return self.depthFrame.timestamp;
}


@end

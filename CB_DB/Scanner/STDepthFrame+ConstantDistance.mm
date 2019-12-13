//
//  STDepthFrame+ConstantDistance.m
//  Scanner
//
//  Created by Kamil Budzynski on 19.06.2015.
//  Copyright (c) 2015 Orthogenic Laboratories. All rights reserved.
//

#import "STDepthFrame+ConstantDistance.h"
#import <Structure/Structure.h>

@implementation STDepthFrame(ConstantDistance)
//@synthesize newDepthInMillimeters;
//@synthesize depthFrame = _depthFrame;

- (float *) depthInMillimeters{
    if ([self respondsToSelector:@selector(depthFrame)]) return self.depthFrame.depthInMillimeters;
    else return self.depthInMillimeters;
    
    if (!self.newDepthInMillimeters) {
        int nOfDepthPoints = self.depthFrame.width + self.depthFrame.height;
        self.newDepthInMillimeters = (float *)malloc(sizeof(float) * nOfDepthPoints);
        for(int i = 0; i < nOfDepthPoints; i++){
            self.newDepthInMillimeters[i] = 900.0f;
        }
    }
    
    //newDepthFrame.depthInMillimeters = array;
    return self.newDepthInMillimeters;
}



- (id) initWithSTDepthFrame:(STDepthFrame *) newDepthFrame{
    self = [super init];
    if (self) {
        NSLog(@"frame init");
        self.depthFrame = newDepthFrame;
        
        NSLog(@"width %d %d", self.depthFrame.width, [self width]);
        
    }
    return self;
}

- (int) width{
    if ([self respondsToSelector:@selector(depthFrame)]) return self.depthFrame.width;
    else return self.width;
}

- (int) height{
    if ([self respondsToSelector:@selector(depthFrame)]) return self.depthFrame.height;
    else return self.height;
}

- (uint16_t *) shiftData{
    if ([self respondsToSelector:@selector(depthFrame)]) return self.depthFrame.shiftData;
    else return self.shiftData;
}

- (STDepthFrame *) halfResolutionDepthFrame{
    if ([self respondsToSelector:@selector(depthFrame)]) return self.depthFrame.halfResolutionDepthFrame;
    else return self.halfResolutionDepthFrame;
}

- (NSTimeInterval) timestamp{
    if ([self respondsToSelector:@selector(depthFrame)]) return self.depthFrame.timestamp;
    else return self.timestamp;
}

@end

//
//  STDepthFramePublic.h
//  Scanner
//
//  Created by Kamil Budzynski on 19.06.2015.
//  Copyright (c) 2015 Orthogenic Laboratories. All rights reserved.
//

#import <Structure/Structure.h>

@interface STDepthFramePublic : STDepthFrame{
    float *newDepthInMillimeters;
}
@property (nonatomic, strong) STDepthFrame *depthFrame;

- (id) initWithSTDepthFrame:(STDepthFrame *) newDepthFrame;


@end

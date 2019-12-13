//
//  STDepthFrame+ConstantDistance.h
//  Scanner
//
//  Created by Kamil Budzynski on 19.06.2015.
//  Copyright (c) 2015 Orthogenic Laboratories. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Structure/Structure.h>

@interface STDepthFrame(ConstantDistance)

@property (nonatomic) float *newDepthInMillimeters;

@property (nonatomic, strong) STDepthFrame *depthFrame;

- (id) initWithSTDepthFrame:(STDepthFrame *) newDepthFrame;


@end

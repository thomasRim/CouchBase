//
//  STDepthFrame+Swizzle.m
//  Scanner
//
//  Created by Kamil Budzynski on 24.06.2015.
//  Copyright (c) 2015 Orthogenic Laboratories. All rights reserved.
//

#import "STDepthFrame+Swizzle.h"
#import <objc/runtime.h>

@implementation STDepthFrame(Swizzle)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class newClass = [self class];
        
        SEL originalSelector = @selector(depthInMillimeters);
        SEL swizzledSelector = @selector(xxx_depthInMillimeters);
        
        Method originalMethod = class_getInstanceMethod(newClass, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(newClass, swizzledSelector);
        
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        // ...
        // Method originalMethod = class_getClassMethod(class, originalSelector);
        // Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(newClass,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(newClass,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

#pragma mark - Method Swizzling



- (float *) xxx_depthInMillimeters{
    
    return [self depthInMillimeters];
//    
//    if ([self respondsToSelector:@selector(depthFrame)]) return self.depthFrame.depthInMillimeters;
//    
//    
//    else return self.depthInMillimeters;
    
//    if (!self.newDepthInMillimeters) {
//        int nOfDepthPoints = self.depthFrame.width + self.depthFrame.height;
//        self.newDepthInMillimeters = (float *)malloc(sizeof(float) * nOfDepthPoints);
//        for(int i = 0; i < nOfDepthPoints; i++){
//            self.newDepthInMillimeters[i] = 900.0f;
//        }
//    }
    
    //newDepthFrame.depthInMillimeters = array;
//    return self.newDepthInMillimeters;
}

@end

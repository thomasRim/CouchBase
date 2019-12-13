//
//  InstructionPopupController.h
//  Scanner
//
//  Created by Ernest Surudo on 2015-08-10.
//  Copyright (c) 2015 Orthogenic Laboratories. All rights reserved.
//

#import <Foundation/Foundation.h>

@class InstructionPopupController;

@protocol InstructionPopupControllerDelegate <NSObject>

@required
- (void)instructionPopupDidDismiss:(InstructionPopupController*)controller;

@end

@interface InstructionPopupController : NSObject

@property (weak, nonatomic) id<InstructionPopupControllerDelegate> delegate;

- (id)initWithTitle:(NSString*)title messages:(NSArray*)messages dismissButtonText:(NSString*)dismissButtonText neverShowUserDefaultsKey:(NSString*)neverShowUserDefaultsKey delegate:(id<InstructionPopupControllerDelegate>)delegate;
- (void)presentIfNeeded;

@end

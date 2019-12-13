//
//  InstructionPopupController.m
//  Scanner
//
//  Created by Ernest Surudo on 2015-08-10.
//  Copyright (c) 2015 Orthogenic Laboratories. All rights reserved.
//

#import "InstructionPopupController.h"

#import <CNPPopupController/CNPPopupController.h>
#import <M13Checkbox/M13Checkbox.h>

@interface InstructionPopupController () <CNPPopupControllerDelegate>

@property (nonatomic, strong) CNPPopupController *popupController;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) NSString *dismissButtonText;
@property (nonatomic, strong) NSString *neverShowUserDefaultsKey;

@property (nonatomic, strong) M13Checkbox *neverShowCheckbox;

@end

@implementation InstructionPopupController

- (id)initWithTitle:(NSString*)title messages:(NSArray*)messages dismissButtonText:(NSString*)dismissButtonText neverShowUserDefaultsKey:(NSString*)neverShowUserDefaultsKey delegate:(id<InstructionPopupControllerDelegate>)delegate;
{
    self = [super init];
    
    if (self) {
        _title = title;
        _messages = messages;
        _dismissButtonText = dismissButtonText;
        _neverShowUserDefaultsKey = neverShowUserDefaultsKey;
        _delegate = delegate;
    }
    
    return self;
}

- (void)presentIfNeeded
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (![userDefaults boolForKey:self.neverShowUserDefaultsKey] && self.popupController == nil)
    {
        NSMutableArray *contents = [NSMutableArray arrayWithCapacity:self.messages.count + 3];
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        NSAttributedString *title = [[NSAttributedString alloc] initWithString:self.title
                                                                    attributes:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:24],
                                                                                  NSParagraphStyleAttributeName: paragraphStyle }];
        
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.numberOfLines = 0;
        titleLabel.attributedText = title;
        
        [contents addObject:titleLabel];
        
        for (NSString *message in self.messages) {
            NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:message
                                                                          attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:18],
                                                                                        NSParagraphStyleAttributeName: paragraphStyle }];
            
            UILabel *messageLabel = [[UILabel alloc] init];
            messageLabel.numberOfLines = 0;
            messageLabel.attributedText = attributedMessage;
            
            [contents addObject:messageLabel];
        }
        
        self.neverShowCheckbox = [[M13Checkbox alloc] initWithTitle:NSLocalizedString(@"CNeverShow", nil)];
        self.neverShowCheckbox.checkAlignment = M13CheckboxAlignmentLeft;
        
        [contents addObject:self.neverShowCheckbox];
        
        CNPPopupButton *button = [[CNPPopupButton alloc] initWithFrame:CGRectMake(0, 0, 260, 60)];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [button setTitle:self.dismissButtonText forState:UIControlStateNormal];
        button.backgroundColor = [UIColor colorWithRed:0.46 green:0.8 blue:1.0 alpha:1.0];
        button.layer.cornerRadius = 4;
        button.selectionHandler = ^(CNPPopupButton *button) {
            [self.popupController dismissPopupControllerAnimated:YES];
        };
        
        [contents addObject:button];
        
        self.popupController = [[CNPPopupController alloc] initWithContents:contents];
        self.popupController.theme = [CNPPopupTheme defaultTheme];
        self.popupController.theme.popupStyle = CNPPopupStyleCentered;
        self.popupController.delegate = self;
        
        [self.popupController presentPopupControllerAnimated:YES];
    }
    else
    {
        if ([self.delegate respondsToSelector:@selector(instructionPopupDidDismiss:)]) {
            [self.delegate instructionPopupDidDismiss:self];
        }
    }
}


#pragma mark - CNPPopupController Delegate

- (void)popupControllerWillDismiss:(CNPPopupController *)controller
{
    NSLog(@"Popup controller will dismiss.");
    
    if (self.neverShowCheckbox.checkState == M13CheckboxStateChecked)
    {
        NSLog(@"Instruction controller 'never show' checkbox is checked. Setting key: %@", self.neverShowUserDefaultsKey);
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setBool:YES forKey:self.neverShowUserDefaultsKey];
        [userDefaults synchronize];
    }
}

- (void)popupControllerDidDismiss:(CNPPopupController *)controller
{
    NSLog(@"Popup controller dismissed.");
    
    self.popupController = nil;
    
    if ([self.delegate respondsToSelector:@selector(instructionPopupDidDismiss:)]) {
        [self.delegate instructionPopupDidDismiss:self];
    }
}

- (void)popupControllerDidPresent:(CNPPopupController *)controller
{
    NSLog(@"Popup controller presented.");
}

@end

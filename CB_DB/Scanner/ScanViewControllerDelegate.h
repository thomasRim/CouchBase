//
//  ScanViewControllerDelegate.h
//  Scanner
//
//  Created by Ernest Surudo on 2015-05-31.
//  Copyright (c) 2015 Orthogenic Laboratories. All rights reserved.
//

@class ScanViewController;

@protocol ScanViewControllerDelegate

- (void)scanViewController:(ScanViewController*)scanViewController didSaveModelToPath:(NSString*)modelPath screenshot:(NSString*)screenshotPath;

@end

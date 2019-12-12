//
//  OrderScansViewController.h
//  Scanner
//
//  Created by Kamil Budzynski on 12.05.2015.
//  Copyright (c) 2015 Orthogenic Laboratories. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Scanner-Swift.h"

#import "OrderDetailCollectionViewFlowLayout.h"
#import "ImagePickerDetailViewController.h"
#import "ScanViewControllerDelegate.h"

@class SensorBatteryViewController;
@class Order;

//typedef NS_ENUM(NSInteger, ScanFootSubtypes) {
//    ScanFootSubtypes_NONE = -1,
//    ScanFootSubtypes_ToeUp,
//    ScanFootSubtypes_ToeDown,
//    ScanFootSubtypes_FoamBox,
//    ScanFootSubtypest_PlasterCast,
//};



@interface OrderScansViewController : ImagePickerDetailViewController<
UIToolbarDelegate
, UICollectionViewDataSource
, UICollectionViewDelegate
, UIActionSheetDelegate
, UIAlertViewDelegate
, ScanViewControllerDelegate
>

@property (nonatomic, strong) NSOrderedSet *assetsScans;
@property (nonatomic, strong) NSOrderedSet *assetsPhotos;

@property (weak, nonatomic) IBOutlet SensorBatteryViewController *sensorBatteryViewController;

@property (weak, nonatomic) IBOutlet UIButton *resetOrderButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

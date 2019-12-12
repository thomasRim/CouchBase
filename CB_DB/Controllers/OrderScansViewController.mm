//
//  OrderScansViewController.mm
//  Scanner
//
//  Created by Kamil Budzynski on 12.05.2015.
//  Copyright (c) 2015 Orthogenic Laboratories. All rights reserved.
//

#import "OrderScansViewController.h"

#import "Scanner-Swift.h"

#import <Structure/Structure.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <MagicalRecord/MagicalRecord.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "UIView+UserInfo.h"
#import "UIView+Border.h"

#import "PhotoViewerDetailViewController.h"
#import "AssetDetailViewController.h"
#import "ScanViewController.h"
#import "ModelViewerDetailViewController.h"
#import "ObjFileEditor.h"


#define kAlertViewTagCaption 1
#define kAlertViewTagSaveError 2

static BOOL showPlus = false;

static NSString * const kCaptionAlertViewDictAssetTypeKey = @"kCaptionAlertViewDictAssetTypeKey";
static NSString * const kCaptionAlertViewDictAssetPathKey = @"kCaptionAlertViewDictAssetPathKey";
static NSString * const kCaptionAlertViewDictAssetPreviewPathKey = @"kCaptionAlertViewDictAssetPreviewPathKey";
static NSInteger const kTagFroAddPhoto = 22;
static NSInteger const kTagFroAddScan = 23; // 24 is reserve for right.


@interface OrderScansViewController ()  <OrderDetailCollectionViewCellGalleryDelegate>

@property (nonatomic, retain) UIImage *addIconImage;

@end

@implementation OrderScansViewController

@synthesize collectionView = _collectionView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addChildViewController:self.sensorBatteryViewController];
    
    // create icons
    FAKIcon *addIcon = [FAKIonIcons plusCircledIconWithSize:100];
    [addIcon addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor]];
    _addIconImage = [addIcon imageWithSize:CGSizeMake(100, 100)];
    
    [self registerNotifications];

    UIImageView *imageV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"smoke-bg"]];
    imageV.frame = _collectionView.bounds;
    imageV.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageV.contentMode = UIViewContentModeScaleAspectFit;
    imageV.alpha = 0.2;
    [self.view insertSubview:imageV belowSubview:_collectionView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self.sensorBatteryViewController.view addTopBorderWithColor:[UIColor colorWithWhite:0.7 alpha:1.0]
                                                        andWidth:0.5];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self collectionViewReloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Properties

- (void)updateAssetsList {
    Order *order = [[AuthenticationManager currentPatient] activeOrder];
    NSLog(@"assets: %lu", (unsigned long)order.assets.count);
    
    NSMutableOrderedSet *assetsScans_ = [NSMutableOrderedSet new];
    NSMutableOrderedSet *assetsPhotos_ = [NSMutableOrderedSet new];
    self.assetsScans = assetsScans_;
    self.assetsPhotos = assetsPhotos_;
    for (Asset *asset in order.assets) {
        if ([asset.type isEqualToString:@"scan"]) {
            [assetsScans_ addObject:asset];
            continue;
        }
        if ([asset.type isEqualToString:@"photo"]) {
            [assetsPhotos_ addObject:asset];
            continue;
        }
    }
    NSLog(@"assets: scans: %lu", (unsigned long)self.assetsScans.count);
    NSLog(@"assets: photos: %lu", (unsigned long)self.assetsPhotos.count);
}

- (void)collectionViewReloadData {
    [self updateAssetsList];
    [_collectionView reloadData];
}

#pragma mark -
- (CGSize)sizeForCell:(UICollectionView *)collectionView {
    CGFloat w = CGRectGetWidth(collectionView.frame);
    CGFloat h = CGRectGetHeight(collectionView.frame);
    CGFloat border = 10.0;
    CGSize m = CGSizeMake((w - (2 + 2) * border) / 3
                          , (h - (2 + 2) * border) / 3);
    CGFloat f = MIN(m.width, m.height);
    return CGSizeMake(f, f);
}



#pragma mark - UICollectionView Data Source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assetsScans.count + (showPlus ? 1 : 0) + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellGalleryIdentifier = @"CollectionCellGallery";
    static NSString *cellIdentifier = @"CollectionCell";
    OrderDetailCollectionViewCell *cell = nil;

    
    Asset *asset = nil;
    CGSize s = [self sizeForCell:collectionView];
    if (showPlus && (indexPath.row == self.assetsScans.count)) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.nameLabel.edgeInsets = UIEdgeInsetsMake(0.0, 8.0, 0.0, 8.0);
        cell.nameLabel.text = NSLocalizedString(@"OAddAssetPhoto", nil);
        cell.backgroundImage.image = _addIconImage;
        [self updateDecoration:cell s:s];
        return cell;
    }

    if (indexPath.row < self.assetsScans.count) {
        asset = [self.assetsScans objectAtIndex:indexPath.row];
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        cell.nameLabel.edgeInsets = UIEdgeInsetsMake(0.0, 8.0, 0.0, 8.0);
        
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellGalleryIdentifier forIndexPath:indexPath];
        if ([cell isKindOfClass:[OrderDetailCollectionViewCellGallery class]]) {
            OrderDetailCollectionViewCellGallery *g = (OrderDetailCollectionViewCellGallery *)cell;
            g.assetsPhotos = self.assetsPhotos;
            g.delegate = self;
            [g prepareGallery];
            return cell;
        }
    }
    
    if (asset.caption.length) {
        cell.nameLabel.text = asset.caption;
        cell.nameLabel.hidden = NO;
        if ( !asset.isDeletableValue ) {
            cell.nameLabel.text  = cell.nameLabel.text.uppercaseString;
        }
    } else {
        cell.nameLabel.hidden = YES;
    }

    UIImage *image = [[UIImage alloc] initWithData:asset.previewData];
    if (image) {
        cell.backgroundImage.image = image;
        [self updateDecoration:cell s:s];
        return cell;
    } else if (asset.placeholderImage) {
        cell.backgroundImage.image = [asset.placeholderImage resize:CGSizeMake(s.width / 2, s.height / 2)];
    }
    
    if ( asset.isDeletableValue ) {
        cell.backgroundImage.image = nil;
        [self updateDecoration:cell s:s];
        return cell;
    }
    [self updateDecoration:cell s:s];

    return cell;
}

- (void)updateDecoration:(OrderDetailCollectionViewCell *)cell s:(CGSize)s {
   
    
    cell.backgroundImage.borderColorExt = UIColor.lightGrayColor;
    cell.backgroundImage.borderWidthExt = 7;
    
    cell.backgroundImage.cornerRadiusExt = s.width / 2.5;
    
    cell.backgroundImage.backgroundColor = UIColor.whiteColor;
    cell.backgroundImage.contentMode = UIViewContentModeCenter;
    
    cell.backgroundColor = [UIColor clearColor];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(10, 0, 0, 0);
}

#pragma mark - OrderDetailCollectionViewCellGalleryDelegate methods

- (void)selectedPhotoAssetWithAsset:(Asset *)asset forGallery:(OrderDetailCollectionViewCellGallery *)forGallery {
    [self presentViewPhotoAssetOld:asset];
}

- (void)plusPressedWithCell:(UICollectionViewCell *)cell forGallery:(OrderDetailCollectionViewCellGallery *)forGallery {
    NSIndexPath *i = [NSIndexPath indexPathForItem:0 inSection:0];
    
    UICollectionViewCell *c = [forGallery collectionView:forGallery.collection cellForItemAtIndexPath:i];
    [self showPhotoMenu:c.frame index:forGallery.collection];
}

- (void)orderPhotoWithCell:(UICollectionViewCell *)cell forGallery:(OrderDetailCollectionViewCellGallery *)forGallery {
    [self showImagePickerForCamera:self];
}

#pragma mark - CollectionViewFlowLayout Methods


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize s = [self sizeForCell:collectionView];

    NSLog(@"aaaaaaaaa = %@", indexPath);
    NSInteger i = indexPath.item;
    if (i < self.assetsScans.count + (showPlus ? 1 : 0)) {
        return s;
    }
    
    CGFloat w = CGRectGetWidth(collectionView.frame);
    
    if (showPlus == false) {
        return CGSizeMake(w, s.height + 10);
    }
    return CGSizeMake(10.0 + (s.width + 10.0) * 2.0, s.height + 10.0);
}


#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (showPlus && (indexPath.item == self.assetsScans.count)) {
        
        UICollectionViewCell *cell = [self collectionView:collectionView cellForItemAtIndexPath:indexPath];
        [self showPhotoMenu:cell.frame index:collectionView];
        return;
    }

    if (indexPath.item > self.assetsScans.count) { return; }

    Asset *asset = nil;
    if (indexPath.row < self.assetsScans.count) {
        asset = [self.assetsScans objectAtIndex:indexPath.row];
    } else {
        asset = [self.assetsPhotos objectAtIndex:indexPath.row - (self.assetsScans.count + (showPlus ? 1 : 0))];
    }

    if (asset.data == nil) {
        
        if ((indexPath.item == 0) || (indexPath.item == 1)) {
            [self showScanMenu:collectionView type:indexPath.item index:indexPath];
            return;
        }
        
        // create the asset (it's currently a placeholder)
        if ([asset.type isEqualToString:@"scan"]) {
            [self presentScanViewControllerWithAsset:asset option:ScanFootSubtypes_NONE];
        } else {
            NSLog(@"Asset with unknown type");
        }
        return;
    }
    [self presentViewPhotoAssetOld:asset];

}

- (void)showPhotoMenu:(CGRect)rect index:(UIView *)collectionView_
{
    UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:nil
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:
                                   NSLocalizedString(@"0PhotoTake", nil)
                                   , NSLocalizedString(@"0PhotoChoose", nil)
                                   , nil];
    [actionSheet setTag:kTagFroAddPhoto];
    [actionSheet showFromRect:rect inView:collectionView_ animated:YES];
}

- (void)showScanMenu:(UICollectionView *)collectionView type:(NSInteger)leftOrRight index:(NSIndexPath *)indexPath {
    UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:nil
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:
                                   NSLocalizedString(@"O3DScan_Foot_ToeUp", nil)
                                   , NSLocalizedString(@"O3DScan_Foot_ToeDown", nil)
                                   , NSLocalizedString(@"O3DScan_Foot_FoamBox", nil)
                                   , NSLocalizedString(@"O3DScan_Foot_PlasterCast", nil)
                                   //                                   , NSLocalizedString(@"O3DScan", nil)
                                   , nil];
    
    UICollectionViewCell *cell = [self collectionView:_collectionView cellForItemAtIndexPath:indexPath];
    [actionSheet setTag:kTagFroAddScan + leftOrRight];
    [actionSheet showFromRect:cell.frame inView:collectionView animated:YES];
}



#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex  // after animation
{
    if (kTagFroAddPhoto == actionSheet.tag) {
        switch (buttonIndex) {
            case 0: [self showImagePickerForCamera:self]; return;
            case 1: [self showImagePickerForPhotoPicker:self]; return;
            default: return;
        }
        return;
    }
    if (kTagFroAddScan == actionSheet.tag) {
        NSInteger assetOrderId = 0;
        Asset *asset = nil;
        if (assetOrderId < self.assetsScans.count) {
            asset = [self.assetsScans objectAtIndex:assetOrderId];
        }
        
        switch (buttonIndex) {
            case 0: [self presentScanViewControllerWithAsset:asset option:ScanFootSubtypes_ToeUp]; return;
            case 1: [self presentScanViewControllerWithAsset:asset option:ScanFootSubtypes_ToeDown]; return;
            case 2: [self presentScanViewControllerWithAsset:asset option:ScanFootSubtypes_FoamBox]; return;
            case 3: [self presentScanViewControllerWithAsset:asset option:ScanFootSubtypest_PlasterCast]; return;
            default: return;
        }
        return;
    }
    if (kTagFroAddScan + 1 == actionSheet.tag) {
        NSInteger assetOrderId = 1;
        Asset *asset = nil;
        if (assetOrderId < self.assetsScans.count) {
            asset = [self.assetsScans objectAtIndex:assetOrderId];
        }
        switch (buttonIndex) {
            case 0: [self presentScanViewControllerWithAsset:asset option:ScanFootSubtypes_ToeUp]; return;
            case 1: [self presentScanViewControllerWithAsset:asset option:ScanFootSubtypes_ToeDown]; return;
            case 2: [self presentScanViewControllerWithAsset:asset option:ScanFootSubtypes_FoamBox]; return;
            case 3: [self presentScanViewControllerWithAsset:asset option:ScanFootSubtypest_PlasterCast]; return;
            default: return;
        }
        return;
    }
}


#pragma mark - UIImagePickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    self.imageData = UIImageJPEGRepresentation(image, 1.0);
    [self dismissViewControllerAnimated:YES completion:nil];
    [self showCaptionAlertViewWithUserInfo:@{ kCaptionAlertViewDictAssetTypeKey: @"photo" }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    Order *order = [[AuthenticationManager currentPatient]  activeOrder];
    
    if (alertView.tag == kAlertViewTagCaption) {
        NSString *caption = [alertView textFieldAtIndex:0].text;
        if ([alertView.userInfo[kCaptionAlertViewDictAssetTypeKey] isEqualToString:@"photo"]) {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"OSavingPhoto", nil)];
            
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                [[order MR_inContext:localContext] addNewPhotoAssetWithPhotoData:self.imageData caption:caption inContext:localContext];
                self.imageData = nil;
            } completion:^(BOOL success, NSError *error) {
                [SVProgressHUD dismiss];
                [self collectionViewReloadData];
            }];
        } else if ([alertView.userInfo[kCaptionAlertViewDictAssetTypeKey] isEqualToString:@"scan"]) {
            [SVProgressHUD showWithStatus:NSLocalizedString(@"OSavingScan", nil)];
            
            __block BOOL success;
            
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                success = [[order MR_inContext:localContext] addNew3DAssetWithDataPath:alertView.userInfo[kCaptionAlertViewDictAssetPathKey]
                                                                        previewDataPath:alertView.userInfo[kCaptionAlertViewDictAssetPreviewPathKey]
                                                                                caption:caption
                                                                           deviceSerial:[[STSensorController sharedController] getSerialNumber]
                                                                              inContext:localContext];
            } completion:^(BOOL success, NSError *error) {
                if (!success) {
                    [self showErrorSavingScanAlertView];
                }
                
                // clean up temp dir, but don't care about failure (OS will take care of it at some point anyways)
                [[NSFileManager defaultManager] removeItemAtPath:alertView.userInfo[kCaptionAlertViewDictAssetPathKey] error:nil];
                [[NSFileManager defaultManager] removeItemAtPath:alertView.userInfo[kCaptionAlertViewDictAssetPreviewPathKey] error:nil];
                
                [SVProgressHUD dismiss];
                [self collectionViewReloadData];
            }];
        }
    }
}


#pragma mark - ScanViewControllerDelegate methods





- (void)scanViewController:(ScanViewController*)scanViewController didSaveModelToPath:(NSString *)modelPath screenshot:(NSString *)screenshotPath
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    // TODO do this in background and display spinner?
    
    if (scanViewController.asset) {
        // existing asset (placeholder)
        Asset *asset = scanViewController.asset;
        ScanFootSubtypes option = scanViewController.optionOfLeftRightFoot;
        
        NSString *caption = asset.caption;
        
        if (option != ScanFootSubtypes_NONE) {
            // Update caption.
            switch (option) {
                case ScanFootSubtypes_NONE:
                    break;
                case ScanFootSubtypes_ToeUp:
                    asset.scanType = @"ToeUp";
                    break;
                case ScanFootSubtypes_ToeDown:
                    asset.scanType = @"ToeDown";
                    break;
                case ScanFootSubtypes_FoamBox:
                    asset.scanType = @"FoamBox";
                    break;
                case ScanFootSubtypest_PlasterCast:
                    asset.scanType = @"PlasterCast";
                    break;
            }
        }
        
        __block BOOL success;
        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
            Asset *localAsset = [asset MR_inContext:localContext];
            localAsset.caption = caption;
            success = [localAsset changeDataWithPath:modelPath previewDataPath:screenshotPath];
            if (success) {
                localAsset.deviceSerial = [[STSensorController sharedController] getSerialNumber];
            }
        }];
        
        if (!success) {
            [self showErrorSavingScanAlertView];
        }
        
        // clean up temp dir, but don't care about failure (OS will take care of it at some point anyways)
        [[NSFileManager defaultManager] removeItemAtPath:modelPath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:screenshotPath error:nil];
        
        [self collectionViewReloadData];
    } else {
        // new asset
        [self showCaptionAlertViewWithUserInfo:@{ kCaptionAlertViewDictAssetTypeKey: @"scan",
                                                  kCaptionAlertViewDictAssetPathKey: modelPath,
                                                  kCaptionAlertViewDictAssetPreviewPathKey: screenshotPath }];
    }
}


#pragma mark - Notifications

- (void)orderDidChange:(NSNotification*)notification
{
    [self collectionViewReloadData];
}


#pragma mark - Privates

- (void)registerNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orderDidChange:)
                                                 name:kOrderDidChangeNotification object:nil];
}

- (void)showCaptionAlertViewWithUserInfo:(NSDictionary*)userInfo
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                        message:[userInfo[kCaptionAlertViewDictAssetTypeKey] isEqualToString:@"scan"] ? NSLocalizedString(@"OCaptionScan", nil) : NSLocalizedString(@"OCaptionPhoto", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"COk", nil)
                                              otherButtonTitles: nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertView.tag = kAlertViewTagCaption;
    alertView.userInfo = userInfo;
    
    [alertView show];
}

- (void)showErrorSavingScanAlertView
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"OSaveErrorTitle", nil)
                                                        message:NSLocalizedString(@"OSaveErrorDescription", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"COk", nil)
                                              otherButtonTitles: nil];
    alertView.tag = kAlertViewTagSaveError;
    
    [alertView show];
}

- (void)presentScanViewControllerWithAsset:(Asset*)asset option:(ScanFootSubtypes)option
{
    //    ScannerMode mode = ScannerModeFoot;
    ScannerMode mode = ScannerModeFoot; /// !!!
    if ([asset.caption.lowercaseString containsString:@"foot"]) {
        mode = ScannerModeFoot;
    } else {
        mode = ScannerModeWeightBearing;
    }
    
    ScanViewController *scanViewController = [[ScanViewController alloc] initWithNibName:@"ScanViewController_iPad" bundle:nil];
    scanViewController.delegate = self;
    scanViewController.asset = asset;
    scanViewController.forceColorScan = NO;
    scanViewController.scannerMode = mode;
    scanViewController.optionOfLeftRightFoot = option;
    
    UINavigationController *scanNavigationController = [[UINavigationController alloc] initWithRootViewController:scanViewController];
    scanNavigationController.navigationBar.translucent = NO;
    scanNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:scanNavigationController animated:YES completion:NULL];
}

- (void)presentViewPhotoAsset:(Asset *)asset {
    // view the asset
    AssetDetailViewController *assetViewer;
    if ([asset.type isEqualToString:@"scan"]) {
        assetViewer = [[UIStoryboard storyboardWithName:@"Scans" bundle:nil] instantiateViewControllerWithIdentifier:@"ModelViewerDetailViewController"];
    } else if ([asset.type isEqualToString:@"photo"]) {
        assetViewer = [[UIStoryboard storyboardWithName:@"Scans" bundle:nil] instantiateViewControllerWithIdentifier:@"PhotoViewerController"];
    } else {
        NSLog(@"Asset with unknown type");
        return;
    }
    
    assetViewer.asset = asset;
    [self.navigationController pushViewController:assetViewer animated:YES];
}

- (void)presentViewPhotoAssetOld:(Asset *)asset {
    NSParameterAssert(asset != nil);
    NSParameterAssert(asset.data != nil);
    // view the asset
    AssetDetailViewController *assetViewer;
    if ([asset.type isEqualToString:@"scan"])
    {
        assetViewer = [[UIStoryboard storyboardWithName:@"Scans" bundle:nil] instantiateViewControllerWithIdentifier:@"ModelViewerDetailViewController"];
    }
    else if ([asset.type isEqualToString:@"photo"])
    {
        assetViewer = [[UIStoryboard storyboardWithName:@"Scans" bundle:nil] instantiateViewControllerWithIdentifier:@"PhotoViewerController"];
    }
    else
    {
        NSLog(@"Asset with unknown type");
        return;
    }
    assetViewer.asset = asset;
    [self.navigationController pushViewController:assetViewer animated:YES];
}

@end

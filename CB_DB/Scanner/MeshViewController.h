/*
  This file is part of the Structure SDK.
  Copyright © 2015 Occipital, Inc. All rights reserved.
  http://structure.io
*/

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <Structure/StructureSLAM.h>
#import "EAGLView.h"

@class MeshViewController;

@protocol MeshViewDelegate <NSObject>

- (void)meshViewWillDismiss:(MeshViewController*)controller;
- (void)meshViewDidDismiss:(MeshViewController*)controller;
- (BOOL)meshView:(MeshViewController*)controller
            didRequestColorizing:(STMesh*)mesh
            previewCompletionHandler:(void(^)(void))previewCompletionHandler
            enhancedCompletionHandler:(void(^)(void))enhancedCompletionHandler;
- (void)meshView:(MeshViewController*)controller
            didSaveModelToPath:(NSString*)modelPath screenshot:(NSString*)screenshotPath;

@optional
- (void)meshViewWillSaveModel:(MeshViewController*)controller;
- (void)meshView:(MeshViewController*)controller didFailSavingModel:(NSError*)error;

@end

@interface MeshViewController : UIViewController <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id<MeshViewDelegate> delegate;

@property (nonatomic) BOOL needsDisplay; // force the view to redraw.
@property (nonatomic) BOOL colorEnabled;
@property (nonatomic) STMesh * mesh;

@property (weak, nonatomic) IBOutlet UISegmentedControl *displayControl;
@property (weak, nonatomic) IBOutlet UILabel *meshViewerMessageLabel;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveScanButton;

- (IBAction)displayControlChanged:(id)sender;

- (void)showMeshViewerMessage:(NSString *)msg;
- (void)hideMeshViewerMessage;

- (void)setCameraProjectionMatrix:(GLKMatrix4)projRt;
- (void)resetMeshCenter:(GLKVector3)center;

- (void)setupGL:(EAGLContext*)context;

@end

/*
  This file is part of the Structure SDK.
  Copyright © 2015 Occipital, Inc. All rights reserved.
  http://structure.io
*/

//#include "CB_DB-Swift.h"

#import "ScanViewController.h"
#import "ScanViewController+Camera.h"
#import "ScanViewController+Sensor.h"
#import "ScanViewController+SLAM.h"
#import "ScanViewController+OpenGL.h"
#import "CustomUIKitStyles.h"
#import "InstructionPopupController.h"

#import <AudioToolbox/AudioToolbox.h>

#include <cmath>

// Needed to determine platform string
#include <sys/types.h>
#include <sys/sysctl.h>


NSString * const kCountdownTimerSecsLeftUserInfoKey = @"kCountdownTimerSecsLeftUserInfoKey";

NSString * const kEnable5secTimerUserDefaultsKey = @"kEnable5secTimerUserDefaultsKey";
NSString * const kEnableColorImageUserDefaultsKey = @"kEnableColorImageUserDefaultsKey";
NSString * const kEnableHighResolutionColorUserDefaultsKey = @"kEnableHighResolutionColorUserDefaultsKey";

NSString * const kHideAlignAndLockInstructionUserDefaultsKey = @"kHideAlignAndLockInstructionUserDefaultsKey";
NSString * const kHideVerifyAndScanInstructionUserDefaultsKey = @"kHideVerifyAndScanInstructionUserDefaultsKey";

#pragma mark - Utilities

namespace // anonymous namespace for local functions.
{
    BOOL isIpadAir2()
    {
        const char* kernelStringName = "hw.machine";
        NSString* deviceModel;
        {
            size_t size;
            sysctlbyname(kernelStringName, NULL, &size, NULL, 0); // Get the size first
            
            char *stringNullTerminated = (char*)malloc(size);
            sysctlbyname(kernelStringName, stringNullTerminated, &size, NULL, 0); // Now, get the string itself
            
            deviceModel = [NSString stringWithUTF8String:stringNullTerminated];
            free(stringNullTerminated);
        }
        
        if ([deviceModel isEqualToString:@"iPad5,3"]) return YES; // Wi-Fi
        if ([deviceModel isEqualToString:@"iPad5,4"]) return YES; // Wi-Fi + LTE
        
        return NO;
    }
    
    BOOL getDefaultHighResolutionSettingForCurrentDevice()
    {
        // iPad Air 2 can handle 30 FPS high-resolution, so enable it by default.
        if (isIpadAir2())
            return TRUE;
        
        // Older devices can only handle 15 FPS high-resolution, so keep it disabled by default
        // to avoid showing a low framerate.
        return FALSE;
    }
} // anonymous

@interface ScanViewController () <InstructionPopupControllerDelegate>

@property (nonatomic, assign) BOOL transitionedBackFromViewer;
@property (nonatomic, strong) InstructionPopupController *instructionPopupController;

- (void)hideCountdownTimerMessageAnimated:(BOOL)animated;
- (void)showCountdownTimerMessageWithCountdown:(NSInteger)secsLeft animated:(BOOL)animated;
- (void)countdownTimerDidFire:(NSTimer*)timer;

@end

static UIFont *switchOffFont;
static UIFont *switchOnFont;
static UIColor *switchOnColor;
static UIColor *switchOffColor;

@implementation ScanViewController

@synthesize delegate = _delegate;
@synthesize transitionedBackFromViewer = _transitionedBackFromViewer;

@synthesize meshViewController = _meshViewController;

+ (void)initialize
{
    switchOnFont = [UIFont boldSystemFontOfSize:17.0];
    switchOffFont = [UIFont systemFontOfSize:17.0];
    switchOnColor = [UIColor whiteColor];
    switchOffColor = [UIColor colorWithWhite:0.9 alpha:1.0];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"ScanViewController – viewDidLoad");
    
    _calibrationOverlay = nil;
    _options.initialVolumeSizeInMeters = _scannerMode == ScannerModeFoot ? GLKVector3Make(0.2f, 0.4f, 0.2f) : GLKVector3Make(0.5f, 0.5f, 0.5f);
    
    [self setupGL];
    [self setupUserInterface];
    [self setupGestures];
    [self setupIMU];
    [self setupStructureSensor];
    
    // Later, we’ll set this true if we have a device-specific calibration
    _useColorCamera = [STSensorController approximateCalibrationGuaranteedForDevice];
    
    // Make sure we get notified when the app becomes active to start/restore the sensor state if necessary.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"ScanViewController – viewWillAppear");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSLog(@"ScanViewController – viewDidAppear");
    
    // The framebuffer will only be really ready with its final size after the view appears.
    [self.glView setFramebuffer];
    [self setupGLViewport];
    [self updateAppStatusMessage];
    [self appDidBecomeActive];
    
    if (_transitionedBackFromViewer) {
        _meshViewController = nil;
        
        _appStatus.statusMessageDisabled = false;
        [self updateAppStatusMessage];
        
        [self connectToStructureSensorAndStartStreaming];
        [self resetSLAM];
        
        _transitionedBackFromViewer = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"ScanViewController – viewWillDisappear");
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"ScanViewController – viewDidDisappear");
}

- (void)appDidBecomeActive
{
    if ([self currentStateNeedsSensor])
        [self connectToStructureSensorAndStartStreaming];
    
    // Abort the current scan if we were still scanning before going into background since we
    // are not likely to recover well.
    if (_slamState.scannerState == ScannerStateScanning)
    {
        [self resetButtonPressed:self];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    [self respondToMemoryWarning];
}

- (void)dealloc
{
    NSLog(@"ScanViewController – dealloc");
    
    [self.avCaptureSession stopRunning];
    
    if ([EAGLContext currentContext] == _display.context)
    {
        [EAGLContext setCurrentContext:nil];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _sensorController.delegate = nil;
}

- (void)setupUserInterface
{
    // Make sure the status bar is hidden.
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"CCancel", nil)
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(cancelButtonPressed:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    self.navigationItem.title = NSLocalizedString(@"STakeScan", nil);
    
    self.trackingLostLabel.edgeInsets = UIEdgeInsetsMake(0.0, 20.0, 0.0, 20.0);
    
    // Fully transparent message label, initially.
    self.appStatusMessageLabel.alpha = 0;
    
    // Make sure the label is on top of everything else.
    self.appStatusMessageLabel.layer.zPosition = 100;
    
    // Countdown timer label
    self.countdownTimerLabel.alpha = 0.0;
    self.countdownTimerLabel.hidden = YES;
    [self.countdownTimerLabel applyCustomStyleWithBackgroundColor:blackLabelColorWithLightAlpha];
    
    // Load user defaults
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.enable5secTimerSwitch.on = [userDefaults boolForKey:kEnable5secTimerUserDefaultsKey];
    self.enableColorSwitch.on = [userDefaults boolForKey:kEnableColorImageUserDefaultsKey];
    self.enableHighResolutionColorSwitch.enabled = NO;
    self.enableHighResolutionColorSwitch.on = NO;
    
    if (self.forceColorScan) {
        self.enableColorSwitch.enabled = NO;
        self.enableColorSwitch.on = YES;
    } else {
//        if ([userDefaults objectForKey:kEnableHighResolutionColorUserDefaultsKey] != nil) {
//            // user set this already
//            self.enableHighResolutionColorSwitch.on = [userDefaults boolForKey:kEnableHighResolutionColorUserDefaultsKey];
//        } else {
//            // Set the default value for the high resolution switch. If set, will use 2592x1968 as color input.
//            self.enableHighResolutionColorSwitch.on = getDefaultHighResolutionSettingForCurrentDevice();
//        }
    }
    
    // Play sounds
    playSound = YES;
    
    [self updateOffLabel:self.enable5secTimerOffLabel onLabel:self.enable5secTimerOnLabel basedOnSwitch:self.enable5secTimerSwitch];
    [self updateOffLabel:self.enableColorOffLabel onLabel:self.enableColorOnLabel basedOnSwitch:self.enableColorSwitch];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (void)setupGestures
{
    // Register pinch gesture for volume scale adjustment.
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [pinchGesture setDelegate:self];
    [self.glView addGestureRecognizer:pinchGesture];
}

- (void)presentMeshViewer:(STMesh *)mesh
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        _meshViewController = [[MeshViewController alloc] initWithNibName:@"MeshView_iPhone" bundle:nil];
    } else {
        _meshViewController = [[MeshViewController alloc] initWithNibName:@"MeshView_iPad" bundle:nil];
    }
    _meshViewController.delegate = self;
    
    [_meshViewController setupGL:_display.context];
    
    _meshViewController.colorEnabled = _useColorCamera;
    _meshViewController.mesh = mesh;
    [_meshViewController setCameraProjectionMatrix:_display.depthCameraGLProjectionMatrix];
    _meshViewController.colorEnabled = self.enableColorSwitch.on;
    
    GLKVector3 volumeCenter = GLKVector3MultiplyScalar([_slamState.mapper volumeSizeInMeters], 0.5);
    [_meshViewController resetMeshCenter:volumeCenter];
    
    [self.navigationController pushViewController:_meshViewController animated:YES];
}

- (void)enterCubePlacementState
{
    self.settingsView.hidden = NO;
    self.didResetDistance = NO;
    
    // Switch to the Scan button.
    self.scanButton.hidden = NO;
    self.doneButton.hidden = YES;
    self.resetButton.hidden = YES;
    
    // We'll enable the button only after we get some initial pose.
    self.scanButton.enabled = NO;
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    self.crosshairImageView.hidden = NO;
    self.lockButton.hidden = NO;
    
    [self setColorCameraParametersForInit];
    
    _slamState.scannerState = ScannerStateCubePlacement;
    
    [self updateIdleTimer];
}

- (void)enterScanningState
{
    self.settingsView.hidden = YES;
    self.scanButton.hidden = YES;
    self.doneButton.hidden = NO;
    self.resetButton.hidden = NO;
    self.crosshairImageView.hidden = YES;
    self.lockButton.hidden = YES;
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    // Tell the mapper if we have a support plane so that it can optimize for it.
    [_slamState.mapper setHasSupportPlane:_slamState.cameraPoseInitializer.hasSupportPlane];
    
    _slamState.tracker.initialCameraPose = _slamState.cameraPoseInitializer.cameraPose;
    
    // We will lock exposure during scanning to ensure better coloring.
    [self setColorCameraParametersForScanning];
    
    _slamState.scannerState = ScannerStateScanning;
    
//    if (playSound) {
//        AudioServicesPlaySystemSound(1108);
//    }
    
    if (self.enable5secTimerSwitch.on) {
        NSInteger secsLeft = 6;
        [self showCountdownTimerMessageWithCountdown:secsLeft animated:NO];
        countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                          target:self selector:@selector(countdownTimerDidFire:)
                                                        userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:(secsLeft-1)], kCountdownTimerSecsLeftUserInfoKey, nil]
                                                         repeats:YES];
    }
}

- (void)enterViewingState
{
    // Cannot be lost in view mode.
    [self hideTrackingErrorMessage];
    
    _appStatus.statusMessageDisabled = true;
    [self updateAppStatusMessage];
    
    self.settingsView.hidden = YES;
    self.scanButton.hidden = YES;
    self.doneButton.hidden = YES;
    self.resetButton.hidden = YES;
    self.crosshairImageView.hidden = YES;
    self.lockButton.hidden = YES;
    
    [_sensorController stopStreaming];

    if (_useColorCamera)
        [self stopColorCamera];
    
    [_slamState.mapper finalizeTriangleMeshWithSubsampling:1];
    
    STMesh *mesh = [_slamState.scene lockAndGetSceneMesh];
    
    [self presentMeshViewer:mesh];
    
    [_slamState.scene unlockSceneMesh];
    
    _slamState.scannerState = ScannerStateViewing;
    
    [self updateIdleTimer];
}

namespace { // anonymous namespace for utility function.
    
    float keepInRange(float value, float minValue, float maxValue)
    {
        if (isnan (value))
            return minValue;
        
        if (value > maxValue)
            return maxValue;
        
        if (value < minValue)
            return minValue;
        
        return value;
    }
    
}

- (void)adjustVolumeSize:(GLKVector3)volumeSize
{
    // Make sure the volume size remains between 10 centimeters and 10 meters.
    volumeSize.x = keepInRange (volumeSize.x, 0.1, 10.f);
    volumeSize.y = keepInRange (volumeSize.y, 0.1, 10.f);
    volumeSize.z = keepInRange (volumeSize.z, 0.1, 10.f);
    
    _slamState.mapper.volumeSizeInMeters = volumeSize;
    
    _slamState.cameraPoseInitializer.volumeSizeInMeters = volumeSize;
    [_display.cubeRenderer adjustCubeSize:_slamState.mapper.volumeSizeInMeters
                         volumeResolution:_slamState.mapper.volumeResolution];
}


#pragma mark -  Structure Sensor Management

-(BOOL)currentStateNeedsSensor
{
    switch (_slamState.scannerState)
    {
        // Initialization and scanning need the sensor.
        case ScannerStateCubePlacement:
        case ScannerStateScanning:
            return TRUE;
            
        // Other states don't need the sensor.
        default:
            return FALSE;
    }
}


#pragma mark - IMU

- (void)setupIMU
{
    _lastGravity = GLKVector3Make (0,0,0);
    
    // 60 FPS is responsive enough for motion events.
    const float fps = 60.0;
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.accelerometerUpdateInterval = 1.0/fps;
    _motionManager.gyroUpdateInterval = 1.0/fps;
    
    // Limiting the concurrent ops to 1 is a simple way to force serial execution
    _imuQueue = [[NSOperationQueue alloc] init];
    [_imuQueue setMaxConcurrentOperationCount:1];
    
    __weak ScanViewController *weakSelf = self;
    CMDeviceMotionHandler dmHandler = ^(CMDeviceMotion *motion, NSError *error)
    {
        // Could be nil if the self is released before the callback happens.
        if (weakSelf) {
            [weakSelf processDeviceMotion:motion withError:error];
        }
    };
    
    [_motionManager startDeviceMotionUpdatesToQueue:_imuQueue withHandler:dmHandler];
}

- (void)processDeviceMotion:(CMDeviceMotion *)motion withError:(NSError *)error
{
    if (_slamState.scannerState == ScannerStateCubePlacement)
    {
        // Update our gravity vector, it will be used by the cube placement initializer.
        _lastGravity = GLKVector3Make (motion.gravity.x, motion.gravity.y, motion.gravity.z);
//        NSLog(@"Gravity %.2f, %.2f, %.2f, ", motion.gravity.x, motion.gravity.y, motion.gravity.z);
    }
    
    if ((_slamState.scannerState == ScannerStateCubePlacement) || _slamState.scannerState == ScannerStateScanning)
    {
        // The tracker is more robust to fast moves if we feed it with motion data.
        [_slamState.tracker updateCameraPoseWithMotion:motion];
    }
}


#pragma mark - Actions

- (IBAction)enable5secTimerSwitchChanged:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:self.enable5secTimerSwitch.on forKey:kEnable5secTimerUserDefaultsKey];
    [userDefaults synchronize];
    
    [self updateOffLabel:self.enable5secTimerOffLabel onLabel:self.enable5secTimerOnLabel basedOnSwitch:self.enable5secTimerSwitch];
}

- (IBAction)enableNewTrackerSwitchChanged:(id)sender
{
    // Save the volume size.
    GLKVector3 previousVolumeSize = _options.initialVolumeSizeInMeters;
    if (_slamState.initialized)
        previousVolumeSize = _slamState.mapper.volumeSizeInMeters;
    
    // Simulate a full reset to force a creation of a new tracker.
    [self resetButtonPressed:self.resetButton];
    [self clearSLAM];
    [self setupSLAM];
    
    // Restore the volume size cleared by the full reset.
    _slamState.mapper.volumeSizeInMeters = previousVolumeSize;
    [self adjustVolumeSize:_slamState.mapper.volumeSizeInMeters];
}

- (IBAction)enableColorSwitchChanged:(id)sender
{
    self.enableHighResolutionColorSwitch.enabled = self.enableColorSwitch.on;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:self.enableColorSwitch.on forKey:kEnableColorImageUserDefaultsKey];
    [userDefaults synchronize];
    
    [self updateOffLabel:self.enableColorOffLabel onLabel:self.enableColorOnLabel basedOnSwitch:self.enableColorSwitch];
}

- (IBAction)enableHighResolutionColorSwitchChanged:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:self.enableHighResolutionColorSwitch.on forKey:kEnableHighResolutionColorUserDefaultsKey];
    [userDefaults synchronize];
    
    if (self.avCaptureSession)
    {
        [self stopColorCamera];
        if (_useColorCamera)
            [self startColorCamera];
    }
    
    // Force a scan reset since we cannot changing the image resolution during the scan is not
    // supported by STColorizer.
    [self resetButtonPressed:self.resetButton];
}

- (IBAction)scanButtonPressed:(id)sender
{
    if (self.enable5secTimerSwitch.on)
    {
        self.scanButton.hidden = YES;
        self.resetButton.hidden = NO;
        self.lockButton.hidden = YES;
        self.settingsView.hidden = YES;
        [self hideTrackingErrorMessage];
        
        [self resetCountdownTimer];
        
        NSInteger secsLeft = 5;
        [self showCountdownTimerMessageWithCountdown:secsLeft animated:NO];
        countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                          target:self selector:@selector(countdownTimerDidFire:)
                                                        userInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:(secsLeft-1)], kCountdownTimerSecsLeftUserInfoKey, nil]
                                                         repeats:YES];
    }
    else
    {
        [self enterScanningState];
    }
}

- (IBAction)resetButtonPressed:(id)sender
{
    if (countdownTimer) {
        [self resetCountdownTimer];
        [self enterCubePlacementState];
    } else {
        [self resetSLAM];
    }
}

- (IBAction)doneButtonPressed:(id)sender
{
    [self resetCountdownTimer];
    [self enterViewingState];
}

- (IBAction)cancelButtonPressed:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SCancelAlertTitle", nil)
                                                        message:NSLocalizedString(@"SCancelAlertDescription", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"CCancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"COk", nil), nil];
    [alertView show];
}

- (void)pinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan)
    {
        if (_slamState.scannerState == ScannerStateCubePlacement)
        {
            _volumeScale.initialPinchScale = _volumeScale.currentScale / [gestureRecognizer scale];
        }
    }
    else if ([gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        if(_slamState.scannerState == ScannerStateCubePlacement && _options.shouldPinchScale)
        {
            // In some special conditions the gesture recognizer can send a zero initial scale.
            if (!isnan(_volumeScale.initialPinchScale))
            {
                _volumeScale.currentScale = [gestureRecognizer scale] * _volumeScale.initialPinchScale;
                
                // Don't let our scale multiplier become absurd
                _volumeScale.currentScale = keepInRange(_volumeScale.currentScale, 0.01, 1000.f);
                
                GLKVector3 newVolumeSize = GLKVector3MultiplyScalar(_options.initialVolumeSizeInMeters, _volumeScale.currentScale);
                
                [self adjustVolumeSize:newVolumeSize];
            }
        }
    }
}

- (IBAction)resetDistance:(id)sender
{
    shouldResetDistance = YES;
}


#pragma mark - MeshViewController delegates

- (void)meshViewWillDismiss:(MeshViewController*)controller
{
    NSLog(@"ScanViewController – meshViewWillDismiss");
    
    // If we are running colorize work, we should cancel it.
    if (_naiveColorizeTask)
    {
        [_naiveColorizeTask cancel];
        _naiveColorizeTask = nil;
    }
    if (_enhancedColorizeTask)
    {
        [_enhancedColorizeTask cancel];
        _enhancedColorizeTask = nil;
    }
    
    [_meshViewController hideMeshViewerMessage];
}

- (void)meshViewDidDismiss:(MeshViewController*)controller
{
    NSLog(@"ScanViewController – meshViewDidDismiss");
    _transitionedBackFromViewer = YES;
}

- (void)meshView:(MeshViewController*)controller didSaveModelToPath:(NSString *)modelPath screenshot:(NSString *)screenshotPath
{
    [self dismissViewControllerAnimated:NO completion:NULL];
    
//    if ([_delegate respondsToSelector:@selector(scanViewController:didSaveModelToPath:screenshot:)]) {
        [_delegate scanViewController:self didSaveModelToPath:modelPath screenshot:screenshotPath];
//    }
}

- (BOOL)meshView:(MeshViewController*)controller didRequestColorizing:(STMesh*)mesh previewCompletionHandler:(void (^)())previewCompletionHandler enhancedCompletionHandler:(void (^)())enhancedCompletionHandler
{
    if (_naiveColorizeTask) // already one running?
    {
        NSLog(@"Already one colorizing task running!");
        return FALSE;
    }
    
    _naiveColorizeTask = [STColorizer
                          newColorizeTaskWithMesh:mesh
                          scene:_slamState.scene
                          keyframes:[_slamState.keyFrameManager getKeyFrames]
                          completionHandler: ^(NSError *error)
                          {
                              if (error != nil) {
                                  NSLog(@"Error during colorizing: %@", [error localizedDescription]);
                              }
                              else
                              {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      previewCompletionHandler();
                                      _meshViewController.mesh = mesh;
                                      [self performEnhancedColorize:(STMesh*)mesh enhancedCompletionHandler:enhancedCompletionHandler];
                                  });
                                  _naiveColorizeTask = nil;
                              }
                          }
                          options:@{kSTColorizerTypeKey: @(STColorizerPerVertex),
                                    kSTColorizerPrioritizeFirstFrameColorKey: @(_options.prioritizeFirstFrameColor)}
                          error:nil];
    
    if (_naiveColorizeTask)
    {
        _naiveColorizeTask.delegate = self;
        [_naiveColorizeTask start];
        return TRUE;
    }
    
    return FALSE;
}


#pragma mark - Properties

- (void)setDidResetDistance:(BOOL)didResetDistance
{
    if (didResetDistance == NO)
    {
        [self showTrackingMessage:NSLocalizedString(@"SAlignAndLockMessage", nil)];
        
        if (self.instructionPopupController == nil)
        {
            self.instructionPopupController = [[InstructionPopupController alloc] initWithTitle:NSLocalizedString(@"SAlignAndLockInstructionTitle", nil)
                                                                                       messages:@[NSLocalizedString(@"SAlignAndLockInstructionMessage", nil)]
                                                                              dismissButtonText:NSLocalizedString(@"CContinue", nil)
                                                                       neverShowUserDefaultsKey:kHideAlignAndLockInstructionUserDefaultsKey
                                                                                       delegate:self];
            [self.instructionPopupController presentIfNeeded];
        }
    }
    else
    {
        [self showTrackingMessage:NSLocalizedString(@"SVerifyAndScanMessage", nil)];
        
        if (self.instructionPopupController == nil)
        {
            self.instructionPopupController = [[InstructionPopupController alloc] initWithTitle:NSLocalizedString(@"SVerifyAndScanInstructionTitle", nil)
                                                                                       messages:@[NSLocalizedString(@"SVerifyAndScanInstructionMessage1", nil), NSLocalizedString(@"SVerifyAndScanInstructionMessage2", nil), NSLocalizedString(@"SVerifyAndScanInstructionMessage3", nil)]
                                                                              dismissButtonText:NSLocalizedString(@"CContinue", nil)
                                                                       neverShowUserDefaultsKey:kHideVerifyAndScanInstructionUserDefaultsKey
                                                                                       delegate:self];
            [self.instructionPopupController presentIfNeeded];
        }
    }
    
    _didResetDistance = didResetDistance;
}


#pragma mark - Other

- (void)backgroundTask:(STBackgroundTask *)sender didUpdateProgress:(double)progress
{
    if (sender == _naiveColorizeTask)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_meshViewController showMeshViewerMessage:[NSString stringWithFormat:NSLocalizedString(@"SApplyingTextureMessage", nil), int(progress*20)]];
        });
    }
    else if (sender == _enhancedColorizeTask)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_meshViewController showMeshViewerMessage:[NSString stringWithFormat:NSLocalizedString(@"SApplyingTextureMessage", nil), int(progress*80)+20]];
        });
    }
}

- (void)performEnhancedColorize:(STMesh*)mesh enhancedCompletionHandler:(void (^)())enhancedCompletionHandler
{
    _enhancedColorizeTask =[STColorizer
       newColorizeTaskWithMesh:mesh
       scene:_slamState.scene
       keyframes:[_slamState.keyFrameManager getKeyFrames]
       completionHandler: ^(NSError *error)
       {
           if (error != nil) {
               NSLog(@"Error during colorizing: %@", [error localizedDescription]);
           }
           else
           {
               dispatch_async(dispatch_get_main_queue(), ^{
                   enhancedCompletionHandler();
                   _meshViewController.mesh = mesh;
               });
               _enhancedColorizeTask = nil;
           }
       }
       options:@{kSTColorizerTypeKey: @(STColorizerTextureMapForObject),
                 kSTColorizerPrioritizeFirstFrameColorKey: @(_options.prioritizeFirstFrameColor),
                 kSTColorizerQualityKey: @(_options.colorizerQuality),
                 kSTColorizerTargetNumberOfFacesKey: @(_options.colorizerTargetNumFaces)} // 20k faces is enough for most objects.
       error:nil];
    
    if (_enhancedColorizeTask)
    {
        // We don't need the keyframes anymore now that the final colorizing task was started.
        // Clearing it now gives a chance to early release the keyframe memory when the colorizer
        // stops needing them.
        [_slamState.keyFrameManager clear];
        
        _enhancedColorizeTask.delegate = self;
        [_enhancedColorizeTask start];
    }
}


- (void) respondToMemoryWarning
{
    switch( _slamState.scannerState )
    {
        case ScannerStateViewing:
        {
            // If we are running a colorizing task, abort it
            if( _enhancedColorizeTask != nil && !_slamState.showingMemoryWarning )
            {
                _slamState.showingMemoryWarning = true;
                
                // stop the task
                [_enhancedColorizeTask cancel];
                _enhancedColorizeTask = nil;
                
                // hide progress bar
                [_meshViewController hideMeshViewerMessage];
                
                UIAlertController *alertCtrl= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"SMemoryAlertTitle", nil)
                                                                                  message:NSLocalizedString(@"SMemoryAlertAbortColorizingMessage", nil)
                                                                           preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"COk", nil)
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action)
                                           {
                                               _slamState.showingMemoryWarning = false;
                                           }];
                
                [alertCtrl addAction:okAction];
                
                // show the alert in the meshViewController
                [_meshViewController presentViewController:alertCtrl animated:YES completion:nil];
            }
            
            break;
        }
        case ScannerStateScanning:
        {
            if( !_slamState.showingMemoryWarning )
            {
                _slamState.showingMemoryWarning = true;
                
                UIAlertController *alertCtrl= [UIAlertController alertControllerWithTitle:NSLocalizedString(@"SMemoryAlertTitle", nil)
                                                                                  message:NSLocalizedString(@"SMemoryAlertAbortScanningMessage", nil)
                                                                           preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"COk", nil)
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action)
                                           {
                                               _slamState.showingMemoryWarning = false;
                                               [self enterViewingState];
                                           }];
                
                
                [alertCtrl addAction:okAction];
                
                // show the alert
                [self presentViewController:alertCtrl animated:YES completion:nil];
            }
            
            break;
        }
        default:
        {
            // not much we can do here
        }
    }
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [_sensorController stopStreaming];
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}


#pragma mark - InstructionPopupControllerDelegate

- (void)instructionPopupDidDismiss:(InstructionPopupController*)controller
{
    self.instructionPopupController = nil;
}


#pragma mark - Privates

// Manages whether we can let the application sleep.
- (void)updateIdleTimer
{
    if ([self isStructureConnectedAndCharged] && [self currentStateNeedsSensor])
    {
        // Do not let the application sleep if we are currently using the sensor data.
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
    else
    {
        // Let the application sleep if we are only viewing the mesh or if no sensors are connected.
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
}

- (void)showTrackingMessage:(NSString*)message
{
    if (!(_slamState.scannerState == ScannerStateScanning && self.enable5secTimerSwitch.on)) {
        self.trackingLostLabel.text = message;
        self.trackingLostLabel.hidden = NO;
    }
}

- (void)hideTrackingErrorMessage
{
    self.trackingLostLabel.hidden = YES;
}

- (void)showAppStatusMessage:(NSString *)msg
{
    _appStatus.needsDisplayOfStatusMessage = true;
    [self.view.layer removeAllAnimations];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self.appStatusMessageLabel setText:msg];
    [self.appStatusMessageLabel setHidden:NO];
    
    __weak ScanViewController *weakSelf = self;
    
    // Progressively show the message label.
    [self.view setUserInteractionEnabled:false];
    [UIView animateWithDuration:0.5f animations:^{
        self.appStatusMessageLabel.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [weakSelf.view setUserInteractionEnabled:true];
    }];
}

- (void)hideAppStatusMessage
{
    if (!_appStatus.needsDisplayOfStatusMessage)
        return;
    
    _appStatus.needsDisplayOfStatusMessage = false;
    [self.view.layer removeAllAnimations];
    
    __weak ScanViewController *weakSelf = self;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         weakSelf.appStatusMessageLabel.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         // If nobody called showAppStatusMessage before the end of the animation, do not hide it.
                         if (!_appStatus.needsDisplayOfStatusMessage)
                         {
                             weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
                             // Could be nil if the self is released before the callback happens.
                             if (weakSelf) {
                                 [weakSelf.appStatusMessageLabel setHidden:YES];
                                 [weakSelf.view setUserInteractionEnabled:true];
                             }
                         }
                     }];
}

- (void)updateAppStatusMessage
{
    // Skip everything if we should not show app status messages (e.g. in viewing state).
    if (_appStatus.statusMessageDisabled)
    {
        [self hideAppStatusMessage];
        return;
    }
    
    // First show sensor issues, if any.
    switch (_appStatus.sensorStatus)
    {
        case AppStatus::SensorStatusOk:
        {
            break;
        }
            
        case AppStatus::SensorStatusNeedsUserToConnect:
        {
            [self showAppStatusMessage:_appStatus.pleaseConnectSensorMessage];
            return;
        }
            
        case AppStatus::SensorStatusNeedsUserToCharge:
        {
            [self showAppStatusMessage:_appStatus.pleaseChargeSensorMessage];
            return;
        }
    }
    
    // Then show color camera permission issues, if any.
    if (!_appStatus.colorCameraIsAuthorized)
    {
        [self showAppStatusMessage:_appStatus.needColorCameraAccessMessage];
        return;
    }
    
    // If we reach this point, no status to show.
    [self hideAppStatusMessage];
}

- (void)hideCountdownTimerMessageAnimated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.5f animations:^{
            self.countdownTimerLabel.alpha = 0.0f;
        } completion:^(BOOL finished){
            [self.countdownTimerLabel setHidden:YES];
        }];
    } else {
        self.countdownTimerLabel.alpha = 0.0f;
        [self.countdownTimerLabel setHidden:YES];
    }
}

- (void)showCountdownTimerMessageWithCountdown:(NSInteger)secsLeft animated:(BOOL)animated
{
    NSString *formatString = _slamState.scannerState == ScannerStateScanning ?
                                NSLocalizedString(@"SCountdownDuringScanMessage", nil) :
                                NSLocalizedString(@"SCountdownBeforeScanMessage", nil);
    
    [self.countdownTimerLabel setText:[NSString stringWithFormat:formatString, (long)secsLeft]];
    
    if (self.countdownTimerLabel.hidden == YES)
    {
        [self.countdownTimerLabel setHidden:NO];
        self.countdownTimerLabel.alpha = 0.0f;
        
        if (animated) {
            [UIView animateWithDuration:0.5f animations:^{
                self.countdownTimerLabel.alpha = 1.0f;
            }];
        } else {
            self.countdownTimerLabel.alpha = 1.0f;
        }
    }
    
    if (playSound && _slamState.scannerState != ScannerStateScanning) {
        AudioServicesPlaySystemSound(1052);
    }
}

- (void)updateOffLabel:(UILabel*)offLabel onLabel:(UILabel*)onLabel basedOnSwitch:(UISwitch*)uiSwitch
{
    offLabel.font = uiSwitch.on ? switchOffFont : switchOnFont;
    offLabel.textColor = uiSwitch.on ? switchOffColor : switchOnColor;
    onLabel.font = uiSwitch.on ? switchOnFont : switchOffFont;
    onLabel.textColor = uiSwitch.on ? switchOnColor : switchOffColor;
}

- (void)countdownTimerDidFire:(NSTimer*)timer
{
    NSInteger secsLeft = [timer.userInfo[kCountdownTimerSecsLeftUserInfoKey] integerValue];
    
    if (secsLeft == 0)
    {
        [self resetCountdownTimer];
        
        if (_slamState.scannerState == ScannerStateScanning) {
            if (playSound) {
                AudioServicesPlaySystemSound(1054);
            }
            [self enterViewingState];
        } else {
            [self enterScanningState];
        }
        
    }
    else
    {
        [self showCountdownTimerMessageWithCountdown:secsLeft animated:NO];
        timer.userInfo[kCountdownTimerSecsLeftUserInfoKey] = [NSNumber numberWithInteger:(secsLeft-1)];
    }
}

- (void)resetCountdownTimer
{
    [self hideCountdownTimerMessageAnimated:NO];
    if (countdownTimer) {
        [countdownTimer invalidate];
        countdownTimer = nil;
    }
}

@end

/*
  This file is part of the Structure SDK.
  Copyright © 2015 Occipital, Inc. All rights reserved.
  http://structure.io
*/

#import "ScanViewController.h"
#import "ScanViewController+OpenGL.h"

#import <Structure/Structure.h>
#import <Structure/StructureSLAM.h>
#import "STDepthFramePublic.h"
//#import "STDepthFrame+ConstantDistance.h"

//#import "STDepthFrame+Swizzle.h"

#pragma mark - Utilities

namespace // anonymous namespace for local functions
{
    float deltaRotationAngleBetweenPosesInDegrees (const GLKMatrix4& previousPose, const GLKMatrix4& newPose)
    {
        GLKMatrix4 deltaPose = GLKMatrix4Multiply(newPose,
                                                  // Transpose is equivalent to inverse since we will only use the rotation part.
                                                  GLKMatrix4Transpose(previousPose));
        
        // Get the rotation component of the delta pose
        GLKQuaternion deltaRotationAsQuaternion = GLKQuaternionMakeWithMatrix4(deltaPose);
        
        // Get the angle of the rotation
        const float angleInDegree = GLKQuaternionAngle(deltaRotationAsQuaternion)/M_PI*180;
        
        return angleInDegree;
    }
}

@implementation ScanViewController (SLAM)

#pragma mark - SLAM

// Set up SLAM related objects.
- (void)setupSLAM
{
    if (_slamState.initialized)
        return;
    
    firstFrame = YES;
    // Initialize the scene.
    _slamState.scene = [[STScene alloc] initWithContext:_display.context
                                      freeGLTextureUnit:GL_TEXTURE2];
    
    // Initialize the camera pose tracker.
    NSDictionary* trackerOptions = @{
                                     kSTTrackerTypeKey: self.enableNewTrackerSwitch.on ? @(STTrackerDepthAndColorBased) : @(STTrackerDepthBased),
                                     kSTTrackerTrackAgainstModelKey: @TRUE, // tracking against the model is much better for close range scanning.
                                     kSTTrackerQualityKey: @(STTrackerQualityAccurate),
                                     kSTTrackerBackgroundProcessingEnabledKey: @TRUE
                                     };
    
    NSError* trackerInitError = nil;
    
    // Initialize the camera pose tracker.
    _slamState.tracker = [[STTracker alloc] initWithScene:_slamState.scene options:trackerOptions error:&trackerInitError];
    
    if (trackerInitError != nil)
    {
        NSLog(@"Error during STTracker initialization: `%@'.", [trackerInitError localizedDescription]);
    }
    
    NSAssert (_slamState.tracker != nil, @"Could not create a tracker.");
    
    // Initialize the mapper.
    NSDictionary* mapperOptions =
    @{
      kSTMapperVolumeResolutionKey: @[@(round(_options.initialVolumeSizeInMeters.x / _options.initialVolumeResolutionInMeters)),
                                      @(round(_options.initialVolumeSizeInMeters.y / _options.initialVolumeResolutionInMeters)),
                                      @(round(_options.initialVolumeSizeInMeters.z / _options.initialVolumeResolutionInMeters))]
      };
    
    _slamState.mapper = [[STMapper alloc] initWithScene:_slamState.scene
                                                options:mapperOptions];
    
    // We need it for the TrackAgainstModel tracker, and for live rendering.
    _slamState.mapper.liveTriangleMeshEnabled = true;
    
    // Default volume size set in options struct
    _slamState.mapper.volumeSizeInMeters = _options.initialVolumeSizeInMeters;
    
    // Setup the cube placement initializer.
    NSError* cameraPoseInitializerError = nil;
    
    // camera is looking at the center of the box
    STCameraPoseInitializerStrategy strategy = STCameraPoseInitializerStrategyTableTopCube;
    
    // camera is in the center of the box (room scan), size of the box is undefined
//    STCameraPoseInitializerStrategy strategy = STCameraPoseInitializerStrategyGravityAlignedAtOrigin;
    
    // camerea is looking from 0,0,0 point, I have no idea what it is useful for
//    STCameraPoseInitializerStrategy strategy = STCameraPoseInitializerStrategyGravityAlignedAtVolumeCenter;
    

    
    _slamState.cameraPoseInitializer = [[STCameraPoseInitializer alloc]
                                        initWithVolumeSizeInMeters:_slamState.mapper.volumeSizeInMeters
                                        options:@{kSTCameraPoseInitializerStrategyKey: @(strategy)}
                                        error:&cameraPoseInitializerError];
    NSAssert (cameraPoseInitializerError == nil, @"Could not initialize STCameraPoseInitializer: %@", [cameraPoseInitializerError localizedDescription]);
    
    // Set up the cube renderer with the current volume size.
    _display.cubeRenderer = [[STCubeRenderer alloc] initWithContext:_display.context];
    
    // Set up the initial volume size.
    [self adjustVolumeSize:_slamState.mapper.volumeSizeInMeters];
    
    // Start with cube placement mode
    [self enterCubePlacementState];
    
    NSDictionary* keyframeManagerOptions = @{
                                             kSTKeyFrameManagerMaxSizeKey: @(_options.maxNumKeyFrames),
                                             kSTKeyFrameManagerMaxDeltaTranslationKey: @(_options.maxKeyFrameTranslation),
                                             kSTKeyFrameManagerMaxDeltaRotationKey: @(_options.maxKeyFrameRotation), // 20 degrees.
                                             };
    
    NSError* keyFrameManagerInitError = nil;
    _slamState.keyFrameManager = [[STKeyFrameManager alloc] initWithOptions:keyframeManagerOptions error:&keyFrameManagerInitError];
    
    NSAssert (keyFrameManagerInitError == nil, @"Could not initialize STKeyFrameManger: %@", [keyFrameManagerInitError localizedDescription]);
    
    _depthAsRgbaVisualizer = [[STDepthToRgba alloc] initWithOptions:@{kSTDepthToRgbaStrategyKey: @(STDepthToRgbaStrategyGray)}
                                                              error:nil];
    
    _slamState.initialized = true;
}

- (void)resetSLAM
{
    _slamState.prevFrameTimeStamp = -1.0;
    [_slamState.mapper reset];
    [_slamState.tracker reset];
    [_slamState.scene clear];
    [_slamState.keyFrameManager clear];
    
    [self enterCubePlacementState];
}

- (void)clearSLAM
{
    _slamState.initialized = false;
    _slamState.scene = nil;
    _slamState.tracker = nil;
    _slamState.mapper = nil;
    _slamState.keyFrameManager = nil;
}

// this is the method in which SDK analyzes the frame and motion data, and puts box in the correct place
- (void)processDepthFrame:(STDepthFrame *)depthFrame
          colorFrameOrNil:(STColorFrame*)colorFrame
{
    // Upload the new color image for next rendering.
    if (_useColorCamera && colorFrame != nil)
    {
        [self uploadGLColorTexture: colorFrame];
    }
    else if(!_useColorCamera)
    {
        [self uploadGLColorTextureFromDepth:depthFrame];
    }
    
    // Update the projection matrices since we updated the frames.
    {
        _display.depthCameraGLProjectionMatrix = [depthFrame glProjectionMatrix];
        if (colorFrame)
            _display.colorCameraGLProjectionMatrix = [colorFrame glProjectionMatrix];
    }
    
    switch (_slamState.scannerState)
    {
        case ScannerStateCubePlacement:
        {
            // Provide the new depth frame to the cube renderer for ROI highlighting.
            STDepthFrame *registeredDepthFrame = [depthFrame registeredToColorFrame:colorFrame];
            [_display.cubeRenderer setDepthFrame:_useColorCamera ? registeredDepthFrame : depthFrame];
            
            // Estimate the new scanning volume position.
            if (GLKVector3Length(_lastGravity) > 1e-5f)
            {
                // this is why the box is always in front of the camera
                GLKVector3 ConstVector = GLKVector3Make (0-1.0,0.0,0.0);
//              GLKVector3 ConstVector = _lastGravity;

                STDepthFrame *currentFrame = registeredDepthFrame;
                
                /** 
                 method updateCameraPoseWithGravity for transforming the box takes 2 parameters: gravity vector and STDepthFrame
                gravity vector tells how the device is tilted. We should pass gravity vector -1 0 0, then the box won't be aligned to the ground, but it will be always floating aligned to the device
                 
                 STDepthFrame tells what is inside the box - in the meaning of the depth. If we could pass an array of float depthInMillimeters with values 600 (mm) then the box would appear in 60cm from the camera. 
                 This is readonly property. I tried to inherit the STDepthFrame (STDepthFramePublic) , and also created a category (STDepthFrame+ConstantDistance) and in both cases, even when I pass the original values, app stops working.
                 Lastly I couldn't override this parameter, so I stopped it working every frame. It works only in first frame and after every "reset distance" action. It takes the closest object in front of the device and sets the distance parameter to this value. From then on, the box will appear at this distance from the camera
                
                */
                
                // value from user interface
                if (shouldResetDistance)
                {
                    self.didResetDistance = YES;
                    shouldResetDistance = NO;
                    NSError *error;
                    bool success = [_slamState.cameraPoseInitializer updateCameraPoseWithGravity:ConstVector depthFrame:currentFrame error:&error];
                    if (error != nil) {
                        NSLog(@"err %@", error.description);
                    }
                    NSAssert (success, @"Camera pose initializer error.");
                }
                else
                {
                    // aligning box to ground in every frame
                    if (_slamState.cameraPoseInitializer.hasValidPose)
                    {
                        // first frame in which already found a pose
//                        if (firstFrame) {
//                            firstFrame = NO;
//                            bool success = [_slamState.cameraPoseInitializer updateCameraPoseWithGravity:ConstVector depthFrame:currentFrame error:nil];
//                            NSAssert (success, @"Camera pose initializer error.");
//                        }
                    }
                    //at the beginning, after start
                    else
                    {
                        firstFrame = YES;
                        
                    // this class inherites from NSDepthFrame, and has a field of another NSDepthFrame (composite pattern?)
                        // it rewrites getters for readonly values of NSDepthFrame
//                        STDepthFramePublic * newDepthFrame = [[STDepthFramePublic alloc] initWithSTDepthFrame:depthFrame];
                        
                        // this is category to override the getters. Right now it is excluded from compile sources because it crashed the app
//                        STDepthFrame * depthWithConstDist = [[STDepthFrame alloc] initWithSTDepthFrame:depthFrame];


//                        currentFrame = newDepthFrame;
//                        currentFrame = depthWithConstDist;
                        
                        NSError *error;
                        bool success = [_slamState.cameraPoseInitializer updateCameraPoseWithGravity:ConstVector depthFrame:currentFrame error:&error];
                        if (error != nil) {
                            NSLog(@"err %@", error.description);
                        }
                        NSAssert (success, @"Camera pose initializer error.");
                    }
                }                
            }
            
            // Tell the cube renderer whether there is a support plane or not.
            [_display.cubeRenderer setCubeHasSupportPlane:_slamState.cameraPoseInitializer.hasSupportPlane];
            
            // Enable the scan button if the pose initializer could estimate a pose and the distance was set
            self.scanButton.enabled = _slamState.cameraPoseInitializer.hasValidPose && self.didResetDistance;
            break;
        }
            
        case ScannerStateScanning:
        {
            // First try to estimate the 3D pose of the new frame.
            NSError* trackingError = nil;
            
            GLKMatrix4 depthCameraPoseBeforeTracking = [_slamState.tracker lastFrameCameraPose];
            
            BOOL trackingOk = [_slamState.tracker updateCameraPoseWithDepthFrame:depthFrame colorFrame:colorFrame error:&trackingError];
            
            // Integrate it into the current mesh estimate if tracking was successful.
            if (trackingOk)
            {
                GLKMatrix4 depthCameraPoseAfterTracking = [_slamState.tracker lastFrameCameraPose];
                
                [_slamState.mapper integrateDepthFrame:depthFrame cameraPose:depthCameraPoseAfterTracking];
                
                if (colorFrame)
                {
                    // Make sure the pose is in color camera coordinates in case we are not using registered depth.
                    GLKMatrix4 colorCameraPoseInDepthCoordinateSpace;
                    [depthFrame colorCameraPoseInDepthCoordinateFrame:colorCameraPoseInDepthCoordinateSpace.m];
                    GLKMatrix4 colorCameraPoseAfterTracking = GLKMatrix4Multiply(depthCameraPoseAfterTracking,
                                                                                 colorCameraPoseInDepthCoordinateSpace);
                    

                    bool showHoldDeviceStill = false;
                    
                    // Check if the viewpoint has moved enough to add a new keyframe
                    if ([_slamState.keyFrameManager wouldBeNewKeyframeWithColorCameraPose:colorCameraPoseAfterTracking])
                    {
                        const bool isFirstFrame = (_slamState.prevFrameTimeStamp < 0.);
                        bool canAddKeyframe = false;
                        
                        if (isFirstFrame) // always add the first frame.
                        {
                            canAddKeyframe = true;
                        }
                        else // for others, check the speed.
                        {
                            float deltaAngularSpeedInDegreesPerSecond = FLT_MAX;
                            NSTimeInterval deltaSeconds = depthFrame.timestamp - _slamState.prevFrameTimeStamp;
                            
                            // If deltaSeconds is 2x longer than the frame duration of the active video device, do not use it either
                            CMTime frameDuration = self.videoDevice.activeVideoMaxFrameDuration;
                            if (deltaSeconds < (float)frameDuration.value/frameDuration.timescale*2.f)
                            {
                                // Compute angular speed
                                deltaAngularSpeedInDegreesPerSecond = deltaRotationAngleBetweenPosesInDegrees (depthCameraPoseBeforeTracking, depthCameraPoseAfterTracking)/deltaSeconds;
                            }
                            
                            // If the camera moved too much since the last frame, we will likely end up
                            // with motion blur and rolling shutter, especially in case of rotation. This
                            // checks aims at not grabbing keyframes in that case.
                            if (deltaAngularSpeedInDegreesPerSecond < _options.maxKeyframeRotationSpeedInDegreesPerSecond)
                            {
                                canAddKeyframe = true;
                            }
                        }
                        
                        if (canAddKeyframe)
                        {
                            [_slamState.keyFrameManager processKeyFrameCandidateWithColorCameraPose:colorCameraPoseAfterTracking
                                                                                         colorFrame:colorFrame
                                                                                         depthFrame:nil];
                        }
                        else
                        {
                            // Moving too fast. Hint the user to slow down to capture a keyframe
                            // without rolling shutter and motion blur.
                            showHoldDeviceStill = true;
                        }
                    }
                    
                    if (showHoldDeviceStill)
                        [self showTrackingMessage:NSLocalizedString(@"SCaptureKeyframeMessage", nil)];
                    else
                        [self hideTrackingErrorMessage];
                }
                else
                {
                    [self hideTrackingErrorMessage];
                }
            }
            else if (trackingError.code == STErrorTrackerLostTrack)
            {
                [self showTrackingMessage:NSLocalizedString(@"STrackingLostMessage", nil)];
            }
            else if (trackingError.code == STErrorTrackerPoorQuality)
            {
                switch ([_slamState.tracker status])
                {
                    case STTrackerStatusDodgyForUnknownReason:
                    {
                        NSLog(@"STTracker Tracker quality is bad, but we don't know why.");
                        // Don't show anything on screen since this can happen often.
                        break;
                    }
                        
                    case STTrackerStatusFastMotion:
                    {
                        NSLog(@"STTracker Camera moving too fast.");
                        // Don't show anything on screen since this can happen often.
                        break;
                    }
                        
                    case STTrackerStatusTooClose:
                    {
                        NSLog(@"STTracker Too close to the model.");
                        [self showTrackingMessage:NSLocalizedString(@"STooCloseMessage", nil)];
                        break;
                    }
                        
                    case STTrackerStatusTooFar:
                    {
                        NSLog(@"STTracker Too far from the model.");
                        [self showTrackingMessage:NSLocalizedString(@"STooFarMessage", nil)];
                        break;
                    }
                        
                    case STTrackerStatusRecovering:
                    {
                        NSLog(@"STTracker Recovering.");
                        [self showTrackingMessage:NSLocalizedString(@"SRecoveringMessage", nil)];
                        break;
                    }
                        
                    case STTrackerStatusModelLost:
                    {
                        NSLog(@"STTracker model not in view.");
                        [self showTrackingMessage:NSLocalizedString(@"SNotInViewMessage", nil)];
                        break;
                    }
                    default:
                        NSLog(@"STTracker unknown quality.");
                }
            }
            else
            {
                NSLog(@"[Structure] STTracker Error: %@.", [trackingError localizedDescription]);
            }
            
            _slamState.prevFrameTimeStamp = depthFrame.timestamp;
            
            break;
        }
            
        case ScannerStateViewing:
        default:
        {} // Do nothing, the MeshViewController will take care of this.
    }
}

@end

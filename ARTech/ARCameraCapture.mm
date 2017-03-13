//
// Created by wangyang on 2017/3/13.
// Copyright (c) 2017 wangyang. All rights reserved.
//

#import "ARCameraCapture.h"
#import "CameraVideo.h"
#import "param.h"
#import "ARView.h"

#define VIEW_DISTANCE_MIN        5.0f          // Objects closer to the camera than this will not be displayed.
#define VIEW_DISTANCE_MAX        2000.0f        // Objects further away from the camera than this will not be displayed.


static void captureStartCallback(void *userdata);

@interface ARCameraCapture () <CameraVideoTookPictureDelegate> {
    AR2VideoParamT *videoID;
    ARGL_CONTEXT_SETTINGS_REF arglContextSettings;
    ARView *glView;
    NSTimeInterval  runLoopTimePrevious;
    BOOL isReady;
}
@property (copy, nonatomic) ARCameraCaptureOpenDeviceHandler openDeviceHandler;
@end

@implementation ARCameraCapture
@synthesize pixelFormat;

- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)setupDisplayView:(ARView *)arView {
    if (!arView) return;
    glView = arView;
    if (!isReady) return;
    GLfloat frustum[16];
    arglCameraFrustumRHf(&self.arParamLT->param, VIEW_DISTANCE_MIN, VIEW_DISTANCE_MAX, frustum);
    [arView setCameraLens:frustum];
    arView.contentFlipV = self.isFlip;
    // Set up content positioning.
    arView.contentScaleMode = ARViewContentScaleModeFill;
    arView.contentAlignMode = ARViewContentAlignModeCenter;
    arView.contentWidth = self.arParam.xsize;
    arView.contentHeight = self.arParam.ysize;

    BOOL isBackingTallerThanWide = (arView.surfaceSize.height > arView.surfaceSize.width);
    if (arView.contentWidth > arView.contentHeight) {
        arView.contentRotate90 = isBackingTallerThanWide;
    }
    else {
        arView.contentRotate90 = !isBackingTallerThanWide;
    }
#ifdef DEBUG
    NSLog(@"[ARViewController start] content %dx%d (wxh) will display in GL context %dx%d%s.\n", glView.contentWidth, glView.contentHeight, (int)glView.surfaceSize.width, (int)glView.surfaceSize.height, (glView.contentRotate90 ? " rotated" : ""));
#endif

    // Setup ARGL to draw the background video.
    arglContextSettings = arglSetupForCurrentContext(&self.arParamLT->param, pixelFormat);

    arglSetRotate90(arglContextSettings, (arView.contentWidth > arView.contentHeight ? isBackingTallerThanWide : !isBackingTallerThanWide));
    if (self.isFlip) arglSetFlipV(arglContextSettings, TRUE);
    int width, height;
    ar2VideoGetBufferSize(videoID, &width, &height);
    arglPixelBufferSizeSet(arglContextSettings, width, height);

    glView.arglContextSettings = arglContextSettings;
}


- (void)openDevice:(ARCameraCaptureOpenDeviceHandler)handler {
    self.openDeviceHandler = handler;
    // See http://www.artoolworks.com/support/library/Configuring_video_capture_in_ARToolKit_Professional#AR_VIDEO_DEVICE_IPHONE
    char *vconf = "";
    if (!(videoID = ar2VideoOpenAsync(vconf, captureStartCallback, (__bridge void *)(self)))) {
        NSLog(@"Error: Unable to open connection to camera.\n");
        [self endCapture];
        self.openDeviceHandler(false);
        return;
    }
}

- (void)beginCapture {
    if (ar2VideoCapStart(videoID) != 0) {
        NSLog(@"Error: Unable to begin camera data capture.\n");
        [self endCapture];
        return;
    }
}

- (void)endCapture {
    if (ar2VideoCapStop(videoID) != 0) {
        NSLog(@"Error: Unable to stop camera data capture.\n");
    }
}

- (void)cameraVideoTookPicture:(id)sender userData:(void *)data {
    AR2VideoBufferT *buffer = ar2VideoGetImage(videoID);
    if (buffer) {
        [self.delegate arCameraCaptureDidCaptureData:buffer];

        [self.delegate arCameraCaptureWillRenderCaptureData:buffer];
        if (buffer->bufPlaneCount == 2) arglPixelBufferDataUploadBiPlanar(arglContextSettings, buffer->bufPlanes[0], buffer->bufPlanes[1]);
        else arglPixelBufferDataUpload(arglContextSettings, buffer->buff);

        [self.delegate arCameraCaptureDidRenderCaptureData:buffer];

        NSTimeInterval runLoopTimeNow;
        runLoopTimeNow = CFAbsoluteTimeGetCurrent();
        [glView updateWithTimeDelta:(runLoopTimeNow - runLoopTimePrevious)];

        // The display has changed.
        [glView drawView:self];
        runLoopTimePrevious = runLoopTimeNow;
    }
}

#pragma mark - Private Methods
static void captureStartCallback(void *userdata) {
    ARCameraCapture *capture = (__bridge ARCameraCapture *)userdata;

    int xsize, ysize;
    if (ar2VideoGetSize(capture->videoID, &xsize, &ysize) < 0) {
        NSLog(@"Error: ar2VideoGetSize.\n");
        [capture endCapture];
        return;
    }

    AR_PIXEL_FORMAT pixelFormat = ar2VideoGetPixelFormat(capture->videoID);
    capture->pixelFormat = pixelFormat;
    if (pixelFormat == AR_PIXEL_FORMAT_INVALID) {
        NSLog(@"Error: Cameraself. is using unsupported pixel format.\n");
        [capture endCapture];
        return;
    }

    // Work out if the front camera is being used. If it is, flip the viewing frustum for
    // 3D drawing.
    BOOL flipV = FALSE;
    int frontCamera;
    if (ar2VideoGetParami(capture->videoID, AR_VIDEO_PARAM_IOS_CAMERA_POSITION, &frontCamera) >= 0) {
        if (frontCamera == AR_VIDEO_IOS_CAMERA_POSITION_FRONT) flipV = TRUE;
    }
    capture.isFlip = flipV;

    // Tell arVideo what the typical focal distance will be. Note that this does NOT
    // change the actual focus, but on devices with non-fixed focus, it lets arVideo
    // choose a better set of camera parameters.
    ar2VideoSetParami(capture->videoID, AR_VIDEO_PARAM_IOS_FOCUS, AR_VIDEO_IOS_FOCUS_0_3M); // Default is 0.3 metres. See <AR/sys/videoiPhone.h> for allowable values.

    // Load the camera parameters, resize for the window and init.
    ARParam cparam;
    if (ar2VideoGetCParam(capture->videoID, &cparam) < 0) {
        char cparam_name[] = "Data2/camera_para.dat";
        NSLog(@"Unable to automatically determine camera parameters. Using default.\n");
        if (arParamLoad(cparam_name, 1, &cparam) < 0) {
            NSLog(@"Error: Unable to load parameter file %s for camera.\n", cparam_name);
            [capture endCapture];
            return;
        }
    }
    capture.arParam = cparam;
    if (cparam.xsize != xsize || cparam.ysize != ysize) {
#ifdef DEBUG
        fprintf(stdout, "*** Camera Parameter resized from %d, %d. ***\n", cparam.xsize, cparam.ysize);
#endif
        arParamChangeSize(&cparam, xsize, ysize, &cparam);
    }
#ifdef DEBUG
    fprintf(stdout, "*** Camera Parameter ***\n");
    arParamDisp(&cparam);
#endif

    if ((capture.arParamLT = arParamLTCreate(&cparam, AR_PARAM_LT_DEFAULT_OFFSET)) == NULL) {
        NSLog(@"Error: arParamLTCreate.\n");
        [capture endCapture];
        return;
    }

    CameraVideo *cameraVideo = ar2VideoGetNativeVideoInstanceiPhone(capture->videoID->device.iPhone);
    if (!cameraVideo) {
        NSLog(@"Error: Unable to set up AR camera: missing CameraVideo instance.\n");
        [capture endCapture];
        return;
    }

    [cameraVideo setTookPictureDelegate:capture];
    [cameraVideo setTookPictureDelegateUserData:NULL];

    capture->isReady = YES;
    [capture setupDisplayView:capture->glView];

    if (capture.openDeviceHandler) {
        capture.openDeviceHandler(YES);
    }
}
@end
//
// Created by wangyang on 2017/3/13.
// Copyright (c) 2017 wangyang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SimpleARViewController.h"
#import "ARView.h"
#import "ARMarkDetector.h"



@interface SimpleARViewController () <ARCameraCaptureDelegate>
@property  (strong, nonatomic) ARView *arView;
@property  (strong, nonatomic) ARCameraCapture *cameraCapture;
@property  (strong, nonatomic) ARMarkDetector *markDetector;
@end


@implementation SimpleARViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.arView = [[ARView alloc] initWithFrame:[[UIScreen mainScreen] bounds] pixelFormat:kEAGLColorFormatRGBA8 depthFormat:kEAGLDepth24 withStencil:YES preserveBackbuffer:YES];
    [self.view addSubview:self.arView];

    self.cameraCapture = [ARCameraCapture new];
    self.cameraCapture.delegate = self;
    [self.cameraCapture openDevice:^(BOOL success) {
      if (success) {
          [self.cameraCapture setupDisplayView:self.arView];
          self.markDetector = [ARMarkDetector new];
          [self.markDetector setupWith:self.cameraCapture.arParamLT pixelFormat:self.cameraCapture.pixelFormat];

          [self.cameraCapture beginCapture];
      }
    }];
}

#pragma mark - Camera Capture delegate
- (void)arCameraCaptureDidCaptureData:(AR2VideoBufferT *)buffer {
    [self.markDetector detect:buffer];
}

- (void)arCameraCaptureWillRenderCaptureData:(AR2VideoBufferT *)buffer {

}

- (void)arCameraCaptureDidRenderCaptureData:(AR2VideoBufferT *)buffer {

}
@end
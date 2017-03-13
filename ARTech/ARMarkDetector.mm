//
//  ARMarkDetector.m
//  ARTech
//
//  Created by wangyang on 2017/3/13.
//  Copyright © 2017年 wangyang. All rights reserved.
//

#import "ARMarkDetector.h"
#import "video.h"
#import "ar.h"


@interface ARMarkDetector () {

    ARHandle       *gARHandle;
    ARPattHandle   *gARPattHandle;
    long            gCallCountMarkerDetect;

    // Transformation matrix retrieval.
    AR3DHandle     *gAR3DHandle;
    ARdouble        gPatt_width;            // Per-marker, but we are using only 1 marker.
    ARdouble        gPatt_trans[3][4];      // Per-marker, but we are using only 1 marker.
    int             gPatt_found;            // Per-marker, but we are using only 1 marker.
    int             gPatt_id;               // Per-marker, but we are using only 1 marker.
    BOOL            useContPoseEstimation;
}
@end

@implementation ARMarkDetector

- (instancetype)init {
    self = [super init];
    if (self) {
        gARHandle = NULL;
        gARPattHandle = NULL;
        gCallCountMarkerDetect = 0;
        gAR3DHandle = NULL;
        useContPoseEstimation = FALSE;
    }
    return self;
}

- (bool)setupWith:(ARParamLT *)paramLT pixelFormat:(AR_PIXEL_FORMAT)pixelFormat {
    // AR init.
    if ((gARHandle = arCreateHandle(paramLT)) == NULL) {
        NSLog(@"Error: arCreateHandle.\n");
        return NO;
    }
    if (arSetPixelFormat(gARHandle, pixelFormat) < 0) {
        NSLog(@"Error: arSetPixelFormat.\n");
        return NO;
    }
    if ((gAR3DHandle = ar3DCreateHandle(&paramLT->param)) == NULL) {
        NSLog(@"Error: ar3DCreateHandle.\n");
        return NO;
    }
    arSetMarkerExtractionMode(gARHandle, AR_USE_TRACKING_HISTORY_V2);
    return [self setupPattern];
}

- (BOOL)setupPattern {
    // Prepare ARToolKit to load patterns.
    if (!(gARPattHandle = arPattCreateHandle())) {
        NSLog(@"Error: arPattCreateHandle.\n");
        return NO;
    }
    arPattAttach(gARHandle, gARPattHandle);

    // Load marker(s).
    // Loading only 1 pattern in this example.
    char *patt_name  = "Data2/hiro.patt";
    if ((gPatt_id = arPattLoad(gARPattHandle, patt_name)) < 0) {
        NSLog(@"Error loading pattern file %s.\n", patt_name);
        return NO;
    }

    gPatt_width = 40.0f;
    gPatt_found = FALSE;
    return YES;
}

- (BOOL)detect:(AR2VideoBufferT *)buffer {
    if (arDetectMarker(gARHandle, buffer->buff) < 0) {
        return NO;
    }
    NSLog(@"Found %d Markers", gARHandle->marker_num);
    return YES;
}

@end

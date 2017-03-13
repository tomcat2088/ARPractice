//
//  ARMarkDetector.h
//  ARTech
//
//  Created by wangyang on 2017/3/13.
//  Copyright © 2017年 wangyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <AR/ar.h>
#include <AR/video.h>
#include <AR/gsub_es2.h>

@interface ARMarkDetector : NSObject
- (void)detect:(AR2VideoBufferT *)buffer;
- (bool)setupWith:(ARParamLT *)paramLT pixelFormat:(AR_PIXEL_FORMAT)pixelFormat;
@end

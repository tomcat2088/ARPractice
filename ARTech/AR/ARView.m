//
//  ARView.m
//  ARApp
//
//  Disclaimer: IMPORTANT:  This Daqri software is supplied to you by Daqri
//  LLC ("Daqri") in consideration of your agreement to the following
//  terms, and your use, installation, modification or redistribution of
//  this Daqri software constitutes acceptance of these terms.  If you do
//  not agree with these terms, please do not use, install, modify or
//  redistribute this Daqri software.
//
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Daqri grants you a personal, non-exclusive
//  license, under Daqri's copyrights in this original Daqri software (the
//  "Daqri Software"), to use, reproduce, modify and redistribute the Daqri
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Daqri Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Daqri Software.
//  Neither the name, trademarks, service marks or logos of Daqri LLC may
//  be used to endorse or promote products derived from the Daqri Software
//  without specific prior written permission from Daqri.  Except as
//  expressly stated in this notice, no other rights or licenses, express or
//  implied, are granted by Daqri herein, including but not limited to any
//  patent rights that may be infringed by your derivative works or by other
//  works in which the Daqri Software may be incorporated.
//
//  The Daqri Software is provided by Daqri on an "AS IS" basis.  DAQRI
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE DAQRI SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//  IN NO EVENT SHALL DAQRI BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE DAQRI SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF DAQRI HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
//  Copyright 2015 Daqri LLC. All Rights Reserved.
//  Copyright 2010-2015 ARToolworks, Inc. All rights reserved.
//
//  Author(s): Philip Lamb
//

#import <QuartzCore/QuartzCore.h>
#import "ARView.h"
#import "ARViewController.h"
#include "glStateCache2.h"
#import "ARGLRender.h"

#include <AR/gsub_es2.h>
#include <AR/gsub_mtx.h>

@interface ARView (ARViewPrivate)
@end

@implementation ARView {
    ARGLRender *render;
}

- (id) initWithFrame:(CGRect)frame pixelFormat:(NSString *)format depthFormat:(EAGLDepthFormat)depth withStencil:(BOOL)stencil preserveBackbuffer:(BOOL)retained {
    if ((self = [super initWithFrame:frame renderingAPI:kEAGLRenderingAPIOpenGLES2 pixelFormat:format depthFormat:depth withStencil:stencil preserveBackbuffer:retained])) {
        render = [ARGLRender new];
    }

    return (self);
}

// Something to look at, draw a rotating colour cube.
- (void) drawCube:(float *)viewProjectionMatrix {
    [render drawCube:viewProjectionMatrix];
}

- (void) drawView:(id)sender {
    float const ir90[16] = { 0.0f, -1.0f, 0.0f, 0.0f,  1.0f, 0.0f, 0.0f, 0.0f,  0.0f, 0.0f, 1.0f, 0.0f,  0.0f, 0.0f, 0.0f, 1.0f };
    float width, height;
    float viewProjection[16];
//
   [self clearBuffers];

    arglDispImage(self.arglContextSettings);
//
   [render setupWithProjection:viewProjection cameraPoseValid:self.cameraPoseValid];
//
//    // Set up 3D mode.
    mtxLoadMatrixf(viewProjection, self.projection);
    glStateCacheEnableDepthTest();
//
//    // Set any initial per-frame GL state you require here.
//    // --->
//
//    // Lighting and geometry that moves with the camera should be added here.
//    // (I.e. should be specified before camera pose transform.)
//    // --->

    if (self.cameraPoseValid) {

        mtxMultMatrixf(viewProjection, self.cameraPose);

        // All lighting and geometry to be drawn in world coordinates goes here.
        // --->
        [self drawCube:viewProjection];
    }

//    // If you added external OpenGL code above, and that code doesn't use the glStateCache routines,
//    // then uncomment the line below.
    glStateCacheFlush();
//
//    // Set up 2D mode.
//    if (self.contentRotate90) {
//        mtxLoadMatrixf(viewProjection, ir90);
//    } else {
//        mtxLoadIdentityf(viewProjection);
//    }
//    width = (float)self.viewPort[(self.contentRotate90 ? viewPortIndexHeight : viewPortIndexWidth)];
//    height = (float)self.viewPort[(self.contentRotate90 ? viewPortIndexWidth : viewPortIndexHeight)];
//    mtxOrthof(viewProjection, 0.0f, width, 0.0f, height, -1.0f, 1.0f);
//    glStateCacheDisableDepthTest();

    // Add your own 2D overlays here.
    // --->

    // If you added external OpenGL code above, and that code doesn't use the glStateCache routines,
    // then uncomment the line below.
    //glStateCacheFlush();

//#ifdef DEBUG
//    // Example of 2D drawing. It just draws a white border line.
//    const GLfloat square_vertices[4][3] = { { 0.5f, 0.5f, 0.0f }, { 0.5f, height - 0.5f, 0.0f }, { width - 0.5f, height - 0.5f, 0.0f }, { width - 0.5f, 0.5f, 0.0f } };
//    const GLubyte square_vertex_colors_white[4][4] = {
//        { 255, 255, 255, 255 }, { 255, 255, 255, 255 }, { 255, 255, 255, 255 }, { 255, 255, 255, 255 }
//    };
//
//    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_PROJECTION_MATRIX], 1, GL_FALSE, viewProjection);
//
//    glVertexAttribPointer(ATTRIBUTE_VERTEX, 3, GL_FLOAT, GL_FALSE, 0, square_vertices);
//    glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
//    glVertexAttribPointer(ATTRIBUTE_COLOUR, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, square_vertex_colors_white);
//    glEnableVertexAttribArray(ATTRIBUTE_COLOUR);
//
//    if (!arglGLValidateProgram(program)) {
//        ARLOGe("[ARView drawView:] Error: shader program %d validation failed.\n", program);
//        return;
//    }
//
//    glDrawArrays(GL_LINE_LOOP, 0, 4);
//#endif

#ifdef DEBUG
    CHECK_GL_ERROR();
#endif

    [self swapBuffers];
}

- (void)updateWithTimeDelta:(NSTimeInterval)timeDelta {
    [render updateWithTimeDelta:timeDelta];
}

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSArray *array = [touches allObjects];
    UITouch *touch;
    NSUInteger i;
    CGPoint location;
    NSUInteger numTaps;

#ifdef DEBUG
    //NSLog(@"[EAGLView touchesBegan].\n");
#endif

    for (i = 0; i < [array count]; ++i) {
        touch = [array objectAtIndex:i];
        if (touch.phase == UITouchPhaseBegan) {
            location = [touch locationInView:self];
            numTaps = [touch tapCount];
            if (self.touchDelegate) {
                if ([self.touchDelegate respondsToSelector:@selector(handleTouchAtLocation:tapCount:)]) {
                    [self.touchDelegate handleTouchAtLocation:location tapCount:numTaps];
                }
            }
        } // phase match.
    } // touches.
}

- (void) handleTouchAtLocation:(CGPoint)location tapCount:(NSUInteger)tapCount {
    render.gDrawRotate = !render.gDrawRotate;
}

@end

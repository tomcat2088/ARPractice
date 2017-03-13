//
//  ARGLRender.m
//  ARToolKit5iOS
//
//  Created by wang yang on 2016/9/27.
//
//

#import "ARGLRender.h"
#include <AR/gsub_es2.h>
#include <AR/gsub_mtx.h>

#import "GLGeometry.h"

// Indices of GL ES program uniforms.
enum {
    UNIFORM_MODELVIEW_PROJECTION_MATRIX,
    UNIFORM_COUNT
};

// Indices of of GL ES program attributes.
enum {
    ATTRIBUTE_VERTEX,
    ATTRIBUTE_COLOUR,
    ATTRIBUTE_COUNT
};

@interface ARGLRender () {
    // Drawing-related.
    BOOL gDrawRotate;
    float gDrawRotateAngle;
    GLint uniforms[UNIFORM_COUNT];
    GLuint program;
    GLGeometry *geometry;
}
@end

@implementation ARGLRender

- (instancetype)init
{
    self = [super init];
    if (self) {
        geometry = [[GLGeometry alloc]initWithWaveFrontFilePath:@""];
    }
    return self;
}

- (void)dealloc {
    glUseProgram(0);
    arglGLDestroyShaders(0, 0, program);
    program = 0;
}

// Something to look at, draw a rotating colour cube.
- (void) drawCube:(float *)viewProjectionMatrix {
    float modelViewProjection[16];
        mtxLoadMatrixf(modelViewProjection, viewProjectionMatrix);
        mtxScalef(modelViewProjection, 20.0f, 20.0f, 20.0f);
        mtxTranslatef(modelViewProjection, 0.0f, 0.0f, 0.5f); // Place base of cube on marker surface.
    mtxRotatef(modelViewProjection, gDrawRotateAngle, 0.0f, 1.0f, 0.0f); // Rotate about z axis.
    geometry.viewProjection = GLKMatrix4MakeWithArray(modelViewProjection);
    
    [geometry draw];
    
//    return;
    // Colour cube data.
//    int i;
//    const GLfloat cube_vertices[8][3] = {
//        /* +z */ { 0.5f, 0.5f, 0.5f }, { 0.5f, -0.5f, 0.5f }, { -0.5f, -0.5f, 0.5f }, { -0.5f, 0.5f, 0.5f },
//        /* -z */ { 0.5f, 0.5f, -0.5f }, { 0.5f, -0.5f, -0.5f }, { -0.5f, -0.5f, -0.5f }, { -0.5f, 0.5f, -0.5f }
//    };
//    const GLubyte cube_vertex_colors[8][4] = {
//        { 255, 255, 255, 255 }, { 255, 255, 0, 255 }, { 0, 255, 0, 255 }, { 0, 255, 255, 255 },
//        { 255, 0, 255, 255 }, { 255, 0, 0, 255 }, { 0, 0, 0, 255 }, { 0, 0, 255, 255 }
//    };
//    const GLubyte cube_vertex_colors_black[8][4] = {
//        { 0, 0, 0, 255 }, { 0, 0, 0, 255 }, { 0, 0, 0, 255 }, { 0, 0, 0, 255 },
//        { 0, 0, 0, 255 }, { 0, 0, 0, 255 }, { 0, 0, 0, 255 }, { 0, 0, 0, 255 }
//    };
//    const GLushort cube_faces[6][4] = {  /* ccw-winding */
//        /* +z */ { 3, 2, 1, 0 }, /* -y */ { 2, 3, 7, 6 }, /* +y */ { 0, 1, 5, 4 },
//        /* -x */ { 3, 0, 4, 7 }, /* +x */ { 1, 2, 6, 5 }, /* -z */ { 4, 5, 6, 7 }
//    };
////    float modelViewProjection[16];
//
//    mtxLoadMatrixf(modelViewProjection, viewProjectionMatrix);
//    mtxRotatef(modelViewProjection, gDrawRotateAngle, 0.0f, 0.0f, 1.0f); // Rotate about z axis.
//    mtxScalef(modelViewProjection, 10.0f, 10.0f, 10.0f);
//    mtxTranslatef(modelViewProjection, 0.0f, 0.0f, 0.5f); // Place base of cube on marker surface.
//    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_PROJECTION_MATRIX], 1, GL_FALSE, modelViewProjection);
//
//    glVertexAttribPointer(ATTRIBUTE_VERTEX, 3, GL_FLOAT, GL_FALSE, 0, cube_vertices);
//    glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
//    glVertexAttribPointer(ATTRIBUTE_COLOUR, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, cube_vertex_colors);
//    glEnableVertexAttribArray(ATTRIBUTE_COLOUR);
//
//#ifdef DEBUG
//    if (!arglGLValidateProgram(program)) {
//        ARLOGe("[ARView drawView:] Error: shader program %d validation failed.\n", program);
//        return;
//    }
//#endif
//
//    for (i = 0; i < 6; i++) {
//        glDrawElements(GL_TRIANGLE_FAN, 4, GL_UNSIGNED_SHORT, &(cube_faces[i][0]));
//    }
//    glVertexAttribPointer(ATTRIBUTE_COLOUR, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, cube_vertex_colors_black);
//    glEnableVertexAttribArray(ATTRIBUTE_COLOUR);
//    for (i = 0; i < 6; i++) {
//        glDrawElements(GL_LINE_LOOP, 4, GL_UNSIGNED_SHORT, &(cube_faces[i][0]));
//    }
}

- (void)updateWithTimeDelta:(NSTimeInterval)timeDelta {
    if (YES) {
        gDrawRotateAngle += (float)timeDelta * 45.0f; // Rotate cube at 45 degrees per second.
        if (gDrawRotateAngle > 360.0f) {
            gDrawRotateAngle -= 360.0f;
        }
    }
}

- (void)setupWithProjection:(float *)viewProjection cameraPoseValid:(BOOL)cameraPoseValid {
    if (!program) {
        GLuint vertShader = 0, fragShader = 0;
        // A simple shader pair which accepts just a vertex position and colour, no lighting.
        const char vertShaderString[] =
            "attribute vec4 position;\n"
            "attribute vec4 colour;\n"
            "uniform mat4 modelViewProjectionMatrix;\n"
            "varying vec4 colourVarying;\n"
            "void main()\n"
            "{\n"
            "gl_Position = modelViewProjectionMatrix * position;\n"
            "colourVarying = colour;\n"
            "}\n";
        const char fragShaderString[] =
            "#ifdef GL_ES\n"
            "precision mediump float;\n"
            "#endif\n"
            "varying vec4 colourVarying;\n"
            "void main()\n"
            "{\n"
            "gl_FragColor = colourVarying;\n"
            "}\n";

        if (program) {
            arglGLDestroyShaders(0, 0, program);
        }
        program = glCreateProgram();
        if (!program) {
            ARLOGe("drawCube: Error creating shader program.\n");
            return;
        }

        if (!arglGLCompileShaderFromString(&vertShader, GL_VERTEX_SHADER, vertShaderString)) {
            ARLOGe("drawCube: Error compiling vertex shader.\n");
            arglGLDestroyShaders(vertShader, fragShader, program);
            program = 0;
            return;
        }
        if (!arglGLCompileShaderFromString(&fragShader, GL_FRAGMENT_SHADER, fragShaderString)) {
            ARLOGe("drawCube: Error compiling fragment shader.\n");
            arglGLDestroyShaders(vertShader, fragShader, program);
            program = 0;
            return;
        }
        glAttachShader(program, vertShader);
        glAttachShader(program, fragShader);

        glBindAttribLocation(program, ATTRIBUTE_VERTEX, "position");
        glBindAttribLocation(program, ATTRIBUTE_COLOUR, "colour");
        if (!arglGLLinkProgram(program)) {
            ARLOGe("drawCube: Error linking shader program.\n");
            arglGLDestroyShaders(vertShader, fragShader, program);
            program = 0;
            return;
        }
        arglGLDestroyShaders(vertShader, fragShader, 0); // After linking, shader objects can be deleted.

        // Retrieve linked uniform locations.
        uniforms[UNIFORM_MODELVIEW_PROJECTION_MATRIX] = glGetUniformLocation(program, "modelViewProjectionMatrix");
    }
    glUseProgram(program);
}

@end

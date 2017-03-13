//
//  Geometry.m
//  OpenESRD
//
//  Created by wangyang on 2016/9/30.
//  Copyright © 2016年 wangyang. All rights reserved.
//

#import "GLGeometry.h"
#import "UIImage+GL.h"
#import "ObjFile.h"
#import "GeometryDefines.h"

@interface GLGeometry () {
    int uniforms[NUM_UNIFORMS];
    GLfloat rotation;
}

@property (assign, nonatomic) GLsizei indiceCount;
@property (assign, nonatomic) GLsizei vertexStride;

@property (assign, nonatomic) GLuint texture;
@property (strong, nonatomic) ObjFile *obj;
@end

@implementation GLGeometry

- (instancetype)initWithWaveFrontFilePath:(NSString *)file {
    self = [super init];
    if (self) {
        self.glProgram = [[GLProgram alloc]initWithVertexShaderFileName:@"Shader" fragmentShaderFileName:@"Shader"];
        [self createTexture];

        self.obj = [ObjFile new];
        [self setupVAO];
    }
    return self;
}

- (void)setupVAO {
    glGenVertexArraysOES(1, &_vao);
    glBindVertexArrayOES(self.vao);

    glBindBuffer(GL_ARRAY_BUFFER, self.obj.vertexVBO);

    GLuint positionLocation = glGetAttribLocation(self.glProgram.value, "position");
    glEnableVertexAttribArray(positionLocation);
    glVertexAttribPointer(positionLocation, 3, GL_FLOAT, GL_FALSE, self.obj.vertexStride, 0);

    GLuint normalLocation = glGetAttribLocation(self.glProgram.value, "normal");
    glEnableVertexAttribArray(normalLocation);
    glVertexAttribPointer(normalLocation, 3, GL_FLOAT, GL_FALSE, self.obj.vertexStride, BUFFER_OFFSET(3 * sizeof(GLfloat)));

    GLuint uvLocation = glGetAttribLocation(self.glProgram.value, "uv");
    glEnableVertexAttribArray(uvLocation);
    glVertexAttribPointer(uvLocation, 2, GL_FLOAT, GL_FALSE, self.obj.vertexStride, BUFFER_OFFSET(6 * sizeof(GLfloat)));

    //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.obj.indiceVBO);

    glBindVertexArrayOES(0);
}

- (void)createTexture {

    GLsizei width, height;
    GLubyte *textureData = [UIImage dataFromImage:@"texture.png" width:&width height:&height];
    
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)draw {
    
    [self update:0.2];
    
    glUseProgram(self.glProgram.value);
    
    glUniformMatrix4fv([self.glProgram uniform:UNIFORM_VIEWPROJECTION], 1, 0, self.viewProjection.m);
    glUniformMatrix4fv([self.glProgram uniform:UNIFORM_MODEL_MATRIX], 1, 0, self.modelMatrix.m);
    glUniformMatrix3fv([self.glProgram uniform:UNIFORM_NORMAL_MATRIX], 1, 0, self.normalMatrix.m);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.texture);
    glBindVertexArrayOES(self.vao);
    //glDrawElements(GL_TRIANGLES, self.obj.indiceCount, GL_UNSIGNED_INT, 0);
    glDrawArrays(GL_TRIANGLES, 0, self.obj.vertexCount);
    glBindVertexArrayOES(0);
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)update:(NSTimeInterval)interval {
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    //modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, rotation, 1.0f, 1.0f, 1.0f);
//    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);

    GLKMatrix3 normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);

    self.normalMatrix = normalMatrix;
    self.modelMatrix = modelViewMatrix;

    rotation += 0;//interval * 0.5f;
}

@end

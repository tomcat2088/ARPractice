//
//  ObjLoader.m
//  OpenESRD
//
//  Created by wang yang on 2016/10/6.
//  Copyright © 2016年 wangyang. All rights reserved.
//

#import "ObjFile.h"

#import "tiny_obj_loader.h"

@implementation ObjFile

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *filePath = [[NSBundle mainBundle]pathForResource:@"monkey" ofType:@".obj"];
        [self loadFromObjFile:filePath];
    }
    return self;
}

- (void)loadFromObjFile:(NSString *)file {
    std::string inputfile = std::string([file cStringUsingEncoding:NSUTF8StringEncoding]);
    tinyobj::attrib_t attrib;
    std::vector<tinyobj::shape_t> shapes;
    std::vector<tinyobj::material_t> materials;

    std::string err;
    bool ret = tinyobj::LoadObj(&attrib, &shapes, &materials, &err, inputfile.c_str());

    if (!err.empty()) { // `err` may contain warning message.
        NSLog(@"%@", [NSString stringWithUTF8String:err.c_str()]);
    }

    if (!ret) {
        exit(1);
    }

    std::vector<GLfloat> vertices;
    std::vector<tinyobj::index_t> indices;
    for (size_t s = 0; s < shapes.size(); s++) {
        for (size_t index = 0; index < shapes[s].mesh.indices.size(); index++) {
            tinyobj::index_t indice = shapes[s].mesh.indices[index];
            indices.push_back(indice);
        }
    }
    std::vector<GLfloat> buffer = [self generateVertexBuffer:attrib indices:indices];
    [self generateVertexVBO:buffer];
    [self generateIndiceVBO:indices];
}

- (std::vector<GLfloat>)generateVertexBuffer:(tinyobj::attrib_t)attrib indices:(std::vector<tinyobj::index_t>)indices {
    std::vector<GLfloat> vertices;
    for (size_t i = 0; i < indices.size(); i++) {
        tinyobj::index_t indice = indices[i];
        vertices.push_back(attrib.vertices[indice.vertex_index * 3 + 0]);
        vertices.push_back(attrib.vertices[indice.vertex_index * 3 + 1]);
        vertices.push_back(attrib.vertices[indice.vertex_index * 3 + 2]);
        vertices.push_back(attrib.normals[indice.normal_index * 3 + 0]);
        vertices.push_back(attrib.normals[indice.normal_index * 3 + 1]);
        vertices.push_back(attrib.normals[indice.normal_index * 3 + 2]);
        vertices.push_back(attrib.texcoords[indice.texcoord_index * 2 + 0]);
        vertices.push_back(attrib.texcoords[indice.texcoord_index * 2 + 1]);
    }
    return vertices;
}

- (void)generateVertexVBO:(std::vector<float>)vertices {
    GLfloat *pVertices = vertices.data();
    glGenBuffers(1, &_vertexVBO);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * vertices.size(), pVertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    self.vertexStride = sizeof(GLfloat) * 8;
    self.vertexCount = (GLsizei)(vertices.size() / 8);
}

- (void)generateIndiceVBO:(std::vector<tinyobj::index_t>)indices {
    std::vector<GLuint> vertexIndices;
    for (size_t index = 0; index < indices.size(); index++) {
        vertexIndices.push_back((GLuint)indices[index].vertex_index);
    }
    GLuint *pIndices = (GLuint *)vertexIndices.data();
    glGenBuffers(1, &_indiceVBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indiceVBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLuint) * vertexIndices.size(), pIndices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    self.indiceCount = (GLsizei)vertexIndices.size();
}

@end

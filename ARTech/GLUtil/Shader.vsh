//
//  Shader.vsh
//  OpenESRD
//
//  Created by wangyang on 2016/9/30.
//  Copyright © 2016年 wangyang. All rights reserved.
//

attribute vec4 position;
attribute vec3 normal;
attribute vec2 uv;

varying lowp vec4 colorVarying;
varying lowp vec2 uvVarying;
varying highp float lightStrength;

uniform mat4 viewProjection;
uniform mat4 modelMatrix;
uniform mat3 normalMatrix;

void main()
{
    mat4 modelViewProjectionMatrix = viewProjection * modelMatrix;
    
    vec3 eyeNormal = normalize(normalMatrix * normal);
    vec3 lightPosition = vec3(0.0, 10.0, 35.0);
    vec4 diffuseColor = vec4(1.0,1.0, 1.0, 0.2);
    vec4 eyeLight = vec4(lightPosition,1.0);// * viewProjection;

    float nDotVP = max(0.0, dot(eyeNormal, normalize(lightPosition)));
    lightStrength = nDotVP;
    colorVarying = diffuseColor * nDotVP;
    uvVarying = uv;
    gl_Position = viewProjection * position;
}

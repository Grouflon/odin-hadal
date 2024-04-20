#version 330

// Input vertex attributes (from vertex shader)
in vec4 fragColor;
in float fragDistance;

// Output fragment color
out vec4 finalColor;

// NOTE: Add here your custom variables
uniform vec2 points[2];
uniform float dashSize;
uniform float dashOffset;

void main()
{
    float a = step(mod((fragDistance - dashOffset) / (dashSize * 2.0), 2.0), 1.0);
    
    finalColor = vec4(fragColor.x, fragColor.y, fragColor.z, fragColor.w * a);
}
#version 330

// Input vertex attributes
in vec3 vertexPosition;
in vec4 vertexColor;

// Input uniform values
uniform mat4 mvp;

// Output vertex attributes (to fragment shader)
out vec4 fragColor;
out float fragDistance;

// NOTE: Add here your custom variables
uniform vec2 points[2];

void main()
{
    // Send vertex attributes to fragment shader
    fragColor = vertexColor;
    vec2 direction = normalize(points[1] - points[0]);
    fragDistance = dot(vertexPosition.xy - points[0], direction);

    // Calculate final vertex position
    gl_Position = mvp*vec4(vertexPosition, 1.0);
}
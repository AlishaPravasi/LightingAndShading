#version 300 es

// Per-vertex variables from the vertex buffers
in vec3 vPosition;           // position of vertex (x, y, z) in world coords
in vec3 vNormal;             // normal of the vertex in world coords

// We need to separate projection and location so we can put points into view/camera
// coordinates to do lighting calculations
uniform mat4 projectionMat;   // projection matrix
uniform mat4 viewMat;         // the view/camera location matrix
uniform mat4 modelMat;        // model matrix

// Light info
uniform vec3 lightPosition;   // light position in world coords
uniform vec3 lightColor;
uniform float ambientFactor;

// Material properties (K)
uniform vec3 materialColor;
uniform float shiny;

// Which Phong components to use
uniform bool ambientOn;
uniform bool diffuseOn;
uniform bool specularOn;

// Interpolated values for the fragment shader
out vec3 fColor;             // output color to send to fragment shader

void main() {

    // transform the vertex, normal, and light position into viewing/camera coordinates
    // If we do view coordinate (VC) then we don't need to pass in the eye position
    // since it is at (0,0,0) in VC - and we already need the viewMatrix anyway
    // Note that we need to use 4d homogeneous coords for the multiplication

    // The position and normal both need to be modified by the model matrix first
    // then the view to get into view coords
    // 1 for w since point
    vec4 posVC4 = viewMat * modelMat * vec4(vPosition.xyz, 1.0);
    // 0 for w since vector - doesn't transform correct with w=1
    vec4 normVC4 = viewMat * modelMat * vec4(vNormal.xyz, 0.0);

    // We will assume point light source so we add 1
    // We could have passed in a 4d point with 1 for point and 0 for directional source
    // The light doesn't need to be transformed with the model matrix since it is
    // independent of the model. It does, however, need to be put into view coords
    // for performing the lighting calculations below
    vec4 lightVC4 = viewMat * vec4(lightPosition.xyz, 1.0);

    // Always have to assign gl_Position - projected into clip coordinates
    gl_Position = projectionMat * posVC4;

    // Now we can calculate the color at the vertex to pass to the fragment shader
    // This is the Gouraud shading (with Phong lighting model)
    // Note that we could also do per-pixel Phong shading rather than Gouraud.
    // This would require interpolating the vertex normals across the fragment
    // like it currently does for color with Gouraud and then do the calculations
    // per pixel in the fragment shader. Phong shading is more computations but
    // can produce better results. We will just do Gouraud in this lab to introduce lighting.

    // For the lighting calculations, we use the pos, norm, and light in VC
    // We already converted them above but will just use the 3d version for the
    // lighting calculations since we are no longer doing matrix mults

    // The normal we were given is probably a unit vector already, but just to be sure
    vec3 normVC3 = normalize(normVC4.xyz);

    // But we should not normalize these since they are points and not vectors
    vec3 posVC3 = posVC4.xyz;
    vec3 lightVC3 = lightVC4.xyz;

    // Calculate the PHONG lighting model

    // Ambient calculation
    vec3 ambientComponent = ambientFactor * materialColor * lightColor;

    // Diffuse calculation
    vec3 lightDirection = normalize(lightVC3 - posVC3);
    float diffuseIntensity = max(dot(normVC3, lightDirection), 0.0);
    vec3 diffuseComponent = diffuseIntensity * materialColor * lightColor;

    // Specular calculation
    vec3 viewDirection = normalize(-posVC3);
    vec3 halfwayVector = normalize(lightDirection + viewDirection);
    float specularIntensity = pow(max(dot(normVC3, halfwayVector), 0.0), shiny);
    vec3 specularComponent = specularIntensity * materialColor * lightColor;

    // Add the components together, conditionally based on the boxes the user checked
    vec3 phong = vec3(0, 0, 0);
    if (ambientOn) {
        phong += ambientComponent;
    }
    if (diffuseOn) {
        phong += diffuseComponent;
    }
    if (specularOn) {
        phong += specularComponent;
    }

    // Send the final shade from the phong model down to the fragment shader
    fColor = phong;
}

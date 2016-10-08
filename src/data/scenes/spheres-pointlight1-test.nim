let objects = @[
  Object(
    name: "ball3",
    geometry: Sphere(o: point(-5.0, 2.0, -10.0), r: 2),
    material: Material(albedo: vec3(0.1, 0.7, 0.2))
  ),
  Object(
    name: "ground",
    geometry: Plane(o: point(0.0, 0.0, 0.0), n: vec(0.0, 1.0, 0.0)),
    material: Material(albedo: vec3(0.4))
  )
]


var lights = newSeq[Light]()

lights.add(
  PointLight(color: vec3(1.0, 0.8, 0.5), intensity: 2000.0,
               pos: vec(3.0, 6.0, -12.0))
)


var scene = Scene(
  bgColor: vec3(0.0, 0.0, 0.0),

  objects: objects,
  lights: lights,

  fov: 50.0,
  cameraToWorld: mat4(1.0).rotate(vec3(1.0, 0, 0), degToRad(-12.0))
                          .translate(vec3(1.0, 5.5, 3.5))
)

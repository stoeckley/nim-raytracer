import math
import glm
import mathutils


type
  Object* = ref object of RootObj
    o*: Vec3[float]
    color*: Vec3[float]

  Sphere* = ref object of Object
    r*: float

  Plane* = ref object of Object
    n*: Vec3[float]

type
  Ray* = object
    o*, dir*: Vec3[float]   # origin and normalized direction vector
    objHit*: Object         # object hit by the ray
    tHit*: float            # point t on the ray where it hit the object


method `$`*(o: Object): string {.base.} = ""

method `$`*(s: Sphere): string =
  result = "(Sphere: o=" & $s.o & ", color=" & $s.color &
           ", r=" & $s.r & ")"

method `$`*(p: Plane): string =
  result = "(Plane: o=" & $p.o & ", color=" & $p.color &
           ", n=" & $p.n & ")"


proc `$`*(r: Ray): string =
  var objHit = if r.objHit == nil: "nil" else: $r.objHit
  result = "(Ray: o=" & $r.o & ", dir=" & $r.dir &
           ", objHit=" & objHit & ", tHit=" & $r.tHit & ")"


method str*(o: Object): string = ""

method str*(s: Sphere): string =
  result = "(Sphere: o=" & $s.o & ", color=" & $s.color &
           ", r=" & $s.r & ")"

method str*(p: Plane): string =
  result = "(Plane: o=" & $p.o & ", color=" & $p.color &
           ", n=" & $p.n & ")"


method intersect*(o: Object, r: var Ray): bool {.base.} = false

method intersect*(s: Sphere, r: var Ray): bool =
  var
    a = r.dir.x * r.dir.x +
        r.dir.y * r.dir.y +
        r.dir.z * r.dir.z

    b = 2 * (r.dir.x * (r.o.x - s.o.x) +
             r.dir.y * (r.o.y - s.o.y) +
             r.dir.z * (r.o.z - s.o.z))

    c = (s.o.x - r.o.x) * (s.o.x - r.o.x) +
        (s.o.y - r.o.y) * (s.o.y - r.o.y) +
        (s.o.z - r.o.z) * (s.o.z - r.o.z) - s.r * s.r

    delta = quadraticDelta(a, b, c)

  if delta < 0.0:
    result = false
  else:
    var (t1, t2) = solveQuadratic(a, b, c, delta)
    r.tHit = min(t1, t2)
    r.objHit = s
    result = true


method intersect*(p: Plane, r: var Ray): bool =
  var denom = p.n.dot(r.dir)
  if abs(denom) > 1e-6:
    var t = (p.o - r.o).dot(p.n) / denom
    if t >= 0:
      r.objHit = p
      r.tHit = t
      result = true


# Tests

when isMainModule:
  var
    s = Sphere(o: vec3(7.0, 9.0, -5.0), color: vec3(0.0, 0.6, 0.2), r: 4.4)
    r = Ray(o: vec3(7.0, 9.0, 0.0), dir: vec3(0.0, 0.0, -1.0))
  echo r

  var
    p = Plane(o: vec3(1.0, 2.0, 3.0),
              color: vec3(0.2, 0.75, 0.1),
              n: vec3(1.0, 0.0, 0.0))

    intersects = s.intersect(r)

  assert intersects == true
  assert r.objHit == s
  var objHit = r.objHit
  echo objHit.str
  assert eq(r.tHit, 0.6)

  echo s
  echo p
  echo r

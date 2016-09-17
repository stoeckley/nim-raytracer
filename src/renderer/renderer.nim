import math, random, strutils, terminal, times
import glm

import ../utils/framebuf
import geom, light, shader, sampling, stats

export geom, framebuf, light, stats


type
  AntialiasKind* = enum
    akNone, akGrid, akJittered, akMultiJittered, akCorrelatedMultiJittered

  Antialias* = ref AntialiasObj
  AntialiasObj = object
    gridSize*: Natural
    case kind*: AntialiasKind
    of akNone: discard
    of akGrid: discard
    of akJittered: discard
    of akMultiJittered: discard
    of akCorrelatedMultiJittered: discard

type
  Options* = object
    width*, height*: Natural
    fov*: float
    cameraToWorld*: Mat4x4[float]
    antialias*: Antialias
    shadowBias*: float
    bgColor*: Vec3[float]

type
  Scene* = object
    objects*: seq[Object]
    lights*: seq[Light]



proc primaryRay(w, h: Natural, x, y, fov: float,
                cameraToWorld: Mat4x4[float]): Ray =

  const DEFAULT_CAMERA_POS = point(0.0, 0.0, 0.0)

  let
    r = w / h
    f = tan(degToRad(fov) / 2)
    cx = ((2 * x * r) / w.float - r) * f
    cy = (1 - 2 * y / h.float) * f

  var o = cameraToWorld * DEFAULT_CAMERA_POS
  var dir = cameraToWorld * vec(cx, cy, -1).normalize

  result = Ray(o: o, dir: dir)


proc trace(ray: var Ray, objects: seq[Object], stats: var Stats) =
  var
    tmin = Inf
    objmin: Object = nil

  for obj in objects:
    var hit = obj.intersect(ray)
    inc stats.numIntersectionTests

    if hit and ray.tHit < tmin:
      tmin = ray.tHit
      objmin = obj
      inc stats.numIntersectionHits

  ray.tHit = tmin
  ray.objHit = objmin


proc shade(ray: Ray, scene: Scene, opts: Options,
           stats: var Stats, debug: bool = false): Vec3[float] =

  if ray.objHit == nil:
    result = opts.bgColor
  else:
    let
      obj = ray.objHit
      hit = ray.o + (ray.dir * ray.tHit)
      hitNormal = obj.normal(hit)
      viewDir = ray.dir * -1

    if debug:
        echo "obj: ", obj
        echo "hit: ", hit
        echo "hitNormal: ", hitNormal
        echo "viewDir: ", viewDir

    result = vec3(0.0)

    for light in scene.lights:
      if debug:
        echo "----------------------------------------"
        echo "light: ", light
      let lightDir = light.direction(hit) * -1
      if debug:
        echo "lightDir: ", lightDir
      var shadowRay = Ray(o: hit + hitNormal * opts.shadowBias, dir: lightDir)
      if debug:
        echo "shadowRay: ", shadowRay
      trace(shadowRay, scene.objects, stats)
      if debug:
        echo "shadowRay (after trace): ", shadowRay
        echo "shadow.hit: ",  shadowRay.o + (shadowRay.dir * shadowRay.tHit)
      if shadowRay.objHit == nil:
        result = result + shadeDiffuse(obj, light, hitNormal, lightDir)
      if debug:
        echo "result: ", result


#    result = shadeFacingRatio(obj, hitNormal, viewDir)


proc calcPixelNoSampling(scene: Scene, opts: Options, x, y: Natural,
                         stats: var Stats): Vec3[float] =

  var ray = primaryRay(opts.width, opts.height, x.float, y.float, opts.fov,
                       opts.cameraToWorld)

  inc stats.numPrimaryRays
  trace(ray, scene.objects, stats)
  var debug = false
  if x == 160 and y == 125:
    debug = true
  result = shade(ray, scene, opts, stats, debug)


proc calcPixel(scene: Scene, opts: Options, x, y: Natural,
               samples: seq[Vec2[float]], stats: var Stats): Vec3[float] =

  result = vec3(0.0)

  for i in 0..samples.high:
    var ray = primaryRay(opts.width, opts.height,
                         x.float + samples[i].x,
                         y.float + samples[i].y,
                         opts.fov, opts.cameraToWorld)

    inc stats.numPrimaryRays
    trace(ray, scene.objects, stats)
    result = result + shade(ray, scene, opts, stats)

  result *= 1 / samples.len


proc renderLine*(scene: Scene, opts: Options,
                 fb: var Framebuf, y: Natural,
                 step: Natural = 1, maxStep: Natural =  1): Stats =

  assert isPowerOfTwo(step)
  assert isPowerOfTwo(maxStep)
  assert maxStep >= step

  var
    stats = Stats()
    color: Vec3[float]

  for x in countup(0, opts.width-1, step):
    if step < maxStep:
      let mask = step * 2 - 1
      if ((x and mask) == 0) and ((y and mask) == 0):
        continue

    case opts.antialias.kind:
    of akNone:
      color = calcPixelNoSampling(scene, opts, x, y, stats)

    of akGrid:
      let m = opts.antialias.gridSize
      color = calcPixel(scene, opts, x, y,
                        samples = grid(m, m), stats)

    of akJittered:
      let m = opts.antialias.gridSize
      color = calcPixel(scene, opts, x, y,
                        samples = jitteredGrid(m, m), stats)

    of akMultiJittered:
      let m = opts.antialias.gridSize
      color = calcPixel(scene, opts, x, y,
                        samples = multiJittered(m, m), stats)

    of akCorrelatedMultiJittered:
      let m = opts.antialias.gridSize
      color = calcPixel(scene, opts, x, y,
                        samples = correlatedMultiJittered(m, m), stats)

    if step > 1:
      for i in x..<min(x+step, opts.width):
        for j in y..<min(y+step, opts.height):
          fb[i,j] = color
    else:
      fb[x,y] = color

  result = stats


proc initRenderer*() =
  randomize()


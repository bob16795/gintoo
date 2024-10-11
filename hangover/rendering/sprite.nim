import hangover/core/types/texture
import hangover/core/types/vector2
import hangover/core/types/color
import hangover/core/types/point
import hangover/core/types/rect
import hangover/core/types/shader
import options

type
  Sprite* = ref object of RootObj
    ## a sprite object stores a source rect and texture
    texture*: Texture   ## the texture
    sourceBounds*: Rect ## the source rect
    shader*: Shader     ## the shader to use

proc newSprite*(texture: Texture, x, y, w, h: float32): Sprite =
  ## creates a new sprite from a texture
  ## bounds are uv coords
  result = Sprite()
  result.texture = texture
  result.sourceBounds = newRect(x, y, w, h)

proc newSprite*(texture: Texture, bounds: Rect): Sprite =
  ## creates a new sprite from a texture
  ## bounds are uv coords
  result = Sprite()
  result.texture = texture
  result.sourceBounds = bounds

proc setShader*(this: Sprite, shader: Shader): Sprite =
  ## sets the sprites shader
  result = this
  result.shader = shader
  return result

method draw*(
  sprite: Sprite,
  target: Rect,
  rotation: float32 = 0,
  color: Color = newColor(255, 255, 255),
  layer: range[0..500] = 0,
  shader: Shader = nil,
  params: seq[TextureParam] = @[],
  rotation_center = newVector2(0.5),
  contrast: ContrastEntry = ContrastEntry(mode: fg),
) {.base.} =
  ## draws a sprite at `target`

  # get target bounds
  var trgSize = target.size

  # if the size is 0, get the origonal bounds
  if target.size == newVector2(0, 0):
    trgSize = sprite.sourceBounds.size

  # draw
  sprite.texture.draw(
    sprite.sourceBounds,
    newRect(target.location, trgSize),
    shader = if shader == nil:
      sprite.shader
    else:
      shader,
    color = color,
    rotation = rotation,
    layer = 0,
    params = params,
    rotation_center = rotation_center,
    contrast = contrast,
  )

method draw*(
  sprite: Sprite,
  position: Vector2,
  rotation: float32,
  size: Vector2 = newVector2(0, 0),
  color: Color = newColor(255, 255, 255, 255),
  rotation_center = newVector2(0.5),
  contrast: ContrastEntry = ContrastEntry(mode: fg),
) {.deprecated: "Use targetRect instead", base.} =
  ## old sprite draw proc
  sprite.draw(
    newRect(position, size),
    rotation,
    color,
    rotation_center = rotation_center,
    contrast = contrast,
  )

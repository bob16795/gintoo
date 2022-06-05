import core/types/texture
import core/types/vector2
import core/types/color
import core/types/point
import core/types/rect


type
  Sprite* = object of RootObj
    texture*: Texture
    sourceBounds*: Rect

proc newSprite*(texture: Texture, x, y, w, h: float32): Sprite =
  ## creates a new sprite from a texture
  ## bounds are uv coords
  result.texture = texture
  result.sourceBounds = newRect(x, y, w, h)

proc newSprite*(texture: Texture, bounds: Rect): Sprite =
  ## creates a new sprite from a texture
  ## bounds are uv coords
  result.texture = texture
  result.sourceBounds = bounds

proc draw*(sprite: Sprite, target: Rect, rotation: float32 = 0, color: Color = newColor(255, 255, 255)) =
  ## draws a sprite at `target`
  var trgSize = target.size
  if target.size == newVector2(0, 0):
    trgSize = sprite.sourceBounds.size
  sprite.texture.draw(sprite.sourceBounds, newRect(target.location,
                        trgSize), color = color, rotation = rotation)

proc draw*(sprite: Sprite, position: Vector2, rotation: float32,
    size: Vector2 = newVector2(0, 0), c: Color = newColor(255, 255, 255, 255)) {.deprecated: "Use targetRect instead".} =
  draw(sprite, newRect(position, size), rotation, c)

import core/types/vector2
import core/types/point
import core/types/color
import core/types/rect
import core/types/font
import ui/elements/uielement
import ui/types/uisprite

type
  UIGroup* = ref object of UIElement
    elements*: seq[UIElement]
    hasPopupAbove*: bool

proc newUIGroup*(bounds: UIRectangle): UIGroup =
  result = UIGroup()
  result.isActive = true
  result.bounds = bounds

proc add*(g: var UIGroup, e: UIElement) =
  g.elements.add(e)

proc clear*(g: var UIGroup) =
  g.elements = @[]

method checkHover*(g: UIGroup, parentRect: Rect, mousePos: Vector2): bool =
  g.focused = false
  if not g.isActive:
    return false
  if g.isDisabled != nil and g.isDisabled():
    return false

  var bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.elements.len:
    if g.elements[i].checkHover(bounds, mousePos):
      g.focused = true

method click*(g: UIGroup, button: int) =
  for i in 0..<g.elements.len:
    if g.elements[i].focused:
      g.elements[i].click(button)



method draw*(g: UIGroup, parentRect: Rect) =
  if not g.isActive:
    return
  var bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.elements.len:
    g.elements[i].draw(bounds)

method update*(g: var UIGroup, parentRect: Rect, mousePos: Vector2,
    dt: float32): bool =
  if not g.isActive:
    return
  var bounds = g.bounds.toRect(parentRect)
  for i in 0..<g.elements.len:
    discard g.elements[i].update(bounds, mousePos, dt)
  return false

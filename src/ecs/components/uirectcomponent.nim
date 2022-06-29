import core/templates
import ecs/types
import ecs/component
import core/events

import ui/types/uirectangle
import core/types/vector2
import core/types/rect
import rectcomponent

import ecs/genmacros

{.experimental: "codeReordering".}

component UIRectComponent:
  var
    rect: UIRectangle
    children: seq[Entity]
    bounds: Rect
    prect: Rect
    root: bool

  proc updateRectComponent() =
    this.bounds = this.rect.toRect(this.prect)
    parent[RectComponentData].size = this.bounds.size
    parent[RectComponentData].position = this.bounds.location
    for child in this.children:
      child[UIRectComponentData].prect = this.bounds
      updateRectComponent(child)

  proc eventResize(size: tuple[w, h: int32]): bool =
    if this.root:
      this.prect = newRect(0, 0, size.w.float32, size.h.float32)
      parent.updateRectComponent()
  
  proc construct(parentRect: Entity,
                 rect: UIRectangle) =
    this.rect = rect
    if parentRect == nil:
      this.root = true
      return
    parentRect[UIRectComponentData].children &= parent
    this.prect = parentRect[UIRectComponentData].bounds
    this.bounds = this.rect.toRect(this.prect)

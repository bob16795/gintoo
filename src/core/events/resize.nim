createEvent(EVENT_RESIZE)
createEvent(EVENT_RESIZE_DONE)

proc sizeCB*(win: Window, res: tuple[w, h: int32]) =
  var r = res
  sendEvent(EVENT_RESIZE, addr r)

proc resizeCB*(win: Window, res: tuple[w, h: int32]) =
  var r = res
  sendEvent(EVENT_RESIZE_DONE, addr r)
import loop
import glfw
import types/font
import events
import audio

template Game*(body: untyped) =

  proc main() =
    proc Setup(): AppData

    var
      pc: float
      loadStatus: string
      ui: bool
      data = Setup()
      ctx = initGraphics(data)
      loop = newLoop(144)

    template setPercent(perc: float): untyped =
      pc = perc
      drawLoading(pc, loadStatus, ctx)
      glfw.pollEvents()
      if glfw.shouldClose(ctx.window):
        quit()
      finishDraw()
      finishRender(ctx)
      when defined(GinDebug):
        echo "loaded " & $(pc * 100).int & "% - " & loadStatus
    template setStatus(status: string): untyped =
      loadStatus = status
      drawLoading(pc, loadStatus, ctx)
      glfw.pollEvents()
      if glfw.shouldClose(ctx.window):
        quit()
      finishDraw()
      finishRender(ctx)
    template noUI() = ui = false

    body

    initAudio()
    initUIManager(data.size)


    setupEventCallbacks(ctx)

    Initialize(ctx)

    deinitFT()

    createListener(EVENT_RESIZE, (p: pointer) => loop.forceDraw(ctx))

    loop.updateProc =
      proc (dt: float): bool =
        glfw.pollEvents()
        if glfw.shouldClose(ctx.window):
          return true
        updateUI(dt)
        return Update(dt)

    loop.drawProc = proc (ctx: var GraphicsContext) =
      ui = true
      Draw(ctx)
      if ui:
        drawUI()
      finishRender(ctx)

    loop.nextTime = glfw.getTime()
    while not loop.done:
      loop.update(ctx)

    gameClose()

  main()

import ../lib/gl
import ../lib/stbi

import rect
import vector2
import color
import shader

type
  Texture* = object
    tex*: GLuint
    size*: Vector2

const
  vertexCode = """
#version 330 core
layout (location = 0) in vec4 vertex;
layout (location = 1) in vec4 tintColorIn;

uniform mat4 projection;
out vec2 texRect;
out vec4 tintColorGeo;

void main()
{
    gl_Position = projection * vec4(vertex.xy, 0.0, 1.0);
    texRect = vertex.zw;
    tintColorGeo = tintColorIn;
}
"""
  geoCode = """
#version 330 core
layout (lines) in;
layout (triangle_strip, max_vertices = 6) out;

in vec2 texRect[2];
in vec4 tintColorGeo[2];

out vec2 texCoords;
out vec4 tintColor;

void main() {
  gl_Position = vec4(gl_in[0].gl_Position.x, gl_in[0].gl_Position.y, gl_in[0].gl_Position.z, gl_in[0].gl_Position.w);
  texCoords = vec2(texRect[0].x, texRect[0].y);
  tintColor = tintColorGeo[0];
  EmitVertex();

  gl_Position = vec4(gl_in[1].gl_Position.x, gl_in[0].gl_Position.y, gl_in[1].gl_Position.z, gl_in[0].gl_Position.w);
  texCoords = vec2(texRect[1].x, texRect[0].y);
  tintColor = tintColorGeo[0];
  EmitVertex();

  gl_Position = vec4(gl_in[1].gl_Position.x, gl_in[1].gl_Position.y, gl_in[1].gl_Position.z, gl_in[1].gl_Position.w);
  texCoords = vec2(texRect[1].x, texRect[1].y);
  tintColor = tintColorGeo[0];
  EmitVertex();
  
  EndPrimitive();

  gl_Position = vec4(gl_in[0].gl_Position.x, gl_in[0].gl_Position.y, gl_in[0].gl_Position.z, gl_in[0].gl_Position.w);
  texCoords = vec2(texRect[0].x, texRect[0].y);
  tintColor = tintColorGeo[0];
  EmitVertex();

  gl_Position = vec4(gl_in[0].gl_Position.x, gl_in[1].gl_Position.y, gl_in[0].gl_Position.z, gl_in[1].gl_Position.w);
  texCoords = vec2(texRect[0].x, texRect[1].y);
  tintColor = tintColorGeo[0];
  EmitVertex();

  gl_Position = vec4(gl_in[1].gl_Position.x, gl_in[1].gl_Position.y, gl_in[1].gl_Position.z, gl_in[1].gl_Position.w);
  texCoords = vec2(texRect[1].x, texRect[1].y);
  tintColor = tintColorGeo[0];
  EmitVertex();
  
  EndPrimitive();
}
"""
  fragmentCode = """
#version 330 core
in vec2 texCoords;
in vec4 tintColor;

out vec4 color;

uniform sampler2D text;

void main()
{
    color = tintColor * texture(text, texCoords);
}
"""

var
  VAO, VBO: GLUint
  textureProgram*: Shader
  queue, pqueue: seq[tuple[u: bool, p: Shader, t: Texture, vs: seq[array[0..7,
      GLFloat]]]]
  buffers: seq[GLUint]
  cullSize: Vector2

template verts(ds, de: Vector2, ss, se: Vector2, c: Color): untyped =
  @[
    [ds.x, ds.y, ss.x, ss.y, c.rf, c.gf, c.bf, c.af],
    [de.x, de.y, se.x, se.y, c.rf, c.gf, c.bf, c.af],
  ]

proc resizeCull*(data: pointer) =
  var size = cast[ptr tuple[w, h: int32]](data)[]
  cullSize = newVector2(size.w, size.h)

proc addVBO*() =
  buffers &= 0.GLuint
  glGenBuffers(1, addr buffers[^1])

proc setVBOS*(count: int) =
  # echo $count
  if count < len(buffers):
    glDeleteBuffers((len(buffers) - count).GLsizei, addr buffers[count])
    buffers = buffers[0..<count]
  elif count > len(buffers):
    while count > len(buffers):
      addVBO()

proc setupTexture*() =
  glGenVertexArrays(1, addr VAO)
  addVBO()
  glBindVertexArray(VAO)
  textureProgram = newShader(vertexCode, geoCode, fragmentCode)
  textureProgram.registerParam("tintColor", SPKFloat4)
  textureProgram.registerParam("projection", SPKProj4)

proc newTexture*(image: string): Texture =
  glGenTextures(1, addr result.tex)

  glEnable(GL_TEXTURE_2D)
  glBindTexture(GL_TEXTURE_2D, result.tex)

  # set the texture wrapping/filtering options
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
      GL_NEAREST.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

  # load the texture
  var
    width, height, channels: cint
    data: pointer = stbi_load(image, width, height, channels, 4)
  if data == nil:
    quit "failed to load image"
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, width.GLsizei, height.GLsizei,
      0, GL_RGBA, GL_UNSIGNED_BYTE.GLenum, data)
  glGenerateMipmap(GL_TEXTURE_2D)
  glBindTexture(GL_TEXTURE_2D, 0)
  glDisable(GL_TEXTURE_2D)
  stbi_image_free(data)

  result.size = newVector2(width, height)

proc aabb*(a, b: Rect): bool =
  if a.x < b.x + b.width and
     a.x + a.width > b.x and
     a.y < b.y + b.height and
     a.y + a.height > b.y:
    return true


proc draw*(texture: Texture, srcRect, dstRect: Rect, program = textureProgram,
    color = newColor(255, 255, 255, 255)) =
  if (not dstRect.aabb(newRect(newVector2(0, 0), cullSize))): return
  var vertices = verts(dstRect.location, dstRect.location + dstRect.size,
      srcRect.location, srcRect.location + srcRect.size, color)
  if queue == @[]:
    queue &= (u: true, p: program, t: texture, vs: vertices)
    return
  if texture == queue[^1].t:
    queue[^1].vs &= vertices
  else:
    queue &= (u: true, p: program, t: texture, vs: vertices)

proc finishDraw*() =
  if queue != @[]:
    for i in 0..<len(queue):
      if pqueue.len() > i and queue[i] == pqueue[i]: queue[i].u = false

  # set texture
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)


  glActiveTexture(GL_TEXTURE0)
  glBindVertexArray(VAO)
  setVBOS(len(queue))
  for i in 0..<len(queue):
    var q = queue[i]
    q.p.use()
    var last = len(q.vs)
    var vertices = q.vs

    glBindTexture(GL_TEXTURE_2D, q.t.tex)
    glBindBuffer(GL_ARRAY_BUFFER, buffers[i])

    # update VBO
    if q.u:
      glBufferData(GL_ARRAY_BUFFER, GLsizeiptr(len(vertices) *
          sizeof(vertices[0])),
          addr(vertices[0]), GL_STREAM_DRAW)
    glVertexAttribPointer(0, 4, cGL_FLOAT, GL_FALSE.GLboolean, 8 * sizeof(
        GLfloat), cast[pointer](0))
    glEnableVertexAttribArray(0)
    glVertexAttribPointer(1, 4, cGL_FLOAT, GL_FALSE.GLboolean, 8 * sizeof(
        GLfloat), cast[pointer](4 * sizeof(GLfloat)))
    glEnableVertexAttribArray(1)
    glBindBuffer(GL_ARRAY_BUFFER, 0)

    # render
    glDrawArrays(GL_LINES, 0, (len(vertices)).GLsizei)
  glBindVertexArray(0)
  glBindTexture(GL_TEXTURE_2D, 0)
  glDisable(GL_BLEND)
  pqueue = queue
  queue = @[]

proc isDefined*(texture: Texture): bool =
  return texture.tex != 0

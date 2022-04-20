import ../lib/gl

type
  Shader* = object
    id*: GLuint

proc newShader*(vCode, fCode: string): Shader =
  var
    vShaderCode = [vCode.cstring]
    fShaderCode = [fCode.cstring]
    vertex, fragment: GLuint
    success: GLint
    infoLog: cstring = cast[cstring](alloc0(512))

  # vertex Shader
  vertex = glCreateShader(GL_VERTEX_SHADER)
  glShaderSource(vertex, 1, cast[cstringArray](addr vShaderCode), nil)
  glCompileShader(vertex)
  # print compile errors if any
  glGetShaderiv(vertex, GL_COMPILE_STATUS, addr success)
  if success == 0:
    glGetShaderInfoLog(vertex, 512, nil, infoLog)
    quit $infoLog

  # fragment Shader
  fragment = glCreateShader(GL_FRAGMENT_SHADER)
  glShaderSource(fragment, 1, cast[cstringArray](addr fShaderCode), nil)
  glCompileShader(fragment)
  # print compile errors if any
  glGetShaderiv(fragment, GL_COMPILE_STATUS, addr success)
  if success == 0:
    glGetShaderInfoLog(fragment, 512, nil, infoLog)
    quit $infoLog

  # shader program
  result.id = glCreateProgram()
  glAttachShader(result.id, vertex)
  glAttachShader(result.id, fragment)
  glLinkProgram(result.id)
  # print linking errors if any
  glGetProgramiv(result.id, GL_LINK_STATUS, addr success)
  if success == 0:
    glGetProgramInfoLog(result.id, 512, nil, infoLog)
    quit $infoLog

  # delete the shaders as they're linked into our program now and no longer necessary
  glDeleteShader(vertex)
  glDeleteShader(fragment)

proc use*(s: Shader) =
  glUseProgram(s.id)
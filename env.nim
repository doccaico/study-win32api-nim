import std/strformat, std/strutils
import winim/lean

# string types
# https://khchen.github.io/winim/winstr.html

block:
  const UserNameLength = 64
  var
    buffer = newWString(UserNameLength + 1)
    size = DWORD(len(buffer))

  GetUserName(buffer, addr size)

  echo fmt("username = {buffer}, size = {size}")


block:
  const MaxLength = 32767
  var
    name = "PATH"
    buffer = newWString(MaxLength)
    size = DWORD(len(buffer))

  GetEnvironmentVariable(name, buffer, size)

  for path in split($$buffer, ';'):
    echo path

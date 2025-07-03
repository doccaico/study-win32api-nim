import std/[random]
import winim/lean
import winim/inc/mmsystem

const WindowTitle = when defined(release) or defined(danger): "lifegame" else: "lifegame (debug)"
const CellSize = 2
const InitialCellCount = 40 * 2
const Fps = 30 div 2
const ScreenWidth = 480
const ScreenHeight = 640
const ColSize = (ScreenWidth div CellSize + 2)
const RowSize = (ScreenHeight div CellSize + 2)
const InitialCellColor = RGB(0, 0, 0)
const InitialBgColor = RGB(245, 245, 245)


type
  State = enum
    dead = 0
    alive = 1

type
  App = object
    board: array[RowSize, array[ColSize, State]]
    boardNeighbors: array[RowSize, array[ColSize, uint8]]
    cellColor: HBRUSH
    bgColor: HBRUSH
    cx: int32
    cy: int32

var
  app : App 
  frames: int = 0
  bitmap : HBITMAP 
  screenDC : HDC
  renderDC : HDC


proc shuffleBoard() =
  for i in 1..<RowSize - 1:
    let minN = 1
    let maxN = app.board[i].len - 2
    var j = maxN - 1
    while j > 0:
      let n = rand(minN..maxN)
      swap(app.board[i][j], app.board[i][n])
      dec j

proc newGame() =
  app.cellColor = CreateSolidBrush(InitialCellColor)
  app.bgColor = CreateSolidBrush(InitialBgColor) 
  for i in 1..<RowSize - 1:
    zeroMem(addr app.board[i], (sizeof State) * app.board[i].len)
    for j in 1..<ColSize - 1:
      if 1 <= j and j <= InitialCellCount:
        app.board[i][j] =  alive
  shuffleBoard()

proc clearBackGround() =
  SelectObject(renderDC, app.bgColor)
  PatBlt(renderDC, 0, 0, app.cx, app.cy, PATCOPY)

proc nextGeneration() =
  for i in 1..<RowSize - 1:
    for j in 1..<ColSize - 1:
      # top = top-left + top-middle + top-right
      let top = uint8(app.board[i - 1][j - 1]) + uint8(app.board[i - 1][j]) + uint8(app.board[i - 1][j + 1])
      # middle = left + right
      let middle = uint8(app.board[i][j - 1]) + uint8(app.board[i][j + 1])
      # bottom = bottom-left + bottom-middle + bottom-right
      let bottom = uint8(app.board[i + 1][j - 1]) + uint8(app.board[i + 1][j]) + uint8(app.board[i + 1][j + 1])

      app.board_neighbors[i][j] = top + middle + bottom;

  for i in 1..<RowSize - 1:
    for j in 1..<ColSize - 1:
      case app.board_neighbors[i][j]
      of 2:
        discard # Do nothing
      of 3:
        app.board[i][j] = alive
      else:
        app.board[i][j] = dead

proc render(hwnd: HWND) =
  SelectObject(renderDC, app.cellColor)
  for i in 1..<RowSize - 1:
    for j in 1..<ColSize - 1:
      if app.board[i][j] == alive:
        PatBlt(renderDC, int32(CellSize * (j - 1)), int32(CellSize * (i - 1)), CellSize, CellSize, PATCOPY)
  BitBlt(screenDC, 0, 0, ScreenWidth, ScreenHeight, renderDC, 0, 0, SRCCOPY)

proc setClientSize(app: var App, hwnd: HWND, sx: int, sy: int) =
  var
    rc1: RECT
    rc2: RECT
  GetWindowRect(hwnd, &rc1)
  GetClientRect(hwnd, &rc2)
  app.cx = int32(sx + ((rc1.right - rc1.left) - (rc2.right - rc2.left)))
  app.cy = int32(sy + ((rc1.bottom - rc1.top) - (rc2.bottom - rc2.top)))

proc WindowProc(hwnd: HWND, message: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
  case message
  of WM_CREATE:

    app.setClientSize(hwnd, ScreenWidth, ScreenHeight)
    let x = GetSystemMetrics(SM_CXSCREEN) div 2 - app.cx div 2
    let y = GetSystemMetrics(SM_CYSCREEN) div 2 - app.cy div 2
    SetWindowPos(hwnd, 0, x, y, app.cx, app.cy, SWP_NOZORDER or SWP_NOOWNERZORDER)
    return 0
  of WM_DESTROY:
    DeleteDC(screenDC);
    DeleteDC(renderDC);
    DeleteObject(bitmap);
    PostQuitMessage(0)
    return 0

  else:
    return DefWindowProc(hwnd, message, wParam, lParam)

proc main() =
  randomize()

  newGame();

  var
    hInstance = GetModuleHandle(nil)
    appName = "CGOL"
    hwnd: HWND
    msg: MSG
    wndclass: WNDCLASSEX

  wndclass.cbSize = UINT(sizeof WNDCLASSEX)
  wndclass.style = CS_HREDRAW or CS_VREDRAW
  wndclass.lpfnWndProc = WindowProc
  wndclass.cbClsExtra = 0
  wndclass.cbWndExtra = 0
  wndclass.hInstance = hInstance
  wndclass.hIcon = LoadIcon(0, IDI_APPLICATION)
  wndclass.hCursor = LoadCursor(0, IDC_ARROW)
  wndclass.hbrBackground = GetStockObject(WHITE_BRUSH)
  wndclass.lpszMenuName = nil
  wndclass.lpszClassName = appName
  wndclass.hIconSm = 0

  if RegisterClassEx(addr wndclass) == 0:
    MessageBox(0, "Error registering window class", appName, MB_ICONERROR)
    return

  hwnd = CreateWindowEx(
    0,
    appName,
    WindowTitle,
    WS_EX_OVERLAPPEDWINDOW or WS_MINIMIZEBOX or WS_SYSMENU,
    CW_USEDEFAULT,
    CW_USEDEFAULT,
    CW_USEDEFAULT,
    CW_USEDEFAULT,
    0,
    0,
    hInstance,
    nil)

  if hwnd != 0:
    ShowWindow(hwnd, SW_SHOW)
    UpdateWindow(hwnd)
  else:
    MessageBox(0, "Error CreateWindowEx failed", appName, MB_ICONERROR)
    return

  screenDC = GetDC(hwnd)
  bitmap = CreateCompatibleBitmap(screenDC, ScreenWidth, ScreenHeight)
  renderDC = CreateCompatibleDC(screenDC)

  SelectObject(renderDC, bitmap)
  SelectObject(renderDC, app.cellColor)

  const TicksPerSecond = Fps
  const SkipTicks = 1000 / TicksPerSecond
  
  timeBeginPeriod(1)
  SetPriorityClass(GetCurrentProcess(), REALTIME_PRIORITY_CLASS)
  var nextGameTick = timeGetTime()

  # A Game loop using PeekMessage function
  # https://gist.github.com/ChlorUpload/8c560f72cbd4222bdaff90a99db6ff40
  while true:
    if PeekMessage(addr msg, 0, 0, 0, PM_REMOVE): 
        if msg.message == WM_QUIT:
            break
        TranslateMessage(&msg)
        DispatchMessageW(&msg)
    else:
      Sleep(1)
      if timeGetTime() > nextGameTick:
        inc frames
        clearBackGround()
        nextGeneration()
        render(hwnd)
        nextGameTick +=  DWORD(SkipTicks)

  timeEndPeriod(1)
  return

main()

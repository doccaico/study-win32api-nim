import std/[random]
import winim/lean

const WindowTitle = when defined(release) or defined(danger): "lifegame" else: "lifegame (debug)"
const CellSize = 2
const InitialCellCount = 40 * 2
# const Fps = 30 / 2
const ScreenWidth = 480
const ScreenHeight = 640
const ColSize = (ScreenWidth div CellSize + 2)
const RowSize = (ScreenHeight div CellSize + 2)
const InitialCellColor = RGB(0, 0, 0)
const InitialBgColor = RGB(245, 245, 245)

# const InitialCellColor = RGB(50, 50, 50)
# # const InitialBgColor = RGB(245, 245, 245)
# const InitialBgColor = RGB(0, 0, 0)

# const InitialCellColor = CreateSolidBrush(RGB(50, 50, 50))
# const InitialBgColor = RGB(245, 245, 245)
# const InitialBgColor = CreateSolidBrush(RGB(0, 0, 0))

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

proc shuffleBoard(app: var App)

proc newGame(app: var App) =
  app.cellColor = CreateSolidBrush(InitialCellColor)
  app.bgColor = CreateSolidBrush(InitialBgColor) 
  for i in 1..<RowSize - 1:
    for j in 1..<ColSize - 1:
      app.board[i][j] = if 1 <= j and j <= InitialCellCount: alive else: dead
  app.shuffleBoard()

proc draw(app: App, buffer: HDC) =
  SelectObject(buffer, app.cellColor)
  for i in 1..<RowSize - 1:
    for j in 1..<ColSize - 1:
      if app.board[i][j] == alive:
        PatBlt(buffer, int32(CellSize * (j - 1)), int32(CellSize * (i - 1)), CellSize, CellSize, PATCOPY)

proc shuffleBoard(app: var App) =
  for i in 1..<RowSize - 1:
    shuffle(app.board[i])


proc clear(app: App, buffer: HDC) =
  SelectObject(buffer, app.bgColor)
  PatBlt(buffer, 0, 0, ScreenWidth, ScreenHeight, PATCOPY)

proc setClientSize(hwnd: HWND, sx: int, sy: int) =
  var
    rc1: RECT
    rc2: RECT
  GetWindowRect(hwnd, &rc1)
  GetClientRect(hwnd, &rc2)
  let cx = int32(sx + ((rc1.right - rc1.left) - (rc2.right - rc2.left)))
  let cy = int32(sy + ((rc1.bottom - rc1.top) - (rc2.bottom - rc2.top)))
  let x = GetSystemMetrics(SM_CXSCREEN) div 2 - cx div 2
  let y = GetSystemMetrics(SM_CYSCREEN) div 2 - cy div 2
  SetWindowPos(hwnd, 0, x, y, cx, cy, SWP_NOZORDER or SWP_NOOWNERZORDER)

proc WindowProc(hwnd: HWND, message: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
  var
    hdc: HDC
    app {.global.}: App 
    bitmap {.global.}: HBITMAP 
    buffer {.global.}: HDC
    brush {.global.}: HBRUSH

  case message
  of WM_CREATE:
    app.newGame();

    hdc = GetDC(hwnd)
    bitmap = CreateCompatibleBitmap(hdc, ScreenWidth, ScreenHeight)
    buffer = CreateCompatibleDC(hdc)

    SelectObject(buffer, bitmap)
    SelectObject(buffer, app.cellColor)
    ReleaseDC(hwnd, hdc);
    return 0
  of WM_PAINT:
    var ps: PAINTSTRUCT
    hdc = BeginPaint(hwnd, addr ps)
    defer: EndPaint(hwnd, addr ps)

    app.clear(buffer)
    app.draw(buffer)
    BitBlt(hdc, 0, 0, ScreenWidth, ScreenHeight, buffer, 0, 0, SRCCOPY)
    return 0

  of WM_DESTROY:
    DeleteObject(brush)
    PostQuitMessage(0)
    return 0

  else:
    return DefWindowProc(hwnd, message, wParam, lParam)

proc main() =
  randomize()

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
    setClientSize(hwnd, ScreenWidth, ScreenHeight)
    ShowWindow(hwnd, SW_SHOW)
    UpdateWindow(hwnd)

  while true:
    let ret = GetMessage(addr msg, 0, 0, 0)
    if ret != 0:
      if ret == -1:
        MessageBox(0, "Error GetMessage failed", appName, MB_ICONERROR)
        return
      else:
        TranslateMessage(addr msg)
        DispatchMessage(addr msg)
    else:
      break

main()

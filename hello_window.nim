import winim/lean

proc WindowProc(hwnd: HWND, message: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
  case message
  of WM_PAINT:
    var ps: PAINTSTRUCT
    var hdc = BeginPaint(hwnd, addr ps)
    defer: EndPaint(hwnd, addr ps)

    var rect: RECT
    GetClientRect(hwnd, addr rect)
    DrawText(hdc, "Hello, Windows!", -1, addr rect, DT_SINGLELINE or DT_CENTER or DT_VCENTER)
    return 0

  of WM_DESTROY:
    PostQuitMessage(0)
    return 0

  else:
    return DefWindowProc(hwnd, message, wParam, lParam)

proc main() =
  var
    hInstance = GetModuleHandle(nil)
    appName = "Hello My App"
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
    "The Hello Program",
    WS_OVERLAPPEDWINDOW,
    CW_USEDEFAULT,
    CW_USEDEFAULT,
    CW_USEDEFAULT,
    CW_USEDEFAULT,
    0,
    0,
    hInstance,
    nil)

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

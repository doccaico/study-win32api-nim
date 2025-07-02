when not defined(windows):
    {.error: "platform not supported!".}

switch("cc", "tcc")
switch("cpu", "amd64")
switch("threads", "off")
switch("verbosity", "0")

when defined(release) or defined(danger):
    switch("cc", "vcc")
    switch("opt", "size") # or "speed"
    switch("d", "lto")
    switch("d", "useMalloc")

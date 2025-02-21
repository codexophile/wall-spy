#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ../#lib/Functions.ahk

ImageCache := GetImageCache()

GetImageCache() {
  Array := []
  loop reg 'HKCU\Control Panel\Desktop' {
    if !InStr(A_LoopRegName, 'TranscodedImageCache') {
      continue
    }
    Readable := HexToAscii(RegRead())
    Readable2 := RegExReplace(Readable, '(.)\.', '$1')
    RegExMatch(Readable2, '(.:\\.+?)\.+\\\\', &Matches)
    if (!Matches) {
      continue
    }
    Array.Push(Matches[1])
  }
  return Array
}

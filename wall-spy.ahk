#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ../#lib/Functions.ahk

; Create the main GUI
MyGui := Gui("+Resize", "Wallpaper Manager")
MyGui.OnEvent("Size", GuiResize)

; Create left panel for image list
LV := MyGui.Add("ListView", "vImageList w300 h400", ["Image Path"])
LV.OnEvent("DoubleClick", ShowInExplorer)
LV.OnEvent("ItemSelect", UpdatePreview)

; Create right panel for preview
PreviewPic := MyGui.Add("Picture", "vPreview x+10 w400 h400")

; Add buttons
btnRefresh := MyGui.Add("Button", "xm y+10 w100", "Refresh List")
btnExplorer := MyGui.Add("Button", "x+10 w100", "Show in Explorer")
btnDelete := MyGui.Add("Button", "x+10 w100", "Delete Selected")
btnCopy := MyGui.Add("Button", "x+10 w100", "Copy Path")

btnRefresh.OnEvent("Click", RefreshList)
btnExplorer.OnEvent("Click", ShowInExplorer)
btnDelete.OnEvent("Click", DeleteSelected)
btnCopy.OnEvent("Click", CopyPath)

; Initialize
ImageCache := GetImageCache()
PopulateImageList()

; Show the GUI
MyGui.Show()

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

PopulateImageList() {
  LV.Delete()
  for path in ImageCache {
    LV.Add(, path)
  }
}

UpdatePreview(*) {
  if (SelectedRow := LV.GetNext()) {
    imagePath := LV.GetText(SelectedRow)
    try {
      PreviewPic.Value := imagePath
    } catch {
      PreviewPic.Value := "" ; Clear preview if image can't be loaded
    }
  }
}

ShowInExplorer(*) {
  if (SelectedRow := LV.GetNext()) {
    imagePath := LV.GetText(SelectedRow)
    Run("explorer.exe /select,`"" imagePath "`"")
  }
}

RefreshList(*) {
  ImageCache := GetImageCache()
  PopulateImageList()
}

DeleteSelected(*) {
  if (SelectedRow := LV.GetNext()) {
    imagePath := LV.GetText(SelectedRow)
    try {
      FileDelete(imagePath)
      LV.Delete(SelectedRow)
      ImageCache := GetImageCache() ; Refresh cache
      PreviewPic.Value := "" ; Clear preview
    } catch as e {
      MsgBox("Error deleting file: " e.Message)
    }
  }
}

CopyPath(*) {
  if (SelectedRow := LV.GetNext()) {
    imagePath := LV.GetText(SelectedRow)
    A_Clipboard := imagePath
    ToolTip("Path copied to clipboard!")
    SetTimer(() => ToolTip(), -1000)
  }
}

GuiResize(thisGui, MinMax, Width, Height) {
  if MinMax = -1    ; The window has been minimized
    return

  ButtonHeight := 30
  Padding := 10

  ; Calculate new dimensions
  ListViewHeight := Height - ButtonHeight - (3 * Padding)
  PreviewWidth := Width - 300 - (3 * Padding)

  ; Resize controls
  LV.Move(, , 300, ListViewHeight)
  PreviewPic.Move(, , PreviewWidth, '-1')

  ; Move buttons
  btnY := Height - ButtonHeight - Padding
  btnRefresh.Move(, btnY)
  btnExplorer.Move(, btnY)
  btnDelete.Move(, btnY)
  btnCopy.Move(, btnY)
}

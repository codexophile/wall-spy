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
ButtonPanel := MyGui.Add("ListView", "xm y+10 w710 h40 -Hdr -E0x200", ["Buttons"])
ButtonPanel.Add(, "Refresh List|Show in Explorer|Delete Selected|Copy Path")

ButtonPanel.OnEvent("ItemSelect", HandleButton)

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

HandleButton(*) {
  selected := ButtonPanel.GetNext()
  ButtonPanel.Modify(selected, "-Select")  ; Deselect the button

  if (SelectedRow := LV.GetNext()) {
    imagePath := LV.GetText(SelectedRow)

    switch selected {
      case 1: ; Refresh
        ImageCache := GetImageCache()
        PopulateImageList()

      case 2: ; Show in Explorer
        ShowInExplorer()

      case 3: ; Delete
        try {
          FileDelete(imagePath)
          LV.Delete(SelectedRow)
          ImageCache := GetImageCache() ; Refresh cache
          PreviewPic.Value := "" ; Clear preview
        } catch as e {
          MsgBox("Error deleting file: " e.Message)
        }

      case 4: ; Copy Path
        A_Clipboard := imagePath
        ToolTip("Path copied to clipboard!")
        SetTimer(() => ToolTip(), -1000)
    }
  }
}

GuiResize(thisGui, MinMax, Width, Height) {
  if MinMax = -1    ; The window has been minimized
    return

  ButtonPanelHeight := 40
  Padding := 10

  ; Calculate new dimensions
  ListViewHeight := Height - ButtonPanelHeight - (3 * Padding)
  PreviewWidth := Width - 300 - (3 * Padding)

  ; Resize controls
  LV.Move(, , 300, ListViewHeight)
  PreviewPic.Move(, , PreviewWidth, ListViewHeight)
  ButtonPanel.Move(, Height - ButtonPanelHeight - Padding, Width - (2 * Padding))
}

use gui

main.load_sounds =
| Folder = "[$data]sound/"
| $sound <= @table: map Name Folder.urls.keep{is.[@_ txt]}{?1}
  | SoundFile = "[Folder][Name].wav"
  | less SoundFile.exists: bad "missing [SoundFile]"
  | [Name SoundFile^sound_load]

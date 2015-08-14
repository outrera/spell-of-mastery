use gui

main.load_sounds =
| Folder = "[$data]sound/"
| $sounds <= @table: map Name Folder.urls.keep{is.[@_ txt]}{?1}
  | SoundFile = "[Folder][Name].wav"
  | less SoundFile.exists: SoundFile <= "[Folder][Name].ogg"
  | less SoundFile.exists: bad "missing [SoundFile]"
  | [Name SoundFile^sound_load]

main.sound Name =
| S = $sounds.Name
| when no S: bad "missing sound ([Name])"
| sound_play S
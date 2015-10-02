use gui param

PlayList = []
PlayListIndex = 0

main.load_sounds =
| Folder = "[$data]sound/units/"
| Params = load_params "[$data]/sound/"
| $credits.sound <= extract_params_authors Params
| $sounds <= @table: map Name Folder.urls.keep{is.[@_ txt]}{?1}
  | SoundFile = "[Folder][Name].wav"
  | less SoundFile.exists: SoundFile <= "[Folder][Name].ogg"
  | less SoundFile.exists: bad "missing [SoundFile]"
  | [Name SoundFile^sound_load]
| for [Path Name Ext] "[$data]/music".urls:
  | when Ext<>txt: case Name "ingame[X]":
    | push "[Name].[Ext]" PlayList
| PlayList <= PlayList.sort

main.sound Name =
/*| S = $sounds.Name
| when no S: bad "missing sound ([Name])"
| sound_play S*/

Channel = 0

main.music Name =
/*| when Name><playlist_advance:
  | less PlayList.size: leave
  | when sound_playing Channel: leave
  | PlayListIndex <= (PlayListIndex+1)%PlayList.size
  | Name <= PlayList.PlayListIndex
| when Name><playlist:
  | PlayListIndex <= 0
  | less PlayList.size: leave
  | Name <= PlayList.PlayListIndex
| Channel <= sound_play: sound_load "[$data]/music/[Name]" music/1
*/
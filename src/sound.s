use gui cfg

PlayList = []
PlayListIndex = 0

main.load_sounds =
| Folders = "[$data]sound/".urls.keep{(?1><'' and ?2><'')}{?0}
| Params = $cfg_load_folder{"[$data]/sound/"}
| $credits.sound <= $extract_cfg_authors{Params}
| $sounds <= @table: @join: map Folder Folders:
  | map Name Folder.urls.keep{is.[@_ txt]}{?1}
    | SoundFile = "[Folder][Name].wav"
    | less SoundFile.exists: SoundFile <= "[Folder][Name].ogg"
    | less SoundFile.exists: bad "missing [SoundFile]"
    | [Name SoundFile^sound_load]
| for [Path Name Ext] "[$data]/music".urls:
  | when Ext<>txt: case Name "ingame[X]":
    | push "[Name].[Ext]" PlayList
| PlayList <= PlayList.sort

main.sound Name volume/1.0 =
| when Name.is_list: Name <= Name.rand
| Cycle = $site.cycle
| SCycles = $site.sound_cycles
| when SCycles.Name><Cycle and not $site.paused: leave
| SCycles.Name <= Cycle
| S = $sounds.Name
| when no S: bad "missing sound `[Name]`"
| sound_play S volume/Volume

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

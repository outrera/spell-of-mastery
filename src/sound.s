use gui


main.load_sounds =
| Folders = "[$data]sound/".urls.keep{(?1><'' and ?2><'')}{?0}
| Cfgs = $cfg_load_folder{"[$data]/sound/"}
| $credits.sound <= $extract_cfg_authors{Cfgs}
| $sounds <= @table: @join: map Folder Folders:
  | map Name Folder.urls.keep{is.[@_ txt]}{?1}
    | [Name "[Folder][Name]"]

main.sound Name volume/1.0 =
| when Name.is_list: Name <= Name.rand
| Cycle = $site.cycle
| SCycles = $site.sound_cycles
| when SCycles.Name><Cycle and not $site.paused: leave
| SCycles.Name <= Cycle
| S = $sounds.Name
| when S.is_text:
  | SoundFile = "[S].wav"
  | less SoundFile.exists: SoundFile <= "[S].ogg"
  | less SoundFile.exists: bad "missing [SoundFile]"
  | S <= sound_load SoundFile
  | $sounds.Name <= S
| when no S: bad "missing sound `[Name]`"
| sound_play S volume/Volume

MusicChannel = 0
MusicLoop = 0
MusicName = 0
PlayList = 0
PlayListIndex = 0

main.music Name loop/0 =
| MusicName <= Name
| MusicLoop <= Loop
| PL = $cfg.playlist.Name
| less got PL: PlayList <= 0
| when got PL:
  | PlayList <= PL
  | PlayListIndex <= 0
  | less PlayList.size: leave
  | PlayListIndex <= PlayList.size.rand-1
  | Name <= PlayList.PlayListIndex
| MusicChannel <= sound_play: sound_load "[$data]/music/[Name].ogg" music/1

main.music_update =
| when sound_playing MusicChannel: leave
| Name = MusicName
| if PlayList then
    | less PlayList.size: leave
    | when not MusicLoop and PlayListIndex+1 >< PlayList.size: leave
    | PlayListIndex <= (PlayListIndex+1)%PlayList.size
    | Name <= PlayList.PlayListIndex
  else less MusicLoop: leave
| MusicChannel <= sound_play: sound_load "[$data]/music/[Name].ogg" music/1
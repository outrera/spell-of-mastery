use gui widgets ui_icon ui_widgets

ui.create_victory_dlg =
| dlg: mtx
  |   0   0 | $img{ui_victory_bg}
  | 100 300 | txt titleb: =>
              | Spoils = $world.site_spoils{victory 0}
              | "You are victorious!\n[Spoils]"
  | $width-360 $height-100
        | button 'CONTINUE' skin/scroll: =>
          | $pick_world
          | $world.leave_site{victory}

ui.create_defeat_dlg = 
| dlg: mtx
  |   0   0 | $img{ui_defeat_bg}
  | 140 300 | txt titleb: =>
              | Spoils = $world.site_spoils{defeat 0}
              | if got $site.data.retreat
                then "You have retreated!\n[Spoils]\n"
                else "You have been defeated!\n[Spoils]\n"
  | $width-360 $height-100
        | button 'CONTINUE' skin/scroll: =>
          | $pick_world
          | $world.leave_site{defeat}

ui.show_results = //called when we have a winner
| get_gui{}.cursor <= $main.img{ui_cursor_point}
| WinnerId = $site.data.winner
| when no WinnerId: WinnerId <= 0
| Winner = $site.players.WinnerId
| if Winner.human
  then | $main.music{victory}
       | $site.data.victory <= 1
       | $pick{victory}
  else | $main.music{defeat}
       | $site.data.victory <= 0
       | $pick{defeat}

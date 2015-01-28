type action{world} what xyz/[0 0 0] next

action.init What XYZ =
| $what <= What
| $xyz <= XYZ

action.free = $world.free_action{Me}

export action
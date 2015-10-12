ZMapHeight = 64
type zmap{size init} data
| $data <= dup $size: dup $size: dup ZMapHeight $init

zmap.clear Value = for Ys $data: for Zs Ys: Zs.clear{Value}

// gets cube at P in the form of [Value OriginXYZ EdgeLength]
zmap.get X Y Z = [$data.X.Y.Z 1]

zmap.set X Y Z V = $data.X.Y.Z <= V

zmap.at X Y Z = $data.X.Y.Z

zmap.getPilar X Y = $data.X.Y.take{$height{X Y}}

zmap.setPilar X Y Zs =
| Vs = $data.X.Y
| Vs.clear{$init}
| times I Zs.size: Vs.I <= Zs.I

zmap.height X Y =
| Vs = $data.X.Y
| Z = ZMapHeight
| while Z
  | !Z-1
  | when Vs.Z.id: leave Z+1
| leave 0

export zmap
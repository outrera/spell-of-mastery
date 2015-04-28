ZMapHeight = 64
type zmap{Size} size/Size data/(dup Size: dup Size: dup ZMapHeight 0)

zmap.clear Value = for Ys $data: for Zs Ys: Zs.clear{Value}

// gets cube at P in the form of [Value OriginXYZ EdgeLength]
zmap.get XYZ =
| X,Y,Z = XYZ
| [$data.X.Y.Z XYZ 1]

zmap.set X,Y,Z V =
| $data.X.Y.Z <= V

zmap.at X,Y,Z = $data.X.Y.Z

zmap.getPilar X Y = $data.X.Y.take{$height{X Y}}

zmap.setPilar X Y Zs =
| Vs = $data.X.Y
| Vs.clear{0}
| for I Zs.size: Vs.I <= Zs.I

zmap.height X Y =
| Vs = $data.X.Y
| Z = ZMapHeight
| while Z
  | !Z-1
  | when Vs.Z: leave Z+1
| leave 0

export zmap
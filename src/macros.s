PI = 3.141592653589793

// size of path segment to cache
PATH_CACHE_SIZE = 10

rgb R G B = form R*#10000 + G*#100 + B
rgba R G B A = form A*#1000000 + R*#10000 + G*#100 + B

get_bit N Me = (Me>>>N)&&&1
set_bit N Bit Me = Me+++(Bit<<<N)+++(Me&&&(1<<<N))

export 'PI' 'PATH_CACHE_SIZE' 'rgb' 'rgba' get_bit set_bit

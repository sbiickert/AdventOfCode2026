unit module AOC::Geometry;

class Coord {...}
class Position {...}
class Extent {...}

my %OFFSET-DIRS = ('N' 	=> Coord.new(x => 0, y => -1),
					'NE' 	=> Coord.new(x => 1, y =>-1),
					'E' 	=> Coord.new(x => 1, y => 0),
					'SE' 	=> Coord.new(x => 1, y => 1),
					'S' 	=> Coord.new(x => 0, y => 1),
					'SW' 	=> Coord.new(x =>-1, y => 1),
					'W' 	=> Coord.new(x =>-1, y => 0),
					'NW' 	=> Coord.new(x =>-1, y =>-1));
					
					
my %OFFSET-ALIASES = ('UP'	=> 'N', 'RIGHT' => 'E', 'DOWN' 	=> 'S', 'LEFT' 	=> 'W',
						'U' => 'N', 'R' => 'E', 'D' => 'S', 'L' => 'W',
						'^' => 'N', '>' => 'E', 'v' => 'S', '<' => 'W');

sub resolve-offset-alias(Str $dir --> Str) {
	if %OFFSET-DIRS{$dir}:exists {
		return $dir;
	}
	return %OFFSET-ALIASES{$dir} // Nil;
}

my %ROTATION-DIRS = ('CW' => 1, 'CCW' => -1);

my %ROTATION-ALIASES = ('R' => 'CW', 'RIGHT' => 'CW',
						'L' => 'CCW', 'LEFT' => 'CCW');

sub resolve-rotation-alias(Str $dir --> Str) {
	if %ROTATION-DIRS{$dir}:exists {
		return $dir;
	}
	return %ROTATION-ALIASES{$dir} // Nil;
}

enum AdjacencyRule is export <ROOK BISHOP QUEEN>;
# constant ROOK is export = 'ROOK';
# constant BISHOP is export = 'BISHOP';
# constant QUEEN is export = 'QUEEN';

my %ADJACENCY-RULES = (ROOK    => ['N','E','S','W'],
						BISHOP => ['NE','SE','SW','NW'],
						QUEEN  => ['N','NE','E','SE','S','SW','W','NW']);

sub adjacent-dirs(AdjacencyRule $rule --> Array) is export {
	my @arr = %ADJACENCY-RULES{$rule}.flat;
	return @arr;
}


class Coord is export {
	has Int $.x = 0;
	has Int $.y = 0;
	
	# class method: origin
	method origin(::?CLASS:U $c2d:) {
		$c2d.new(x => 0, y => 0);
	}
	
	# class method: offset
	method get-offset(::?CLASS:U $c2d: Str $direction --> Coord) {
		my $off = resolve-offset-alias($direction);
		if $off {
			return %OFFSET-DIRS{$off};
		}
		return Coord.origin;
	}
	
	# class method: construct from two Ints
	method from-ints(::?CLASS:U $c2d: Int $x, Int $y --> Coord) {
		$c2d.new( x => $x, y => $y );
	}
	
	# class method: construct from a Str representation 
	method from-str(::?CLASS:U $c2d: $str) {
		my $x = 0; my $y = 0;
		if $str ~~ rx:s/\[(\d+)\, ?(\d+)\]/ {
			$x = +~$0; $y = +~$1;
		}
		$c2d.new( x => $x, y => $y );
	}

	# class method: compression map used for working with large, sparse data
	method create-compression-map(::?CLASS:U $c2d: @coords) {
		my @x = @coords.map(*.x).Set.keys.sort;
		my @y = @coords.map(*.y).Set.keys.sort;

		my %x-map = ();
		my %x-map-rev = ();
		for 0..@x.end -> $x {
			%x-map{$x} = @x[$x];
			%x-map-rev{@x[$x]} = $x;
		}
		my %y-map = ();
		my %y-map-rev = ();
		for 0..@y.end -> $y {
			%y-map{$y} = @y[$y];
			%y-map-rev{@y[$y]} = $y;
		}

		return ('x_expand' => %x-map, 'x_compress' => %x-map-rev, 'y_expand' => %y-map, 'y_compress' => %y-map-rev);
	}
	
	method Str { "[$.x,$.y]" }
	
	multi method gist(Coord:U:) { self.^name }
	multi method gist(Coord:D:) { "•[$.x, $.y]" }
	
	method col returns Int { $.x; }
	method row returns Int { $.y; }
	
	method add(Coord $other --> Coord) {
		Coord.new( x => $.x + $other.x, y => $.y + $other.y )
	}
	
	method is-adjacent(Coord $other, AdjacencyRule $rule = AdjacencyRule::ROOK --> Bool) {
		if ($rule eq AdjacencyRule::ROOK) {
			return self.manhattan-distance-to($other) == 1;
		}
		elsif ($rule eq AdjacencyRule::BISHOP) {
			return abs($!x - $other.x) == 1 &&
					abs($!y - $other.y) == 1;
		}
		#QUEEN
		return (self.manhattan-distance-to($other) == 1) ||
				(abs($!x - $other.x) == 1 &&
				 abs($!y - $other.y) == 1)
	}
	
	
	method get-adjacent-coords(AdjacencyRule $rule = AdjacencyRule::ROOK) {
		my @result = ();
		if (%ADJACENCY-RULES{$rule}:exists) {
			my @dirs = %ADJACENCY-RULES{$rule}.flat;
			for @dirs -> $dir {
				@result.push(self.offset($dir));
			}
		}
		return @result;
	}

	method offset(Str $dir, Int $size = 1 --> Coord) {
		return self.clone if $size == 0;
		my $resolved-dir = resolve-offset-alias($dir);
		my $off = Coord.get-offset($resolved-dir);
		if (abs($size) > 1) {
			$off = Coord.from-ints($off.x * $size, $off.y * $size);
		}
		return self.add($off);
	}
	
	method delta(Coord $other --> Coord) {
		Coord.new( x => $other.x - $.x, y => $other.y - $.y )
	}
	
	method distance-to(Coord $other --> Num) {
		my $delta = $.delta($other);
		return sqrt($delta.x**2 + $delta.y**2);
	}
	
	method manhattan-distance-to(Coord $other --> Int) {
		#my $delta = $.delta($other);
		#return abs($delta.x) + abs($delta.y);
		return abs($other.x - $.x) + abs($other.y - $.y);
	}
}

multi infix:<eqv>(Coord $l, Coord $r) is export { $l.x == $r.x && $l.y == $r.y }
multi infix:<+>(Coord $l, Coord $r) is export { $l.add($r) }
multi infix:<->(Coord $l, Coord $r) is export { $l.delta($r) }


class Coord3D is export {
	has Int $.x = 0;
	has Int $.y = 0;
	has Int $.z = 0;

	# class method: origin
	method origin(::?CLASS:U $c3d:) {
		$c3d.new(x => 0, y => 0, z => 0);
	}

	# class method: construct from 3 ints
	method from-ints(::?CLASS:U $c3d: Int $x, Int $y, Int $z) {
		$c3d.new( x => $x, y => $y, z => $z );
	}
	
	# class method: construct from a Str representation 
	method from-str(::?CLASS:U $c3d: $str) {
		my $x = 0; my $y = 0; my $z = 0;
		if $str ~~ rx:s/\[(\d+)\, ?(\d+)\, ?(\d+)\]/ {
			$x = +~$0; $y = +~$1; $z = +~$2;
		}
		$c3d.new( x => $x, y => $y, z => $z );
	}
	
	method Str { "[$.x,$.y,$.z]" }
	
	multi method gist(Coord3D:U:) { self.^name }
	multi method gist(Coord3D:D:) { "•[$.x, $.y, $.z]" }
	
	
	method add(Coord3D $other --> Coord3D) {
		Coord3D.new( x => $.x + $other.x, y => $.y + $other.y, z => $.z + $other.z )
	}
	
	method delta(Coord3D $other --> Coord3D) {
		Coord3D.new( x => $other.x - $.x, y => $other.y - $.y, z => $other.z - $.z )
	}
	
	method distance-to(Coord3D $other --> Num) {
		my $delta = $.delta($other);
		return sqrt($delta.x**2 + $delta.y**2 + $delta.z**2);
	}
	
	method manhattan-distance-to(Coord3D $other --> Int) {
		return abs($other.x - $.x) + abs($other.y - $.y) + abs($other.z - $.z);
	}
}

multi infix:<eqv>(Coord3D $l, Coord3D $r) is export { $l.x == $r.x && $l.y == $r.y && $l.z == $r.z }
multi infix:<+>(Coord3D $l, Coord3D $r) is export { $l.add($r) }
multi infix:<->(Coord3D $l, Coord3D $r) is export { $l.delta($r) }

class Position is export {
	has Coord $.coord;
	has Str $.dir;
	
	# Overriding default constructor to check $dir
	method new( Coord :$coord, Str :$dir ) {
		my $resolved = resolve-offset-alias($dir // 'N') // 'N';
		return self.bless(coord => $coord, dir => $resolved);
	}
	
	method Str { '{' ~ $.coord.Str ~ ' ' ~ $.dir ~ '}' }
	
	multi method gist(Position:U:) { self.^name }
	multi method gist(Position:D:) { self.Str }
	
	method turn(Str $rotation-direction --> Position) {
		my $rot-dir = resolve-rotation-alias($rotation-direction);
		my $step = 0;
		if $rot-dir { $step = %ROTATION-DIRS{$rot-dir}; }
		my @ordered = %ADJACENCY-RULES{AdjacencyRule::ROOK}.flat; # ('N', 'E', 'S', 'W');
		my $index = @ordered.first($.dir, :k);
		$index = ($index + $step) % 4;
		return Position.new(coord => $.coord.clone, dir => @ordered[$index]);
	}
	
	method move-forward(Int $distance = 1 --> Position) {
		my $off = %OFFSET-DIRS{$.dir};
		my $move = Coord.new(x => $off.x * $distance,
							 y => $off.y * $distance);
		#my $new-coord = self.coord + $move;
		my $new-coord = self.coord.add($move);
		return Position.new(coord => $new-coord, dir => self.dir);
	}
}

multi infix:<eqv>(Position $l, Position $r) is export {
	$l.coord eqv $r.coord && $l.dir eq $r.dir;
}


class Segment is export {
	has Coord $.from;
	has Coord $.to;
	
	method Str { $.from ~ "->" ~ $.to }
	
	multi method gist(Segment:U:) { self.^name }
	multi method gist(Segment:D:) { self.Str }
		
	method is-horizontal(--> Bool) {
		$.from.y == $.to.y;
	}
	
	method is-vertical(--> Bool) {
		$.from.x == $.to.x;
	}
	
	method direction(--> Str) {
		if $.is-horizontal {
			return $.from.x < $.to.x ?? 'E' !! 'W';
		}
		elsif $.is-vertical {
			return $.from.y < $.to.y ?? 'S' !!'N';
		}
		
		if ($.from.x < $.to.x) {
			return $.from.y < $.to.y ?? 'SE' !! 'NE';
		}
		return $.from.y < $.to.y ?? 'SW' !! 'NW';
	}
}

multi infix:<eqv>(Segment $l, Segment $r) is export {
	$l.from eqv $r.from && $l.to eq $r.to;
}


class Extent1D is export {
	has Range $.range;

	submethod TWEAK {
		if $!range.min > $!range.max {
			$!range = $!range.max..$!range.min;
		}
	}

	method min(--> Int) { return $.range.min; }
	method max(--> Int) { return $.range.max; }

	method Str { '{min: ' ~ self.min ~ ' max: ' ~ self.max ~ '}' }
	
	method size(--> Int) { return $.range.minmax[1] - $.range.minmax[0] + 1; }

	multi method contains(Extent1D $other --> Bool) {
		return self.min <= $other.min && $other.max <= self.max;
	}

	multi method contains(Int $value --> Bool) {
		return self.min <= $value && $value <= self.max;
	}

	method overlaps(Extent1D $other --> Bool) {
		return !(self.intersect($other) ~~ Nil);
	}

	method union(Extent1D $other --> Extent1D) {
		return Extent1D.new(range => min(self.min, $other.min)..max(self.max, $other.max));
	}

	method intersect(Extent1D $other --> Extent1D) {
		my $bigmin = max(self.min, $other.min);
		my $smallmax = min(self.max, $other.max);
		if ($bigmin <= $smallmax) {
			return Extent1D.new(range => $bigmin..$smallmax);
		}
		return Nil;
	}
}

multi infix:<eqv>(Extent1D $l, Extent1D $r) is export { $l.range eqv $r.range; }


class Extent is export {
	has Coord $.min;
	has Coord $.max;
	
	# class method: construct from Ints 
	method from-ints(::?CLASS:U $e2d: Int $xmin, Int $ymin, Int $xmax, Int $ymax) {
		my $min = Coord.new( x => $xmin, y => $ymin );
		my $max = Coord.new( x => $xmax, y => $ymax );
		$e2d.from-coords( [$min, $max] );
	}
	
	# class method: construct from a list of Coord 
	method from-coords(::?CLASS:U $e2d: @coords) {
		my $ext = Extent.new;
		
		for @coords -> $coord {
			if $coord.isa(Coord) {
				$ext = $ext.expand-to-fit($coord);
			}
		}
		return $ext;
	}
	
	method expand-to-fit( Coord $coord --> Extent ) {
		my Coord $new-min;
		my Coord $new-max;
		
		if $.is-empty {
			$new-min = $coord.clone;
			$new-max = $coord.clone;
		}
		else {
			$new-min = Coord.new( x => min($.min.x, $coord.x), y => min($.min.y, $coord.y) );
			$new-max = Coord.new( x => max($.max.x, $coord.x), y => max($.max.y, $coord.y) );
		}
		
		return Extent.new( min => $new-min, max => $new-max )
	}
	
	method is-empty(--> Bool) {
		return !$.min && !$.max;
	}
	
	method Str { $.is-empty ?? '[EMPTY]' !! "[$.min,$.max]" }
	
	multi method gist(Extent:U:) { self.^name }
	multi method gist(Extent:D:) { $.is-empty ?? "▭[EMPTY]" !! "▭[$.min, $.max]" }
	
	method nw(--> Coord) { return $.min.clone; }
	method ne(--> Coord) { return Coord.new( x => $.max.x, y => $.min.y ); }
	method sw(--> Coord) { return Coord.new( x => $.min.x, y => $.max.y ); }
	method se(--> Coord) { return $.max.clone; }
	
	method width(--> Int) {
		return $.is-empty ?? 0 !! $.max.x - $.min.x + 1;
	}
	
	method height(--> Int) {
		return $.is-empty ?? 0 !! $.max.y - $.min.y + 1;
	}
	
	method area(--> Int) {
		return $.width * $.height;
	}

	method centroid(--> Coord) {
		my $mid-x = (($.max.x - $.min.x) / 2).int;
		my $mid-y = (($.max.y - $.min.y) / 2).int;
		return Coord.new(x => $mid-x, y => $mid-y);
	}
	
	method all-coords(--> Array of Coord) {
		my Coord @coords = ();
		
		for $.min.x .. $.max.x X $.min.y .. $.max.y -> $pair {
			@coords.push( Coord.new( x => $pair[0], y => $pair[1] ) );
		}
		return @coords;
	}

	method edge-coords(--> Array of Coord) {
		my Coord @coords = ();
		my $xmin = $.min.x;
		my $xmax = $.max.x;
		my $ymin = $.min.y;
		my $ymax = $.max.y;
		for $xmin .. $xmax X $ymin .. $ymax -> $pair {
			if ($pair[0] == $xmin || $pair[0] == $xmax  
				|| $pair[1] == $ymin || $pair[1] == $ymax )
			{
				@coords.push( Coord.new( x => $pair[0], y => $pair[1] ) );
			}
		}
		return @coords;
	}
	
	method contains( Coord $coord --> Bool ) {
		if $.is-empty { return False }
		return ($.min.x <= $coord.x && $coord.x <= $.max.x)
			&& ($.min.y <= $coord.y && $coord.y <= $.max.y);
	}
	
	# intersect
	method intersect( Extent $other --> Extent ) {
		if self.is-empty || $other.is-empty { return Extent.new; } # empty Extent
		my $common-min-x = max($.min.x, $other.nw.x);
		my $common-max-x = min($.max.x, $other.se.x);
		if ($common-max-x < $common-min-x) { return Extent.new; } # empty Extent
		my $common-min-y = max($.min.y, $other.nw.y);
		my $common-max-y = min($.max.y, $other.se.y);
		if ($common-max-y < $common-min-y) { return Extent.new; } # empty Extent

		return Extent.from-ints($common-min-x, $common-min-y, $common-max-x, $common-max-y);
	}
	
	# Union of two extents, returned as non-overlapping pieces that cover both.
	#
	# The edges of the overlap cut each extent into a 3x3 grid of bands, like
	# a noughts-and-crosses board drawn around the overlap (see cells-around):
	#
	#                x before    x inside    x after
	#              +-----------+-----------+-----------+
	#     y before |           |           |           |
	#              +-----------+-----------+-----------+
	#     y inside |           |  OVERLAP  |           |
	#              +-----------+-----------+-----------+
	#     y after  |           |           |           |
	#              +-----------+-----------+-----------+
	#
	# Cells that would have zero width or height are dropped. The middle cell
	# is the overlap itself, so it's returned once; every other cell is a
	# piece of that extent lying outside the overlap. For example:
	#
	#     +---------+                    +----+----+
	#     | self    |                    | s  | s  |
	#     |    +----+----+               +----+----+----+
	#     |    |####|    |     ==>       | s  |####| o  |
	#     +----+----+    |               +----+----+----+
	#          |  other  |                    | o  | o  |
	#          +---------+                    +----+----+
	#
	#     #### = the overlap    s = pieces of self    o = pieces of other
	method union( Extent $other --> Array of Extent ) {
		my Extent @pieces;
		return @pieces if self.is-empty || $other.is-empty;

		my $overlap = self.intersect($other);
		if $overlap.is-empty {
			@pieces.push: self.clone, $other.clone;
			return @pieces;
		}

		@pieces.push: $overlap;
		for self, $other -> $e {
			@pieces.append: $e.cells-around($overlap).grep({ !($_ eqv $overlap) });
		}
		return @pieces;
	}

	# Cut this extent into up to nine cells along the edges of $other:
	# the part they share, plus the bands of this extent around it.
	# Empty cells are left out. If the extents don't overlap, the result
	# is a copy of this extent; if this extent is empty, the result is empty.
	method cells-around( Extent $other --> List ) {
		return () if self.is-empty;
		my $inner = self.intersect($other);
		return (self.clone,) if $inner.is-empty;

		my @columns = bands($.min.x, $.max.x, $inner.min.x, $inner.max.x);
		my @rows    = bands($.min.y, $.max.y, $inner.min.y, $inner.max.y);
		return (@columns X @rows).map(-> ($xs, $ys) {
			Extent.from-ints($xs.min, $ys.min, $xs.max, $ys.max)
		}).List;
	}

	# Split the range lo..hi into the parts before, inside and after cut-lo..cut-hi,
	# dropping any that are empty.
	sub bands( Int $lo, Int $hi, Int $cut-lo, Int $cut-hi ) {
		($lo .. $cut-lo - 1, $cut-lo .. $cut-hi, $cut-hi + 1 .. $hi).grep(*.elems)
	}
	
	method inset( Int $inset --> Extent ) {
		if $.is-empty { return Extent.new; }
		return Extent.from-ints( $.min.x + $inset, $.min.y + $inset,
								 $.max.x - $inset, $.max.y - $inset );
	}
}
	
multi infix:<eqv>(Extent $l, Extent $r) is export { $l.min eqv $r.min && $l.max eqv $r.max }


unit module AOC::Grid;

use AOC::Geometry;

role GridGlyph is export {
	method glyph( --> Str) { ... }
}

class Grid is export {
	has %!data = Hash.new;
	has $.default = '.';
	has AOC::Geometry::AdjacencyRule $.rule is required is rw;
	has Extent $!extent;
	
	submethod TWEAK {
		%!data = Hash.new;
		$!extent = Extent.new;
	}
	
	multi method get(Coord $key --> Any) {
		self.get($key.Str);
	}
	
	multi method get(Str $key --> Any) {
		if %!data{$key}:exists {
			return %!data{$key};
		}
		return $.default;
	}
	
	multi method get-glyph(Str $key --> Str) {
		my $value = self.get($key);
		return self!glyph-from-value($value);
	}
	
	multi method get-glyph(Coord $key --> Str) {
		my $value = self.get($key);
		return self!glyph-from-value($value);
	}
	
	method !glyph-from-value(Any $value --> Str) {
		if $value.isa(List) {
			return $value[0].Str;
		}
		elsif $value.isa(Map) {
			return $value{'glyph'}.Str;
		}
		elsif $value.does(GridGlyph) {
			return $value.glyph;
		}
		return $value.Str;
	}

	method set(Coord $key, Any $value) {
		%!data{$key.Str} = $value;
		
		# Update the extent to include the $coord
		if ! $.extent.contains($key) {
			my $temp = $.extent.expand-to-fit($key);
			$!extent = $temp;
		}
	}
	
	method set-rule(AdjacencyRule $r) {
		self.rule = $r;
	}
	
	method clear(Coord $key, Bool :$reset-extent = False) {
		%!data{$key.Str}:delete;
		self!reset-extent if $reset-extent;
	}
	
	method extent(--> Extent) { return $!extent; }
	
	method !reset-extent() {
		$!extent = Extent.from-coords( self.coords );
	}
	
	method coords(Str $with-value = '') {
		my Coord @result = ();
		for %!data.keys -> $key {
			if $with-value.chars == 0 || self.get-glyph($key) eq $with-value {
				@result.push(Coord.from-str($key));
			}
		}
		return @result;
	}
	
	method histogram(Bool $include-unset = False --> Hash) {
		my Int %hist is default(0);
		
		my Coord @coords-to-summarize = ();
		if ($include-unset) {
			@coords-to-summarize = self.extent.all-coords;
		}
		else {
			@coords-to-summarize = self.coords;
		}
		
		for @coords-to-summarize -> $c {
			my $val = self.get-glyph($c);
			%hist{$val} = %hist{$val} + 1;
		}
		
		return %hist;
	}
	
	method neighbors(Coord $c --> Array) {
		return $c.get-adjacent-coords($.rule);
	}

	method flood-fill(Coord $c, $value) {
		# say "fill at $c with $value";
		my $local-value = self.get($c);
		self.set($c, $value);
		my @neighbors = self.neighbors($c);
		my $ext = self.extent;
		for @neighbors -> $n {
			self.flood-fill($n, $value) if self.get($n) eq $local-value && $ext.contains($n);
		}
	}
	
	method print(:%markers = {}, Bool :$invert-y = False) {
		print self.sprint(markers => %markers, invert-y => $invert-y);
	}
	
	method sprint(:%markers = {}, Bool :$invert-y = False --> Str) {
		my $str = '';
		return $str if $!extent.is-empty;
		
		my $xmin = $!extent.min.x;
		my $xmax = $!extent.max.x;
		my $ymin = $!extent.min.y;
		my $ymax = $!extent.max.y;
		
		my @y-indexes = ();
		for ($ymin..$ymax) -> $y {
			@y-indexes.push($y);
		}
		@y-indexes = @y-indexes.reverse if $invert-y;

		for @y-indexes -> $y {
			my @row = ();
			for ($xmin..$xmax) -> $x {
				my $c = Coord.from-ints($x, $y);
				my $c-str = $c.Str;
				my $glyph = self.get-glyph($c-str);
				if %markers.keys.elems > 0 && (%markers{$c-str}:exists) {
					$glyph = %markers{$c-str};
				}
				@row.push($glyph);
			}
			@row.push("\n");
			$str ~= @row.join(' ');
		}
		
		return $str;
	}
	
	method load(@rows) {
		for 0..@rows.end -> $r {
			my @cols = @rows[$r].split('', :skip-empty);
			for 0..@cols.end -> $c {
				if @cols[$c] ne $.default {
					self.set(Coord.from-ints($c, $r), @cols[$c]);
				}
			}
		}
	}
}

class AGrid is export {
	has @!data = ();
	has Any $.default = '.';
	has Int $.x is required;
	has Int $.y is required;
	has AOC::Geometry::AdjacencyRule $.rule is required is rw;
	has Extent $!extent;

	submethod TWEAK {
		@!data = [$!default xx ($!x + 1)] xx ($!y + 1);
		$!extent = Extent.from-ints(0, 0, $!x, $!y);
	}
	
	method get(Coord $key --> Any) {
		self.get-xy($key.x, $key.y);
	}

	method get-xy(Int $x, Int $y --> Any) {
		return @!data[$y][$x];
	}

	method get-glyph(Coord $key --> Str) {
		self.get-glyph-xy($key.x, $key.y);
	}

	method get-glyph-xy(Int $x, Int $y --> Str) {
		my $value = self.get-xy($x, $y);
		return self!glyph-from-value($value);
	}
	
	method !glyph-from-value(Any $value --> Str) {
		if $value.isa(List) {
			return $value[0].Str;
		}
		elsif $value.isa(Map) {
			return $value{'glyph'}.Str;
		}
		elsif $value.does(GridGlyph) {
			return $value.glyph;
		}
		return $value.Str;
	}

	method set(Coord $key, Any $value) {
		self.set-xy($key.x, $key.y, $value);
	}

	method set-xy(Int $x, int $y, Any $value) {
		@!data[$y][$x] = $value;
	}
	
	method set-rule(AdjacencyRule $r) {
		self.rule = $r;
	}
	
	method clear(Coord $key) {
		self.clear-xy($key.x, $key.y);
	}

	method clear-xy(Int $x, Int $y) {
		@!data[$y][$x] = $.default;
	}
	
	method extent(--> Extent) { return $!extent; }

	method histogram(Bool $include-unset = False --> Hash) {
		# TODO
	}

	method neighbors(Coord $c --> Array) {
		return $c.get-adjacent-coords($.rule);
	}

	method neighbors-xy(Int $x, Int $y --> Array) {
		# TODO
	}

	method flood-fill(Coord $c, Any $value) {
		# say "fill at $c with $value";
		my $local-value = self.get($c);
		self.set($c, $value);
		my @neighbors = self.neighbors($c);
		my $ext = self.extent;
		for @neighbors -> $n {
			self.flood-fill($n, $value) if self.get($n) eq $local-value && $ext.contains($n);
		}
	}
	
	method print(:%markers = {}, Bool :$invert-y = False) {
		print self.sprint(markers => %markers, invert-y => $invert-y);
	}
	
	method sprint(:%markers = {}, Bool :$invert-y = False --> Str) {
		my $str = '';
		return $str if $!extent.is-empty;
		
		my $xmin = 0;
		my $xmax = $.x;
		my $ymin = 0;
		my $ymax = $.y;
		
		my @y-indexes = ();
		for ($ymin..$ymax) -> $y {
			@y-indexes.push($y);
		}
		@y-indexes = @y-indexes.reverse if $invert-y;

		for @y-indexes -> $y {
			my @row = ();
			for ($xmin..$xmax) -> $x {
				my $glyph = self.get-glyph-xy($x, $y);

				if %markers.keys.elems > 0 {
					my $c = Coord.from-ints($x, $y);
					if %markers{$c.Str}:exists {
						$glyph = %markers{$c.Str};
					}
				}

				@row.push($glyph);
			}
			@row.push("\n");
			$str ~= @row.join(' ');
		}
		
		return $str;
	}
	
	method load(@rows) {
		for 0..@rows.end -> $r {
			my @cols = @rows[$r].split('', :skip-empty);
			for 0..@cols.end -> $c {
				if @cols[$c] ne $.default {
					self.set-xy($c, $r, @cols[$c]);
				}
			}
		}
	}
}
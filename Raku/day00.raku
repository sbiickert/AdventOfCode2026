#!/usr/bin/env raku

use lib $*PROGRAM.sibling('lib');
use AOC::Util;
#use AOC::Geometry;
#use AOC::Grid;

sub MAIN(Str $type = 'test', $index = 0) {
    say "Advent of Code 2026, Day 0: Test Zero";
    my $file = "../Input/day00_{ $type }.txt";
    my @input = read-grouped-input($file, $index);

    my $p1 = solve-part-one(@input);
    say "Part One: $p1";

    my $p2 = solve-part-two(@input);
    say "Part Two: $p2";
}

sub solve-part-one(@input --> Int) {

	return 1;
}

sub solve-part-two(@input --> Int) {
	
    return 2;
}

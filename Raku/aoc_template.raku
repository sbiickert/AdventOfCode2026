#!/usr/bin/env raku

use lib $*PROGRAM.sibling('lib');
use AOC::Util;
#use AOC::Geometry;
#use AOC::Grid;

my $TYPE := 'test';

sub MAIN(Str $file = "../Input/day<##>_{ $TYPE }.txt") {
    say "Advent of Code <##>, Day <##>: <##>";
    my @input = read_input($file);

    my $p1 = solve_part_one(@input);
    say "Part One: $p1";

    my $p2 = solve_part_two(@input);
    say "Part Two: $p2";
}

sub solve-part-one(@input --> Int) {

	return 1;
}

sub solve-part-two(@input --> Int) {
	
    return 2;
}

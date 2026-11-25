#!/usr/bin/env raku

constant TEMPLATE = 'aoc_template.raku';
my $tag := '<##>';
my $year := 2026;

sub MAIN(Int $day, Str $challenge-name) {
	my @lines = TEMPLATE.IO.lines;
	my $pad-day = '%02s'.sprintf($day);
	@lines = @lines.map(-> $line {
		my $temp = $line.subst("$tag, Day $tag: $tag", "$year, Day $day: $challenge-name", :g);
		$temp = $temp.subst($tag, $pad-day);
	});
	
	my $filename = "day$pad-day.raku";
	!$filename.IO.e or die "File $filename already exists. Exiting.";
	
	my $fh = open $filename, :w;
	for @lines -> $line {
		$fh.say($line);
	}
	$fh.close;
	shell("chmod +x $filename; code $filename");
	
}

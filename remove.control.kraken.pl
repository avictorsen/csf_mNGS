#!/usr/bin/perl
use strict;
use warnings;

unless (@ARGV > 1){
        die "not enough input";
}
print "Input report file: $ARGV[0]\n";
print "Sample Kraken file: $ARGV[1]\n";

#open (INPUT, "<".$ARGV[0].".report") || die "Cannot open Input file";
open (INPUT, "<".$ARGV[0]) || die "Cannot open Input file";
open (KRAKEN, "<".$ARGV[1]) || die "Cannot open Sample file";
open (OUT, ">".$ARGV[1].".subtracted") || die "Cannot open Output file";

my %to_delete;
while (<INPUT>) {
	my @line = split('\t', $_);
	$to_delete{$line[4]}=1;
}
close INPUT;

while (<KRAKEN>){
	#print $_;
	my @line=split("\t", $_);
	if (exists ($to_delete{$line[2]})){;}
	else{
		print OUT $_;
	}
}	

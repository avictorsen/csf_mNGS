#!/usr/bin/perl
use strict;
use warnings;

unless (@ARGV > 1){
        die "not enough input";
}
print "Input report file: $ARGV[0]\n";
print "Sample Kaiju file: $ARGV[1]\n";

#open (INPUT, "<".$ARGV[0].".report") || die "Cannot open Input file";
open (INPUT, "<".$ARGV[0]) || die "Cannot open Input file";
open (KAIJU, "<".$ARGV[1]) || die "Cannot open Sample file";
open (OUT, ">".$ARGV[1].".subtracted") || die "Cannot open Output file";

my %to_delete;
# remove Escherichia phage MS2
$to_delete{"12022"} = 0;
while (<INPUT>) {
	if ($_ ne ""){
		my @line = split('\t', $_);
#		if (exists ($to_delete{$line[7]})){;}
		if (exists ($to_delete{$line[2]})){;}
		else {
			$to_delete{$line[2]}=1;
		}
	}
}
close INPUT;

while (<KAIJU>){
	#print $_;
	my @line=split("\t", $_);
	if (exists ($to_delete{$line[2]})){;}
	else{
		print OUT $_;
	}
}	

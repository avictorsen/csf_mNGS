#!/usr/bin/perl
use strict;
use warnings;

unless (@ARGV > 0){
        die "not enough input";
}
print "kraken threshold file: $ARGV[0]\n";
print "Original report file: $ARGV[1]\n";

my $current_D="null";

my %threshold;
open (THRESHOLD, "<".$ARGV[0]) || die "Cannot open threshold file";
while (<THRESHOLD>){
	chomp;
	my @values = split('\t', $_);
	$threshold{$values[0]} = $values[1];
}
close THRESHOLD;

open (REPORT, "<".$ARGV[1].".report") || die "Cannot open report file";
open (KRAKEN, "<".$ARGV[1]) || die "Cannot open kraken file";
open (OUT, ">".$ARGV[1].".thresholded") || die "Cannot open output file";

my $rank;
my %to_delete;
while (<REPORT>) {
	my @line = split('\t', $_);
	#for first domain
	if ($current_D eq "null" && $line[3] eq "D"){
		$line[5]=~ m/\S\N+/;
		$current_D=$&;
		#print "Domain: X".$current_D."X\n";
		if ($line[2] < $threshold{$current_D}){
			$to_delete{$line[4]}=1;
		}
	#for next domain
	}elsif ($current_D ne "null" && $line[3] eq "D"){
		$line[5]=~ m/\S+/;
		$current_D=$&;
		if (exists $threshold{$current_D}){
			if ($line[2] < $threshold{$current_D}){
				$to_delete{$line[4]}=1;
				#print "$_ $line[1] is less then threshold for $current_D\n";
			}
		}
	#for non domain lines
	}elsif ($current_D ne "null" && $line[3] ne "D"){
		#if there's a threshold in place
		if (exists $threshold{$current_D}){
			$line[5]=~ m/\S\N+/;
			#if there's a special threshold for the species ie Cryptococcus
			if (exists $threshold{$&}){
				if ($line[2] < $threshold{$&}){
					$to_delete{$line[4]}=1;
					#print "$_ $line[2] is less then threshold for $current_D\n";
				}
			}else{
				if ($line[2] < $threshold{$current_D}){
					$to_delete{$line[4]}=1;
					#print "$_ $line[2] is less then threshold for $current_D\n";
				}else{
					#print "--------------\n";
					#print "Domain: $current_D\n";
					#print $_;
					#<STDIN>;
				}
			}
		}
	}else{
	}
}
close REPORT;

while (<KRAKEN>){
	#print $_;
	my @line=split("\t", $_);
	if (exists ($to_delete{$line[2]})){;}
	else{
		print OUT $_;
	}
}	

#!/usr/bin/perl
use strict;
use warnings;

unless (@ARGV > 0){
        die "not enough input";
}
print "Original report file: $ARGV[0]\n";

my $current_D="null";

#my %threashold = (
#	'Archaea' => 10,
#	'Bacteria' => 200,
#	'Viruses' => 3,
#	'Cryptococcus neoformans' => 100,
#	'Eukaryota' => 100,
#);
my %threashold;
open (THREASHOLD, "<", "~/csf_mNGS/kraken.threasholds.txt") || die "Cannot open threashold file";
while (<THREASHOLD>);
	chomp;
	my @values = split('\t', $_);
	$threashold{$value[0]} = $value[1];
}
close THREASHOLD;

open (REPORT, "<".$ARGV[0].".report") || die "Cannot open report file";
open (KRAKEN, "<".$ARGV[0]) || die "Cannot open kraken file";
open (OUT, ">".$ARGV[0].".threasholded") || die "Cannot open output file";

my $rank;
my %to_delete;
while (<REPORT>) {
	my @line = split('\t', $_);
	#for first domain
	if ($current_D eq "null" && $line[3] eq "D"){
		$line[5]=~ m/\S\N+/;
		$current_D=$&;
		#print "Domain: X".$current_D."X\n";
		if ($line[2] < $threashold{$current_D}){
			$to_delete{$line[4]}=1;
		}
	#for next domain
	}elsif ($current_D ne "null" && $line[3] eq "D"){
		$line[5]=~ m/\S+/;
		$current_D=$&;
		if (exists $threashold{$current_D}){
			if ($line[2] < $threashold{$current_D}){
				$to_delete{$line[4]}=1;
				#print "$_ $line[1] is less then threashold for $current_D\n";
			}
		}
	#for non domain lines
	}elsif ($current_D ne "null" && $line[3] ne "D"){
		#if there's a threashold in place
		if (exists $threashold{$current_D}){
			$line[5]=~ m/\S\N+/;
			#if there's a special threashold for the species ie Cryptococcus
			if (exists $threashold{$&}){
				if ($line[2] < $threashold{$&}){
					$to_delete{$line[4]}=1;
					#print "$_ $line[2] is less then threashold for $current_D\n";
				}
			}else{
				if ($line[2] < $threashold{$current_D}){
					$to_delete{$line[4]}=1;
					#print "$_ $line[2] is less then threashold for $current_D\n";
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

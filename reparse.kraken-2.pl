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
open (THREASHOLD, "< /home/thyagara/victo160/csf_mNGS/kraken.thresholds.txt") || die "Cannot open threshold file";
while (<THREASHOLD>){
        chomp;
	my @values = split('\t', $_);
	$threashold{$values[0]} = $values[1];
}
close THREASHOLD;

open (REPORT, "<".$ARGV[0].".report") || die "Cannot open report file";
open (KRAKEN, "<".$ARGV[0]) || die "Cannot open kraken file";
open (OUT, ">".$ARGV[0].".thresholded") || die "Cannot open output file";

my $burk = 0;
my $rank;
my %to_delete = ('9606' => 1);
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
	if ($burk == 1){
		if ($line[3] eq "F"){
			$to_delete{$line[4]}=1;
		}		
		elsif ($line[3] eq "F1"){
			$to_delete{$line[4]}=1;
		}		
		elsif ($line[3] eq "G"){
			$to_delete{$line[4]}=1;
		}		
		elsif ($line[3] eq "G1"){
			$to_delete{$line[4]}=1;
		}		
		elsif ($line[3] eq "S"){
			$to_delete{$line[4]}=1;
		}		
		elsif ($line[3] eq "S1"){
			$to_delete{$line[4]}=1;
		}		
		else{
			$burk = 0;
		}		
	}
	#for every line seach for start of Burkholderia
	if ($line[4] eq "80840"){
		$burk = 1;
		$to_delete{$line[4]}=1;
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

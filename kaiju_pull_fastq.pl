#!/usr/bin/perl
use strict;
use warnings;

unless (@ARGV > 2){
	die "not enough input";
}
#print "kaiju file: $ARGV[0]\n";
#print "1st fastq file: $ARGV[1]\n";
#print "2nd file: $ARGV[2]\n";


my $counter;
my %KAIJU;
my %OR1_hash;
my $OR1_key;
my @OR1_value;
my %OR2_hash;
my $OR2_key;
my @OR2_value;

$counter = 0;
open (R1, "<".$ARGV[0]) || die "Cannot open file";
while (<R1>) {
	chomp;
	my @id = split("\t",$_);
	if (exists ($KAIJU{$id[1]})){
		die "Duplicate read in fastq!";
	}else{
		$KAIJU{$id[1]} = $_;
		$counter += 1;
		#print "$id[1]\n";
	}
}
close R1;
#print "$counter reads read from file\n";

my $reads=scalar keys %KAIJU;
my $readcounter=0;
open (OR1, "<", $ARGV[1]) || die "Cannot open 1st fastq file";
while (<OR1>) {
	if (($.+3) % 4 == 0){
		@OR1_value = ();
		$OR1_key = $_;
		$OR1_key =~ s/^@//;
		$OR1_key =~ m/ /;
		$OR1_key = $`;
		$counter=0;
	}else{
		chomp;
		push(@OR1_value, $_);
		$counter += 1;
	}
	if ($counter == 3){
		$OR1_key =~ m/\S+/;
		if (exists $KAIJU{$&}){
			$readcounter += 1;
			$KAIJU{$&}.="\t$OR1_value[0]";
		}
	}
}
if ($readcounter != $reads){die "R1 output file is missing reads!";}
close OR1;
#print "R1 fastq has been read\n";


$readcounter=0;
open (OR2, "<", $ARGV[2]) || die "Cannot open 2nd fastq file";
while (<OR2>) {
	if (($.+3) % 4 == 0){
		@OR2_value = ();
		$OR2_key = $_;
                $OR1_key = $_;
                $OR2_key =~ s/^@//;
                $OR2_key =~ m/ /;
                $OR2_key = $`;
		$counter=0;
	}else{
		chomp;
		push(@OR2_value, $_);
		$counter += 1;
	}
	if ($counter == 3){
		$OR2_key =~ m/\S+/;
		if (exists $KAIJU{$&}){
			$readcounter += 1;
			$KAIJU{$&}.="\t$OR2_value[0]";
		}
	}
}
if ($readcounter != $reads){die "R2 file is missing reads!";}
close OR2;
#print "R2 fastq has been read\n";

foreach  (keys %KAIJU){
	print "$KAIJU{$_}\n";
}

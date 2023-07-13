#!/usr/bin/perl
use strict;
use warnings;
use feature 'state';

unless (@ARGV > 1){
	die "not enough";
}
#print "1st file: $ARGV[0]\n";
#print "2nd file: $ARGV[1]\n";
#print "3rd file: $ARGV[2]\n";
#print "4th file: $ARGV[3]\n";


my $counter;
my %READS;
my %OR1_hash;
my $OR1_key;
my @OR1_value;
my %OR2_hash;
my $OR2_key;
my @OR2_value;

$counter = 0;
open (R1, "<".$ARGV[0]) || die "Cannot open file";
while (<R1>) {
        if (($.+3) % 4 == 0){
		chomp;
		if (exists ($READS{$_})){
			die "Duplicate read in fastq!";
		}else{
			$READS{$_} = "";
			$counter += 1;
		}
	}
}
close R1;

print "$counter reads read from 1st file, ";
print scalar keys %READS;
print " total reads read\n";

$counter = 0;
open (R2, "<".$ARGV[1]) || die "Cannot open file";
while (<R2>) {
        if (($.+3) % 4 == 0){
		chomp;
		if (!exists ($READS{$_})){	
			$READS{$_} = "";
			$counter += 1;
		}
	}
}
close R2;

print "$counter reads read from 2nd file, ";
print scalar keys %READS;
print " total reads read\n";
#open (TEMPO, ">", "queries.txt") || die;
#foreach (keys %READS){
#	print TEMPO "$_\n";
#} 

my $reads=scalar keys %READS;
state $readcounter=0;

my $R1="R1_new.fastq";
my $R2="R2_new.fastq";

open (NOR1, ">".$R1) || die "Cannot open outfile";
close NOR1;
open (NOR2, ">".$R2) || die "Cannot open outfile";
close NOR2;

sub read_file {
	my @list=@_;
	#print "\tFH: $list[0]\n";
	#print "\tOFH: $list[1]\n";
	#print "\tHR: $list[2]\n";
	my %HASH = %{$list[2]};
	open (FH, "<".$list[0]) || die "Cannot open file";
	open (OFH, ">>".$list[1]) || die "Cannot open outfile";
	
	while (<FH>) {
	        if (($.+3) % 4 == 0){
			@OR1_value = ();
			$OR1_key = $_;
			$counter=0;
		}else{
			push(@OR1_value, $_);
			$counter += 1;
		}
		if ($counter == 3){
			$OR1_key =~ m/\S+/;
			if (exists $HASH{$&}){
				$readcounter += 1;
				print OFH $OR1_key;
				for my $i (0 .. 2){
					print OFH $OR1_value[$i];
				}
			}
		}
	}
	close FH;
	close OFH;
}

opendir (DIR, ".");
my @x=grep(/^original_R1.temp/,readdir(DIR));
my @filelist=sort { $a cmp $b } @x;
foreach (@filelist){
#	print "$_\n";
	read_file($_, $R1, \%READS);
}
print "$readcounter\n";
if ($readcounter != $reads){die "R1 output file is missing reads!";}
print "R1_new.fastq written\n";
@x=();
closedir DIR;

opendir (DIR, ".");
$readcounter=0;
@x=grep(/^original_R2.temp/,readdir(DIR));
@filelist=sort { $a cmp $b } @x;
foreach (@filelist){
#	print "$_\n";
	read_file($_, $R2, \%READS);
}

if ($readcounter != $reads){die "R2 output file is missing reads!";}
print "R2_new.fastq written\n";

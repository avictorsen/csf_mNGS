#!/usr/bin/perl
use strict;
use warnings;

unless (@ARGV > 2){
	die "not enough";
}
#print "1st file: $ARGV[0]\n";
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
	chomp;
	my @id = split("\t",$_);
	if (exists ($READS{$id[1]})){
		die "Duplicate read in fastq!";
	}else{
		$READS{$id[1]} = "";
		$counter += 1;
	}
}
close R1;

print "$counter reads read from file\n";

my $reads=scalar keys %READS;
my $readcounter=0;
open (OR1, "gunzip -c $ARGV[1] |") ||die "Cannot open file";
open (NOR1, ">", "R1_new.fastq") || die "Cannot open outfile";
while (<OR1>) {
#        if ($_ =~ /^\@/){
	if (($.+3) % 4 == 0){
		@OR1_value = ();
		$OR1_key = $_;
#		print $OR1_key;
		$OR1_key =~ s/^@//;
		$OR1_key =~ m/ /;
		$OR1_key = $`;
#		print $OR1_key;<STDIN>;
		$counter=0;
	}else{
		push(@OR1_value, $_);
		$counter += 1;
	}
	if ($counter == 3){
		$OR1_key =~ m/\S+/;
		if (exists $READS{$&}){
			$readcounter += 1;
			print NOR1 "@".$OR1_key."\n";
			for my $i (0 .. 2){
				print NOR1 $OR1_value[$i];
			}
		}
	}
}
if ($readcounter != $reads){die "R1 output file is missing reads!";}
close OR1;
close NOR1;
print "R1_new.fastq written\n";

$readcounter=0;
open (OR2, "gunzip -c $ARGV[2] |")  || die "Cannot open file";
open (NOR2, ">", "R2_new.fastq") || die "Cannot open outfile";
while (<OR2>) {
#        if ($_ =~ /^\@/){
	if (($.+3) % 4 == 0){
		@OR2_value = ();
		$OR2_key = $_;
                $OR1_key = $_;
                $OR2_key =~ s/^@//;
                $OR2_key =~ m/ /;
                $OR2_key = $`;
		$counter=0;
	}else{
		push(@OR2_value, $_);
		$counter += 1;
	}
	if ($counter == 3){
		$OR2_key =~ m/\S+/;
		if (exists $READS{$&}){
			$readcounter += 1;
			print NOR2 "@".$OR2_key."\n";
			for my $i (0 .. 2){
				print NOR2 $OR2_value[$i];
			}
		}
	}
}
if ($readcounter != $reads){die "R1 output file is missing reads!";}
close OR2;
close NOR2;
print "R2_new.fastq written\n";

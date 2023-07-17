#!/usr/bin/perl
use strict;
use warnings;

open (INFILE, "<", $ARGV[0]) || die "Cannot open in file!";
open (GOODOUTFILE, ">", $ARGV[0].".good.parsed") || die "Cannot open good output file!";
open (BADOUTFILE, ">", $ARGV[0].".bad.parsed") || die "Cannot open bad output file!";
#open (UGLYOUTFILE, ">", $ARGV[0].".questionable.parsed") || die "Cannot open ugly output file!";

my @line;
my $len;
my $readlen1;
my $readlen2;
my $kmers;
my $kmer1;
my $kmer2;
my $R1kmerLEN;
my $R2kmerLEN;
my @kmerarray;

sub add_kmers {
	my %sum;
	my ($one, $key) = @_;
	my @array = @{$one};
	foreach (@array){
		if ($_ =~ /\:/){
			if ($sum{$`}){
				$sum{$`} = $sum{$`}+$';
			} else {
				$sum{$`} = $'
			}
		} else {die "Cannot split kmer."};
	}
	
	if ($sum{$key}){ return $sum{$key}; }
	else {return '0'}
}

while (<INFILE>){
	my $line = $_;
	#print $line;
	@line=split("\t", $line);
	my $taxid = $line[2];
	$len=$line[3];
	$kmers=$line[4];
	if ($len =~ /\|/){
		$readlen1=$`;
		$readlen2=$';
	} else {die "Cannot seperate read lengths.";}
        if ($kmers =~ /\|\:\|/){
		$kmer1 = $`;
		$kmer2 = $';
	} else {die "Cannot seperate kmers.";}

	$R1kmerLEN=$readlen1 - 34;
	$R2kmerLEN=$readlen2 - 34;

	#print "LEN: $R1kmerLEN\t$R1kmerLEN\n";

	@kmerarray = split(" ",$kmer1);
	my $sum1=add_kmers(\@kmerarray, 0);
	#print "R1 $sum1\n";
	@kmerarray = ();

	@kmerarray = split(" ",$kmer2);
	my $sum2=add_kmers(\@kmerarray, 0);
	#print "R2 $sum2\n";
	@kmerarray = ();

#	@kmerarray = split(" ",$kmer1);
#	my $sum3=add_kmers(\@kmerarray, $taxid);
#	#print "$taxid $sum3\n";
#	@kmerarray = ();

#	@kmerarray = split(" ",$kmer2);
#	my $sum4=add_kmers(\@kmerarray, $taxid);
#	#print "$taxid $sum4\n";
#	@kmerarray = ();

	if ( ($sum1 / $R1kmerLEN) < 0.2 && ($sum2 / $R2kmerLEN) < 0.2 ){
#		if ( ($sum3 / $R1kmerLEN) < 0.25 || ($sum4 / $R2kmerLEN) < 0.25 ){
#			print UGLYOUTFILE $line;
#		} else {
			print GOODOUTFILE $line;
#		}
	} else {
		print BADOUTFILE $line;
#		printf ("%.2f", ($sum1 / $R1kmerLEN));
#		print "\n";
#		printf ("%.2f", ($sum2 / $R2kmerLEN));
#		print "\n";
#		print "skipping line: $line";

	}
	($sum1,$sum2,$R1kmerLEN,$R2kmerLEN,$len,$readlen1,$readlen2,$kmers,$kmer1,$kmer2)=();

}


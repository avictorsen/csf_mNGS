#!/usr/bin/perl
use strict;
use warnings;

unless (@ARGV > 1){
        die "not enough";
}
#print "1st: $ARGV[0]\n";
#print "2nd: $ARGV[1]\n";

open (TRC, "<",$ARGV[0]."/samples/".$ARGV[1]."/01_fastqc_original/Total_read_count.txt") or die "Cannot open file 1";
my $trc = <TRC>;
chomp $trc;
while ($trc =~ s/(.*\d)(\d\d\d)/$1\,$2/g){};
close TRC;

open (URC, "<",$ARGV[0]."/samples/".$ARGV[1]."/04_BWA/Useable_read_count.txt") or die "Cannot open file 2"; 
my $urc = <URC>;
chomp $urc;
while ($urc =~ s/(.*\d)(\d\d\d)/$1\,$2/g){};
close URC;

open (HRC, "<",$ARGV[0]."/samples/".$ARGV[1]."/04_BWA/Human_read_count.txt") or die "Cannot open file 3"; 
my $hrc = <HRC>;
chomp $hrc;
while ($hrc =~ s/(.*\d)(\d\d\d)/$1\,$2/g){};
close HRC;

my $hmrc=0;
if ( -e $ARGV[0]."/samples/".$ARGV[1]."/04_BWA/Human_mRNA_read_count.txt" ){
	open (HMRC, "<",$ARGV[0]."/samples/".$ARGV[1]."/04_BWA/Human_mRNA_read_count.txt") or die "Cannot open file 3.5"; 
	my $hmrc = <HMRC>;
	chomp $hmrc;
	while ($hmrc =~ s/(.*\d)(\d\d\d)/$1\,$2/g){};
	close HMRC;
}

open (LRC, "<",$ARGV[0]."/samples/".$ARGV[1]."/04_BWA/Lambda_read_count.txt") or die "Cannot open file 4"; 
my $lrc = <LRC>;
chomp $lrc;
while ($lrc =~ s/(.*\d)(\d\d\d)/$1\,$2/g){};
close LRC;

open (MRC, "<",$ARGV[0]."/samples/".$ARGV[1]."/04_BWA/MS2_read_count.txt") or die "Cannot open file 5"; 
my $mrc = <MRC>;
chomp $mrc;
while ($mrc =~ s/(.*\d)(\d\d\d)/$1\,$2/g){};
close MRC;

open (UNQ, "<",$ARGV[0]."/samples/".$ARGV[1]."/05_prinseq/Unique_read_count.txt") or die "Cannot open file 5.5"; 
my $unq = <UNQ>;
chomp $unq;
my $unq_raw=$unq;
while ($unq =~ s/(.*\d)(\d\d\d)/$1\,$2/g){};
close UNQ;

my $input=1;
open (KAIJUSUB, "<",$ARGV[0]."/samples/".$ARGV[1]."/06_kaiju/kaiju.strict.hits.subtracted.report") or $input=0;
my %hits;
if ($input == 1){
	while (<KAIJUSUB>){
		chomp;
		my @info = split("\t",$_);
		if ($info[0] eq "C"){
			if ($hits{$info[7]}){
				$hits{$info[7]}++;
			}elsif ($info[7] eq "Escherichia phage MS2"){
				;
			}else{
				$hits{$info[7]}=1;
			}
		}
	}
}
close KAIJUSUB;

open (KAIJUTRESH, "<",$ARGV[0]."/samples/".$ARGV[1]."/06_kaiju/kaiju.strict.report") or die "Cannot open file 7";
my %all;
while (<KAIJUTRESH>){
	chomp;
	my @info = split("\t",$_);
	if ($info[0] eq "C"){
		if ($hits{$info[7]}){
			;
		}elsif ($info[7] eq "Escherichia phage MS2"){
			;
		}elsif ($all{$info[7]}){
			$all{$info[7]}++;
		}else{
			$all{$info[7]}=1;
		}
	}
}
close KAIJUTRESH;

open (OUT, ">",$ARGV[1].".kaiju.output.txt") or die "Cannot open file OUT"; 

print OUT "Total reads: $trc\n";
print OUT "Useable reads: $urc\n";
print OUT "Human reads: $hrc\n";
print OUT "Human mRNA reads: $hmrc\n";
print OUT "Lambda phage spike-in reads: $lrc\n";
print OUT "MS2 phage spike-in reads: $mrc\n";
print OUT "Unique filtered reads: $unq\n\n\n";

if ($input == 1){
	print OUT "Organisms not seen in input, reads:\n";
	foreach (sort {$hits{$b} <=> $hits{$a}} keys %hits){
		printf OUT "\t%s: %i\n", $_, $hits{$_};
	}
	print OUT "\nOrganisms also seen in input, reads:\n";
}else{
	print OUT "Organisms, reads:\n";
}
foreach (sort {$all{$b} <=> $all{$a}} keys %all){
	printf OUT "\t%s: %i\n", $_, $all{$_};
}

close OUT;
exit



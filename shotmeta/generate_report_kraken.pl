#!/usr/bin/perl
use strict;
use warnings;

unless (@ARGV > 1){
        die "not enough";
}
print "Project DIR: $ARGV[0]\n";
print "Sample Name: $ARGV[1]\n";

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


open (RAW, "< /home/thyagara/victo160/csf_mNGS/kraken.thresholds.txt") or die "Cannot open file 6";
my %raw;
while (<RAW>){
	chomp;
	my @line = split("\t",$_);
        $raw{$line[0]} = $line[1];
}
close RAW;

open (THRESH, "< /home/thyagara/victo160/csf_mNGS/RPKR.thresholds.txt") or die "Cannot open file 6.5";
my %hold;
while (<THRESH>){
	chomp;
	my @line = split("\t",$_);
        $hold{$line[0]} = $line[1];
}
close THRESH;

open (KRAKENTRESH, "<",$ARGV[0]."/samples/".$ARGV[1]."/06_kraken/kraken.good.parsed.thresholded.report") or die "Cannot open file 7";
my %hits; 
my %path; # for likely pathogens but below threshold
my %orgs; # for unlikely pathogens but above kingdom threshold
while (<KRAKENTRESH>){
	chomp;
	my @info = split("\t",$_);
	$info[5] =~ s/^\s*//;
	if ($info[3] eq "S" || $hold{$info[5]}){						# line is species or there's a RPKM threshold for organism
		if ($hold{$info[5]}){
			if (($info[1] / ( $unq_raw / 1000 )) > $hold{$info[5]}){		# if above RPKM threshold		
				$hits{$info[5]} = ( $info[1] / ( $unq_raw / 1000 ));
			}else{									# if below RPKM threshold
				$path{$info[5]} = ( $info[1] / ( $unq_raw / 1000));
			}
		}else{										# if no RPKM threshold, but higher then kingdom because it's pulling from parsed kraken file
			$orgs{$info[5]} = ( $info[1] / ( $unq_raw / 1000));
		}
	}
}
close KRAKENTRESH;

# Using this file doesn't add up because reads are removed if they're iffy.
#open (KRAKEN, "<",$ARGV[0]."/samples/".$ARGV[1]."/06_kraken/kraken.report") or die "Cannot open file 7.5";
#my %bugs; # all organisms above kingdom threshold
#while (<KRAKEN>){
#	chomp;
#	my @info = split("\t",$_);
#	$info[5] =~ s/^\s*//;
#	if ($info[3] eq "S"){
#		if ( $hits{$info[5]} || $orgs{$info[5]} || $path{$info[5]}){			# if organism is in any other more important list, skip it
#			;
#			$bugs{$info[5]} = ( $info[1] );
#		}elsif ($info[5] eq "Homo sapiens"){						# if organism is Human, skip it
#			;
#		}else{
#			$bugs{$info[5]} = ( $info[1] / ( $unq_raw / 1000));			# report RPKM
#			$bugs{$info[5]} = ( $info[1] );						# report raw reads
#		}
#	}
#}
#close KRAKEN;



open (OUT, ">",$ARGV[1].".output.txt") or die "Cannot open file OUT"; 

print OUT "Total reads: $trc\n";
print OUT "Useable reads: $urc\n";
print OUT "Human reads: $hrc\n";
print OUT "Human mRNA reads: $hmrc\n";
print OUT "Lambda phage spike-in reads: $lrc\n";
print OUT "MS2 phage spike-in reads: $mrc\n";
print OUT "Unique filtered reads: $unq\n\n\n";

print OUT "Organisms above species specific threshold, reads per thousand filtered reads:\n";
foreach (sort keys %hits){
	printf OUT "\t%s: %.4f\n", $_, $hits{$_};
}

print OUT "\nOrganisms with species RPKM thresholds, but below thresholds:\n";
#foreach (sort keys %path){
foreach (sort {$path{$b} <=> $path{$a}} keys %path){
	printf OUT "\t%s: %.4f\n",$_,$path{$_};
}

print OUT "\nOrganisms with no species RPKM thresholds, but above raw read kingdom thresholds:\n";
#foreach (sort keys %orgs){
foreach (sort {$orgs{$b} <=> $orgs{$a}} keys %orgs){
	printf OUT "\t%s: %.4f\n",$_,$orgs{$_};
}

#print OUT "\nTop 10 observed organisms below kingdom thresholds:\n";
#my $j=0;
#foreach (sort {$bugs{$b} <=> $bugs{$a}} keys %bugs){
#	if ($j < 10){
#		printf OUT "\t%s: %.4f\n",$_,$bugs{$_};
#		printf OUT "\t%s: %i\n",$_,$bugs{$_};
#	}
#	$j++;
#}

print OUT "\n\nthresholds:\n\tSpecies thresholds, reads per thousand filtered reads:\n";
foreach (sort keys %hold){
	print OUT "\t\t$_: $hold{$_}\n";
} 

print OUT "\n\n\tKingdom thresholds, reads:\n";
foreach (sort keys %raw){
	print OUT "\t\t$_: $raw{$_}\n";
}


close OUT;
exit



#!/usr/bin/perl
use strict;
use warnings;
use Bio::MAGE::QuantitationType::PValue;

unless (@ARGV > 1){
        die "not enough";
}
print "RUNNING STDDEV TEST\n";
print "1st argument: $ARGV[0]\n";
print "2nd argument: $ARGV[1]\n";
print "3rd argument: $ARGV[2]\n";

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


open (RAW, "< ".$ARGV[2]."/kraken.thresholds.txt") or die "Cannot open file 6";
my %raw;
while (<RAW>){
	chomp;
	my @line = split("\t",$_);
        $raw{$line[0]} = $line[1];
}
close RAW;

open (THRESH1, "< ".$ARGV[2]."/RPKR.thresholds.txt") or die "Cannot open file 6.5";
my %thres;
while (<THRESH1>){
	chomp;
	my @line = split("\t",$_);
	$thres{$line[0]} = $line[1];
}
close THRESH1;

open (THRESH2, "< ".$ARGV[2]."/RPKR.stddev.thresholds.txt") or die "Cannot open file 6.5";
my %hold;
while (<THRESH2>){
	chomp;
	my @line = split("\t",$_);
	#$count,$mean,$std
        $hold{$line[0]} = [$line[1], $line[2], $line[3]];

}
close THRESH2;

open (KRAKENTRESH, "<",$ARGV[0]."/samples/".$ARGV[1]."/06_kraken/kraken.good.parsed.thresholded.report") or die "Cannot open file 7";
my %hits; # Orgs with RPKR > 0.0001 (1:10,000 or Z>=5))
my %rare; # Infrequent orgs n < 10
my %orgs; # Orgs by RPKR
while (<KRAKENTRESH>){
	chomp;
	my @info = split("\t",$_);
	$info[5] =~ s/^\s*//;
	if ($info[3] eq "S" || $hold{$info[5]}){
		if ($hold{$info[5]}){												# line is species or there's a RPKM threshold for organism
			print "$info[5] $info[1] $unq_raw n=$hold{$info[5]}[0] mean=$hold{$info[5]}[1] σ=$hold{$info[5]}[2]\n";
			# if RPKR is significantly higher then background
			if ($hold{$info[5]}[0] >= 10){										# if threshold is derived from at least 10 observations
				my $Z=(abs(( $info[1] / ( $unq_raw / 1000 )) - $hold{$info[5]}[1] ) / $hold{$info[5]}[2] );
				print "  Z: $Z\n";
				if ($Z >= 5){											# if threshold z-score is > 5 stds.
					$hits{$info[5]}[0] = ( $info[1] / ( $unq_raw / 1000 ));						# set RPKM as value 1
					$hits{$info[5]}[1] = $Z;									# set Z as value 2
					$hits{$info[5]}[2] = $hold{$info[5]}[0];							# set n as value 3
				}else{												# if threshold z-score is < 5 stds.
					$orgs{$info[5]} = ( $info[1] / ( $unq_raw / 1000));						# insignificant
				}
			}
			else{													# if threshold is derived from less then 10 observations
				if ($thres{$info[5]}){										# if RPKM threshold exists
					if (($info[1] / ( $unq_raw / 1000 )) > $thres{$info[5]}){				# if > then RPKM theshold
						$rare{$info[5]}[0] = ( $info[1] / ( $unq_raw / 1000 ));					# set RPKM as value 1
						$rare{$info[5]}[1] = "n=$hold{$info[5]}[0]";						# set Z as value 2
					}else{
						$orgs{$info[5]} = ( $info[1] / ( $unq_raw / 1000));					# insignificant
					}
				}else{
					$orgs{$info[5]} = ( $info[1] / ( $unq_raw / 1000));						# insignificant
				}
			}
		}else{														# if there is no threshold
			$orgs{$info[5]} = ( $info[1] / ( $unq_raw / 1000));
		}
	}
}
close KRAKENTRESH;

# Using this file doesn't add up because reads are removed if they're iffy.
#open (KRAKEN, "<",$ARGV[0]."/samples/".$ARGV[1]."/06_kraken/kraken.report") or die "Cannot open file 7.5";
#my %bugs; # all orgs, raw reads
#while (<KRAKEN>){
#	chomp;
#	my @info = split("\t",$_);
#	$info[5] =~ s/^\s*//;
#	if ($info[3] =~ /^S/){	#will pull subspecies
#	if ($info[3] eq "S"){
#		if ( $hits{$info[5]} || $orgs{$info[5]} ){
#			$bugs{$info[5]} = ( $info[1] );
#		}else{
#			$bugs{$info[5]} = ( $info[1] / ( $unq_raw / 1000));
#			$bugs{$info[5]} = ( $info[1] );
#		}
#	}
#}
#close KRAKEN;



open (OUT, ">",$ARGV[1].".STD.output.txt") or die "Cannot open file OUT"; 

print OUT "Total reads: $trc\n";
print OUT "Useable reads: $urc\n";
print OUT "Human reads: $hrc\n";
print OUT "Human mRNA reads: $hmrc\n";
print OUT "Lambda phage spike-in reads: $lrc\n";
print OUT "MS2 phage spike-in reads: $mrc\n";
print OUT "Unique filtered reads: $unq\n\n\n";

print OUT "Organisms with RPKM(reads per thousand filtered reads) > 5σ:\n";
foreach (sort keys %hits){
	printf OUT "\t%s: %.4f z=%.2fσ, n=%i\n", $_, $hits{$_}[0], $hits{$_}[1], $hits{$_}[2];
}

print OUT "\nOrganisms with unknown RPKM distributions (observed in n 'negative' datasets), but are above species specific thresholds listed below, reads per thousand filtered reads:\n";
foreach (sort keys %rare){
	printf OUT "\t%s: %.4f, %s\n", $_, $rare{$_}[0], $rare{$_}[1];
}

print OUT "\nAll organisms above kingdom threshold, reads per thousand filtered reads:\n";
#foreach (sort keys %orgs){
foreach (sort {$orgs{$b} <=> $orgs{$a}} keys %orgs){
	printf OUT "\t%s: %.4f\n",$_,$orgs{$_};
}

#print OUT "\nTop 20 observed organisms by number of reads:\n";
#my $j=0;
#foreach (sort {$bugs{$b} <=> $bugs{$a}} keys %bugs){
#	if ($j < 20){
##		printf OUT "\t%s: %.4f\n",$_,$bugs{$_};
#		printf OUT "\t%s: %i\n",$_,$bugs{$_};
#	}
#	$j++;
#}

print OUT "\n\nthresholds:\n\tSpecies thresholds, reads per thousand filtered reads:\n";
foreach (sort keys %thres){
	print OUT "\t\t$_: $thres{$_}\n";
}

print OUT "\n\n\tKingdom thresholds, reads:\n";
foreach (sort keys %raw){
	print OUT "\t\t$_: $raw{$_}\n";
}

close OUT;
exit



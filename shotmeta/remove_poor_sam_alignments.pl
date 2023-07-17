#!/usr/bin/perl
use strict;
use warnings;

unless (@ARGV > 0){
	die "not enough";
}

open (INFILE, "<".$ARGV[0]) || die "Cannot open file";
open (BOUTFILE, ">".$ARGV[0].".bad") || die "Cannot open outfile";
open (GOUTFILE, ">".$ARGV[0].".good") || die "Cannot open outfile";

while (<INFILE>) {
        if ($_ =~ /^\@/){
		next;
	}
	my $line=$_;
#	chomp $line;
	my @j=split("\t", $line);
	my $dig=0;
	my @num;
	my @char;
	my $match;
	foreach (@j){
		if ($_ =~ /^MD\:Z\:/){
			$match=$';
			my @array = split("", $match);
			for my $i (0 .. $#array){
				#if first character is a non-zero numeral start recording digets
				if ($dig == 0 && $array[$i] =~ /[1-9]/){
					$dig = $array[$i];
				}
				# if first char is a zero add to char array
				elsif ($dig == 0 && $array[$i] =~ /0/){
					#push(@char, $array[$i]);
				}
				#if digets have been started, continue
				elsif ($dig != 0 && $array[$i] =~ /\d/){
					$dig .= $array[$i];
				}
				#if digets have been started stop when we hit a char
				elsif ($array[$i] =~ /\D/){
					push(@char, $array[$i]);
					push(@num, $dig);
					$dig=0;
				}
				else{
					die "Error!"
				}
			}
			if ($dig != 0){
				push(@num, $dig);
			}
		}
	}
#	print "$match\n";
#	foreach (@num){print "$_ "};
#	print "\n";
#	foreach (@char){print "$_ "};
#	print "\n";	
		
	my $total = 0;
	my $chartotal = 0;
	my $numtotal=0;
	$total = scalar(@char);
	$chartotal = $total;	
#	print "Muts: $total\n";
	for my $k ( 0 .. $#num){
		$total += $num[$k];
		$numtotal += $num[$k];
	}
	my $max = (sort { $a <=> $b } @num)[-1];
#	print "Max: $num[-1]\n";
#	print "Total: $total\n\n";
#	print "%Mut: ".$chartotal / $total."\n";
#	print "%run: ".$num[-1] / $total."\n";
#	<STDIN>;
	
	if ($total != 0){
		if (($chartotal / $total) > 0.04 && ($max / $total) < 0.33){
			print BOUTFILE $line;#."\tAV:$chartotal:$numtotal:$total\n";
#			print $line;
		}else{
			print GOUTFILE $line;#."\tAV:$chartotal:$numtotal:$total\n";
		}
	}
#	if (($chartotal / $total) > 0.04 && ($max / $total) > 0.33){
#		<STDIN>
#	}

}

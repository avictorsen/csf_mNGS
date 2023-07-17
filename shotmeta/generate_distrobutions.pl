#!/usr/bin/perl
use warnings;
use Statistics::Basic qw(:all);

unless (@ARGV > 0){
        die "not enough";
}
#print "1st: $ARGV[0]\n";

my @INPUT_LIST=`find $ARGV[0] -name Unique_read_count.txt`;
#foreach (@INPUT_LIST){
#	print "$_";
#};<STDIN>;

my %HoA;
#read all Useable_read_count.txt files
for (my $i=0; $i < (scalar @INPUT_LIST); $i++){
	print "\n\n$INPUT_LIST[$i]";
	my $URC="URC-".$i;
	open ($URC, "<$INPUT_LIST[$i]") or die "Cannot open file $INPUT_LIST[$i] $!";
	my $denom=<$URC>;
	chomp $denom;
	close $URC;
	#print "$denom\n";

	#Read final output files to know which organisms to remove
	my $OPF=$INPUT_LIST[$i];
	chomp $OPF;
	$OPF =~ s/\/05_prinseq\/Unique_read_count.txt/.output.txt/;
	$OPF =~ s/\/samples//;
	my $OPFH="OPFH-".$i;

	my @org_skip;
	if (-e $OPF){
		open ($OPFH, "<$OPF") or die "Cannot open file $OPF $!";
		my $read=0;
		while (<$OPFH>){
			chomp;
			if ($_ =~ "Organisms above kingdom threashold,"){
				$read=0;
			}
			if ( $read == 1 ){
				if ($_ eq ""){
					$read=0;
				}else{
					$_ =~ s/^\s+//;
					$_ =~ /(.+):/;
					print "$1\n";
					push (@org_skip, $1);
				}
			}
			if ($_ =~ "Organisms above species specific threashold,"){
				$read=1;
			}
		}
		if (scalar @org_skip == 0){
			print "  Didn't find a positive hit in report file!\n";
		}
	}else{
		print "  Skipping, no report file!\n";
	}
	close $OPFH;

	my $KP=$INPUT_LIST[$i];
	chomp $KP;
	$KP =~ s/05_prinseq\/Unique_read_count.txt/06_kraken\/kraken.good.parsed.report/;
	my $KPFH="KPFH-".$i;

	# check if KP exists
	if (-e $KP){
		open ($KPFH, "<$KP") or die "Cannot open file $KP";
		while (<$KPFH>){
			chomp;
			my @info = split("\t",$_);
			$info[5] =~ s/^\s*//;
			if ($info[3] eq "S"){
				my $found = 0;
				foreach (@org_skip){
					if ($_ eq $info[5]){$found=1;}
				}
				if ($found != 1){
#					if ($info[5] eq "Acinetobacter baumannii"){
#						print "$info[1] / ($denom / 1000)\n";
#						my $x=$info[1] / ($denom / 1000);
#						print "$x\n";<STDIN>;
#					}
					push (@{$HoA{$info[5]}}, $info[1] / ($denom / 1000));
				}
			}
		}
		close $KPFH;
	}else{
		print "  Didn't find a krkaen file!!\n";
	}	
	undef @org_skip;
}

my $k=0;
open (OUT, ">organism.distrobutions.txt") or die "cannot open organism.distrobutions.txt for writting!";
for my $i (keys %HoA){
	my $count = scalar (@{$HoA{$i}});
	my $mean = mean(@{$HoA{$i}});
	my $std = stddev(@{$HoA{$i}});
#	if ($i eq "Acinetobacter baumannii"){printf ("%s\t%i\t%.14e\t%.14e\n",$i,$count,$mean,$std); foreach (@{$HoA{$i}}){print "$_\n";};<STDIN>;};

#	printf OUT ("%s\tn=%i\tmean=%.14e\tstd=%.14e\n",$i,$count,$mean,$std);
	printf OUT ("%s\t%i\t%.14e\t%.14e\n",$i,$count,$mean,$std);


#	foreach (@{$HoA{$i}}){
#		print "  $_\n";
#	}

#	if ($k > 4){exit;}
#	else{$k++};
}

close OUT;

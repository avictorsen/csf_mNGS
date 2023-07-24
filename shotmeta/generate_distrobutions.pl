#!/usr/bin/perl
use warnings;
use Statistics::Basic qw(:all);
use JSON::XS qw(encode_json decode_json);

# this should be executed in shotmeta scripts directory with the first being that of the directory with all the
# previously processed files.  Needs perl v5.28+.

unless (@ARGV > 0){
        die "not enough";
}
#print "1st: $ARGV[0]\n";

if ( -e "RPKR.stddev.thresholds.txt" ){
	print "RPKR.stddev.thresholds.txt already exists! Please rename it before rerunning.\n";
	exit;
}

# compile file list from directory
my @INPUT_LIST=`find $ARGV[0] -name Unique_read_count.txt`;

# Exclude all Zymo Positive samples
for (my $i=0; $i < scalar(@INPUT_LIST); $i++){
	if ($INPUT_LIST[$i] =~ /Positive|Zymo/){
		#print "$INPUT_LIST[$i]\n";
		splice(@INPUT_LIST, $i, 1);
	}		
};

# read previous hash from json file 
my %HoA;
if (-e "RPKR.stddev.values.json"){
	open (PREVIOUS, "<RPKR.stddev.values.json") || die "Cannot open file I just found!";
	my $line=<PREVIOUS>;
	%HoA = %{decode_json($line)};
#	foreach (keys %HoA){
#		print "$_\n";
#		foreach (@{$HoA{$_}}){
#			print "$_ ";
#		}		
#		print "\n\n";
#		<STDIN>;
#	}
}
close PREVIOUS;

my %FCID_hash;
if (-e "RPKR.stddev.FCID.txt"){
	open (ALREADY, "<RPKR.stddev.FCID.txt") || die "Cannot open file previously found!";
	while (<ALREADY>){
		my $key=$_;
		chomp $key;
		$FCID_hash{$key}=1;
	}
}
close ALREADY;

#read all Useable_read_count.txt files,
#trys to open extra_R1.fastq.gz or next Useable_read_count.txt file
#trys to open *output.txt file or next Useable_read_count.txt file
#trys to open kraken file or next Useable_read_count.txt file

for (my $i=0; $i < (scalar @INPUT_LIST); $i++){
	system "sleep 0.25"; # consider changing to Time::HiRes;
	print "\n\n$INPUT_LIST[$i]";
	my $URC="URC-".$i;
	open ($URC, "<$INPUT_LIST[$i]") or die "Cannot open file $INPUT_LIST[$i] $!";
	my $denom=<$URC>;
	chomp $denom;
	close $URC;
	#print "$denom\n";

	#Read md5 of raw reads
	my $RPF=$INPUT_LIST[$i];
	chomp $RPF;
	$RPF =~ s/\/05_prinseq\/Unique_read_count.txt/\/04_BWA\/extra_R1.fastq.gz/;
	my $RPFH="RPFH-".$i;

	my $FCID;
        if (-e $RPF){
                open ($RPFH, "gunzip -c $RPF |") or die "Cannot open file $RPF $!";
                my $read=<$RPFH>;
		chomp $read;
		my @line=split(":",$read);
		$FCID=$line[2].":".$line[9];
		#print "$FCID $read\n";<STDIN>;
		if (exists $FCID_hash{$FCID}){
			print "  Data already exists for this experiment, skipping!\n";
			next;
		}else{
			$FCID_hash{$FCID}=1;
		}
        }else{
              	print "  Skipping, no processed FASTQ file!\n$RPF\n";
		next;
        }
        close $RPFH;

	#Read final output files to know which organisms to remove
	my $OPF=$INPUT_LIST[$i];
	chomp $OPF;
	#$OPF =~ s/\/05_prinseq\/Unique_read_count.txt/.output.txt/;
	$OPF =~ s/\/05_prinseq\/Unique_read_count.txt/.STD.output.txt/;
	$OPF =~ s/\/samples//;
	my $OPFH="OPFH-".$i;

	my @org_skip;
	if (-e $OPF){
		open ($OPFH, "<$OPF") or die "Cannot open file $OPF $!";
		my $read=0;
		while (<$OPFH>){
			chomp;

			# reset reading status if last category.
			if ($_ =~ "rganisms above kingdom threashold,"){ #only trigers if no positive category. 
				$read=0;
			}
			if ( $read == 1 ){
				if ($_ eq ""){
					next;
				}elsif ($_ =~ "rganisms with unknown RPKM"){
					next;
				}elsif ($_ =~ "rganisms above kingdom threshold"){
					$read=0;
				}else{
					$_ =~ s/^\s+//; #remove inital whitespaces
					$_ =~ /(.+):/; #select anything before a colon
					print "  Positive for $1\n";
					push (@org_skip, $1);
				}
			}
			# if category reached 
			#if ($_ =~ "Organisms above species specific threashold,"){ #for original output.txt files
			if ($_ =~ "Organisms with RPKM"){
				$read=1;
			}
		}
		if (scalar @org_skip == 0){
			print "  Didn't find a positive hit in report file!\n";
		}
	}else{
		print "  Skipping, no report file!\n";
		next;
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
		print "  Didn't find a kraken file!!\n";
		next;
	}	
	undef @org_skip;
}

# write %HoA to JSON
my $json = encode_json \%HoA;
open (HASHOUT, ">RPKR.stddev.values.json") or die "Cannot open file to write hash!";
print HASHOUT $json;
close HASHOUT;

my $k=0;
open (OUT, ">RPKR.stddev.thresholds.txt") or die "cannot open organism.distrobutions.txt for writting!";
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

open (FCID_OUT, ">RPKR.stddev.FCID.txt") or die "Cannot open FCID output record!\n";
foreach (keys %FCID_hash){
	print FCID_OUT "$_\n";
}
close FCID_OUT;

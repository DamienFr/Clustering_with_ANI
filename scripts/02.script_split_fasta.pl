use strict;
use warnings;

$#ARGV == 1 ? print "" : die "02.script_split_fasta.pl : Wrong number of arguments ...\n\nUsage: perl 02.script_split_fasta.pl all_fiches.fasta dossier_tmp\noutputs multiple files like title_nucl_splitted\nWe extract all the fasta sequences of a multi-fasta file (first argument) to put them all in separate files in a special folder (path of it is second argument)\n\n";

my $fasta = $ARGV[0];
chomp $fasta;
my $out_folder = $ARGV[1];
chomp $out_folder;

my ($seq, $titre_seq, %h);
my $i = 0;

open (my $fasta_file, "<", $fasta) or die "can't open $!";
while (my $line = <$fasta_file>) {
	$line =~ s/\r?\n//;
	if ($line =~ />/)
	{
	$line =~ s/\s/_/g; #added 7 sep 2016
	$line =~ s/,/_/g; #added 9 sep 2016
	if ($line =~ /\|/) { $line =~ s/\|/./g; print "\n02.script_split_fasta.pl: fasta name containing '|', replacing it by '.' in $line\n"  }
	
	$i ++ ;
	$h{$i} = $line . "\n";
	}
	else
	{
	$h{$i} .= $line;
	};
}

my ($fh, $fasta_out);

if ($fasta =~ /\//){$fasta_out = (split /\//, $fasta)[-1]}else{$fasta_out = $fasta}

foreach my $key (keys %h)
{
print ".";
	my $title = (split /\n/, $h{$key})[0];
	$title =~ s/>//;
	$title =~ s/\//\./g; #in case the title contains "/" we need to replace it because it would be considered as a path
	if (-e $out_folder . "/" . $title . "_" . "nucl_splitted"){print "\nBIG ISSUE : $out_folder" . "/" . $title . "_" . "nucl_splitted file already exists\nIt can mean that you have two sequences with the same name in your multi-fasta file. Fix that and relaunch."; die}
	
	open ($fh, ">", $out_folder . "/" . $title . "_" . "nucl_splitted") or die "can't open $!";
		print $fh $h{$key} . "\n";
	close $fh;
}


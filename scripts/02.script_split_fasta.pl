use strict;
use warnings;

	my $RED="\e[31m";
	my $GREEN="\033[0m";
	my $ORANGE="\e[33m";

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
	$line =~ s/^>//;
	if ($line =~ /[^0-9a-zA-Z]/) {  print "${ORANGE}\n02.script_split_fasta.pl: fasta name containing one or more special characters, replacing it by '.' in $line\n${GREEN}"  }
	$line =~ s/[^0-9a-zA-Z]/./g;
	$line = ">" . $line;
	
	#$line =~ s/\s/./g; #added 7 sep 2016
	
	#if ($line =~ /_/) { $line =~ s/_/./g; print "\n02.script_split_fasta.pl: fasta name containing '_', replacing it by '.' in $line\n"  }
	#if ($line =~ /,/) { $line =~ s/,/./g; print "\n02.script_split_fasta.pl: fasta name containing ',', replacing it by '.' in $line\n"  }
	#if ($line =~ /\|/) { $line =~ s/\|/./g; print "\n02.script_split_fasta.pl: fasta name containing '|', replacing it by '.' in $line\n"  }


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
	if (-e $out_folder . "/" . $title . "_" . "nucl_splitted"){print "${RED}\nBIG ISSUE : $out_folder" . "/" . $title . "_" . "nucl_splitted file already exists\nIt can mean that you have two sequences with the same name in your multi-fasta file. Fix that and relaunch.${GREEN}"; die}
	
	open ($fh, ">", $out_folder . "/" . $title . "_" . "nucl_splitted") or die "${RED}${out_folder}/${title}_nucl_splitted can't be opened :\n $! ${GREEN}";
		print $fh $h{$key} . "\n";
	close $fh;
}


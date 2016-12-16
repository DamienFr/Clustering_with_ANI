#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Long;
use List::Util qw(min);
use Cwd qw(abs_path);

=head1 Name

    Version created by Damien Richard, phd student at Cirad, Reunion island, French territories, 12/08/2016

    Information about original ANI.pl script :
    ANI.pl
    Date: June 23th, 2013
    Contact: kevinchjp@gmail.com
    original script at : https://github.com/chjp/ANI

=head1 Description
    
    This program calculates Average Nucleotide Identity (ANI) based on genomes of a pair of prokaryotes.
    It can however be included in a pipeline to work on more than two sequences, processing them pair by pair.
	Note:the ani score is the sum of the pcent of identity (of matches longer than $cvg_cut %) divided by the number of matches. It means that a contig with genes A,B,C,D will have high score with a contig containing only gene A.

=head1 Usage
    
    perl ANI.pl --fd formatdb --bl blastall --qr one_strain_genome --sb the_other_strain_genome --od output_directory --help (optional) --id 95 --length 95 [--seg_length 1020]

    Arguments explained
    bl: Directory of blastall excecutable file
    fd: Directory of BLAST makeblastdb excecutable file
    qr: Query strain genome sequence in FASTA format
    sb: Subject strain genome sequence in FASTA format
    od: output directory
    id: minimum % identity of two fragments
    length: minimum matching % of the length of two fragments 
    seg_length: length of fragments (defaut 1020 nucleotids)
    help: print this help information

=head1 Example

    perl ANI.pl -bl ./blast-2.2.23/bin/blastall -fd makeblastdb -qr strain1.fa -sb strain2.fa -od result --id 95 --length 95

=cut


my ($qr,$sb,$od,$fd,$bl,$id_cut,$cvg_cut,$hl);
GetOptions(
	"qr=s" => \$qr,
	"sb=s" => \$sb,
	"od=s" => \$od,
	"fd=s" => \$fd,
	"bl=s" => \$bl,
	"id=s" => \$id_cut,
	"length=s" => \$cvg_cut,
	"seg_length=s" => \(my $chop_len = 1020),
	"help" => \$hl
  );
die `pod2text $0` unless $qr && $sb && $od && $fd && $bl && $id_cut && $cvg_cut ;
die `pod2text $0` if $hl;

	my $RED="\e[31m";
	my $GREEN="\033[0m";
	my $ORANGE="\e[33m";

if($chop_len < 20 ){print "\n${RED}You shouldn't use a segment length inferior to 20bp, it's already very small, knowing defaut blast word size is 11 ... I'll die now ... relaunch me ;) \n ${GREEN}"; die}


$qr=abs_path($qr);
$sb=abs_path($sb);
my $tmp = "./temporary_ANI_folder";
unless(-d $tmp){`mkdir $tmp`;}

#Split query genome and write segments in $tmp/Query.split
$/ = "\n>"; #this is a nice way to read in fasta files that can be multiline fasta
open (my $fasta_file,"<", $qr ) or die "${RED}$qr can't be opened :\n $! ${GREEN}";
open (my $fasta_splitted ,">", "$tmp/Query.split") or die "${RED}${tmp}/Query.split can't be opened :\n $! ${GREEN}";
my $number_parts = 0;
while(<$fasta_file>){
	chomp;
	s/>//g;
	my ($scaf,$seq) = split /\n/,$_,2;
	my $scaf_name = (split /\s+/,$scaf)[0];
	$seq =~ s/\s+//g;
	my @cut = ($seq =~ /(.{1,$chop_len})/g);
	$number_parts = $#cut + 1;
		if($number_parts < 10){ my $seq_name = (split /\//, $qr)[-1] ; print "\n${ORANGE}Warning: Sequence $seq_name only cut into $number_parts segments, which will make the analysis not very sensitive. You should decrease segment length${GREEN}\n"}
	for my $cut_num (0..$#cut){
		#next if length($cut[$cut_num]) < 100;
		next if length($cut[$cut_num]) < (0.1*$chop_len); #i prefer to ignore a segment if its size is inferior to 10% of the selected fragment length than to specify a fixed value, it's smarter.
		my $sgmID = "$scaf_name\_$cut_num";
		print $fasta_splitted ">$sgmID\n$cut[$cut_num]\n";
	}
}

$/ = "\n";

## BLAST alingment

#print "Creating symlink for subject fasta...\n";
`ln -sf "${sb}" $tmp/Subject.fa`;
#print "Formating Database of the query ...\n";
#`$fd -i $tmp/Subject.fa -p F`;
`$fd -in $tmp/Subject.fa -dbtype nucl `;
#print "Blasting subject against query Database...\n";
`$bl -query $tmp/Query.split -task blastn -db $tmp/Subject.fa -out $tmp/raw.blast -penalty -2 -reward 1 -gapopen 2 -gapextend 2 -outfmt '10 std qlen gaps qseq sseq'`;

my ($ANI,%qr_best); my $count = my $sumID = 0;

open (my $blast_result, "<", "$tmp/raw.blast") or die "${RED}${tmp}/raw.blast can't be opened :\n $! ${GREEN}";
while(<$blast_result>){
	chomp;
	my @t = split /,/;
	next if exists $qr_best{$t[0]}; $qr_best{$t[0]} = 1; #only use best hit for every query segments, as they are ordered by goodness the first one is the best
	next if $t[2]<=$id_cut;
	next if ($t[3]*100/$chop_len) < $cvg_cut;
	$sumID += $t[2];
	$count++;
}

if ($count == 0){$ANI = 0}else{$ANI = $sumID/$count}

my ($qr2, $sb2);

if ($qr =~ /\//){$qr2 = (split /\//, $qr)[-1]}else{$qr2 = $qr}
if ($sb =~ /\//){$sb2 = (split /\//, $sb)[-1]}else{$sb2 = $sb}


open (my $out, ">>", $od . "result_ANI" . ".$id_cut" . ".$cvg_cut" ) or die "${RED}${od}result_ANI.${id_cut}.${cvg_cut} can't be opened :\n $! ${GREEN}";
if($ANI != 0){
	print $out "$qr2\t$sb2\tANI:\t$ANI\tseq_cut_into:\t$number_parts\tmatching_parts:\t$count\n";
}

#print "End of script ... if i'm part of a pipeline, i'll run square times the nb of sequences\n";

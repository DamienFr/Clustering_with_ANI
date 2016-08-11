#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Long;
use List::Util qw(min);
use Cwd qw(abs_path);

=head1 Name

    ANI.pl
    Date: June 23th, 2013
    Contact: kevinchjp@gmail.com
    original script at : https://github.com/chjp/ANI

=head1 Description
    
    This program calculates Average Nucleotide Identity (ANI) based on genomes of a pair of prokaryotes.
	Note:the ani score is the sum of the pcent of identity (of matches longer than $cvg_cut %) divided by the number of matches. It means that contig with gene A,B,C,D will have high score with contig containing gene A.

=head1 Usage
    
    perl ANI.pl --fd formatdb --bl blastall --qr one_strain_genome --sb the_other_strain_genome --od output_directory --help (optional) --id 95 --length 95 [--seg_length 1020]

    Arguments explained
    bl: Directory of blastall excecutable file
    fd: Directory of BLAST formatdb excecutable file
    qr: Query strain genome sequence in FASTA format
    sb: Subject strain genome sequence in FASTA format
    od: output directory
    id: minimum % identity of two fragments
    length: minimum matching % of the length of two fragments 
    seg_length: length of fragments (defaut 1020 nucleotids)
    help: print this help information

=head1 Example

    perl ANI.pl -bl ./blast-2.2.23/bin/blastall -fd ./blast-2.2.23/bin/formatdb -qr strain1.fa -sb strain2.fa -od result --id 95 --length 95

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

if($chop_len < 200 ){print "\n\nYou shouldn't use a segment length inferior to 200bp, because noise introduced by small matches will affect more your results. In any cases this script does not treat matches inferior to 100b for the same reason.\nI'll die now ... relaunch me ;) \n\n"; die}


$qr=abs_path($qr);
$sb=abs_path($sb);
unless(-d $od){`mkdir $od`;}

#Split query genome and write segments in $od/Query.split
#my $chop_len = 1020;
$/ = "\n>";
open QR,$qr or die "$qr $!\n";
open CR,">$od/Query.split";
my $number_parts = 0;
while(<QR>){
	chomp;
	s/>//g;
	my ($scaf,$seq) = split /\n/,$_,2;
	my $scaf_name = (split /\s+/,$scaf)[0];
	$seq =~ s/\s+//g;
	my @cut = ($seq =~ /(.{1,$chop_len})/g);
	$number_parts = $#cut + 1;
	for my $cut_num (0..$#cut){
		next if length($cut[$cut_num]) < 100;
		my $sgmID = "$scaf_name\_$cut_num";
		print CR ">$sgmID\n$cut[$cut_num]\n";
	}
}
close QR;close CR;
$/ = "\n";

#BLAST alingment
`ln -sf $sb $od/Subject.fa`;
`$fd -i $od/Subject.fa -p F`;

`$bl -query $od/Query.split -task blastn -db $od/Subject.fa -out $od/raw.blast -penalty -2 -reward 1 -gapopen 2 -gapextend 2 -outfmt '10 std qlen gaps qseq sseq'`;

my ($ANI,%qr_best);
my $count = 0;
my $sumID = 0;
open BL,"$od/raw.blast" or die "raw.blast $!\n";
while(<BL>){
	chomp;
	my @t = split /,/;
	next if exists $qr_best{$t[0]}; $qr_best{$t[0]} = 1; #only use best hit for every query segments
	next if $t[2]<=$id_cut;
	next if ($t[3]*100/$chop_len) < $cvg_cut;
	$sumID += $t[2];
	$count++;
}
close BL;
if ($count == 0){$ANI = 0}else{$ANI = $sumID/$count}

my $qr2;
my $sb2;

if ($qr =~ /\//){$qr2 = (split /\//, $qr)[-1]}else{$qr2 = $qr}
if ($sb =~ /\//){$sb2 = (split /\//, $sb)[-1]}else{$sb2 = $sb}


open (OUT, ">>", "result_ANI" . ".$id_cut" . ".$cvg_cut" ) or die "can't open $!";

if($ANI != 0){
	print OUT "$qr2\t$sb2\tANI:\t$ANI\tseq_cut_into:\t$number_parts\tmatching_parts:\t$count\n";
}

close OUT;

print "End of script ... i'll run square times the nb of sequences\n";


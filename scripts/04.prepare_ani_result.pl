#!/usr/bin/perl
use strict;
use warnings;

print "\n#####################\n04.prepare_ani_result.pl running ...\n#####################\n";

$#ARGV == 1 ? print "Good argument number was given, it's okay ...\n" : die "Wrong number of arguments given to 04.prepare_ani_result.pl ...\n\nUsage: perl ./scripts/04.prepare_ani_result.pl  size_of_all_fiches result_ANI.\${identity_p_cent}.\${length_p_cent}\nExtracts the best results from the ANI result file (second argument), using size of all sequences (first argument)\n\nOutputs bestresult_ANI.\${identity_p_cent}.\${length_p_cent} that is automatically used and then deleted in the pipeline version\n";

my $sizefile = $ARGV[0];
chomp $sizefile;
my $ani = $ARGV[1];
chomp $ani;

#size_of_all_fiches
open (my $size_file, "<", $sizefile) or die "erreur 1 can't open $!";
my (%h_size, $tmp);
while (my $li2 = <$size_file>){
	$li2 =~ s/\r?\n//g;
	if($li2 =~ /^>/) {$li2 =~ s/>//;$tmp = $li2} else {$h_size{$tmp} = $li2; $tmp=""} # %h_size contains all the sizes of the sequences
}

open (my $ani_file, "<", $ani) or die "erreur 2 can't open $!";
my %h;
while (my $li = <$ani_file>)
{
	$li =~ s/\r?\n//g;
	
	my @field2 = split /\t/ , $li;  #added 21/06/2016
	if($field2[0] ne $field2[1]) #added 21/06/2016
	{  #added 21/06/2016
		my @field = split /_/ , $li;
		my $tmp2 = (split /\s/,$field[2])[1]; # cette ligne a été modifiee pour la version network xanthomonadaceae
		#			my $tmp2 = (split /\t/,$field[3])[1];  #version xanthomonadaceae
		$h{$li} = $h_size{$tmp2};
	}   				#added 21/06/2016
}


my (%h2, %h3);
foreach my $kei (sort { $h{$b} <=> $h{$a} } keys %h) #inside this hash we are working with the numericaly sorted values of the hash (stored in $kei variable)
{
	my @FI = split /\t/, $kei;
	if(!exists $h2{$FI[0]} || $h2{$FI[0]} < $FI[-1])  #we filter the best results in order to keep them ONLY
	{
		$h2{$FI[0]} = $FI[-1];
		$h3{$FI[0]} = $kei;
	}
}

$ani =~ s/([^\.]*)\.\/(.*)/$1$2/;
my $folderr = $ani; $folderr =~ s/([^\/]*)\/(.*)/$1/;
$ani =~ s/([^\/]*)\/(.*)/$2/;
my $output_best_ani = $folderr . "/best" . $ani ;
#print "\n\n\nvoici le chemin non créé\n$output_best_ani\n\n\n";
# best./results_ANI_2016-12-15:19:33:54/result_ANI.90.90

if (-e $output_best_ani){unlink $output_best_ani; print "Previous output $output_best_ani removed\n"}
open (my $out, ">", $output_best_ani) or die "erreur 3 can't open $!";

# %h3 contains only ther best results
foreach my $key3 (keys %h3){  #we print the best results in the output file
	print $out "$h3{$key3}\n";
}

print "\nEnd of 04.prepare_ani_result.pl\n";




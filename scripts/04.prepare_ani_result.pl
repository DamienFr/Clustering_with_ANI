#!/usr/bin/perl
use strict;
use warnings;

print "Usage: perl 04.prepare_ani_result.pl  size_of_all_fiches95 result_ANI.95.95\noutputs bestresult_ANI.95.953\n";
print "extracts the best results from the ANI result file (second argument), using size of all sequences (first argument)\n\n";

$#ARGV == 1 ? print "Good argument number was given, it's okay ...\n" : die "Wrong number of arguments ...\n\n";

my $sizefile = $ARGV[0];
chomp $sizefile;

my $ani = $ARGV[1];
chomp $ani;

#size_of_all_fiches
open (SIZE, "<", $sizefile) or die "can't open $!";
my (%h_size, $tmp);
while (my $li2 = <SIZE>){
	$li2 =~ s/\r?\n//g;
	if($li2 =~ /^>/) {$li2 =~ s/>//;$tmp = $li2} else {$h_size{$tmp} = $li2; $tmp=""} # %h_size contains all the sizes of the sequences
}
close SIZE;

open (ANI, "<", $ani) or die "can't open $!";
my %h;
while (my $li = <ANI>)
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
close ANI;

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


my $output_best_ani = "best" . $ani . "3" ;
if (-e $output_best_ani){unlink $output_best_ani; print "Previous output $output_best_ani removed\n"}
open (ANI2, ">", $output_best_ani) or die "can't open $!";

# %h3 contains only ther best results
foreach my $key3 (keys %h3){  #we print the best results in the output file
	print ANI2 "$h3{$key3}\n";
}
close ANI2;






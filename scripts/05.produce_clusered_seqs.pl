#!/usr/bin/perl
use strict;
use warnings;

print "Usage: perl 05.produce_clusered_seqs.pl all_fiches.fastaseq95 bestresult_ANI.95.953\n\nThis script outputs bestresult_ANI.95.953.out2 and bestresult_ANI.95.953.out\n\n";
print "\t\tbestresult_ANI.95.953.out2 looks like\n";
print "\t\t922913515_872691482_876089902_\n\n";
print "\t\tbestresult_ANI.95.953.out is a multi-fasta file, it looks like\n";
print ">922913515_nucl_splitted	872691482_nucl_splitted	876089902_nucl_splitted\nATGTCTGCTCGTTACACGAGTGTGCAGCTGTCTACG\n\n";

print "From the intput multi-fasta (first argument) and the ANI result file (second argument), this script outputs the corresponding clusters\nThe hard part is to create the clusters from the ANi result file that contains pair by pair comparisons of the sequences.\nto obtain a log file (bestresult_ANI.95.953.log giving the content of the hashes used in the script in order to check if the output files are okay (because they rely on the fasta file content, not the hash content that is made from the ani file)), you just have to add a third argument to the script, no matters what it is.)\n\n";

$#ARGV >= 1 ? print "Good argument number was given, it's okay ...\n" : die "Wrong number of arguments ...\n\n";

my $fasta = $ARGV[0];
chomp $fasta;
my $ani = $ARGV[1];
chomp $ani;

my $log_mode = 0;
if($#ARGV == 2){ $log_mode = 1}

my $fasta_out;
if ($fasta =~ /\//){$fasta_out = (split /\//, $fasta)[-1]}else{$fasta_out = $fasta}

open (ANI, "<", $ani) or die "can't open $!";

my (%h_assigne__a_qui, %h_seq_prt__arr_seq_enfant);

while (my $li = <ANI>){
	$li =~ s/\r?\n//g;
	my @field = split /\t/, $li;
	my $parent = $field[1];
	my $enfant = $field[0];
	my $p0 = 0;
	my $p1 = 0;
	my $p2 = 0;

		if((($field[7])  ) >= ($field[5] - 2 ) && $parent ne $enfant && !exists $h_assigne__a_qui{$enfant}  && ( !exists $h_assigne__a_qui{$parent}  || ( exists $h_assigne__a_qui{$parent} && $h_assigne__a_qui{$parent} ne $enfant     )                          ) )   # we authorize 2 segments not matching to allow start and end different positions for the two seqs
	# la dernière condition vérifie que le test exactement inverse de celui effectué là n'ait pas déja été fait et retourné positif
	{

		if(exists $h_seq_prt__arr_seq_enfant{$enfant} && exists $h_assigne__a_qui{$parent}) # cas particulier où "parent déjà enfant" ET "enfant déjà parent"
		{
			$p0 = 1;
			print "\nParticular case where two exceptions are true at the same time ...... @field\n";
			
			print "Tested child is $enfant\n";
			print "It was already parent of @{$h_seq_prt__arr_seq_enfant{$enfant}}\n--\n";
			
			print "Tested parent is $parent\n";
			print "It was already child of $h_assigne__a_qui{$parent}\n--\n";
			print "To resolve this conflict, the two sequences tested here ($enfant and $parent) are now child of $h_assigne__a_qui{$parent} \n This might appear differently in the result file because $h_assigne__a_qui{$parent} can still be re-assigned as a child\n";
			
			#il faut transférer tous les enfants de l'enfant au parent du parent
			# pour cela il faut découper les taches à effectuer :

			#le parent du parent va accumuler les enfants de l'enfant
			for my $i (0 .. $#{$h_seq_prt__arr_seq_enfant{$enfant}})
			{ push @{$h_seq_prt__arr_seq_enfant{$h_assigne__a_qui{$parent}}}, ${$h_seq_prt__arr_seq_enfant{$enfant}}[$i] ;

				#mais également modifier l'assignation des enfants des enfants au parent du parent
				$h_assigne__a_qui{${$h_seq_prt__arr_seq_enfant{$enfant}}[$i]} = $h_assigne__a_qui{$parent};}

			#on doit aussi après coup supprimer le hash de l'enfant qui n'est plus parent
			undef @{$h_seq_prt__arr_seq_enfant{$enfant}}; #ou delete $h_seq_prt__arr_seq_enfant{$enfant}  #ou les deux !!
			delete $h_seq_prt__arr_seq_enfant{$enfant};

			#l'enfant qui n'est plus parent doit devenir l'enfant du parent du parent
			push @{$h_seq_prt__arr_seq_enfant{$h_assigne__a_qui{$parent}}}, $enfant;

			$h_assigne__a_qui{$enfant} = $h_assigne__a_qui{$parent} ;

		}
		else
		{

			if (exists $h_seq_prt__arr_seq_enfant{$enfant} ) # si la séquence travaillée EST le parent de someone ! #1
			{
				$p2 = 1;

				#notre $parent va devenir le parent de tout le monde de $enfant (qui est parent)
				#@{$h_seq_prt__arr_seq_enfant{$parent}} = @{$h_seq_prt__arr_seq_enfant{$enfant}};
				#plus on l'update
				push @{$h_seq_prt__arr_seq_enfant{$parent}}, $enfant;

				#on doit changer les assigné_a_qui de tous les enfants ....
				for my $i (0 .. $#{$h_seq_prt__arr_seq_enfant{$enfant}})
				{ push @{$h_seq_prt__arr_seq_enfant{$parent}}, ${$h_seq_prt__arr_seq_enfant{$enfant}}[$i] ;
					$h_assigne__a_qui{${$h_seq_prt__arr_seq_enfant{$enfant}}[$i]} = $parent;}

				#on doit aussi après coup supprimer le hash du parent
				undef @{$h_seq_prt__arr_seq_enfant{$enfant}}; #ou delete $h_seq_prt__arr_seq_enfant{$enfant}  #ou les deux !!
				delete $h_seq_prt__arr_seq_enfant{$enfant};
				$h_assigne__a_qui{$enfant} = $parent ;
			}

			if (exists $h_assigne__a_qui{$parent}) #checks if the PARENT sequence is already assigned to "someone"  #2
			{
				$p1 = 1;

				#si c'est le cas on sait à qui elle est assignée par la valeur du hash
				#on assigne notre seq enfant au même parent
				$h_assigne__a_qui{$enfant} = $h_assigne__a_qui{$parent};

				# il faut aussi updaté l'array du hash parent
				push @{$h_seq_prt__arr_seq_enfant{$h_assigne__a_qui{$parent}}}, $enfant;
			}

			if (!$p1 && !$p2){
				$h_assigne__a_qui{$enfant} = $parent;
				push @{$h_seq_prt__arr_seq_enfant{$parent}}, $enfant;
			}
		}
	}

	#if ($p0){print "Particular case where two exceptions are true at the same time ...... @field\n\n"}
}

close ANI;

#je vais ouvrir le fichier fasta pour regarder sur toutes les lignes si la séquence est à garder ou non

open (FAS, "<", $fasta ) or die "can't open $!";
open (OUT, ">", $fasta . "_clust_and_seqs.fasta") or die "can't open $!";
open (OUT2, ">", $fasta . "_clust_names_alone.txt") or die "can't open $!";


my $k = 0;

while (my $fli = <FAS>){
	$fli =~ s/\r?\n//g;

	if($fli =~ /^>/)
	{
		$fli =~ s/>//;
		$fli = $fli . "_nucl_splitted";
		#print $fli . "\n";
		if( exists $h_seq_prt__arr_seq_enfant{$fli})
			{
			#if we are in here it means the studied seq is the parent of someone
			my $to_print = ">" . $fli . join("_",@{$h_seq_prt__arr_seq_enfant{$fli}}) . "\n";
			$to_print =~ s/_nucl_splitted/_/g;
			$to_print =~ s/__/_/g;
			print OUT $to_print;
			print OUT2 $to_print;
			$k = 1;}
		else
		{ #if we are in here it means the studied seq is NOT PARENT
			if(!exists $h_assigne__a_qui{$fli})
				{
				#studied seq is not child of anybody, therefore we need to print it's sequence (it's the only seq in this cluster)
				my $toprint2 = ">" . $fli . "\n";
				$toprint2 =~ s/_nucl_splitted/_/g;
				$toprint2 =~ s/__/_/g;
				print OUT $toprint2 ;
				print OUT2 $toprint2 ;
				$k = 1;}
			else
				{print "."} #studied seq IS CHILD OF SOMEONE, therefore its seq has been printed in the cluster seq it belongs to 
		}
	}
	else
	{
		if ($k)
			{print OUT $fli . "\n";
			$k = 0;}
	}

}
close FAS;
close OUT;
close OUT2;

if($log_mode)
{
open (LOG2, ">", $ani . "log") or die "can't open $!";
foreach my $key (keys %h_seq_prt__arr_seq_enfant){
	print LOG2 $key . "\t";
	foreach my $j (0 .. $#{$h_seq_prt__arr_seq_enfant{$key}})
	{print LOG2 ${$h_seq_prt__arr_seq_enfant{$key}}[$j] . "\t";}
	print LOG2 "\n";
	#print "$#{$h{$key}}____matches____$key : @{$h{$key}}\n" ;
}
close LOG2;
}

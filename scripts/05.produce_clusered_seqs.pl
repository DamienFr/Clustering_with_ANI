#!/usr/bin/perl
use strict;
use warnings;

print "\n#####################\n05.produce_clusered_seqs.pl running ...\n#####################\n";

if ($#ARGV >= 1) { print "Good argument number was given, it's okay ...\n"}else{
print "Wrong number of arguments ...\n\nUsage: perl 05.produce_clusered_seqs.pl all_fiches.fasta bestresult_ANI.\${identity_p_cent}.\${length_p_cent}\n\nThis script outputs bestresult_ANI.\${identity_p_cent}.\${length_p_cent}.out2 and bestresult_ANI.\${identity_p_cent}.\${length_p_cent}.out\n\n";
print "\t\tbestresult_ANI.\${identity_p_cent}.\${length_p_cent}.out2 looks like\n";
print "\t\t922913515_872691482_876089902_\n\n";
print "\t\tbestresult_ANI.\${identity_p_cent}.\${length_p_cent}.out is a multi-fasta file, it looks like\n";
print "\t\t>922913515_nucl_splitted	872691482_nucl_splitted	876089902_nucl_splitted\n\t\tATGTCTGCTCGTTACACGAGTGTGCAGCTGTCTACG\n\n";
print "From the intput multi-fasta (first argument) and the ANI result file (second argument), this script outputs the corresponding clusters\nThe hard part is to create the clusters from the ANi result file that contains pair by pair comparisons of the sequences.\nto obtain a log file (bestresult_ANI.95.953.log giving the content of the hashes used in the script in order to check if the output files are okay (because they rely on the fasta file content, not the hash content that is made from the ani file)), you just have to add a third argument to the script, no matters what it is.)\n\n";
die;}


my $fasta = $ARGV[0];
chomp $fasta;
my $ani = $ARGV[1];
chomp $ani;

my $log_mode = 0;
if($#ARGV == 2){ $log_mode = 1}



##################################################################################################################################################################################
#########  In this script, variable names are COMPLICATED, therefore i'll explain it here. #######################################################################################
##################################################################################################################################################################################
######### When we cluster sequences, one sequence can be included in another one, larger.
######### The sequence that had been included is considered as the "child" of the larger "parent" sequence
######### 
######### In variable names, i reffer to :
######### ch = child
######### prt = parent
######### val = value
######### key = a perl hash is structured this way : $h{$key} = $value 
######### We can use an array instead of $value
#########
######### Knowing this, we define TWO HASHES
#########
######### %key_ch_of_val gives the parent of each child sequence : $h{$child} = $parent
######### %key_prt_of_arr_val gives, for each parent ($key) the array of its children ($values) : $h{$parent} = @($child1, $child2, $child3 ...) #################################
##################################################################################################################################################################################


my (%key_ch_of_val, %key_prt_of_arr_val, $fasta_out);
if ($fasta =~ /\//){$fasta_out = (split /\//, $fasta)[-1]}else{$fasta_out = $fasta}

open (my $input_ani, "<", $ani) or die "can't open $!";
while (my $li = <$input_ani>){
	$li =~ s/\r?\n//g;
	my @field = split /\t/, $li;
	my $parent = $field[1];
	my $child = $field[0];
	my $p0 = my $p1 = my $p2 = 0;

		if((($field[7])  ) >= ($field[5] - 2 ) && $parent ne $child && !exists  $key_ch_of_val{$child}  && ( !exists  $key_ch_of_val{$parent}  || ( exists  $key_ch_of_val{$parent} &&  $key_ch_of_val{$parent} ne $child     )                          ) )   # we authorize 2 segments not matching to allow start and end different positions for the two seqs
	# la dernière condition vérifie que le test exactement inverse de celui effectué là n'ait pas déja été fait et retourné positif
	{

		if(exists $key_prt_of_arr_val{$child} && exists  $key_ch_of_val{$parent}) # cas particulier où "parent déjà enfant" ET "enfant déjà parent"
		{
			$p0 = 1;
			print "\nParticular case where two exceptions are true at the same time ...... @field\n";
			
			print "Tested child is $child\n";
			print "It was already parent of @{$key_prt_of_arr_val{$child}}\n--\n";
			
			print "Tested parent is $parent\n";
			print "It was already child of  $key_ch_of_val{$parent}\n--\n";
			print "To resolve this conflict, the two sequences tested here ($child and $parent) are now child of  $key_ch_of_val{$parent} \n This might appear differently in the result file because  $key_ch_of_val{$parent} can still be re-assigned as a child\n";
			
			#il faut transférer tous les enfants de l'enfant au parent du parent
			# pour cela il faut découper les taches à effectuer :

			#le parent du parent va accumuler les enfants de l'enfant
			for my $i (0 .. $#{$key_prt_of_arr_val{$child}})
			{ push @{$key_prt_of_arr_val{$key_ch_of_val{$parent}}}, ${$key_prt_of_arr_val{$child}}[$i] ;

				#mais également modifier l'assignation des enfants des enfants au parent du parent
				 $key_ch_of_val{${$key_prt_of_arr_val{$child}}[$i]} =  $key_ch_of_val{$parent};}

			#on doit aussi après coup supprimer le hash de l'enfant qui n'est plus parent
			undef @{$key_prt_of_arr_val{$child}}; #ou delete $key_prt_of_arr_val{$child}  #ou les deux !!
			delete $key_prt_of_arr_val{$child};

			#l'enfant qui n'est plus parent doit devenir l'enfant du parent du parent
			push @{$key_prt_of_arr_val{$key_ch_of_val{$parent}}}, $child;

			 $key_ch_of_val{$child} =  $key_ch_of_val{$parent} ;

		}
		else
		{

			if (exists $key_prt_of_arr_val{$child} ) # si la séquence travaillée EST le parent de someone ! #1
			{
				$p2 = 1;

				#notre $parent va devenir le parent de tout le monde de $child (qui est parent)
				#@{$key_prt_of_arr_val{$parent}} = @{$key_prt_of_arr_val{$child}};
				#plus on l'update
				push @{$key_prt_of_arr_val{$parent}}, $child;

				#on doit changer les assigné_a_qui de tous les enfants ....
				for my $i (0 .. $#{$key_prt_of_arr_val{$child}})
				{ push @{$key_prt_of_arr_val{$parent}}, ${$key_prt_of_arr_val{$child}}[$i] ;
					 $key_ch_of_val{${$key_prt_of_arr_val{$child}}[$i]} = $parent;}

				#on doit aussi après coup supprimer le hash du parent
				undef @{$key_prt_of_arr_val{$child}}; #ou delete $key_prt_of_arr_val{$child}  #ou les deux !!
				delete $key_prt_of_arr_val{$child};
				 $key_ch_of_val{$child} = $parent ;
			}

			if (exists  $key_ch_of_val{$parent}) #checks if the PARENT sequence is already assigned to "someone"  #2
			{
				$p1 = 1;

				#si c'est le cas on sait à qui elle est assignée par la valeur du hash
				#on assigne notre seq enfant au même parent
				 $key_ch_of_val{$child} =  $key_ch_of_val{$parent};

				# il faut aussi updaté l'array du hash parent
				push @{$key_prt_of_arr_val{$key_ch_of_val{$parent}}}, $child;
			}

			if (!$p1 && !$p2){
				 $key_ch_of_val{$child} = $parent;
				push @{$key_prt_of_arr_val{$parent}}, $child;
			}
		}
	}

	#if ($p0){print "Particular case where two exceptions are true at the same time ...... @field\n\n"}
}


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
		if( exists $key_prt_of_arr_val{$fli})
			{
			#if we are in here it means the studied seq is the parent of someone
			my $to_print = ">" . $fli . join("_",@{$key_prt_of_arr_val{$fli}}) . "\n";
			$to_print =~ s/_nucl_splitted/_/g;
			$to_print =~ s/__/_/g;
			print OUT $to_print;
			print OUT2 $to_print;
			$k = 1;}
		else
		{ #if we are in here it means the studied seq is NOT PARENT
			if(!exists $key_ch_of_val{$fli})
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
open (LOG, ">", $ani . "log") or die "can't open $!";
foreach my $key (keys %key_prt_of_arr_val){
	print LOG $key . "\t";
	foreach my $j (0 .. $#{$key_prt_of_arr_val{$key}})
	{print LOG ${$key_prt_of_arr_val{$key}}[$j] . "\t";}
	print LOG "\n";
	#print "$#{$h{$key}}____matches____$key : @{$h{$key}}\n" ;
}
close LOG;
}


print "\n#####################\nEnd of 05.produce_clusered_seqs.pl\n#####################\n";


#!/bin/bash

################################################################
################# PARAMETERS TO MODIFY  ########################
################################################################

fasta_file=path-to-your-file # Indicate the path leading to your multi-fasta file,  example: fasta_file=/home/user/filtration/sequence.fasta
identity_p_cent=70
length_p_cent=70
seg_length_ANI=1020 # this should be decreased (not under 200bp) if you are working with short sequences. With this defaut parameter, sequences should not be smaller than 10 000 nucleotides

################################################################
################# END OF PARAMETERS SECTION ####################
################################################################






mkdir 01.fasta_to_analyse #this temporary folder will contain the splitted fasta files

# We extract all the fasta sequences of a multi-fasta file (first argument) to put them all in separate files in a special folder (path of it is second argument)
perl ./scripts/02.script_split_fasta.pl ${fasta_file} 01.fasta_to_analyse #outputs multiple files like "title_nucl_splitted"


mkdir results
for files in 01.fasta_to_analyse/*splitted*
do
	for ffiles in 01.fasta_to_analyse/*splitted*
	do 
	perl ./scripts/03.ANI.pl --fd formatdb --bl blastn --qr $files --sb $ffiles --od ./results --id ${identity_p_cent} --length ${length_p_cent} --seg_length ${seg_length_ANI}
	done
done

rm -rf results
rm -f formatdb.log

# Pour étudier les résultats de l'ANI il faut classer les séquences parent par taille
# je récupère la taille de toutes les séquences
perl -ne 'if (/^>/){print}else{print length() . "\n"}' 01.fasta_to_analyse/*splitted* >> size_of_all_fiches

rm -rf 01.fasta_to_analyse

#04.prepare_ani_result.pl extracts the best results from the ANI result file, using size of all sequences 
perl ./scripts/04.prepare_ani_result.pl  size_of_all_fiches result_ANI.${identity_p_cent}.${length_p_cent} #directly outputs "bestresult_ANI.${stringence}.${stringence}3"
#From the intput multi-fasta (first argument) and the ANI result file (second argument), this script outputs the corresponding clusters\nThe hard part is to create the clusters from the ANi result file that contains pair by pair comparisons of the sequences
perl ./scripts/05.produce_clusered_seqs.pl ${fasta_file} bestresult_ANI.${identity_p_cent}.${length_p_cent}3 #outputs bestresult_ANI.95.953.out2 and bestresult_ANI.95.953.out and bestresult_ANI.95.953.log if thrid argument provided

rm -f bestresult_ANI.${identity_p_cent}.${length_p_cent}3
rm -f result_ANI.${identity_p_cent}.${length_p_cent}
rm -f size_of_all_fiches






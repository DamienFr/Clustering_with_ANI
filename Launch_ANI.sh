#!/bin/bash


usage() { printf "\nUsage: $0 -f fasta_file [-i 90] [-l 90] [-s 1020] [-k] [-h]
[] means argument is optional
\navailable arguments:
\n\t-f\tinput file, fasta format
\t-i\tpercentage of identical bases between two DNA fragments to consider them identical. Default 90%%
\t-l\tidentity of two DNA fragments must cover at least this percentage of the longest fragment to consider them identical. Default 90%%
\t-s\tsegment length. Must be shorter than the shorter studied sequence. Should be < 10%% of the shorter sequence's length for best accuracy, but shouldn't be < 200
\t-k\tactivate log mode. Keep the two subfolders created for the analysis instead of removing them 
\t-h\tdisplay this help\n" 1>&2; exit 1; }

log_mode=false

while getopts f:i:l:s:kh? opts; do
   case ${opts} in
      f) input=${OPTARG} ;;
      i) identity_p_cent=${OPTARG} ;;
      l) length_p_cent=${OPTARG} ;;
      s) seg_length_ANI=${OPTARG} ;;
      k) log_mode=true ;;
      h|\?) usage;  exit 0 ;;
   esac
done

[ -z "$input" ]  &&  usage
[ -z "$identity_p_cent" ]  && identity_p_cent=90  && echo "-i (% identity) not specified, using default value 90" 
[ -z "$length_p_cent" ]  &&  length_p_cent=90  && echo "-l (% length) not specified, using default value 90" 
[ -z "$seg_length_ANI" ]  && seg_length_ANI=1020 && echo "-s (fragment length) not specified, using default value 1020. Seqs should not be < 10 000 nucleotides"



fasta_file=$(basename $input) # Indicate the path leading to your multi-fasta file,  example: fasta_file=/home/user/filtration/sequence.fasta
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
FASTAPATH="$( cd "$(dirname "$input")" ; pwd -P )"

cd $FASTAPATH

DATE=`date +%Y-%m-%d:%H:%M:%S`

mkdir ./01.fasta_to_analyse_${DATE} #this temporary folder will contain the splitted fasta files
mkdir results_ANI_${DATE}

printf "\n#####################\n02.script_split_fasta.pl running ...\n#####################\n";
# We extract all the fasta sequences of a multi-fasta file (first argument) to put them all in separate files in a special folder (path of it is second argument)
perl ${SCRIPTPATH}/scripts/02.script_split_fasta.pl ${FASTAPATH}/${fasta_file} ./01.fasta_to_analyse_${DATE} #outputs multiple files like "title_nucl_splitted"

printf "\n#####################\n03.ANI.pl running ...\n#####################\n";
for files in 01.fasta_to_analyse_${DATE}/*splitted*
do
	for ffiles in 01.fasta_to_analyse_${DATE}/*splitted*
	do 
		if [ $files != $ffiles ] ; then
		perl ${SCRIPTPATH}/scripts/03.ANI.pl --fd formatdb --bl blastn --qr $files --sb $ffiles --od ./results_ANI_${DATE}/ --id ${identity_p_cent} --length ${length_p_cent} --seg_length ${seg_length_ANI}
		fi
	done
done

rm -rf temporary_ANI_folder
rm -f formatdb.log

# Pour étudier les résultats de l'ANI il faut classer les séquences parent par taille
# je récupère la taille de toutes les séquences
perl -ne 'if (/^>/){print}else{print length() . "\n"}' 01.fasta_to_analyse_${DATE}/*splitted* >> ./results_ANI_${DATE}/size_of_all_fiches_${DATE}

#04.prepare_ani_result.pl extracts the best results from the ANI result file, using size of all sequences 
perl ${SCRIPTPATH}/scripts/04.prepare_ani_result.pl  ./results_ANI_${DATE}/size_of_all_fiches_${DATE} ./results_ANI_${DATE}/result_ANI.${identity_p_cent}.${length_p_cent} #directly outputs "bestresult_ANI.${stringence}.${stringence}"
#From the intput multi-fasta (first argument) and the ANI result file (second argument), this script outputs the corresponding clusters\nThe hard part is to create the clusters from the ANi result file that contains pair by pair comparisons of the sequences
# script 05 only treats one line fasta, i'll therefore create it as temporary file and delete it later # 06/12/2016
perl -ne 'if(/>/){if(!$a){print}else{print "\n$_"}}else{s/\r?\n//g; print}; $a++' ${fasta_file} > ${fasta_file}.tmp
perl ${SCRIPTPATH}/scripts/05.produce_clusered_seqs.pl ${fasta_file}.tmp ./results_ANI_${DATE}/bestresult_ANI.${identity_p_cent}.${length_p_cent} #outputs bestresult_ANI.95.95.out2 and bestresult_ANI.95.95.out and bestresult_ANI.95.95.log if third argument provided

rm -rf ${fasta_file}.tmp


if ! $log_mode  ; then 
rm -rf 01.fasta_to_analyse_${DATE}
rm -rf results_ANI_${DATE}
fi

printf "\n#####################\nEnd of the pipeline\n#####################\n\nYour output files are:\n\n-${FASTAPATH}/${fasta_file}_clust_and_seqs.fasta\n-${FASTAPATH}/${fasta_file}_clust_names_alone.txt\n\n"



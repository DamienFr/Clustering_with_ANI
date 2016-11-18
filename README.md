# Clustering_with_ANI
clustering any nucleotid sequences using ANI (Average Nucleotid Identity)  
I have build this tool for my personal research use, to fill the gap that exists in clustering tools. Indeed, most of the available programs that make clustering of sequences do not work with large sequences such as chromosomes, are not fully customisable, or are really heavy and time consuming processes.

Based on an available ANI script (https://github.com/chjp/ANI) i made a script that allows customisable clustering of any kind of nucleotid sequences, no limit regarding size and/or number of sequences. It works by comparing pairs of sequences.
This tool relies on blast, so you must have it installed on your computer. It is written in shell bash and perl. Unix environment required.

How to use the programm ?

1. Give execution permission to Launch_ANI.sh by typing in a terminal "chmod +x	Launch_ANI.sh" or right-clicking on it, properties, permissions, make executable.
2. Run the program by calling Launch_ANI.sh from your opened terminal.

Usage: /home/path_to_the_script/Launch_ANI.sh -f fasta_file [-i 90] [-l 90] [-s 1020] [-k] [-h]

[] means argument is optional

available arguments:

	-f	input file, fasta format
	-i	percentage of identical bases between two DNA fragments to consider them identical. Default 90%
	-l	identity of two DNA fragments must cover at least this percentage of the longest fragment to consider them identical. Default 90%
	-s	segment length. Must be shorter than the shorter studied sequence. Should be < 10% of the shorter sequence's length for best accuracy, but shouldn't be < 200
	-k	activate log mode. Keep the two subfolders created for the analysis instead of removing them 
	-h	display this help


The folder "scripts" contain 4 scripts that represent the backbone of the pipeline. Any script can be run alone without any arguments to get to its help instructions. 

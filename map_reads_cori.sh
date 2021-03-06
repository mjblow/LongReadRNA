#!/bin/bash -l
PROJECT=$1 #e.g. Arabidopsis_SeqTech_USA-70B
NAME=$2 #e.g. ONT_RNA_X0143_ALB2-1
GENOME=$3 #e.g. "/global/projectb/scratch/mjblow/ONT_RNA/Arabidopsis_SeqTech_USA-70/REF.fa"
GENEFASTA=$4 #e.g. "/global/projectb/scratch/mjblow/ONT_RNA/Arabidopsis_SeqTech_USA-70/Athaliana_167_TAIR10.cds_primaryTranscriptOnly.fa"
GXGFF=$5 # e.g."~/user_support_projects/ONT_RNA/Arabidopsis_lyrata_SeqTech_USA-79/Alyrata_384_v2.1.gene_exons.sorted.gff3"
GXGTF=$6 # e.g."~/user_support_projects/ONT_RNA/Arabidopsis_lyrata_SeqTech_USA-79/Alyrata_384_v2.1.gene_exons.sorted.gff3"
GXBED=$7 # e.g."~/user_support_projects/ONT_RNA/Arabidopsis_lyrata_SeqTech_USA-79/Alyrata_384_v2.1.gene_exons.sorted.bed"
PASS=$8 # e.g. /global/dna/projectdirs/RD/Adv-Seq/www/OxfordNanoPore-AnalysisReports/X0123/data/nanopore02_jgi_psf_org_20170608_FNFAH04643_MN18617_sequencing_run_170608_1002001975_001-combined.pass-1D.fastq.gz
FAIL=$9

SCRIPTS="/global/u2/m/mjblow/user_support_projects/Long_Read_RNA/scripts"
BBTOOLS="shifter --image registry.services.nersc.gov/jgi/bbtools:latest"
SAMTOOLS="shifter --image mjblow/samtools:1.5"
MINIMAP2="shifter --image mjblow/minimap2:2.5-r572"
HTSBOX="shifter --image mjblow/htsbox:r312"
BEDTOOLS="shifter --image mjblow/bedtools:2.25.0"

mkdir -p $SCRATCH/Long_Read_RNA/${PROJECT}/${NAME}
cd $SCRATCH/Long_Read_RNA/${PROJECT}/${NAME}

#link to reference genome
ln -s ${GENOME} . 

#link ONT RNA data, Convert U to T (required by mappers)
#Not necessary for latest minimap2
zcat ${PASS} ${FAIL} > ${NAME}.fastq
#${BBTOOLS} reformat.sh in=${NAME}.fastq out=${NAME}.fasta overwrite=true
#sed 's/U/T/g' ${NAME}.fasta > ${NAME}.T.fasta

#get readlength distributions of inputs
${BBTOOLS} readlength.sh in=${GENEFASTA} bin=100 max=50000 nzo=f out=PrimaryTranscripts.readlength.txt
${BBTOOLS} readlength.sh bin=100 nzo=f max=50000 in=${NAME}.fastq out=${NAME}.readlength.txt

#map reads using minimap2
${MINIMAP2} minimap2 -x splice -a -t 32 ${GENOME} ${NAME}.fastq > ${NAME}.minimap2.sam

#Convert to bam and index
${SAMTOOLS} samtools view -bhS ${NAME}.minimap2.sam | ${SAMTOOLS} samtools sort - -o ${NAME}.minimap2.bam
${SAMTOOLS} samtools index ${NAME}.minimap2.bam

#Mapping stats
${SCRIPTS}/k8 ${SCRIPTS}/mapstats.js ${NAME}.minimap2.sam > ${NAME}.mapstats.txt

#Intersect with gene annotations
perl ${SCRIPTS}/transcript_overlap.pl ${GXBED} ${NAME}.minimap2.bam > ${NAME}.tx_overlap.txt

#Summarize first-to-last-exon reads by tx exon count
perl ${SCRIPTS}/first_to_last_exon_reads.pl ${NAME}.tx_overlap.txt > ${NAME}.exon_cov.txt

#summarzie >90% tx coverage by tx_length
perl ${SCRIPTS}/full_transcript_reads.pl ${NAME}.tx_overlap.txt 500 10000 > ${NAME}.tx_cov.txt

#compare with annotated introns
${SCRIPTS}/k8 ${SCRIPTS}/intron-eval.js ${GXGTF} ${NAME}.minimap2.sam > ${NAME}.intron_eval.txt

#run variant detection analysis
${HTSBOX} htsbox pileup -s 5 -q10 -vcf ${GENOME} ${NAME}.minimap2.bam > ${NAME}.minimap2.vcf

#filter for variants with >10 reads and allele frequency >90%
perl ${SCRIPTS}/filter_variants.pl ${NAME}.minimap2.vcf  > ${NAME}.filtered_variants.vcf

#Intersect with gene annotations
${BEDTOOLS} intersectBed -wb -a ${NAME}.filtered_variants.vcf -b ${GXGFF} | grep exon | cut -f 1-11,18,20 |  uniq > ${NAME}.filtered_variants.annotated.vcf

#Reorient variants with respect to transcribed strand
perl ${SCRIPTS}/fix_strandedness.pl ${NAME}.filtered_variants.annotated.vcf > ${NAME}.filtered_variants.annotated.vcf.stranded.txt

#Extract coordinates of variants +- 3bp
awk '{print $1"\t"$2-3"\t"$3+3"\t"$4"\t"$5"\t"$6}' ${NAME}.filtered_variants.annotated.vcf.stranded.txt > ${NAME}.filtered_variants.local_context.bed

#Get flanking sequence contexts
${BEDTOOLS} fastaFromBed -fi ${GENOME} -bed ${NAME}.filtered_variants.local_context.bed -s -tab -fo ${NAME}.filtered_variants.local_context.seq

#Reannotate variant files with flanking sequence contexts
perl ${SCRIPTS}/add_seq_context.pl ${NAME}.filtered_variants.annotated.vcf.stranded.txt ${NAME}.filtered_variants.local_context.seq > ${NAME}.filtered_variants.annotated.vcf.stranded.seq.txt


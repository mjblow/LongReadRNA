#!/bin/bash -l
#SBATCH --ntasks=1 #3 tasks total
#SBATCH -N 1 #Use 3 nodes (one per task)
#SBATCH -c 8 #number of cpus required per task = all available on haswell node = 64 threads (due to hyperthreading)
#SBATCH -t 12:00:00  #Set 12 hour time limit
#SBATCH -C haswell   #Use Haswell nodes
#SBATCH --qos=jgi #Use JGI allocation
#SBATCH -A gentechp #Charge to gentech
#SBATCH --exclusive #Charge to gentech

#X0123 - Old basecaller - albacore2.0.1
#srun -N1 -n1 /global/u2/m/mjblow/user_support_projects/ONT_RNA/Arabidopsis_SeqTech_USA-70B/map_reads_cori.sh ONT_RNA_X0123_ALB2-0-2 /global/dna/projectdirs/RD/Adv-Seq/www/OxfordNanoPore-AnalysisReports/X0123/data/nanopore02_jgi_psf_org_20170608_FNFAH04643_MN18617_sequencing_run_170608_1002001975_001-combined.pass-1D.fastq.gz

#X0123 - New basecaller - albacore2.1

#X0143 - New Basecaller - albacore2.1 
srun -N1 -n1 /global/u2/m/mjblow/user_support_projects/ONT_RNA/Arabidopsis_SeqTech_USA-70B/map_reads_cori.sh ONT_RNA_X0143_ALB2-1 /global/dna/projectdirs/RD/Adv-Seq/www/OxfordNanoPore-AnalysisReports/X0143/data/nanopore03_jgi_psf_org_20171101_FAH21375_MN17641_sequencing_run_171101_X0143_001-combined.pass-1D.fastq.gz /global/dna/projectdirs/RD/Adv-Seq/www/OxfordNanoPore-AnalysisReports/X0143/data/nanopore03_jgi_psf_org_20171101_FAH21375_MN17641_sequencing_run_171101_X0143_001-combined.fail-fwd.fastq.gz

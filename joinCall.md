# join call script

```shell
# loop with one chr21
chrs=("chr21")
for chr in ${chrs[@]}; do
    #### join call for all interval, iterate through chr ####
    int=`wc -l intervalDir/${chr}.interval.list | awk '{print $1}'`
    batch="1-${int}"
    qsub -v chr="$chr" \
        -J $batch -o logs/joinCall-${chr}.pbs.log.^array_index^ \
        src/joinCall-chr.pbs
    # check completion and rerun
    qsub -v chr="$chr" \
        -o logs/joinCall-${chr}.rerun-init.pbs.log \
        src/joinCall-chr.rerun-init.pbs
    #### call GVCF for all interva, iterate through chr####
    qsub -v chr="$chr" \
        -J $batch -o logs/genotypeGvcf-${chr}.pbs.log.^array_index^ \
        src/genotypeGvcf-chr.pbs
    # check completion and rerun
    qsub -W depend=afterany:135910[].pbs01 \
        -v chr="$chr" \
        -o logs/genotypeGvcf-${chr}.rerun-init.pbs.log \
        src/genotypeGvcf-chr.rerun-init.pbs
    #### concat vcf for all interval, iterate through chr ####
    qsub -W depend=afterany:135932[].pbs01 \
        -v chr="$chr" \
        -o logs/concatVcfs-${chr}.pbs.log \
        src/concatVcfs-chr.pbs

done

```

# genotype gvcf script

```shell

```

# concat vcf script

```shell

```
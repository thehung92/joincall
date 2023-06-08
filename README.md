# joint call on hadley

## create workspace

```shell
# on local, copy the old files
mkdir -p intervalDir
cp -r ../20230117_jointCalling/intervalDir ./
# calculate average of interval on  chr22
cat intervalDir/chr22.interval.list | awk -F'[:-]' '{sum+=$3-$2} END {print sum/NR}'
# calculate median of interval on chr22
# on hadley
cp ../20230523_hadleyManage/output/ga5k_20230523.txt data/
```

## create map of chr22

```shell
#
storeDir="/gpfs1/scratch/projects/ga100k/GRCh38_gVCFs"
# read  gaid from list into array
readarray -t gaids < data/ga5k_20230523.txt
# create map
for i in {1..22}; do
    for gaid in ${gaids[@]}; do
        printf "${gaid}\t${storeDir}/${gaid}/${gaid}.chr${i}.g.vcf.gz\n"
    done > mapDir/ga5k_chr${i}.map
done
# check file avail for chr22
files=(`awk '{print $2}' mapDir/ga5k_chr22.map`)
for file in ${files[@]}; do
    [ -r $file ] || echo $file not found
done
# all can be read #
# create list of vcf interval
chrs=(`printf "chr%s\n" {1..22}`)
for chr in ${chrs[@]}; do
    ints=(`cat intervalDir/${chr}.interval.list | sed 's/:/-/'`)
    for int in ${ints[@]}; do
        echo ga5k.vcf/${int}.vcf.gz
    done > output/ga5k.${chr}.vcf.list
done
```

# devlop qsub with accompanying script

```shell
# join call
chr="chr22"
int=`wc -l intervalDir/${chr}.interval.list | awk '{print $1}'`
batch="1-${int}"
qsub -v chr="$chr" \
    -J $batch \
    src/joinCall-chr22.pbs
# check completion
grep -Eo "Exit Status: [^0].*" logs/joinCall-chr22.pbs*
grep -Eo "Exit Status: .*" logs/joinCall-chr22.pbs* | grep -v "0$"

```

# create joint vcf

```shell
# genotype gvcf
qsub -J $batch src/genotypeGvcf-chr22.pbs
# check completion
while read -r line; do
    status=`echo $line | awk '{print $NF}'`
    index=`echo $line | awk -F':' '{print $1}' | awk -F '.' '{print $NF}'`
    echo $index $status
done < <(grep -Eo "Exit Status: [^0].*" logs/genotypeGvcf-chr22.pbs.log*) > rerun-array-index.txt
# run failed jobs # check if the rerun-index is empty
if [[ -s rerun-array-index.txt ]]; then
    # echo submit job to rerun
    nline=`wc -l rerun-array-index.txt | awk '{print $1}'`
    batch="1-${nline}"
    qsub -N genotypeGvcf-chr22.rerun -v chr="chr22" \
        -l select=1:ncpus=12,walltime=36:00:00 \
        -J $batch \
        -o logs/genotypeGvcf-chr22.rerun.pbs.log.^array_index^ \
        src/genotypeGvcf-chr22.rerun.pbs
fi
# check completion of rerun
grep -Eo 'Exit Status: .*' logs/genotypeGvcf-chr22.rerun.pbs.log.*
#
```
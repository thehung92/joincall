# joint call on hadley

[![](https://mermaid.ink/img/pako:eNp1U02PgjAU_CvN86IRXCkfCsnuZU32snvZTTxsuNRSEAMtodXoGv_7lg8VUXuhTOfNG6aPI1ARMQiAZkTKRUqSkuQhR3pFacmoSgVHn98hb7CahZIdjY8NUK0xykQiXzYi5e8ky0y6Lq-HJhrUfIle9U6SvMiY7NZ2y4YV00ApV6zckWx02S1WTcnpbKQiItN8u2F0PV7xe6cJ40IdCvahRe7dXitry-fXG9NdheG93SWNe347ol3XNfGR7WUv4QG6ZPjQEBWcEqWr5HCE9Cc9d7BsgzuTut0b7Fnjm6TGSIpSVXcVsX2vFSc5kwWhDK2IouuNWKGO5nWG-lj_th_G0vYCA3JW5iSN9PDW6iGoNctZCIHeRiwm20yFEPKKSrZK_Bw4hUCVW2bAtoiIYu24QxDrNDVaEA7BEfYQYHc2sefebOr6ju9PsW3AAQLL9ye-47iOh7FvWdjCJwP-hNAK08ls7mLPd23seg62HbuW-60Pm54sSpUov9rfrXqc_gEHPhG1?type=png)](https://mermaid.live/edit#pako:eNp1U02PgjAU_CvN86IRXCkfCsnuZU32snvZTTxsuNRSEAMtodXoGv_7lg8VUXuhTOfNG6aPI1ARMQiAZkTKRUqSkuQhR3pFacmoSgVHn98hb7CahZIdjY8NUK0xykQiXzYi5e8ky0y6Lq-HJhrUfIle9U6SvMiY7NZ2y4YV00ApV6zckWx02S1WTcnpbKQiItN8u2F0PV7xe6cJ40IdCvahRe7dXitry-fXG9NdheG93SWNe347ol3XNfGR7WUv4QG6ZPjQEBWcEqWr5HCE9Cc9d7BsgzuTut0b7Fnjm6TGSIpSVXcVsX2vFSc5kwWhDK2IouuNWKGO5nWG-lj_th_G0vYCA3JW5iSN9PDW6iGoNctZCIHeRiwm20yFEPKKSrZK_Bw4hUCVW2bAtoiIYu24QxDrNDVaEA7BEfYQYHc2sefebOr6ju9PsW3AAQLL9ye-47iOh7FvWdjCJwP-hNAK08ls7mLPd23seg62HbuW-60Pm54sSpUov9rfrXqc_gEHPhG1)

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
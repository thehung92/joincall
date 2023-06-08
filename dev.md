# PBS, submit a job with multiple variable

```shell
qsub -v chr="chr22",rerun="select-file.txt" \
    -q dev -l select=1:ncpus=1,walltime=00:01:00 \
    -J 1-2 \
    -j oe -o logs/dev.pbs.log.^array_index^ \
    - <<'STDIN'
cd $PBS_O_WORKDIR
echo $chr
echo $PBS_ARRAY_INDEX
echo $rerun
STDIN
```

# awk on rerun file

```shell
grep -Eo "Exit Status: [^0].*" logs/genotypeGvcf-chr22.pbs.log.* |\
    sed -n "${index}p" |\
    awk -F':' '{print $1}' | awk -F '.' '{print $NF}'
```

# pattern in grep

```shell
pattern="logs/genotypeGvcf-${chr}.pbs.log"'*'
echo "$pattern"
```

# get jobid from qsub

```shell
JOB1=`qsub -v chr="chr22",rerun="select-file.txt" \
    -q dev -l select=1:ncpus=1,walltime=00:01:00 \
    -j oe -o logs/dev.pbs.log \
    - <<'STDIN'
echo hello world
STDIN`
```

# try qrerun

```shell
# batch job with exit status
export myVar="hello world"
JOB1=`qsub -V -q dev -l select=1:ncpus=1,walltime=00:01:00 \
    -J 1-3 -j oe -o logs/dev.pbs.log.^array_index^ \
    - <<'EOF'
echo $myVar
status=$(( PBS_ARRAY_INDEX - 1 ))
exit $status
EOF`
```
```shell
# qrerun can not be used to rerun a failed job array index
qrerun `echo $JOB1 | sed 's,\[\],\[3\],'`
```
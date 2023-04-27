#!/bin/bash -e
set -o pipefail
# Prevent commands misbehaving due to locale differences
export LC_ALL=C

function usage {
    cat <<EOS

Usage: $(basename "$0") -i input_dir -o output_dir -t experiment.txt -r [VALUE] -e [VALUE] -n [VALUE]

	-h  Display help
	-i  Directory containing count files generated by Shiba
	-o  Output directory
	-t  Experiment table
	-r  Reference group for differential expression analysis (default: NA)
	-e  Experiment group for differential expression analysis (default: NA)
	-n  Number of PCs to use for DESeq2 (default: 3)

EOS
    exit 2
}


SRC_PATH=$(dirname "$0")
REFGROUP="NA"
EXPGROUP="NA"
PC=3


function lack_of_necessary_param() {
    usage
    exit 1
}


IS_THERE_NECESSARY_OPT_i=false
IS_THERE_NECESSARY_OPT_o=false
IS_THERE_NECESSARY_OPT_t=false


while getopts "i:o:t:r:e:n:h" optKey; do
    case "$optKey" in
    i)
        IS_THERE_NECESSARY_OPT_i=true
        INPUTDIR=${OPTARG}
        ;;
	o)
        IS_THERE_NECESSARY_OPT_o=true
        OUTPUTDIR=${OPTARG}
        ;;
	t)
        IS_THERE_NECESSARY_OPT_t=true
        EXPERIMENT=${OPTARG}
        ;;
	r)
        REFGROUP=${OPTARG}
        ;;
    e)
        EXPGROUP=${OPTARG}
        ;;
	n)
		PC=${OPTARG}
		;;
    h|* )
        usage
        ;;
    esac
done




if [ "${IS_THERE_NECESSARY_OPT_i}" == false ] || [ "${IS_THERE_NECESSARY_OPT_o}" == false ] || [ "${IS_THERE_NECESSARY_OPT_t}" == false ]; then
    lack_of_necessary_param
fi;


# Create output directory
mkdir -p ${OUTPUTDIR}/logs


# Perform PCA
echo -e "Performing PCA..."
python ${SRC_PATH}/pca.py \
${INPUTDIR}/TPM.txt \
${EXPERIMENT} \
${REFGROUP} \
${EXPGROUP} \
${OUTPUTDIR}/pca.txt \
${OUTPUTDIR}/contribution.txt \
-n ${PC} 2> ${OUTPUTDIR}/logs/pca.log


# Perform DESeq2
if [ "${REFGROUP}" == "NA" ] || [ "${EXPGROUP}" == "NA" ]; then

    :

else

    echo -e "Differential expression analysis by DESeq2..."
    # Differential expression analysis by DESeq2
    Rscript ${SRC_PATH}/deseq2.R \
    ${EXPERIMENT} \
    ${INPUTDIR}/counts.txt \
	${OUTPUTDIR}/pca.txt \
    ${REFGROUP} \
    ${EXPGROUP} \
    ${OUTPUTDIR}/DEG.txt 2> ${OUTPUTDIR}/logs/DESeq2.log

fi


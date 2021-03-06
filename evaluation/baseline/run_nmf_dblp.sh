if [[ -z "$INPUT" ]]; then
	INPUT=/shared/data/tensor_embedding/data/dblp/frequent
fi

if [[ -z "$OUTPUT" ]]; then
	OUTPUT=results/dblp
fi

mkdir -p $INPUT/matlab
if [ ! -e $INPUT/matlab/name0.txt ]; then
	pypy matlab_data_prepare.py -input $INPUT/events.txt -output $INPUT/matlab
	chmod a+rwx -R $INPUT/matlab
fi
mkdir -p $OUTPUT

evaluate () {
	THREAD=5
	python ../transform_format.py -emb $1 -label $2 -output $OUTPUT/data_nmf_norm.txt -norm 1
	echo "logistic regression (normalization):"
	../liblinear/train -q -s 0 -v 5 -n $THREAD $OUTPUT/data_nmf_norm.txt
	echo "linear svm (normalization):"
	../liblinear/train -q -s 2 -v 5 -n $THREAD $OUTPUT/data_nmf_norm.txt
	python ../ranking.py -input $OUTPUT/data_nmf_norm.txt

	python ../transform_format.py -emb $1 -label $2 -output $OUTPUT/data_nmf.txt -norm 0
	echo "logistic regression (no normalization):"
	../liblinear/train -q -s 0 -v 5 -n $THREAD $OUTPUT/data_nmf.txt
	echo "linear svm (no normalization):"
	../liblinear/train -q -s 2 -v 5 -n $THREAD $OUTPUT/data_nmf.txt
	python ../ranking.py -input $OUTPUT/data_nmf.txt
}

run () {
	matlab -nojvm -nodisplay -nodesktop -r \
		"input_folder='$INPUT/matlab/';output_folder='$OUTPUT';options.dim=$1;options.log=$2;options.norm=$3;run('./collective_nmf/collective_nmf');quit"
	echo 0 0 > $OUTPUT/colnmf_embedding$2$3.txt
	paste -d' ' $INPUT/matlab/name2.txt $OUTPUT/colnmf2.txt >> $OUTPUT/colnmf_embedding$2$3.txt
	echo === evaluating 4 research group labels ===
	evaluate $OUTPUT/colnmf_embedding$2$3.txt $INPUT/label-group.txt
	echo
	echo === evaluating 4 research area labels ===
	evaluate $OUTPUT/colnmf_embedding$2$3.txt $INPUT/label-area.txt
	echo
}

echo nmf
run 300 0 0
echo nmf log
run 300 1 0
echo nmf norm
run 300 0 1
echo nmf log norm
run 300 1 1

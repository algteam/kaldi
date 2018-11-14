#!/bin/bash


user=all
rootdir=/home/swair/Desktop/data/github_ws/kaldi/egs/simple_sre/wav_set
eval_wav=$rootdir/wav/$user/eval
eval_result=$rootdir/result/$user
train_result=$rootdir/train_mode
enroll_result=$rootdir/result/$user

echo $eval_wav
echo $eval_result

if [ ! -d $eval_wav ]; then
    echo "$0: empty file $eval_wav"
    exit 1;
fi




trials=data/eval/speaker_ver.lst

. ./cmd.sh
. ./path.sh

set -e # exit on error


rm -rf $eval_result/data/eval
mkdir $eval_result/data/eval -p


#prepare text data
./myscript/prepare_eval_data.py $eval_wav $eval_result

./local/produce_trials.py $eval_result/data/eval/utt2spk $eval_result/$trials

#mfcc
steps/make_mfcc.sh --cmd "$train_cmd" --nj 1 \
    $eval_result/data/eval \
    $eval_result/exp/make_mfcc/eval \
    $eval_result/mfcc

#vad
sid/compute_vad_decision.sh --nj 1 --cmd "$train_cmd" \
    $eval_result/data/eval \
    $eval_result/exp/make_mfcc/eval \
    $eval_result/mfcc

#extract ivectors
sid/extract_ivectors.sh --cmd "$train_cmd" --nj 1 \
    $train_result/exp/extractor_1024 \
    $eval_result/data/eval \
    $eval_result/exp/ivector_eval_1024

#compute plda score
$train_cmd $eval_result/exp/ivector_eval_1024/log/plda_score.log \
    ivector-plda-scoring --num-utts=ark:$enroll_result/exp/ivector_enroll_1024/num_utts.ark \
    $train_result/exp/ivector_train_1024/plda \
    ark:$enroll_result/exp/ivector_enroll_1024/spk_ivector.ark \
    "ark:ivector-normalize-length scp:$eval_result/exp/ivector_eval_1024/ivector.scp ark:- |" \
    "cat '$eval_result/$trials' | awk '{print \\\$2, \\\$1}' |" $eval_result/trials_out

#compute eer
awk '{print $3}' $eval_result/trials_out | paste - $eval_result/$trials | awk '{print $1, $4}' | compute-eer - > $eval_result/err.txt

cat $eval_result/trials_out

echo 'ok'


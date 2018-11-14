#!/bin/bash


user=all
rootdir=/home/swair/Desktop/data/github_ws/kaldi/egs/simple_sre/wav_set
enroll_wav=$rootdir/wav/$user/enroll
enroll_result=$rootdir/result/$user
train_result=$rootdir/train_mode

echo $enroll_wav
echo $enroll_result

if [ ! -d $enroll_wav ]; then
    echo "$0: empty file $enroll_wav"
    exit 1;
fi


. ./cmd.sh
. ./path.sh

set -e # exit on error


rm -rf $enroll_result/data/enroll
mkdir $enroll_result/data/enroll -p

#prepare text data
./myscript/prepare_enroll_data.py $enroll_wav $enroll_result

#mfcc
steps/make_mfcc.sh --cmd "$train_cmd" --nj 1 \
    $enroll_result/data/enroll \
    $enroll_result/exp/make_mfcc/enroll \
    $enroll_result/mfcc

#vad
sid/compute_vad_decision.sh --nj 1 --cmd "$train_cmd" \
    $enroll_result/data/enroll \
    $enroll_result/exp/make_mfcc/enroll \
    $enroll_result/mfcc

#extract ivectors
sid/extract_ivectors.sh --cmd "$train_cmd" --nj 1 \
    $train_result/exp/extractor_1024 \
    $enroll_result/data/enroll \
    $enroll_result/exp/ivector_enroll_1024


echo 'ok'



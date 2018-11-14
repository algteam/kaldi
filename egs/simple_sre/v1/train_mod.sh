#!/bin/bash

export train_cmd="run.pl --mem 4G"
export KALDI_ROOT=`pwd`/../../..
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sph2pipe_v2.5:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C



set -e # exit on error



rootdir=/home/swair/Desktop/data/github_ws/kaldi/egs/simple_sre/wav_set
train_wav=$rootdir/train
train_result=$rootdir/train_mode


rm -rf $train_result/data/*
rm -rf $train_result/exp/*
rm -rf $train_result/mfcc


# Data Preparation
mkdir $train_result/data/train -p
./myscript/prepare_train_data.py $train_wav $train_result

# Now make MFCC  features.
steps/make_mfcc.sh --cmd "$train_cmd" --nj 1 \
    $train_result/data/train \
    $train_result/exp/make_mfcc/train \
    $train_result/mfcc

sid/compute_vad_decision.sh --nj 1 --cmd "$train_cmd" \
    $train_result/data/train \
    $train_result/exp/make_mfcc/train \
    $train_result/mfcc 

# train diag ubm
sid/train_diag_ubm.sh --nj 1 --cmd "$train_cmd" --num-threads 16 \
    $train_result/data/train 1024 \
    $train_result/exp/diag_ubm_1024

#train full ubm
sid/train_full_ubm.sh --nj 1 --cmd "$train_cmd" \
    $train_result/data/train \
    $train_result/exp/diag_ubm_1024 \
    $train_result/exp/full_ubm_1024


#train ivector
sid/train_ivector_extractor.sh --cmd "$train_cmd --mem 10G" --num-iters 5 \
    $train_result/exp/full_ubm_1024/final.ubm \
    $train_result/data/train \
    $train_result/exp/extractor_1024

#extract ivector
sid/extract_ivectors.sh --cmd "$train_cmd" --nj 1 \
    $train_result/exp/extractor_1024 \
    $train_result/data/train \
    $train_result/exp/ivector_train_1024

#train plda
$train_cmd $train_result/exp/ivector_train_1024/log/plda.log \
    ivector-compute-plda ark:$train_result/data/train/spk2utt \
    'ark:ivector-normalize-length scp:'$train_result'/exp/ivector_train_1024/ivector.scp  ark:- |' \
    $train_result/exp/ivector_train_1024/plda


echo 'ok'




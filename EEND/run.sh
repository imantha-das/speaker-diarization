#!/bin/bash
clear

bin_dir="eend/bin"

eval_dir="`pwd`/egs/callhome/v1/data/eval"
data_dir="`pwd`/egs/callhome/v1/data"

config_dir="egs/callhome/v1/conf"
train_config="train.yaml"
infer_config="infer.yaml"
adapt_config="adapt.yaml"

train_set="callhome1_spk2"
valid_set="callhome2_spk2"

exp_name="callhome.train"
model_dir="exp/diarize/model"
infer_dir="exp/diarize/infer"
scoring_dir="exp/diarize/scoring"

echo $KALDI_ROOT
export PATH="$KALDI_ROOT/tools/sph2pipe:$KALDI_ROOT/tools/sctk-20159b5/bin:${PATH}"

stage=8

if [ $stage -le 1 ]; then
    echo "Stage 1: Training"
    #python3 $bin_dir/train.py -c egs/mini_librispeech/v1/conf/$train_config  egs/mini_librispeech/v1/data/simu/data/train_clean_5_ns2_beta2_500 egs/mini_librispeech/v1/data/simu/data/dev_clean_2_ns2_beta2_500 egs/mini_librispeech/v1/$model_dir/train_clean_5_ns2_beta2_500.dev_clean_2_ns2_beta2_500.train
    #python3 $bin_dir/train.py -c $config_dir/$train_config  $data_dir/simu/data/swb_sre_tr_ns2_beta2_100000 $data_dir/simu/data/swb_sre_cv_ns2_beta2_500 $model_dir/swb_sre_tr_ns2_beta2_100000.swb_sre_cv_ns2_beta2_500.train

    python3 $bin_dir/train.py -c $config_dir/$train_config \
    $data_dir \
    $data_dir/$train_set \
    $data_dir/$valid_set $model_dir/$exp_name
else
    echo "Skipped Stage 1"
fi

if [ $stage -le 2 ]; then
    echo ""
    echo "Stage 2: Model Averaging"
    python3 $bin_dir/model_averaging.py \
    $model_dir/$exp_name/avg91-100.nnet.npz \
    $model_dir/$exp_name/snapshot_epoch-91 \
    $model_dir/$exp_name/snapshot_epoch-92 \
    $model_dir/$exp_name/snapshot_epoch-93 \
    $model_dir/$exp_name/snapshot_epoch-94 \
    $model_dir/$exp_name/snapshot_epoch-95 \
    $model_dir/$exp_name/snapshot_epoch-96 \
    $model_dir/$exp_name/snapshot_epoch-97 \
    $model_dir/$exp_name/snapshot_epoch-98 \
    $model_dir/$exp_name/snapshot_epoch-99 \
    $model_dir/$exp_name/snapshot_epoch-100
else
    echo "Skipped Stage 2"
fi

if [ $stage -le 3 ]; then
    echo ""
    echo "Stage 3: Inference"
    python3 $bin_dir/infer.py -c $config_dir/$infer_config  \
    $data_dir $eval_dir/$valid_set \
    $model_dir/$exp_name/avg91-100.nnet.npz \
    $infer_dir/$exp_name.avg91-100.infer/$valid_set
else
    echo "Skipped Stage 3"
fi

if [ $stage -le 4 ]; then
    echo ""
    echo "Stage 4: Scoring"
    mkdir -p $scoring_dir/$exp_name.avg91-100.infer/$valid_set/.work
    find $infer_dir/$exp_name.avg91-100.infer/$valid_set -iname *.h5 \
    > $scoring_dir/$exp_name.avg91-100.infer/$valid_set/.work/file_list_callhome2_spk2

    python3 $bin_dir/make_rttm.py --median=1 --threshold=0.3 --frame_shift=80 \
    --subsampling=10 --sampling_rate=8000 \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.3_1.rttm 

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.3_1.rttm > \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/result_th0.3_med1_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=1 --threshold=0.4 \
    --frame_shift=80 --subsampling=10 --sampling_rate=8000 \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.4_1.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.4_1.rttm > \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/result_th0.4_med1_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=1 --threshold=0.5 \
    --frame_shift=80 --subsampling=10 --sampling_rate=8000 \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.5_1.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.5_1.rttm > \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/result_th0.5_med1_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=1 --threshold=0.6 \
    --frame_shift=80 --subsampling=10 --sampling_rate=8000 \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.6_1.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.6_1.rttm > \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/result_th0.6_med1_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=1 --threshold=0.7 \
    --frame_shift=80 --subsampling=10 --sampling_rate=8000 \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.7_1.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.7_1.rttm > \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/result_th0.7_med1_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=11 --threshold=0.3 \
    --frame_shift=80 --subsampling=10 --sampling_rate=8000 \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.3_11.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.3_11.rttm > \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/result_th0.3_med11_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=11 --threshold=0.4 \
    --frame_shift=80 --subsampling=10 --sampling_rate=8000 \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.4_11.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.4_11.rttm > \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/result_th0.4_med11_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=11 --threshold=0.5 \
    --frame_shift=80 --subsampling=10 --sampling_rate=8000 \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.5_11.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.5_11.rttm > \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/result_th0.5_med11_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=11 --threshold=0.6 \
    --frame_shift=80 --subsampling=10 --sampling_rate=8000 \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.6_11.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.6_11.rttm > \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/result_th0.6_med11_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=11 --threshold=0.7 \
    --frame_shift=80 --subsampling=10 --sampling_rate=8000 \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.7_11.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.infer/$valid_set/hyp_0.7_11.rttm > \
    $scoring_dir/$exp_name.avg91-100.infer/$valid_set/result_th0.7_med11_collar0.25 \
    2>/dev/null
else
    echo "Skipped Stage 4"
fi

if [ $stage -le 5 ]; then
    echo ""
    echo "Stage 5: Adapting - Training"
    python3 $bin_dir/train.py -c $config_dir/$adapt_config  \
    --initmodel $model_dir/$exp_name/avg91-100.nnet.npz \
    $data_dir \
    $eval_dir/$train_set \
    $eval_dir/$valid_set \
    $model_dir/$exp_name.avg91-100.adapt
else
    echo "Skipped Stage 5"
fi

if [ $stage -le 6 ]; then
    echo ""
    echo "Stage 6: Adapt - Averaging"
    python3 $bin_dir/model_averaging.py $model_dir/$exp_name.avg91-100.adapt/avg91-100.nnet.npz \
    $model_dir/$exp_name.avg91-100.adapt/snapshot_epoch-91 \
    $model_dir/$exp_name.avg91-100.adapt/snapshot_epoch-92 \
    $model_dir/$exp_name.avg91-100.adapt/snapshot_epoch-93 \
    $model_dir/$exp_name.avg91-100.adapt/snapshot_epoch-94 \
    $model_dir/$exp_name.avg91-100.adapt/snapshot_epoch-95 \
    $model_dir/$exp_name.avg91-100.adapt/snapshot_epoch-96 \
    $model_dir/$exp_name.avg91-100.adapt/snapshot_epoch-97 \
    $model_dir/$exp_name.avg91-100.adapt/snapshot_epoch-98 \
    $model_dir/$exp_name.avg91-100.adapt/snapshot_epoch-99 \
    $model_dir/$exp_name.avg91-100.adapt/snapshot_epoch-100
else
    echo "Skipped Stage 6"
fi

if [ $stage -le 7 ]; then
    echo ""
    echo "Stage 7: Adapt - Inference"
    python3 $bin_dir/infer.py -c $config_dir/$infer_config \
    $data_dir $eval_dir/$valid_set \
    $model_dir/$exp_name.avg91-100.adapt/avg91-100.nnet.npz \
    $infer_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set
else
    echo "Skipped Stage 7"
fi

if [ $stage -le 8 ]; then
    echo ""
    echo "Stage 8: Adapt - Scoring"
    mkdir -p $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/.work
    find $infer_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set -iname *.h5 > $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/.work/file_list_$valid_set

    python3 $bin_dir/make_rttm.py --median=1 --threshold=0.3 --frame_shift=80 \
    --subsampling=10 --sampling_rate=8000 \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.3_1.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.3_1.rttm > \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/result_th0.3_med1_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=1 --threshold=0.4 --frame_shift=80 \
    --subsampling=10 --sampling_rate=8000 $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.4_1.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.4_1.rttm > \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/result_th0.4_med1_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=1 --threshold=0.5 --frame_shift=80 \
    --subsampling=10 --sampling_rate=8000 $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.5_1.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.5_1.rttm > \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/result_th0.5_med1_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=1 --threshold=0.6 --frame_shift=80 \
    --subsampling=10 --sampling_rate=8000 $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.6_1.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.6_1.rttm > \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/result_th0.6_med1_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=1 --threshold=0.7 --frame_shift=80 \
    --subsampling=10 --sampling_rate=8000 $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.7_1.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.7_1.rttm > \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/result_th0.7_med1_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=11 --threshold=0.3 --frame_shift=80 \
    --subsampling=10 --sampling_rate=8000 $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.3_11.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.3_11.rttm > \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/result_th0.3_med11_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=11 --threshold=0.4 --frame_shift=80 \
    --subsampling=10 --sampling_rate=8000 $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.4_11.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.4_11.rttm > \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/result_th0.4_med11_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=11 --threshold=0.5 --frame_shift=80 \
    --subsampling=10 --sampling_rate=8000 $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.5_11.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.5_11.rttm > \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/result_th0.5_med11_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=11 --threshold=0.6 --frame_shift=80 \
    --subsampling=10 --sampling_rate=8000 $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.6_11.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.6_11.rttm > \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/result_th0.6_med11_collar0.25 \
    2>/dev/null

    python3 $bin_dir/make_rttm.py --median=11 --threshold=0.7 --frame_shift=80 \
    --subsampling=10 --sampling_rate=8000 $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/.work/file_list_$valid_set \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.7_11.rttm

    md-eval.pl -c 0.25 -r $eval_dir/$valid_set/rttm \
    -s $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/hyp_0.7_11.rttm > \
    $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set/result_th0.7_med11_collar0.25 \
    2>/dev/null
else
    echo "Skipped Stage 8"
fi

if [ $stage -le 9 ]; then
    echo ""
    echo "Stage 9: Obtaining best scores"
    utils/best_score.sh $scoring_dir/$exp_name.avg91-100.adapt.avg91-100.infer/$valid_set
else
    echo "Skipped Stage 9"
fi

echo "Finished!"

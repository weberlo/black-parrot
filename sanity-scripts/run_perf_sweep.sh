#!/usr/bin/env bash

# exit after any errors
set -e

email_address='loganrweber@gmail.com'
function on_exit {
  mail -s 'Test Script Finished Execution' "$email_address"
  # ring bell
  echo -e '\a'
  # kill all child processes
  pkill -P $$
}
trap on_exit EXIT

timestamp=$(date +"%y-%m-%d-%H-%M")

script_dir="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

declare -a sat_sizes=(1 2 3 4 5 6)

function bleach_all {
  cd "${script_dir}/../../ee477-chip"
  make bleach_all
}

function prep_rtl_hard {
  cd "${script_dir}/../../ee477-chip"
  # we never need to bleach memgen, because we're not creating new memories
  make memgen
}

function prep_post_synth {
  cd "${script_dir}/../../ee477-chip"
  make synth
}

function prep_post_pnr {
  prep_post_synth_pid="$1"
  # wait for post-synth to finish before we do PnR.
  # we can't use `wait`, because it's not a child process; it's a sibling
  while [ -e "/proc/${prep_post_synth_pid}" ]; do sleep 0.1; done

  cd "${script_dir}/../../ee477-chip"
  make chip_finish
  make icc_output
}

function run_single_test {
  sim_target="$1"
  sat_size="$2"

  base_report_dir="${script_dir}/sat-counter-reports/${timestamp}"

  cd "${script_dir}/../bp_top/syn"
  rm reports/verilator/bp_softcore.e_bp_single_core_cfg.regress.list.sc.rpt

  curr_report_dir="${base_report_dir}/${sim_target}"
  mkdir -p "${curr_report_dir}"
  curr_report_path="${curr_report_dir}/${sat_size}-bit-sat.rpt"

  if [ "${sim_target}" == "rtl" ]; then
   make -j4 regress.list.sc LIST=baseline_regress.lst
  elif [ "${sim_target}" == "rtl-hard" ]; then
   make -j4 regress.list.sc LIST=baseline_regress.lst RTL_HARD=1
  elif [ "${sim_target}" == "post-synth" ]; then
   make -j4 regress.list.sc LIST=baseline_regress.lst POST_SYNTH=1
  elif [ "${sim_target}" == "post-pnr-func" ]; then
   make -j4 regress.list.sc LIST=baseline_regress.lst POST_PNR_FUNC=1
  elif [ "${sim_target}" == "post-pnr-time" ]; then
   make -j4 regress.list.sc LIST=baseline_regress.lst POST_PNR_TIME=1
  else
   echo "invalid sim target: ${sim_target}"
   exit 1
  fi

  cat reports/verilator/bp_softcore.e_bp_single_core_cfg.regress.list.sc.rpt
  cp reports/verilator/bp_softcore.e_bp_single_core_cfg.regress.list.sc.rpt "${curr_report_path}"
}

function test_sat_size {
  sat_size="$1"
  echo "[Sat Size == ${sat_size}]"

  cd "${script_dir}/.."
  sed -i "s/localparam saturation_size_p = [0-9]\+/localparam saturation_size_p = ${sat_size}/" bp_fe/src/v/bp_fe_bht.v

  base_report_dir="${script_dir}/sat-counter-reports/${timestamp}"
  mkdir -p "${base_report_dir}"

  # we start by kicking off different stages of the CAD flow in the background,
  # so we don't need to wait as long for the rtl_hard, post_synth,
  # post_pnr_func, and post_pnr_time targets when we reach them
  bleach_all
  prep_rtl_hard &
  prep_rtl_hard_pid="$!"
  prep_post_synth &
  prep_post_synth_pid="$!"
  prep_post_pnr "$prep_post_synth_pid" &
  prep_post_pnr_pid="$!"

  #######
  # RTL #
  #######
  run_single_test rtl "${sat_size}"

  ############
  # RTL_HARD #
  ############
  echo "waiting on rtl-hard prep (PID=$prep_rtl_hard_pid)"
  wait "$prep_rtl_hard_pid"

  run_single_test rtl-hard "${sat_size}"

  ##############
  # POST_SYNTH #
  ##############
  echo "waiting on post-synth prep (PID=$prep_post_synth_pid)"
  wait "$prep_post_synth_pid"

  run_single_test post-synth "${sat_size}"

  #################
  # POST_PNR_FUNC #
  #################
  echo "waiting on $prep_post_pnr_pid"
  wait "$prep_post_pnr_pid"

  run_single_test post-pnr-func "${sat_size}"

  #################
  # POST_PNR_TIME #
  #################
  run_single_test post-pnr-time "${sat_size}"
}

for sat_size in "${sat_sizes[@]}"
do
  test_sat_size "$sat_size"
done

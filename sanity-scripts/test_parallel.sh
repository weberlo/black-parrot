#!/usr/bin/env bash

function on_exit {
  #mail -s 'Test Script Finished Execution' "$email_address"
  # ring bell
  echo -e '\a'
  pkill -P $$
}
trap on_exit EXIT

function prep_rtl_hard {
  echo "prepping rtl hard"
  sleep 1
  echo "finished prepping rtl hard"
}

function prep_post_synth {
  echo "prepping post synth"
  sleep 2
  echo "finished prepping post synth"
}

function prep_post_pnr {
  prep_post_synth_pid="$1"
  # wait for post-synth to finish before we do PnR.
  # we can't use `wait`, because it's not a child process; it's a sibling
  while [ -e "/proc/${prep_post_synth_pid}" ]; do sleep 0.1; done
  echo "prepping post pnr"
  sleep 2
  echo "finished prepping post pnr"
}

prep_rtl_hard &
prep_rtl_hard_pid="$!"
prep_post_synth &
prep_post_synth_pid="$!"
prep_post_pnr "$prep_post_synth_pid" &
prep_post_pnr_pid="$!"

echo "waiting on $prep_rtl_hard_pid"
wait "$prep_rtl_hard_pid"
echo "waiting on $prep_post_synth_pid"
wait "$prep_post_synth_pid"
echo "waiting on $prep_post_pnr_pid"
wait "$prep_post_pnr_pid"

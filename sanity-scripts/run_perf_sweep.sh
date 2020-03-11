#!/usr/bin/env bash

script_dir="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd "$script_dir"

if [ -z "$1" ]
then
    echo "no argument supplied"
    exit 1
fi

report_loc="${script_dir}/sat-counter-reports/rtl/${1}.rpt"

if [ -f "${report_loc}" ]
then
    echo "file ${report_loc} already exists"
    exit 1
fi

cd ../black-parrot/bp_top/syn
make -j4 regress.list.sc LIST=baseline_regress.lst
cat reports/verilator/bp_softcore.e_bp_single_core_cfg.regress.list.sc.rpt

cp reports/verilator/bp_softcore.e_bp_single_core_cfg.regress.list.sc.rpt "${report_loc}"

# ring bell
echo -e '\a'

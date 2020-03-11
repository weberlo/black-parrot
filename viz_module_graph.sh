#!/usr/bin/env bash

script_dir="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

python gen_module_graph.py | dot -Tsvg >module.svg

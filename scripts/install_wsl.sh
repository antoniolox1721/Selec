#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y \
  python3 \
  python3-pip \
  git \
  octave \
  gnuplot \
  build-essential

python3 -m pip install --user --upgrade pip
python3 -m pip install --user PySide2 requests

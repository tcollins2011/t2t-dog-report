#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="./data"  
ROOT="/data/mschatz1/t2t-dogs/2025.07.17.Zeke/HiFi"

dogs=(Appa Molly Noodle Orfhlaith Pandan Zeke)

mkdir -p "$DATA_DIR"

for DOG in "${dogs[@]}"; do
  doglc=$(echo "$DOG" | tr 'A-Z' 'a-z')
  src="${ROOT}/${DOG}/${DOG}.asm.bp.p_ctg.fa.lens"
  dest="${DATA_DIR}/${doglc}_primary.fa.lens"

  if [[ -r "$src" ]]; then
    ln -sf "$src" "$dest"
    echo "linked: $dest -> $src"
  else
    echo "WARN: missing $src" >&2
  fi
done

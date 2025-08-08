#!/usr/bin/env bash
set -euo pipefail

# ----------------------------- CONFIG ---------------------------------- #
DOGS=(Appa Molly Noodle Orfhlaith Pandan Zeke)

# Fixed root for every dog, as requested:
ROOT_BASE="/data/mschatz1/t2t-dogs/2025.07.17.Zeke/HiFi"

# Panagram run directory (adjust if yours differs)
PANAGRAM_RUN="/data/mschatz1/tcolli32/panagram/t2t_dogs"

# Report project dirs (run this script from your Quarto project root)
REPORT_ROOT="$(pwd)"
ASSETS="$REPORT_ROOT/assets"
DATA="$REPORT_ROOT/data"
mkdir -p "$ASSETS" "$DATA"

# Tool-specific subpaths / filenames
RAGTAG_SUB="ragtag"
RAGTAG_OUTS=(primary_scaffold hap1_scaffold hap2_scaffold)
RAGTAG_FASTA="ragtag.scaffold.fasta"
RAGTAG_STATS="ragtag.scaffold.fasta.stats"

LIFTOFF_SUB="liftoff"
LIFTOFF_SCAFFS=(hap1_scaffold hap2_scaffold)

# (Re)initialize summary TSVs
: > "$DATA/assemblies.tsv"
: > "$DATA/ragtag_stats.tsv"
: > "$DATA/liftoff_summary.tsv"

# Headers
echo -e "dog\tassembly\tcontigs\tlength_bp\tn50_bp\tmax_bp\tmean_bp" >> "$DATA/assemblies.tsv"
echo -e "dog\tscaffold_set\tstat_key\tstat_value"                   >> "$DATA/ragtag_stats.tsv"
echo -e "dog\thaplotype\tgenes_mapped\ttranscripts_mapped\texons_mapped\tunmapped_genes" >> "$DATA/liftoff_summary.tsv"

for DOG in "${DOGS[@]}"; do
  DOGDIR="${ROOT_BASE}/${DOG}"
  if [[ ! -d "$DOGDIR" ]]; then
    echo "WARN: missing $DOGDIR, skipping $DOG" >&2
    continue
  fi

  DEST="$ASSETS/${DOG}"
  mkdir -p "$DEST/hifiasm" "$DEST/ragtag" "$DEST/liftoff"

  echo "-- ${DOG}"

  # --------------------- HIFIASM: assemblies & stats -------------------- #
  for base in "$DOGDIR/${DOG}.asm.bp.p_ctg" \
              "$DOGDIR/${DOG}.asm.bp.hap1.p_ctg" \
              "$DOGDIR/${DOG}.asm.bp.hap2.p_ctg"; do
    bn="$(basename "$base")"  # e.g., Zeke.asm.bp.hap1.p_ctg
    for ext in fa fa.fai fa.lens fa.stats fa.stats.flat gfa; do
      [[ -r "${base}.${ext}" ]] && ln -sfn "${base}.${ext}" "$DEST/hifiasm/${bn}.${ext}"
    done

    # Append to assemblies.tsv if stats exist (expects num/sum/n50/max/mean)
    if [[ -r "${base}.fa.stats.flat" ]]; then
      asm_label=$(echo "$bn" | sed -E 's/^.*\.bp\.//')  # pctg | hap1.p_ctg | hap2.p_ctg
      num=$(awk '$1=="num"{print $2}'  "${base}.fa.stats.flat")
      sum=$(awk '$1=="sum"{print $2}'  "${base}.fa.stats.flat")
      n50=$(awk '$1=="n50"{print $2}'  "${base}.fa.stats.flat")
      max=$(awk '$1=="max"{print $2}'  "${base}.fa.stats.flat")
      mean=$(awk '$1=="mean"{print $2}' "${base}.fa.stats.flat")
      echo -e "${DOG}\t${asm_label}\t${num}\t${sum}\t${n50}\t${max}\t${mean}" >> "$DATA/assemblies.tsv"
    fi
  done

  # ----------------------- RAGTAG: scaffolds/stats ---------------------- #
  for set in "${RAGTAG_OUTS[@]}"; do
    SDIR="$DOGDIR/$RAGTAG_SUB/$set"
    if [[ -d "$SDIR" ]]; then
      mkdir -p "$DEST/ragtag/$set"
      for f in "$RAGTAG_FASTA" "$RAGTAG_STATS" ragtag.scaffold.agp; do
        [[ -r "$SDIR/$f" ]] && ln -sfn "$SDIR/$f" "$DEST/ragtag/$set/$f"
      done

      if [[ -r "$SDIR/$RAGTAG_STATS" ]]; then
        while read -r line; do
          for tok in $line; do
            key="${tok%%=*}"
            val="${tok#*=}"
            if [[ "$key" != "$val" && -n "$key" && -n "$val" ]]; then
              echo -e "${DOG}\t${set}\t${key}\t${val}" >> "$DATA/ragtag_stats.tsv"
            fi
          done
        done < "$SDIR/$RAGTAG_STATS"
      fi
    fi
  done

  # -------------------------- LIFTOFF outputs --------------------------- #
  for hap in "${LIFTOFF_SCAFFS[@]}"; do
    LDIR="$DOGDIR/$LIFTOFF_SUB/$hap"
    [[ -d "$LDIR" ]] || continue
    mkdir -p "$DEST/liftoff/$hap"

    gff=$(ls -1 "$LDIR"/*.gff3 2>/dev/null | head -n1 || true)
    unm=$(ls -1 "$LDIR"/*unmapped*.txt 2>/dev/null | head -n1 || true)
    [[ -n "$gff" ]] && ln -sfn "$gff" "$DEST/liftoff/$hap/$(basename "$gff")"
    [[ -n "$unm" ]] && ln -sfn "$unm" "$DEST/liftoff/$hap/$(basename "$unm")"

    genes=0; tx=0; exons=0; unmapped=0
    if [[ -n "$gff" ]]; then
      genes=$(awk 'BEGIN{FS="\t"} $3=="gene"{c++} END{print c+0}' "$gff")
      tx=$(awk 'BEGIN{FS="\t"} $3=="transcript"||$3=="mRNA"{c++} END{print c+0}' "$gff")
      exons=$(awk 'BEGIN{FS="\t"} $3=="exon"{c++} END{print c+0}' "$gff")
    fi
    [[ -n "$unm" && -r "$unm" ]] && unmapped=$(grep -v '^\s*$' "$unm" | wc -l | awk '{print $1}')
    echo -e "${DOG}\t${hap}\t${genes}\t${tx}\t${exons}\t${unmapped}" >> "$DATA/liftoff_summary.tsv"
  done

done

# ----------------------------- PANAGRAM --------------------------------- #
if [[ -r "$PANAGRAM_RUN/genome_dist.tsv" ]]; then
  ln -sfn "$PANAGRAM_RUN/genome_dist.tsv" "$DATA/genome_dist.tsv"
  echo "Linked Panagram genome distances -> data/genome_dist.tsv"
else
  echo "NOTE: Panagram genome_dist.tsv not found at $PANAGRAM_RUN (skip link)"
fi

if [[ -d "$PANAGRAM_RUN/anchor" ]]; then
  mkdir -p "$ASSETS/panagram_anchor"
  find "$PANAGRAM_RUN/anchor" -maxdepth 2 -name chrs.tsv -print0 | \
    while IFS= read -r -d '' f; do
      sname="$(basename "$(dirname "$f")")"
      ln -sfn "$f" "$ASSETS/panagram_anchor/${sname}.chrs.tsv"
    done
fi

echo
echo "Done. Collected:"
echo "  - assets/<dog>/{hifiasm,ragtag,liftoff}/"
echo "  - data/assemblies.tsv, data/ragtag_stats.tsv, data/liftoff_summary.tsv"
[[ -L "$DATA/genome_dist.tsv" ]] && echo "  - data/genome_dist.tsv (Panagram)"

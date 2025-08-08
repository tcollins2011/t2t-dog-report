#!/bin/sh
# ---------- edit if paths change --------------------------------------------
DOG_ROOT_BASE="/home/tcolli32/t2t-dogs/2025.07.17.Zeke/HiFi"
QPROJ_DATA="/home/tcolli32/data_mschatz1/tcolli32/quarto/t2t-dogs-report/data/scaffold"
# ---------------------------------------------------------------------------

mkdir -p "$QPROJ_DATA"

for DOG in Appa Molly Noodle Orfhlaith Pandan Zeke; do
    DOG_CAP=$(printf '%s\n' "$DOG" | sed 's/^./\U&/')
    BASE="$DOG_ROOT_BASE/${DOG_CAP}/ragtag"

    for SCAF in primary_scaffold hap1_scaffold hap2_scaffold; do
        [ -d "$BASE/$SCAF" ] || { echo "Skip $DOG $SCAF (missing)"; continue; }

        fasta="$BASE/$SCAF/ragtag.scaffold.fasta"
        stats="$BASE/$SCAF/ragtag.scaffold.fasta.stats"
        lens="$BASE/$SCAF/ragtag.scaffold.fasta.lens"

        # create .lens once
        if [ ! -s "$lens" ] && [ -s "$fasta" ]; then
            echo "Generating .lens for $DOG $SCAF …"
            awk '
                /^>/     { if(len) {print len}; len=0; next }
                          { len += length($0) }
                END      { print len }
            ' "$fasta" | sort -nr > "$lens"
        fi

        # link into Quarto project
        asm_tag=$(echo "$SCAF" | sed 's/_scaffold//')   # -> primary / hap1 / hap2
        ln -sf "$fasta" "$QPROJ_DATA/${DOG_CAP}_${asm_tag}.scaf.fa"
        ln -sf "$lens"  "$QPROJ_DATA/${DOG_CAP}_${asm_tag}.scaf.fa.lens"
        ln -sf "$stats" "$QPROJ_DATA/${DOG_CAP}_${asm_tag}.scaf.stats.tsv"
    done
done

echo "✓ Scaffold links ready in $QPROJ_DATA"



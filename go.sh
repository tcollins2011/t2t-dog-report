# mkdir -p data/tmp

# # GeneID → GO
# wget -qO- https://ftp.ncbi.nih.gov/gene/DATA/gene2go.gz | gunzip -c \
#   | awk -F'\t' 'BEGIN{OFS="\t"} NR>1 && $1==9615 {print $2,$3}' \
#   > data/tmp/canFam_gene2go.tsv     # GeneID\tGO

# # GeneID ↔ symbol
# wget -qO- https://ftp.ncbi.nih.gov/gene/DATA/gene_info.gz | gunzip -c \
#   | awk -F'\t' 'BEGIN{OFS="\t"} NR>1 && $1==9615 {print $2,$3}' \
#   > data/tmp/canFam_geneid2sym.tsv  # GeneID\tSymbol

sort -k1,1 data/tmp/canFam_geneid2sym.tsv  > data/tmp/sym.sorted
sort -k1,1 data/tmp/canFam_gene2go.tsv     > data/tmp/go.sorted

join -t $'\t' data/tmp/sym.sorted data/tmp/go.sorted \
| awk -F'\t' 'BEGIN{OFS="\t"} {print $2,$3}' \
> data/ref_gene2go.tsv

# rm -r data/tmp
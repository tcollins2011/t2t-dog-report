ROOT=/home/tcolli32/t2t-dogs/2025.07.17.Zeke/HiFi      

for DOG in Appa Molly Noodle Orfhlaith Pandan Zeke; do
  for ASM in hap1_scaffold hap2_scaffold; do
    src="${ROOT}/${DOG}/liftoff/${ASM}/${DOG}_${ASM}_unmapped.txt"
    dst="./${DOG}_${ASM}_unmapped.txt"
    ln -sf "$src" "$dst"
  done
done

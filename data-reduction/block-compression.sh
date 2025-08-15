#!/usr/bin/env -S zsh -d

set -x

local pattern_size=1024 # 16, 32, ... 8192
local to_8k=$((8192 / $pattern_size)) # number of times to repeat pattern_size to get 8k

# create the pattern
dd if=/dev/urandom of=pattern.bin bs=$pattern_size count=1 iflag=fullblock

# create 8k
for i in {1..$to_8k}; do
  dd if=pattern.bin of=8k.bin bs=$pattern_size iflag=fullblock count=1 oflag=append conv=notrunc
done

# create 8g
cp 8k.bin curr.bin
for i in {1..20}; do
  dd if=curr.bin of=next.bin bs=8K iflag=fullblock oflag=append conv=notrunc
  dd if=curr.bin of=next.bin bs=8K iflag=fullblock oflag=append conv=notrunc
  mv next.bin curr.bin
done
mv curr.bin 8g.bin

# duplicate across disks
for d in {1..8}; do
  dd if=8g.bin of=/mnt/test-disks/$d/8g.bin bs=4K iflag=fullblock &
done
wait

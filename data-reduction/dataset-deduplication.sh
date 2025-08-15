#!/usr/bin/env -S zsh -d -f -i

set -x
local target_disks=(1 2 3) # target disks to copy to

# download the dataset
apt update && apt install unzip curl -y
curl -L -o ./flightprices.zip https://www.kaggle.com/api/v1/datasets/download/dilwong/flightprices
unzip ./flightprices.zip

# duplicate across disks
for d in $target_disks; do
  cp ./itineraries.csv /mnt/test-disks/$d/itineraries.csv &
done
wait
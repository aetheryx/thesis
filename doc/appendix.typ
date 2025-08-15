#import "@preview/codly:1.3.0": *
#import "lib/setup.typ": setup
#show: setup

#set heading(outlined: false)

= Appendix
#set heading(numbering: (..nums) => {
   numbering("A:", ..nums.pos().slice(1))
})
== Supplementary Repository <git_repo>
The GitHub repository for this thesis (#link("https://github.com/aetheryx/thesis")[github.com/aetheryx/thesis]) provides various supplementary files for reference, including the advanced data aggregation scripts, data visualisations and statistical analysis, and the content of this research paper.

== PD Storage Class <k8s_pdsc>
#codly(header: align(center)[*persistent-disk.StorageClass.yaml*])
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: persistent-disk
parameters:
  type: pd-ssd # Specifies the Persistent Disk type for the cloud provider
```

== PD PVC <k8s_pdpvc>
#codly(header: align(center)[*my-pvc.PersistentVolumeClaim.yaml*])
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  storageClassName: persistent-disk # Refers to the storage class above
  resources:
    requests:
      storage: 256 GiB # Creates a 256 GiB disk
```

== HD Storage Class <k8s_hdsc>
#codly(header: align(center)[*hyperdisk.StorageClass.yaml*])
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: hyperdisk
parameters:
  type: hyperdisk-balanced
  provisioned-iops-on-create: "3000"
  provisioned-throughput-on-create: "140Mi"
```

== HD Storage Class Pool <k8s_hdsc_pool>
#codly(header: align(center)[*hyperdisk.StorageClass.yaml*])
```diff
 parameters:
   type: hyperdisk-balanced
+  storage-pool: "projects/hva/zones/europe-west/storagePools/my-pool"
```

== Creating a pool <gcloud_pool>
#codly(header: align(center)[*create-pool.sh*])
```bash
gcloud compute storage-pools create "my-pool" \
    --project=hva --zone=europe-west4 \
    --storage-pool-type=hyperdisk-balanced \
    --provisioned-capacity=10240 # Capacity in GiB
```

== PVC change <pvc_change>
#codly(header: align(center)[*my-pvc.PersistentVolumeClaim.yaml*])
```diff
 spec:
-   storageClassName: persistent-disk
+   storageClassName: hyperdisk
```


== FIO Base configuration <appendix_fio>
These configuration parameters are applied to all `fio` executions for this research.
#codly(header: align(center)[*fio-base.ini*])
```ini
[global]
# The directory where `fio` writes files
directory = /home/user/fio 

# The I/O engine FIO uses for operations
# `libaio` is the Linux-native async I/O engine
ioengine = libaio 

# Whether `fio` should connect disk utilization metrics
# Disabled as these are not relevant to this research
disk_util = 0

# Whether `fio` should collect various latency metrics
# Disabled as these are not relevant to this research
disable_lat = 1
disable_clat = 1
disable_slat = 1

# Whether I/O should be non-buffered
# Enabled as buffered I/O reduces the accuracy of results
direct = 1

# Whether written file contents should be verified after writes
# Disabled as this is not relevant to this research
verify = 0

# Various I/O depth related configuration settings
# Set to `256` as this allows us to measure IOPS sufficiently
iodepth = 256
iodepth_batch_submit = 256
iodepth_batch_complete_max = 256

# Whether data bandwidth should be measured
# Disabled as this research focuses on IOPS
disable_bw = 1
```

== FIO Finite amount
The following `fio` job file is used to write 4 GiB of randomized data:
#codly(header: align(center)[*fio-write.ini*])
```ini
[fio-write-4g]
# Describes the I/O pattern `fio` will execute the task with
rw = randwrite
# Describes the block size for each disk write operation
blocksize = 4K
# Describes the total size of the file to write
size = 4G
```

== FIO Indefinite amount
The following `fio` job file is used to write randomized data indefinitely, effectively simulating a noisy neighbor:
#codly(header: align(center)[*fio-noisy-neighbor.ini*])
```ini
[fio-noisy-neighbor]
# Describes a task to write an 8 GiB file
rw = randwrite
blocksize = 4K
size = 8G

# Configure the task to be time-based
# with a runtime of 1000 days (effectively indefinite)
# Under this configuration, `fio` simply wraps around to
# the start of the 8 GiB file when the end is reached
time_based = 1
runtime = 1000d
```

== Prometheus: Individual noisy neighbors <prom_disks>
This query selects individual disks that have a resource usage above 40.000 IOPS.
#codly(header: align(center)[*noisy-neighbors.promql*])
```promql
sum by (device_name) (
  max_over_time(
    instance_disk_max_write_ops_count{
      zone="europe-west4-c",
      device_name=~"pvc-.*",
    }[$__interval]
  )
) > 40000
```

== Prometheus: Any noisy neighbors <prom_flat>
This query returns a flattened metric that returns a high signal when noisy neighbors were observed, and a low signal when no noisy neighbors were observed.
#codly(header: align(center)[*noisy-neighbors.promql*])
```promql
(count(
  sum by (device_name) (
    max_over_time(
      instance_disk_max_write_ops_count{
        zone="europe-west4-c",
        device_name=~"pvc-.*"
      }[$__interval]
    )
  ) > 40000
) * vector(0)) + vector(1)
or vector(0)
```

== Bazel output directories <bazel_out>
The configuration for all minimally impacted monorepos is as follows:
```bash
$ bazel info output_base
"/home/user/.cache/bazel/_bazel_user/b97476"
$ findmnt -T $(bazel info output_base)
TARGET                  SOURCE
/home/user/.cache/bazel /dev/md0
```

And the configuration for the Java monorepo is as follows:
```bash
$ bazel info output_base
"/home/user/.java_bazelcache/workspace/156927"
$ findmnt -T $(bazel info output_base)
TARGET     SOURCE
/home/user /dev/nvme0n5
```

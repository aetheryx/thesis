#import "@preview/codly:1.3.0": *
#import "setup.typ": setup
#show: setup

#set heading(outlined: false)

= Appendix
== FIO commands <appendix_fio>
=== Base configuration
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
# Disabled as these are not relevant to our research
disk_util = 0

# Whether `fio` should collect various latency metrics
# Disabled as these are not relevant to our research
disable_lat = 1
disable_clat = 1
disable_slat = 1

# Whether I/O should be non-buffered
# Enabled as buffered I/O reduces the accuracy of results
direct = 1

# Whether written file contents should be verified after writes
# Disabled as this is not relevant to our research
verify = 0

# Various I/O depth related configuration settings
# Set to `256` as this allows us to measure IOPS sufficiently
iodepth = 256
iodepth_batch_submit = 256
iodepth_batch_complete_max = 256

# Whether data bandwidth should be measured
# Disabled as our research focuses on IOPS
disable_bw = 1
```

=== Writing a finite amount of randomized data
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

=== Writing randomized data indefinitely
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
# Under this configuration, `fio` will simply wrap around to
# the start of the 8 GiB file when the end is reached
time_based = 1
runtime = 1000d
```

== Prometheus queries 
=== Measuring individual noisy neighbors <prom_disks>
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

=== Measuring occurrences of any noisy neighbors <prom_flat>
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

#import "lib/setup.typ": setup
#show: setup

= Disk capacity utilization <disk_cap>
== Introduction
This section answers the _"How do Hyperdisk Storage Pools affect disk capacity utilization compared to Persistent Disks?"_ sub-question. As previously mentioned, the investigated application is Uber's cloud development environment. These environments are provisioned with various resources such as CPUs, RAM, GPUs and storage.

Across these resources, a significant part of the cost is attributed to storage. As mentioned in @storage_pooling, the cloud provider offers the concept of "storage pools" using Hyperdisks. These storage pools claim to improve storage utilization through various methods, potentially leading to significant improvements in capacity utilization for Uber's CDEs. In this chapter, the efficiency and technical details of these storage pools are investigated through a number of experiments.

== Disk utilization
=== Problem context
Each of Uber's CDEs is provisioned with 256 GiB of storage capacity by default. However, the utilization of this capacity is quite low: on average, each CDE only uses approximately 30% of its provisioned storage. The reason for this is that Uber's CDEs are optimized for peak capacity: in the event that a user requires additional storage, resizing an existing disk is a disruptive operation, requiring a restart of the CDE. Despite optimizing for peak capacity being necessary, the current utilization of 30% is a major cost inefficiency.

=== Thin provisioning
The first advantage of storage pools aims to address this problem. Storage pools provide a _thin provisioning_ strategy, where capacity is allocated in a virtual manner #cite(<gcp-hd-pool-intro>). For example, if a CDE is provisioned with a 256 GiB disk, the operating system will observe 256 GiB of available capacity, but the underlying storage pool will not mark any capacity as in-use until the storage is utilized (i.e. bytes are written to the disk). Effectively, thin provisioning allows for overprovisioned capacity: it allows the system to provision more capacity than what is physically available.

While thin provisioning significantly improves utilization, there are constraints to be aware of. A direct consequence of overprovisioning is the fact that provisioned storage may not be physically available as utilization grows. Suppose that 100 CDEs are provisioned with 256 GiB of capacity each, totaling 25 TiB of provisioned capacity, and the average utilization across the CDEs is 20%. In this case, only 5 TiB of storage is utilized, meaning a storage pool with 5 TiB of physically provisioned capacity would fit. However, when the utilization of the CDEs grows, there would not be any physical storage available, causing disk operations to fail. In this scenario, the storage pool will automatically provision additional physical storage. As this is not an instant operation, it is recommended to configure an autoscaling utilization target: this target percentage defines when the storage pool automatically provisions additional capacity. For example, with a utilization target of 90%, the storage pool will have time to provision the additional capacity, reducing the likelihood of disruptions. 

=== Selected configuration
Considering these requirements, the planned capacity for Uber's CDE system using thin provisioning is calculated as follows.

Firstly, the current total provisioned capacity is calculated. For the purpose of this research, this is defined hypothetically. In this hypothetical scenario, Uber currently provisions 1000 CDEs with 256 GiB each, totaling 500 TiB provisioned. 

Secondly, the current average utilization for Uber's CDEs is calculated using disk utilization metrics. This utilization is 28,35%. 

Thirdly, an appropriate autoscaling utilization target is defined. The cloud provider suggests a utilization target of 90%. One could argue that this utilization target can be optimized further, considering that Uber's CDEs operate at a large scale, making it unlikely that individual CDEs could cause utilization spikes significant enough to cause disruptions. However, the impact of these disruptions would be significant for Uber's CDEs, as they are considered a critical service. Therefore, the suggested utilization target of 90% remains appropriate.

The new capacity using thin provisioning is calculated as follows: 

$C_"new" = C_"old" dot U dot (100) / T$ 

where $C_"old"$ is the current provisioned capacity, $U$ is the current utilization, and $T$ is the autoscaling utilization target.

Calculating these values for Uber's scenario yields the following planned capacity:\
$C_"new" = 500 "TiB" dot 28","35% dot 100 / 90$\
$C_"new" = 141","75 "TiB" dot 100 / 90$\
$C_"new" = 157","5 "TiB"$

Effectively, thin provisioning allows Uber to reduce their total provisioned capacity from 500 TiB to 157,5 TiB, which is a reduction of 68,5%. 

== Data reduction
=== Problem context
Utilization aside, another characteristic of Uber's CDEs is duplicate data. As previously mentioned, Uber has adopted the concept of monorepos, which are a development strategy where multiple projects are located within the same repository. These monorepos can grow to over 40 GiB in size, and each CDE is pre-configured with a monorepo cloned, meaning the same large monorepos are stored across thousands of disks.

Storage pools claim to offer data reduction capabilities, which could potentially improve the data duplication introduced by large monorepos. However, Google's documentation on the topic significantly lacks detail: it broadly states that storage pools use a variety of data reduction technologies, with no concrete details on what these data reduction technologies are, nor how they work #cite(<gcp-hd-pool-features>). 

Therefore, this section aims to further investigate Google's claims. Specifically, two common data reduction technologies are investigated: the first being block-level compression, and the second being file-based deduplication. In addition to the experiments, an evaluation is performed using real-world data from Uber's CDEs, in order to provide a realistic estimation for the data reduction ratio for Uber's application.

=== Block-level Compression
Linux-based filesystems organize data in fixed-size _blocks_ of bytes, where the most common block size is 4096 bytes #cite(<linux-foundation-2025>). Block-level compression operates within individual blocks: meaning, small repeating patterns that occur within the same block yield the most benefit. Block-level compression is well-supported by a number of modern Linux filesystems, such as ZFS #cite(<zhang-2010>) and BTRFS #cite(<li-2016>). 

In order to determine whether Hyperdisk Storage Pools implement block-level compression, an experiment was performed. The goal of the experiment is to measure the data reduction ratio across varying levels of data repetition at the block level. More specifically, each iteration of the experiment generates a repeating pattern of randomized bytes of a specific size, and then repeats this pattern to fill an 8 GiB file. This 8 GiB file is then duplicated across 8 disks in the pool (totaling $8 "GiB" dot 8 = 64 "GiB"$). Each iteration of the experiment is performed with a different size for the repeating pattern, specifically the powers-of-two from $2^4$ (16) to $2^13$ (8192). 

The results of the experiment are visualised as follows:
#figure(
  image("images/block-comp.png", width: 115%),
  caption: [Data reduction ratio with varying size of a randomized repeating pattern]
)

These results clearly indicate that Hyperdisk Storage Pools apply block-level compression. Firstly, observe that for the pattern sizes of 4096 and 8192 bytes, no data reduction is observed. This implies that the underlying file system is configured with a block size of 4096 bytes, as there is no compression when the source pattern exceeds 4096 bytes. Secondly, observe that the data reduction ratio approximately scales with the amount of times the pattern fits in the block size. More specifically, the compressed size consistently follows the theoretical compressed size based on the block-to-pattern ratio, plus 1 GiB:

#figure(
  table(
    columns: 4,
    [Pattern size], [Block-pattern ratio], [Theoretical compressed size], [Actual compressed size],
    [64], [64 (4096:64)], [1 GiB (64 GiB / 64)], [2.00 GiB],
    [128], [32 (4096:128)], [2 GiB (64 GiB / 32)], [3.00 GiB],
    [256], [16 (4096:256)], [4 GiB (64 GiB / 16)], [5.00 GiB],
    [512], [8 (4096:512)], [8 GiB (64 GiB / 8)], [9.00 GiB],
    [1024], [4 (4096:1024)], [16 GiB (64 GiB / 4)], [17.00 GiB],
    [2048], [2 (4096:2048)], [32 GiB (64 GiB / 2)], [33.00 GiB],
  ),
  caption: [Data reduction results with varying size of a randomized repeating pattern]
)

The exact reason for the additional 1 GiB is unknown, but not unexpected, nor relevant to overall conclusions drawn from the results.

=== Deduplication
As previously mentioned, block-based compression provides the ability to compress repeated patterns of data in a given 4096-byte source block. The primary restriction for block-based compression is that it operates exclusively within an individual block: it does not address data repetition across distinct blocks. Deduplication is a different data reduction strategy that does aim to solve repetition across distinct blocks. As an example, the BTRFS filesystem provides file-based deduplication and block-based deduplication #cite(<btrfs-contributors-2023>). 

The results from the block-level compression experiment indicate that it is unlikely that Hyperdisk Storage Pools apply deduplication. Recall that for the 8192-byte repeating pattern, there was no data reduction. If file-level deduplication was applied, data reduction would have been observed, as the same 8 GiB file was duplicated across 8 disks within the pool. If block-level deduplication was applied, data reduction would have been observed, as the same 8192-byte pattern was repeated into an 8 GiB file ($128 dot 1024 dot 8$ times).

However, the block-level compression experiment is highly synthetic. To confirm whether Hyperdisk Storage Pools apply deduplication, another experiment was performed, with the goal of simulating a more realistic scenario. In this experiment, a storage pool containing 6 disks was created, each provisioned with 32 GiB of capacity. A large open-source CSV dataset totaling 31.09 GB was selected as the test data (#link("https://www.kaggle.com/datasets/dilwong/flightprices")[flightprices.csv]). This dataset was downloaded to each of the disks one-by-one, and the storage pool utilization was measured in between each additional occurrence of the dataset.

The results of this experiment are as follows:
#figure(
  table(
    columns: 4,
    [Dataset instances], [Uncompressed size], [Compressed size], [Compression ratio],
    [1], [28.99 GiB], [12.58 GiB], [2.31:1],
    [2], [57.95 GiB], [25.15 GiB], [2.30:1],
    [3], [86.91 GiB], [37.72 GiB], [2.30:1],
    [4], [115.73 GiB], [50.25 GiB], [2.30:1],
    [5], [144.79 GiB], [62.86 GiB], [2.30:1],
    [6], [173.46 GiB], [75.31 GiB], [2.30:1],
  ),
  caption: [Compression ratio across increasing instances of 31 GiB dataset]
)


These results further confirm that Hyperdisk Storage Pools do not seem to apply deduplication. Observe that as the number of dataset instances increases, the compressed size grows linearly, meaning recurring data is not being deduplicated. Despite the lack of deduplication, the 2.31:1 compression ratio is still impressive for a real-world dataset.

=== Real-world evaluation
The two sections above have investigated the potential storage efficiency improvements using synthetic experiments. In addition to these synthetic experiments, the most accurate estimation for the improvements can be determined by provisioning a storage pool with copies of production instances of Uber's CDEs. Such an experiment is quite feasible, as Uber's CDE system creates automatic snapshots of provisioned disks, and these disks can be cloned into a new storage pool with a number of simple scripts.

For simplicity, this experiment was executed in only one datacenter of Uber's CDE infrastructure. Considering the amount of CDEs globally, the size of this set of CDEs can accurately represent the storage patterns for the entire fleet.

More specifically, the experiment executes the following steps:
+ Create a Hyperdisk Storage Pool in the same region as the datacenter
+ Select all running CDEs in the region that are older than 24 hours
+ For each CDE, select its most recent snapshot
+ From each of these snapshots, provision a Hyperdisk with the same capacity in the storage pool
+ Mount each of the disks to measure the amount of uncompressed bytes stored on the disks
+ Measure the amount of physical bytes in use by the storage pool

The results of this experiment are as follows:
#figure(
  table(
    columns: 2,
    [Previous total capacity], [187,75 TiB],
    [Sum of bytes written to disks], [57,72 TiB],
    [Physical bytes in use by the storage pool], [53,60 TiB],
    [Minimum storage pool size], [59,56 TiB]
  ),
  caption: [Results of production data evaluation],
)


From these results, the total capacity reduction yielded from Hyperdisk Storage Pools can be calculated. Without storage pooling, the total capacity of this set of CDEs is 187,75 TiB. When mounting each of the disks, 57,72 TiB of data written to the disks was observed. At the storage pool level, the amount of used capacity reported post-compression is 53,60 TiB, meaning that the data reduction resulted in an additional 7,13% reduction of capacity usage (1,08:1). Lastly, as the 53,60 TiB in use by the storage pool should be a 90% utilization target, the final storage pool size would be $53","60 dot 100/90 = 59","56 "TiB"$. Effectively, the total capacity reduction is $1 - (59,56)/(187,75) = 68","28%$. 

== Conclusion
An answer to the sub-question of this chapter, _"How do Hyperdisk Storage Pools affect disk capacity utilization compared to Persistent Disks?"_, can now be provided. In this chapter, two relevant Hyperdisk Storage Pool features were identified, and these features were thoroughly investigated through a number of experiments.

For the thin provisioning capabilities of Hyperdisk Storage Pools, a hypothetical scenario with a total capacity of 500 TiB, a utilization percentage of 28,35%, and an autoscaling utilization target of 90% was evaluated. This calculation predicted an approximate 68,5% reduction in total storage capacity for Uber's CDE fleet.

For the data reduction capabilities of Hyperdisk Storage Pools, a number of synthetic experiments were performed. The only data reduction technology that could be observed was block-level compression, with a block size of 4096 bytes. This compression proved to be efficient for large datasets, but unlikely to solve Uber's data duplication problems related to monorepos. 

Lastly, a subset of production CDEs was cloned and provisioned into a Hyperdisk Storage Pool, in order to approximate the real-world capacity reduction for Uber's CDE fleet. For this subset, Hyperdisk Storage Pools reduced the total purchased capacity from 187,75 TiB to 59,56 TiB, which is a 68,28% reduction. This observed reduction aligns with the expected reduction of 68,5% that was calculated before.

As mentioned in the introduction of this chapter, Uber's CDEs are provisioned with various components, including CPUs, RAM, GPUs and storage. A significant share of the total cost of these components is attributed to storage. Therefore, reducing the total purchased storage capacity by 68,28% would be a significant improvement in cost efficiency for Uber's CDEs.

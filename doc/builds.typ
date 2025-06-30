#import "@preview/codly:1.3.0": *
#import "setup.typ": setup
#show: setup

= Build performance
== Introduction
This chapter answers the _"How does migrating Uber's CDE from Persistent Disks to Hyperdisks affect the build duration of projects?"_ sub-question. As previously mentioned, the investigated application is Uber's cloud development environment, which was initially developed to improve the build performance of large-scale codebases compared to laptops. Therefore, build performance is considered one of the most relevant metrics to describe the overall performance of Uber's CDE's. In order to compare the build performance between Persistent Disks and Hyperdisks, we will perform an experiment measuring how long it takes to build projects across various disk configurations.

== Defining the experiment
As mentioned in the introduction of this paper, Uber has adopted the concept of monorepos, which are a development strategy where multiple projects are located within the same repository and form direct dependencies on each other. More specifically, Uber maintains a total of five monorepos supported by Uber's CDE, each of which holds projects in specific programming languages. The five supported monorepos are the Golang monorepo, the Java monorepo, the Web monorepo, the Python monorepo and the Android monorepo. When a CDE is created, it is preconfigured for one specific monorepo. Therefore, the goal of the experiment is to compare build performance between Persistent Disks and Hyperdisks, for all of the supported monorepos. 

=== CDE configurations
First, we define the specific disk configurations that will be compared in the experiment. 

The first configuration is the Persistent Disk configuration. For this configuration, we intentionally want to measure the resource pooling advantage of Persistent Disks described in @perf_prov. Specifically, we will provision a pool of 4 CDE's that each have a 256 GiB Persistent Disk, and only one of these CDE's will be used for measurement. By using the formulas defined in @perf_model, we can calculate the performance resources for this pool, which is 38.640 IOPS. Effectively, the Persistent Disk configuration is a CDE with a total resource pool of 38.640 IOPS.

The second configuration is the PD-equivalent Hyperdisk configuration. This configuration is allocated with the same per-disk performance as the Persistent Disk configuration, but without the advantage of resource sharing. Specifically, this is $38.640 / 4 = 9.660$ IOPS per disk. This configuration would be similar in cost to the Persistent Disk configuration. 

The third configuration is the minimum Hyperdisk configuration. This configuration is allocated with the minimum amount of performance resources that can be provisioned for an individual Hyperdisk, which is 3.000 IOPS per disk. This configuration allows us to identify when disk performance is a bottleneck for build performance. 

Other than the disk configuration, all other hardware parameters are identical. The virtual machines used are configured with the same underlying hardware specification. Each CDE is provisioned with 48 CPU cores and 96 GiB of RAM. 

In order to provision the CDE's with different disk configurations, we follow the instructions defined in @provisioning_hd.

In summary, we will evaluate three configurations: a Persistent Disk configuration with 38.640 IOPS, a PD-equivalent Hyperdisk configuration with 9.660 IOPS, and a minimum Hyperdisk configuration with 3.000 IOPS.

=== Project selection
It is not feasible to measure the build time of all projects in each monorepo. Therefore, we can only measure a subset of projects. Considering that there are five monorepos in total, selecting three projects per monorepo is a feasible amount to measure for this research. 

The selected subset must represent the projects in the monorepo with sufficient breadth. The selection criteria is defined as follows. First, the projects in each monorepo are sorted by an appropriate heuristic that represents their expected build duration. Then, the projects at each of the three quartiles are selected for measurement, meaning the projects at the 25th, 50th and 75th percentile sorted by the heuristic. 

Specifically, the chosen heuristic is the amount of transitive dependencies each project has. The reason this heuristic is appropriate is due to the nature of monorepos. Fundamentally, the relationship between targets in monorepos is a directed acyclic graph, where each node in the graph represents any necessary files for other targets to depend on #cite(<bazel-deps-dag>). Considering the final executable target of a project as a leaf node, this node will have direct dependencies on nodes containing the source files implementing the project. Other dependencies, such as libraries, are represented in the build graph as well. Therefore, the total amount of transitive dependencies of a project accurately represents it's size: it includes the implementation files of the project itself, as well as the dependencies of the project, and their dependencies, and so on.

In summary, we will select three projects in each monorepo, which are the projects at the 25th, 50th and 75th percentiles sorted by transitive dependency count per project.

=== Measurement process
As previously mentioned, the goal of the experiment is to compare the build duration between Hyperdisks and Persistent Disks, for each of the five monorepos supported by Uber. For each monorepo, we will select three projects for measurement.

It is important that we understand how the disk types affect build performance for each monorepo specifically: for example, the Golang monorepo might be affected by disk performance differently than the Web monorepo, as they are completely different languages that are compiled and executed differently. Further, it is not important that the differences within the three selected projects are analyzed, as the goal of the subset selection is to represent the monorepo as a whole. Considering these requirements, the experiment will yield one measurement for each combination of a monorepo and a disk configuration, where each measurement represents the average build time of that monorepo under that disk configuration.

\

Specifically, the measurement strategy is defined as follows:
+ In order to reduce the risk of abnormal measurements, each project is measured 10 times. Out of the 10 measurements, the median measurement is selected as the build time for this specific project.
+ The average of the three build times is calculated, representing the build time for this monorepo under a specific disk configuration.
+ These measurements are taken for each combination of monorepo and disk configuration. With 5 monorepos and 3 disk configurations, the experiment yields a total of $5 dot 3 = 15$ aggregated datapoints.

Additionally, the process to measure a single build execution is defined as follows:
+ Each build is performed on a freshly provisioned CDE, meaning there is no existing build cache.
+ Each CDE is checked out to the same revision of the monorepo, ensuring that the same source files are built and the same toolchain versions are used. 
+ Each build is performed in isolation, meaning all other CDE's in the pool are idle, and there are no other tasks running on the active CDE.
+ For each build, the remote dependencies in the target graph are pre-fetched. This ensures that our results do not rely on network performance, as the reliability of external package registries would influence our results incorrectly.
+ For each build, the measurement is taken using the `time` command-line tool found on most standard Linux systems.

== Results
The results of the experiment are visualised as follows:

#align(center)[#image("images/build_perf.png", width: 120%)]

From these results, there are a number of initial observations to make. Firstly, we observe that for the Golang, Web, Python and Android monorepos, build time is negligibly affected by Hyperdisks. Considering that the PD configuration has more than 10 times the IOPS as the minimum Hyperdisk configuration, this is an unexpected result. Secondly, we observe that the Java monorepo is affected by the reduction in IOPS, unlike the other monorepos. The remainder of this section elaborates on the root cause for these observations. 

=== Unaffected monorepos
First, let us investigate why the Golang, Web, Python and Android monorepos are minimally affected by the reduction in disk performance. As observed in the results above, the Golang and Web monorepos are nearly identical: for Golang, the Persistent Disk and PD-equivalent Hyperdisk configuration performed identically, and the minimum Hyperdisk configuration was 0.3% slower. In the Python and Android monorepos, the differences are slightly larger, with the Python monorepo observing degradations of 0.2% and 2.4% respectively, and the Android monorepo observing degradations of 1.2% and 1.5% respectively.

It is important to remember that this research focuses on the comparison between Persistent Disks and Hyperdisks, both of which are forms of network-attached storage. However, as mentioned in @both_disks, Uber's CDE's provision another type of disk as well: the locally-attached disk. As a reminder, locally-attached disks offer significantly more performance than network-attached disks, but locally-attached disks are ephemeral while network-attached disks are persisted. 

Recall from @both_disks that the locally-attached disk is used for the build output, and the network-attached disk is used to store the source code repository. Each of these disks serve specific purposes during a build. As the network-attached storage holds the contents of the repository, the source code files in the repository are read so that they can be compiled. And as the locally-attached storage holds the build outputs, compiled targets are written to the locally-attached storage, as well as being read from the locally-attached storage when they are consumed as a dependency.

This experiment compares different configurations of network-attached disks. In all three disk configurations, the same locally-attached disks were used to store the build output. In order to understand the relevance of both disks, we are able to use the `strace` Linux profiling tool to intercept the low-level system calls made by Bazel. We can then perform further analysis on the recorded system calls in order to quantify the relevance of each of the disks.

The following table describes an aggregated comparison of the disk-related system calls made, categorized by the disk type:
#table(
  columns: 4,
  [], [Network-attached], [Locally-attached], [Relative increase],
  [Files opened], [4.857], [91.339], [18,8x],
  [Sum of bytes read], [73,52 MiB], [8,21 GiB], [106,6x],
  [Sum of bytes written], [14,07 KiB], [2,67 GiB], [189.653,1x]
)

Comparing the locally-attached disk to the network-attached disk, we observe that there were over 100 times more bytes read, and nearly 190.000 times more bytes written. It is clear that during a build, the build output directory receives an order of magnitude more disk operations compared to the repository directory. This explains why the Golang, Web, Python and Android monorepos are minimally affected by the reduction in disk performance for the network-attached disk: this disk is simply not used nearly as much as the locally-attached disk that stores the build output, therefore minimally impacting the overall build performance.

=== The Java monorepo
The results of the experiment indicated that the Golang, Web, Python and Android were minimally impacted by the reduction in disk performance, but the Java monorepo did observe a considerable impact.

The previous section provided an answer for the minimally impact monorepos: those monorepos were minimally impacted because they were configured to use locally-attached disks for build outputs, making the network-attached disk less relevant. When investigating the directory configuration for the Java monorepo, we observe that it's configuration deviates. The configuration for all minimally impacted monorepos is as follows:
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

We observe that the other monorepos are configured to use the `~/.cache/bazel` directory for build outputs, and this directory is mounted on the `/dev/md0` block device, which is the locally-attached disk. However, the Java monorepo has overridden the build output directory to `~/.java_bazelcache`, and this directory is not mounted on the locally-attached disk. As it falls under the home directory, it is effectively using the network-attached disk `/dev/nvme0n5`. 

This deviation in the configuration for the Java monorepo explains why it is impacted by the reduction in disk performance: for the Java monorepo, the network-attached disk is utilized fully for the build output, meaning that the performance of the network-attached disk is much more relevant. In order to confirm this theory, we can configure the Java CDE's to mount the `~/.java_bazelcache` directory on the locally-attached disk. 

With this change in place, the build times for the Java monorepo are measured again and visualised as follows:
#align(center)[#image("images/build-java.png", width: 120%)]

With the improved configuration in place, we observe that the Java monorepo behaves the same way as the other monorepos: the reduction in disk performance does not affect build performance.

Whether the deviating configuration is intentional is uncertain. In the results above, we observe that the build performance for Persistent Disks had a minimal improvement in execution time, from 79 seconds to 77.7 seconds. Additionally, using the network-attached disk for build outputs provides the benefit of persisting the build cache across restarts of the CDE. Considering this benefit, and the fact that using network-attached storage for the build output did not result in a large performance improvement for the Java monorepo, it would seem feasible that the configuration was intentional. If Hyperdisks were to be adopted, the advantage of using the locally-attached disk for the build output would be more significant, as the locally-attached disk reduced the build duration from 102.9 seconds to 77.9 seconds under the minimum Hyperdisk configuration.

== Conclusion
We are now able to provide an answer to the sub-question of this chapter, _"How is build performance affected by migrating from Persistent Disks to Hyperdisks?"_. In this chapter, we performed an experiment comparing three disk configurations, namely a Persistent Disk configuration with 38.640 IOPS, a PD-equivalent Hyperdisk configuration with 9.660 IOPS, and a minimum Hyperdisk configuration with 3.000 IOPS. For each of the configurations, we measured the build time for each one of Uber's CDE-supported monorepos, namely the Go, Web, Python, Android and Java monorepos.

For the Go, Web, Python, and Android monorepos, the experiment indicated that Hyperdisks minimally impact the build time of services, despite the large difference in the raw disk performance of the configurations. Specifically, the Go and Web monorepos had no measurable impact, the Python monorepo had a minimal increase of 2.4%, and the Android monorepo had a minimal increase of 1.5%. The reason for the minimal impact is because the monorepos are configured to use locally-attached disks for build output directories, and these locally-attached disks are separate from the network-attached disks we are comparing. The build output directories proved to be utilized an order of magnitude more, meaning that the network-attached disk is minimally relevant to build performance. Effectively, Hyperdisks have a negligible impact on the build performance for the Go, Web, Python and Android monorepos.

For the Java monorepo, the experiment indicated that Hyperdisks resulted in a considerable degradation in build time. The reason why the Java monorepo behaves differently is because it does not use locally-attached disks for the build output directories. When modifying the configuration for the Java monorepo to align with the other monorepos, it behaves the same way as the Go and Web monorepos, meaning no impact is observed between the disk configurations. It is unclear whether the deviating configuration for the Java monorepo is intentional. Effectively, the Java monorepo currently observes a 13.5% increase in build duration for the PD-equivalent Hyperdisk configuration, and a 30.3% increase for the minimum Hyperdisk configuration. However, these degradations can be mitigated if the configuration is modified.

To conclude, build performance is minimally affected by migrating from Persistent Disks to Hyperdisks for the majority of Uber's monorepos, due to the fact that their build output directories are not stored on network-attached disks. The Java monorepo is an exception, where a 30.3% increase in build duration was observed for the minimum Hyperdisk configuration. However, the Java monorepo can be reconfigured to behave the same way as the other monorepos, in which case it would not observe a degradation in build time.



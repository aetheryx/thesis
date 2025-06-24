#import "setup.typ": setup
#show: setup

= Impact of performance provisioning models
This chapter answers the _"How do the fundamental differences in the performance provisioning models between Persistent Disks and Hyperdisks impact the raw disk performance of Uber's CDE?"_ sub-question. As previously mentioned in @perf_model, the fundamental difference between the performance provisioning models is that Persistent Disks share a pool of performance resources (known as "pooled performance"), and Hyperdisks provision performance statically per disk (known as "static performance"). In this chapter, we will further investigate the advantages and disadvantages between the two performance provisioning models, in order to determine how they affect raw disk performance.

== Advantages of pooled performance
The primary advantage of pooled performance is _burstability_. Consider a distributed application where each instance of the application consumes resources at short-lived, uncorrelated intervals (known as _bursts_). In this situation, active instances of the application can effectively borrow performance resources from their idle neighbors, allowing for faster completion of tasks. 

In order to demonstrate this impact, we will perform an experiment measuring the raw disk performance of CDE's with a synthetic benchmark. In this experiment, the performed task is writing 4 GiB of randomized data to the disk. We will provision two groups of CDE's: one group using Persistent Disks (pooled performance), and one group using Hyperdisks (static performance). For each group, we will measure how long the task takes to execute, with a varying amount of CDE's either performing the task or being idle. These executions are started at the same time within each group: for example, when measuring the execution time for 3 CDE's, all 3 CDE's start the task at the same time.

The results of this experiment are visualised as follows:
#image("perf_burst.png")

From the graph above, we can make a number of observations. Firstly, for CDE's using pooled performance (labeled "PD" for Persistent Disk), we observe a correlation between the amount of idle neighbors and the reduction in execution time: the more neighbors are idle, the lower the execution time is. Secondly, for CDE's using static performance (labeled "HD" for Hyperdisk), we observe that the execution time is not impacted by the idle-active distribution: no matter the amount of idle neighbors, CDE's using Hyperdisks perform the task in a consistent time. Thirdly, we observe that when all CDE's are active, the execution time of both pooled performance and static performance is nearly equal.

== Advantages of static performance provisioning
As described in the previous graph, performance pooling can allow for improved performance for burstable workloads. While this seems like a significant advantage, performance pooling also introduces a lack of predictability and consistency when it comes to the availability of performance resources. 

=== Improved predictability
Performance pooling results in a lack of predictability regarding the availability of performance resources. This is commonly known as the "noisy neighbor" problem within computing: suppose that 4 CDE's have to share the performance resources allocated to a given pool, and 1 CDE within this pool is executing long-running performance intensive tasks, effectively claiming all resources in the pool. In this situation, if a second CDE wants to perform a task, the performance scheduler needs to fairly re-distribute the performance resources within the pool, effectively needing to deallocate resources from the first CDE and allocate them to the second CDE. 

In order to investigate the fairness of the resource redistribution algorithm, we will perform an experiment measuring raw disk performance using a synthetic benchmark. In this experiment, we will set up two groups of 4 CDE's each, where the first group is using Hyperdisks and the second group is using Persistent Disks. The task that we will measure is writing 1 GiB of data to the disk. In order to measure fairness, these tasks will be performed with a varying amount of _noisy neighbors_, where a noisy neighbor is a resource consumer within the same pool that is already occupying performance resources prior to the start of the task execution. For this specific experiment, we will simulate noisy neighbors by instructing them to continuously write randomized data to the disk as fast as possible, effectively attempting to use as many performance resources as available.

The results of this experiment are visualised as follows:
#image("perf_neighbor.png")

// remove x noisy, x active, x idle labels, very confusing

In the graph above, we observe that noisy neighbors have a negative impact on execution time when using pooled performance: as the amount of noisy neighbors grows, execution time increases significantly, indicating that the performance redistribution algorithm for Persistent Disks is not sufficiently fair. As expected, the group using static performance provisioning is not impacted by noisy neighbors whatsoever: we observe that the execution time for Hyperdisks is nearly equal in all scenarios.

=== Improved consistency and precision
Suppose that noisy neighbors are not necessarily a problem and applications are performing comparable tasks. Even in this situation, resources are allocated more consistently and precisely when using static performance provisioning. This advantage is most relevant for latency-critical applications, such as user-facing databases or finance applications.

To demonstrate this difference across the two performance provisioning models, we will perform an experiment measuring raw disk performance using a synthetic benchmark. In this experiment, we will set up two groups of 4 CDE's, where the first group is using Hyperdisks and the second group is using Persistent Disks. The task that we will measure is writing 4 GiB of data to the disk. We will instruct each CDE in each pool to perform this task continuously for 180 minutes, measuring the execution time of each execution.

The experiment collected a total of 750 samples. The results are visualised as follows:
// todo: x axis for hyperdisk is longer

#image("distrib.png")
#align(center)[#table(
  columns: 6,
  [], [Minimum], [Median], [Maximum], [Min-Max Range], [Std. Dev.],

  [Persistent Disk], [105.52], [108.16], [110.74], [5.22], [1.09],
  [Hyperdisk], [108.05], [108.10], [108.12], [0.07], [0.02]
)]

From these results, we observe that pooled performance significantly impacts the consistency of resource availability. For both performance provisioning models, the median execution time is nearly equal around 108.1 seconds. For Persistent Disks, we observe a minimum-maximum range of 5.22 seconds and a standard deviation of 1.09 seconds. Hyperdisks proved to perform much more consistently, with a minimum-maximum range of only 0.07 seconds and a standard deviation of 0.02 seconds.


// == Fairness of resource sharing algorithms
// From the previous section, we understand that both strategies have their advantages and disadvantages. We can determine that if the workload is often bursty and often has idle neighbors, performance pooling is far more advantageous, 

// In summary: static performance provisioning is favorable for workloads that need predictable and consistent availability of performance, and pooled performance provisioning is favorable for workloads that have uncorrelated bursts of resource usage.

// == Utilization pattern of CDE's
// It is commonly understood that the utilization pattern of CDE's is bursty, due to their nature. Typically, engineers will have their CDE open throughout the day. Tasks such as compiling applications or executing test suites would result in bursts of utilization. However, considering the workflow of engineers, these tasks are rare occurrences surrounded by other idle tasks such as writing code or reading documentation. As an example, consider the following utilization graph of one of Uber's CDE's.

// #align(center)[#image("cpu-example.png")]

// While this is just one example, it clearly demonstrates the bursty utilization pattern. We observe that the majority of time is spent idling as the engineer works on smaller tasks, and we observe a number of larger bursts.

// == Fairness of the resource sharing algorithm
// As we have now determined that the utilization pattern of CDE's is bursty, we can investigate the theoretical disk performance in two scenarios.

// The first scenario is when a CDE has idle neighbors. In this situation, the CDE is provisioned on a virtual machine with a number of other CDE's, but the other CDE's are idling. With resource pooling, the CDE will be able to borrow resources from the pool, effectively receiving a larger allocation of performance resources. With static performance provisioning, the CDE will not be able to take advantage of resource pooling, effectively only receiving it's own share of performance resources. In this scenario, the expectation is that resource pooling allows for significantly more performance resources.

// The other scenario is when a CDE does not have idle neighbors. In this situation, the CDE is provisioned on a virtual machine with a number of other CDE's, and the other CDE's are also performing tasks. With resource pooling, the CDE will contend for resources between other CDE's in the pool, resulting in inconsistent availability of performance resources. With static performance provisioning, the CDE will have it's own resource allocation, resulting in consistent availability of performance resources. 

// It is clear that resource sharing is always more optimal when the CDE has idle neighbors. However, when it does not, it is important to understand how resources are shared under contention. The advantage of static performance provisioning guarantees that resources are allocated fairly by disallowing resource sharing altogether - however, this does not imply that resource sharing is inherently unfair. To investigate the fairness of the resource sharing algorithm when using resource sharing, we will conduct an experiment.


// keep it simple
// graph 1: pd vs hd with idle neighbors, show pd >> hd
// graph 2: pd vs hd under contention, show hd is consistent and pd is not


#import "setup.typ": setup
#show: setup

= Impact of performance provisioning models
This chapter answers the _"How do the fundamental differences in the performance provisioning models between Persistent Disks and Hyperdisks impact the raw disk performance of Uber's CDE?"_ sub-question. As previously mentioned in @perf_model, the fundamental difference between the performance provisioning models is that Persistent Disks share a pool of performance resources (known as "pooled performance"), and Hyperdisks provision performance statically per disk (known as "static performance"). In this chapter, we will further investigate the advantages and disadvantages between the two performance provisioning models, in order to determine how they affect raw disk performance.

== Background research: Measuring raw disk performance
This chapter investigates raw disk performance across different configurations, by performing various experiments. In this section, we briefly describe the technical details of how these experiments are performed.

First, we define how raw disk performance is measured. The `fio` command-line tool is used (https://github.com/axboe/fio), which provides the ability to perform disk operations and measure their execution time. For example, the `fio` tool can be instructed to write 1 GiB of randomized data to a specific file, and the output of this operation would be how long it took to write the data. The specific configuration parameters are included in full in the Appendix (@appendix_fio). 

Second, we define how the experiments are commonly configured. In this chapter, all experiments provision two groups of CDE's: one group using Persistent Disks (pooled performance), and one group using Hyperdisks (static performance). The groups are isolated from each other, and each group contains 4 CDE's each. The group using Persistent Disks has a performance pool of 38.640 IOPS in total, shared by 4 CDE's. For the group using Hyperdisks, we provision each CDE with 9660 IOPS, meaning both groups have an equal amount of total IOPS.

== Advantages of pooled performance
The primary advantage of pooled performance is _burstability_. Consider a distributed application where each instance of the application consumes resources at short-lived, uncorrelated intervals (known as _bursts_). In this situation, active instances of the application can effectively borrow performance resources from their idle neighbors, allowing for faster completion of tasks. 

In order to demonstrate this impact, we will perform an experiment with the goal of understanding how execution time is impacted by the amount of active CDE's. The task that will be measured is writing 4 GiB of randomized data to the disk. For each CDE group, we will measure the task execution time, with a varying amount of CDE's that are either performing the task or being idle. Executions are started at the same time within each group: for example, when measuring the execution time with 3 active CDE's, all 3 CDE's start the task at the same time.

The results of this experiment are visualised as follows:
#image("images/perf_burst.png")

From these results, we can make a number of observations. Firstly, for CDE's using pooled performance, we observe a correlation between the amount of idle neighbors and the reduction in execution time: the more neighbors are idle, the lower the execution time is. Secondly, for CDE's using static performance, we observe that the execution time is not impacted by the idle-active distribution: no matter the amount of idle neighbors, CDE's using static performance perform the task in a consistent time. Thirdly, we observe that when all CDE's are active, the execution time of both pooled performance and static performance is nearly equal.

== Advantages of static performance provisioning
As described in the previous graph, performance pooling can allow for improved performance for burstable workloads. While this seems like a significant advantage, performance pooling also introduces a lack of predictability and consistency when it comes to the availability of performance resources. 

=== Improved predictability
Performance pooling introduces a lack of predictability regarding the availability of performance resources. This is commonly known as the "noisy neighbor" problem within computing: suppose that there are 4 CDE's using pooled performance, and 1 CDE within this pool is executing a long-running performance intensive task, effectively claiming all resources in the pool. In this situation, if a second CDE wants to perform a task, the resource scheduler needs to fairly re-distribute the performance resources within the pool, effectively needing to deallocate resources from the first CDE and allocate them to the second CDE. 

In order to investigate the fairness of the resource redistribution algorithm, we will perform an experiment with the goal of understanding how execution time is impacted when the performance scheduler needs to redistribute allocated resources. The task we will measure is the execution time to write 1 GiB of randomized data to the disk. For each measurement, one CDE will execute the task for measurement, and a varying amount of CDE's will act as noisy neighbors. As previously mentioned, a noisy neighbor is a resource consumer within the same pool that is already occupying performance resources prior to the start of the task execution. We will simulate noisy neighbors by instructing them to continuously write randomized data to the disk as fast as possible, effectively attempting to use as many performance resources as available. 

The results of this experiment are visualised as follows:
#image("images/perf_neighbor.png")

// remove x noisy, x active, x idle labels, very confusing

In the graph above, we observe that noisy neighbors have a negative impact on execution time when using pooled performance: as the amount of noisy neighbors grows, execution time increases significantly, indicating that the performance scheduler for Persistent Disks does not redistribute allocated resources fairly. As expected, the group using static performance provisioning is not impacted by noisy neighbors whatsoever: we observe that the execution time using static performance is nearly equal in all scenarios.

=== Improved consistency and precision
Suppose that noisy neighbors are not necessarily a problem and applications are performing comparable tasks. Even in this situation, resources are allocated more consistently and precisely when using static performance provisioning. This advantage is most relevant for latency-critical applications, such as user-facing databases or finance applications.

In order to investigate the consistency and precision of performance allocations, we will perform an experiment that simulates a consistently sized, distributed workload: each CDE in each pool will perform the task continuously, and the task is the same across all CDE's, namely writing 4 GiB of data to the disk. The simulation is ran continuously for 180 minutes, measuring the execution time of each execution.

The experiment collected a total of 750 samples. The results are visualised as follows:
// todo: x axis for hyperdisk is longer

#image("images/distrib.png")
#align(center)[#table(
  columns: 6,
  [], [Min.], [Median], [Max.], [Range], [Std. Dev.],

  [Persistent Disk], [105.52], [108.14], [110.74], [5.22], [1.09],
  [Hyperdisk], [108.05], [108.10], [108.12], [0.07], [0.02]
)]

From these results, we observe that pooled performance significantly impacts the consistency of resource availability. For both performance provisioning models, the median execution time is nearly equal around 108.1 seconds. For Persistent Disks, we observe a min-max range of 5.22 seconds and a standard deviation of 1.09 seconds. Hyperdisks proved to perform much more consistently, with a min-max range of only 0.07 seconds and a standard deviation of 0.02 seconds.


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


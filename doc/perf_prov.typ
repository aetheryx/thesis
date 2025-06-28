#import "setup.typ": setup
#show: setup

= Impact of performance provisioning models
This chapter answers the _"How do the differences in the performance provisioning models of Persistent Disks and Hyperdisks impact the raw disk performance of Uber's CDE?"_ sub-question. As previously mentioned in @perf_model, the fundamental difference between the performance provisioning models is that Persistent Disks share a pool of performance resources (known as "pooled performance") and Hyperdisks provision performance statically per disk (known as "static performance"). In this chapter, we will further investigate the advantages and disadvantages between the two performance provisioning models, in order to determine how they affect raw disk performance. It is important to note that the performance provisioning models are merely one aspect of the disks: in further chapters, other characteristics will be investigated.

== Background research: Measuring raw disk performance
This chapter investigates raw disk performance in various scenarios, by performing a number of experiments. In this section, we briefly describe the technical details of how these experiments are generally performed.

First, we define how raw disk performance is measured. The `fio` command-line tool is used (https://github.com/axboe/fio), which provides the ability to perform synthetic disk operations and measure their execution time. For example, the `fio` tool can be instructed to write 1 GiB of randomized data to a specific file, and the time taken for this execution can be measured. The specific configuration parameters are included in full in the Appendix (@appendix_fio). 

Second, we define how the experiments are commonly configured. In this chapter, all experiments provision two isolated groups of CDE's: one group using Persistent Disks (pooled performance), and one group using Hyperdisks (static performance). Each group contains 4 CDE's each. The group using Persistent Disks has a performance pool of 38.640 IOPS in total, shared by 4 CDE's. For the group using Hyperdisks, we provision each CDE with 9660 IOPS, meaning both groups have an equal amount of total IOPS.

== Advantages of pooled performance
The primary advantage of pooled performance is _burstability_. Consider a distributed application where each instance of the application consumes resources at short-lived, uncorrelated intervals (known as _bursts_). In this situation, active instances of the application can effectively borrow performance resources from their idle neighbors, allowing for faster completion of tasks. 

In order to demonstrate burstability, we will perform an experiment with the goal of understanding how execution time is impacted by the amount of active CDE's. The task that will be measured is writing 4 GiB of randomized data to the disk. For each CDE group, we will measure the task execution time, with a varying amount of CDE's that are either performing the task or being idle. Executions are started at the same time within each group: for example, when measuring the execution time with 3 active CDE's, all 3 CDE's start the task at the same time.

The results of this experiment are visualised as follows:
#image("images/perf_burst.png")

From these results, we can make a number of observations. Firstly, for CDE's using pooled performance, we observe a correlation between the amount of idle neighbors and the reduction in execution time: the more neighbors are idle, the lower the execution time is. Secondly, for CDE's using static performance, we observe that the execution time is not impacted by the idle-active distribution: no matter the amount of idle neighbors, CDE's using static performance perform the task in a consistent time. Thirdly, we observe that when all CDE's are active, the execution time of both pooled performance and static performance is nearly equal.

== Advantages of static performance provisioning
As described in the previous section, performance pooling can allow for improved performance for burstable workloads. While this seems like a significant advantage, performance pooling also introduces a lack of predictability and consistency when it comes to the availability of performance resources. 

=== Improved predictability
Performance pooling introduces a lack of predictability regarding the availability of performance resources. This is commonly known as the "noisy neighbor" problem within computing: suppose that there are 4 CDE's using pooled performance, and 1 CDE within this pool is executing a long-running performance intensive task, effectively claiming all resources in the pool. In this situation, if a second CDE wants to perform a task, the resource scheduler needs to fairly re-distribute the performance resources within the pool, effectively needing to deallocate resources from the first CDE and allocate them to the second CDE. 

In order to investigate the fairness of the resource redistribution algorithm, we will perform an experiment with the goal of understanding how execution time is impacted when the performance scheduler needs to redistribute allocated resources. The task we will measure is the execution time to write 1 GiB of randomized data to the disk. For each measurement, one CDE will execute the task for measurement, and a varying amount of CDE's will act as noisy neighbors. As previously mentioned, a noisy neighbor is a resource consumer within the same pool that is already occupying performance resources prior to the start of the task execution. We will simulate noisy neighbors by instructing them to continuously write randomized data to the disk as fast as possible, effectively attempting to use as many performance resources as available. 

The results of this experiment are visualised as follows:
#image("images/perf_neighbor.png")

In the graph above, we observe that noisy neighbors have a negative impact on execution time when using pooled performance: as the amount of noisy neighbors grows, execution time increases significantly, indicating that the performance scheduler for Persistent Disks does not redistribute allocated resources fairly. As expected, the group using static performance provisioning is not impacted by noisy neighbors whatsoever: we observe that the execution time using static performance is nearly equal in all scenarios.

=== Improved consistency and precision
Suppose that noisy neighbors are not necessarily a problem and applications are performing comparable tasks. Even in this situation, resources are allocated more consistently and precisely when using static performance provisioning. This advantage is most relevant for latency-critical applications, such as user-facing databases or finance applications.

In order to investigate the consistency and precision of performance allocations, we will perform an experiment that simulates a consistently sized, distributed workload: each CDE in each pool will perform the task continuously, and the task is the same across all CDE's, namely writing 4 GiB of data to the disk. The simulation is ran continuously for 180 minutes, measuring the execution time of each execution.

The experiment collected a total of 750 samples. The results are visualised as follows:
#image("images/distrib.png")
#align(center)[#table(
  columns: 6,
  [], [Min.], [Median], [Max.], [Range], [Std. Dev.],

  [Persistent Disk], [105.52], [108.14], [110.74], [5.22], [1.09],
  [Hyperdisk], [108.05], [108.10], [108.12], [0.07], [0.02]
)]

From these results, we observe that pooled performance significantly impacts the consistency of resource availability. For both performance provisioning models, the median execution time is nearly equal around 108.1 seconds. For Persistent Disks, we observe a min-max range of 5.22 seconds and a standard deviation of 1.09 seconds. Hyperdisks proved to perform much more consistently, with a min-max range of only 0.07 seconds and a standard deviation of 0.02 seconds.

== Interpreting results for Uber's CDE
Up until now, the previous sections of this chapter have presented experiment results with general observations. In this section, we will relate the experiment results to Uber's CDE, in order to understand what the real-world impact for the raw disk performance of Uber's CDE's may be.

=== Burstability
The first advantage of pooled performance is the ability to share resources for bursty workloads. When it comes to the utilization pattern of CDE's, it is commonly understood that they are bursty. Typically, engineers will have their CDE open throughout the day. Tasks such as compiling applications or executing test suites would result in bursts of utilization. However, considering the workflow of engineers, these tasks are rare occurrences surrounded by other idle tasks such as writing code or reading documentation. As an example, consider the following utilization graph of one of Uber's CDE's.

#align(center)[#image("images/cpu-example.png")]

While this is just one example, it clearly demonstrates the bursty utilization pattern. We observe that the majority of time is spent idling as the engineer works on smaller tasks, and we observe a number of larger bursts when the engineer needs to compile projects to run them.

In addition to the bursty utilization pattern, consider that Uber's CDE's are provisioned on a virtual machine holding 12 to 14 CDE deployments. Taking all factors into account, we understand the utilization pattern of CDE's is bursty and resources are shared between 12 deployments. Therefore, it is likely that individual CDE's would significantly benefit from pooled performance, as it is unlikely that a majority of the 12 deployments would be executing performance intensive tasks.

To conclude, burstability would allow for significantly improved disk performance for Uber's CDE's, therefore making pooled performance more optimal in this aspect.

=== Noisy neighbors
The first advantage of static performance is predictability, especially being more resilient to noisy neighbors. In order to determine how useful resiliency against noisy neighbors is for Uber's CDE's, we can query the past 14 days of resource usage for Uber's CDE's and observe occurrences of noisy neighbors. We will specifically query the Europe region, where there are currently 620 active CDE's.

Using a Prometheus query, we can measure the allocated IOPS for each Persistent Disk in the region, and select metrics where the allocated IOPS are above a certain threshold. Considering that Uber's CDE's share 100.000 IOPS per resource pool, we define a noisy neighbor as an individual disk using 40% of this capacity, i.e. 40.000 IOPS. The full query is available in the Appendix (@prom_disks). Over the past 14 days, this query returns the following graph data:
#image("images/noisy-disks.png")

Visually, we can observe that noisy neighbors are not a frequent occurrence. The raw data for this query can be further analyzed to measure the amount of occurrences and their durations. The results of the analysis are as follows:

#table(
  columns: 2,
  [Metric], [Value],

  [Amount of occurrences], [40],
  [Minimum duration], [5 minutes],
  [Mean duration], [7.5 minutes],
  [Maximum duration], [20 minutes],
)

It is worth noting that the time intervals were downsampled by the query engine, as this data is being queried over a large timeframe (14 days). Regardless, the observations indicate that noisy neighbors are not a frequent occurrence. The Europe region for Uber's CDE contains approximately 50 virtual machines, each with a dedicated resource pool. Over the course of 14 days, we observed 40 occurrences of noisy neighbors across all 50 of these virtual machines, and the mean duration for noisy neighbor activity was only 7.5 minutes. 

To conclude, while the improved predictability and isolation of static performance does provide resiliency against noisy neighbors, this type of activity occurs very infrequently for very short time intervals. Therefore, this benefit of static performance is not expected to be useful for Uber's CDE.

=== Improved consistency and precision
The second advantage of static performance is improved accuracy and precision regarding the performance allocations. This is an advantage that is primarily relevant for latency-critical workloads, such as production databases or real-time stock trading systems. The experiment performed earlier in this chapter indicated that the accuracy of the performance allocations under static performance is an order of magnitude more accurate than pooled performance.

However, objectively, the accuracy of pooled performance is perfectly acceptable for Uber's CDE's. CDE's are effectively development environments, and the difference in accuracy could not be perceived by a human engineer. The accuracy of pooled performance resource allocations still performed consistent enough for CDE's as a usecase.

To conclude, while static performance does provision performance more accurately, this advantage is irrelevant to Uber's CDE's.

== Conclusion
To investigate the advantages and disadvantages between the performance provisioning models of Persistent Disks and Hyperdisks, we performed a number of experiments. We performed in-depth statistical analysis on the experiment results to quantify the impact, and we used this statistical analysis to understand how these differences could relate to the performance of Uber's CDE.

Firstly, the pooled performance model of Persistent Disks allows for significant disk performance improvements, as Uber's CDE exhibits a bursty workload pattern. This is a significant advantage for Persistent Disks that would be lost when migrating to Hyperdisks. Secondly, the static performance model of Hyperdisks provides stronger resiliency against noisy neighbors, however, noisy neighbors were proven to be a rare occurrence for Uber's CDE. Therefore, while this resiliency is an advantage for Hyperdisks, it is not very useful for Uber's CDE. Thirdly, the static performance model provides significantly improved accuracy for performance allocations compared to Persistent Disks. However, as Uber's CDE is not a latency-critical application, the accuracy of Persistent Disks is sufficient. Therefore, the improved accuracy of Hyperdisks does not provide a useful benefit for Uber's CDE's.

To conclude, the pooled performance model of Persistent Disks is more advantageous for Uber's CDE. The primary reason for this is that Uber's CDE's exhibit a bursty workload pattern, meaning that resource pooling allows for significantly larger performance allocations for active CDE's, as their neighbors are likely idle. The static performance model of Hyperdisks does not allow for resource sharing, which is a significant disadvantage. While the static performance model does bring other benefits, such as resiliency against noisy neighbors and improved accuracy of performance allocations, these other benefits are minimally useful for Uber's CDE's. 
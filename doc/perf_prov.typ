#import "lib/setup.typ": setup
#show: setup

= Impact of performance provisioning models <perf_prov>
This chapter answers the _"How do the differences in the performance provisioning models of Persistent Disks and Hyperdisks impact the raw disk performance of Uber's CDE?"_ sub-question. As previously mentioned in @perf_model, the fundamental difference between the performance provisioning models is that Persistent Disks share a pool of performance resources (known as "pooled performance") and Hyperdisks provision performance statically per disk (known as "static performance"). The chapter further investigates the advantages and disadvantages between the two performance provisioning models, in order to determine how they affect raw disk performance. It is important to note that the performance provisioning models are merely one aspect of the disks: in subsequent chapters, other characteristics are investigated.

== Background research: Measuring raw disk performance
This chapter investigates raw disk performance in various scenarios, by performing a number of experiments. In this section, the technical details of how these experiments are generally performed are briefly described.

First, the way raw disk performance is measured is using the `fio` command-line tool (#link("https://github.com/axboe/fio")), which provides the ability to perform synthetic disk operations and measure their execution time. For example, the `fio` tool can be instructed to write 1 GiB of randomized data to a specific file, and the time taken for this execution can be measured. The specific configuration parameters are included in full in the Appendix (@appendix_fio).

Second, the experiments are commonly configured as follows. In this chapter, all experiments provision two isolated groups of @cde:short:pl: one group using Persistent Disks (pooled performance), and one group using Hyperdisks (static performance). Each group contains 4 @cde:short:pl each. The group using Persistent Disks has a performance pool of 38.640 IOPS in total, shared by 4 @cde:short:pl. For the group using Hyperdisks, each CDE is provisioned with 9.660 IOPS, meaning both groups have an equal amount of total IOPS.

== Advantages of pooled performance
The primary advantage of pooled performance is _burstability_. Consider a distributed application where each instance of the application consumes resources at short-lived, uncorrelated intervals (known as _bursts_). In this situation, active instances of the application can effectively borrow performance resources from their idle neighbors, allowing for faster completion of tasks.

In order to demonstrate burstability, an experiment was performed with the goal of understanding how execution time is impacted by the amount of active @cde:short:pl. The task that was measured is writing 4 GiB of randomized data to the disk. For each CDE group, the task execution time was measured, with a varying amount of @cde:short:pl that are either performing the task or being idle. Executions are started at the same time within each group: for example, when measuring the execution time with 3 active @cde:short:pl, all 3 @cde:short:pl start the task at the same time.

\

The results of this experiment are visualised as follows:
#align(center)[#image("images/perf_burst.png", width: 120%)]

A number of observations can be drawn from these results. Firstly, for @cde:short:pl using pooled performance, there is a correlation between the amount of idle neighbors and the reduction in execution time: the more neighbors are idle, the lower the execution time is. Secondly, for @cde:short:pl using static performance, the execution time is not impacted by the idle-active distribution: no matter the amount of idle neighbors, @cde:short:pl using static performance perform the task in a consistent time. Thirdly, when all @cde:short:pl are active, the execution time of both pooled performance and static performance is nearly equal.

== Advantages of static performance provisioning
As described in the previous section, performance pooling can allow for improved performance for burstable workloads. While this seems like a significant advantage, performance pooling also introduces a lack of predictability and consistency when it comes to the availability of performance resources.

=== Isolation against noisy neighbors
The first advantage of static performance is the fact that performance allocations are isolated from neighboring CDEs on the same virtual node. When using pooled performance, CDEs can be susceptible to resource starvation under contention from neighboring CDEs. More specifically, this is known as the "noisy neighbor" problem within computing #cite(<bouattour-2020>). Suppose that there are 4 @cde:short:pl using pooled performance, and 1 CDE within this pool is executing a long-running performance intensive task, effectively claiming all resources in the pool. In this situation, if a second CDE wants to perform a task, the resource scheduler needs to fairly re-distribute the performance resources within the pool, effectively needing to deallocate resources from the first CDE and allocate them to the second CDE. When using performance pooling, this reallocation process does not always happen fairly, leading to resource starvation.

In order to investigate the fairness of the resource redistribution algorithm, an experiment was performed with the goal of understanding how execution time is impacted when the performance scheduler needs to redistribute allocated resources. The task measured is the execution time to write 1 GiB of randomized data to the disk. For each measurement, one CDE executed the task for measurement, and a varying amount of @cde:short:pl acted as noisy neighbors. As previously mentioned, a noisy neighbor is a resource consumer within the same pool that is already occupying performance resources prior to the start of the task execution. Noisy neighbors were simulated by instructing them to continuously write randomized data to the disk as fast as possible, effectively attempting to use as many performance resources as available.

The results of this experiment are visualised as follows:
#align(center)[#image("images/perf_neighbor.png", width: 120%)]

In the graph above, noisy neighbors have a negative impact on execution time when using pooled performance: as the amount of noisy neighbors grows, execution time increases significantly, indicating that the performance scheduler for Persistent Disks does not redistribute allocated resources fairly. As expected, the group using static performance provisioning is not impacted by noisy neighbors whatsoever: the execution time using static performance is nearly equal in all scenarios.

=== Improved consistency
Suppose that noisy neighbors are not necessarily a problem and applications are performing comparable tasks. Even in this situation, resource allocations are more precise and consistent when using static performance provisioning. This advantage is most relevant for latency-critical applications that have no tolerance for inconsistent availability of performance, such as user-facing databases or real-time stock trading #cite(<hsu-2004>).

In order to investigate the consistency of performance allocations, an experiment simulated a consistently sized, distributed workload: each CDE in each pool performed the task continuously, and the task is the same across all @cde:short:pl, namely writing 4 GiB of data to the disk. The simulation was run continuously for 180 minutes, measuring the execution time of each execution.

The experiment collected a total of 750 samples. The results are visualised as follows:
#image("images/distrib.png")
#align(center)[#table(
  columns: 6,
  [], [Min.], [Median], [Max.], [Range], [Std. Dev.],

  [Persistent Disk], [105,52], [108,14], [110,74], [5,22], [1,09],
  [Hyperdisk], [108,05], [108,10], [108,12], [0,07], [0,02]
)]

From these results, pooled performance significantly impacts the consistency of resource availability. For both performance provisioning models, the median execution time is nearly equal around 108,1 seconds. For Persistent Disks, the min-max range is 5,22 seconds and the standard deviation is 1,09 seconds. Hyperdisks proved to perform much more consistently, with a min-max range of only 0,07 seconds and a standard deviation of 0,02 seconds.

Aside from the difference in consistency, the nearly equal median execution times are a further indication of the fundamental similarities between Hyperdisks and Persistent Disks. The fact that the median execution time is nearly equal in these scenarios indicates that the underlying hardware between the disk types performs identically in isolation.

== Interpreting results for Uber's CDE
Up until now, the previous sections of this chapter have presented experiment results with general observations. This section relates the experiment results to Uber's CDE, in order to understand what the real-world impact for the raw disk performance of Uber's @cde:short:pl may be.

=== Burstability
The first advantage of pooled performance is the ability to share resources for bursty workloads. When it comes to the utilization pattern of @cde:short:pl, it is commonly understood that they are bursty #cite(<potter-2024>). Typically, engineers have their CDE open throughout the day, but the majority of this time is spent on idle tasks such as writing code or reading documentation. It is only when engineers actively compile projects or run test suites that @cde:short:pl require performance, and these tasks often have short durations.

As an example, consider the following utilization graph of one of Uber's @cde:short:pl:
#align(center)[#image("images/cpu-example.png", width: 115%)]

While this is just one example, it clearly demonstrates the bursty utilization pattern. The majority of time is spent idling as the engineer works on smaller tasks, and a number of larger bursts are observed when the engineer needs to compile projects to run them.

In addition to the bursty utilization pattern, consider that Uber's @cde:short:pl are provisioned on a virtual machine holding up to 12 CDE deployments. Taking all factors into account, the utilization pattern of @cde:short:pl is bursty and resources are shared between up to 12 deployments. Therefore, it is likely that individual @cde:short:pl benefit significantly from pooled performance, as it is unlikely that a majority of the 12 deployments would be executing performance intensive tasks.

To conclude, burstability would allow for significantly improved disk performance for Uber's @cde:short:pl, therefore making pooled performance more optimal in this aspect.

=== Isolation
The first advantage of static performance is isolation, specifically being more resilient to noisy neighbors. In order to determine how useful resiliency against noisy neighbors is for Uber's @cde:short:pl, the past 14 days of resource usage for Uber's @cde:short:pl can be queried, to observe occurrences of noisy neighbors in a given datacenter.

Using a Prometheus query, the allocated IOPS for each Persistent Disk in the region can be measured, and metrics where the allocated IOPS are above a certain threshold can be selected. Considering that Uber's @cde:short:pl share 100.000 IOPS per resource pool, a noisy neighbor is defined as an individual disk using 40% of this capacity, i.e. 40.000 IOPS. The full query is available in the Appendix (@prom_disks).

Over the past 14 days, this query returns the following graph data:
#align(center)[#rect(image("images/noisy-disks.png"), width: 120%, stroke: gray)]

Visually, noisy neighbors are not a frequent occurrence. The raw data for this query can be further analyzed to measure the amount of occurrences and their durations. The script for this analysis is available in the GitHub repository at #link("https://github.com/aetheryx/thesis/tree/main/noise")[`thesis/noise`].

The results of the analysis are as follows:
#table(
  columns: 2,
  [Metric], [Value],

  [Amount of occurrences], [40],
  [Minimum duration], [5 minutes],
  [Mean duration], [7,5 minutes],
  [Maximum duration], [20 minutes],
)

It is worth noting that the time intervals were downsampled by the query engine, as this data is being queried over a large timeframe (14 days). Regardless, the analysis indicates that noisy neighbors are not a frequent occurrence. The Europe region for Uber's CDE contains approximately 50 virtual machines, each with a dedicated resource pool. Over the course of 14 days, 40 occurrences of noisy neighbors were observed across all 50 of these virtual machines, and the mean duration for noisy neighbor activity was only 7,5 minutes.

To conclude, while the isolation of static performance does provide resiliency against noisy neighbors, this type of activity occurs infrequently, for short time intervals. Therefore, this benefit of static performance is not expected to be useful for Uber's CDE.

=== Improved consistency
The second advantage of static performance is improved consistency regarding the performance allocations. The experiment performed earlier in this chapter indicated that the performance allocations under static performance are an order of magnitude more accurate than pooled performance.

However, the consistency under pooled performance is perfectly acceptable for Uber's @cde:short:pl. @cde:short:pl are effectively development environments, and the difference in consistency would realistically not be perceived by a human engineer. The consistency of pooled performance resource allocations is adequate for @cde:short:pl as a usecase.

To conclude, while static performance does provision performance more consistently, this advantage is irrelevant to Uber's @cde:short:pl.

== Conclusion
To investigate the advantages and disadvantages between the performance provisioning models of Persistent Disks and Hyperdisks, a number of experiments were performed. In-depth statistical analysis was performed on the experiment results to quantify the impact, and this statistical analysis was used to understand how these differences could relate to the performance of Uber's CDE.

Firstly, the pooled performance model of Persistent Disks allows for significant disk performance improvements, as Uber's CDE exhibits a bursty workload pattern. This is a significant advantage for Persistent Disks that would be lost when migrating to Hyperdisks. Secondly, the static performance model of Hyperdisks provides stronger resiliency against noisy neighbors, however, noisy neighbors were proven to be a rare occurrence for Uber's CDE, therefore making this advantage minimally useful. Thirdly, the static performance model allocates performance significantly more consistently, however, this advantage is not useful for Uber's CDE as it is not latency-critical.

To conclude, the pooled performance model of Persistent Disks is more advantageous for Uber's CDE. Resource pooling allows for significantly larger performance allocations for active @cde:short:pl, as their neighbors are likely idle. While static performance brings other benefits, such as resiliency against noisy neighbors and improved consistency of performance allocations, these other benefits are minimally useful for Uber's CDE.

Additionally, the experiments indicated that the underlying hardware between Hyperdisks and Persistent Disks performs nearly equally in fair comparisons. In the first experiment comparing burstability, Persistent Disks and Hyperdisks performed nearly equally under contention, with execution times of 107,02 seconds and 106,96 seconds respectively. Further, in the third experiment comparing consistency for latency-critical workloads, the median execution times are nearly equal at 108,14 seconds and 108,10 seconds respectively.

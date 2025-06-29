// can compare 5 pd concurrent vs. 5 hd concurrent


#import "setup.typ": setup
#show: setup

= Build performance
== Introduction
This chapter answers the _"How is build performance affected by migrating from Persistent Disks to Hyperdisks?"_ sub-question. As previously mentioned, the investigated application is Uber's cloud development environment, which was initially developed to improve the build performance of large-scale codebases compared to laptops. Therefore, build performance is considered one of the most relevant metrics to describe the overall performance of Uber's CDE's. In order to compare the build performance between Persistent Disks and Hyperdisks, we will perform an experiment measuring how long it takes to build projects across various disk configurations.

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

Specifically, the chosen heuristic is the amount of transitive dependencies each project has. The reason this heuristic is appropriate is due to the nature of monorepos. Fundamentally, the relationship between targets in monorepos is a directed acyclic graph, where each node in the graph represents any necessary files for other targets to depend on. Considering the final executable target of a project as a leaf node, this node will have direct dependencies on nodes containing the source files implementing the project. Other dependencies, such as libraries, are represented in the build graph as well. Therefore, the total amount of transitive dependencies of a project accurately represents it's size: it includes the implementation files of the project itself, as well as the dependencies of the project, and their dependencies, and so on.

In summary, we will select three projects in each monorepo, which are the projects at the 25th, 50th and 75th percentiles sorted by transitive dependency count per project.

=== Measurement process
As previously mentioned, the goal of the experiment is to compare the build duration between Hyperdisks and Persistent Disks, for each of the five monorepos supported by Uber. For each monorepo, we will select three projects for measurement.

It is important that we understand how the disk types affect build performance for each monorepo specifically: for example, the Golang monorepo might be affected by disk performance differently than the Web monorepo, as they are completely different languages that are compiled and executed differently. Further, it is not important that the differences within the three selected projects are analyzed, as the goal of the subset selection is to represent the monorepo as a whole. Considering these requirements, the experiment will yield one measurement for each combination of a monorepo and a disk configuration, where each measurement represents the average build time of that monorepo under that disk configuration.

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





// The definition of _primary workloads_ is as follows: as previously mentioned, the  These environments allow engineers to perform many different tasks, as any software engineer does. By _primary workloads_, we specifically investigate the most commonly performed tasks by engineers, focusing on their core workflow. 

// Specifically, the primary workloads selected for investigation are build performance, IDE operations and git latency. Each of these workloads are individually investigated in this chapter, yielding data that is statistically analyzed. At the end of the chapter, the analysis is used to draw conclusions, combined with the context of the goal.

// == Build Performance

// While we are able to define the various processes that involve the disk, the goal of this section is to precisely investigate the relevance of disk performance. In order to investigate this impact, we will perform an experiment comparing build time between environments using Persistent Disks and environments using Hyperdisks.


// ==== Environment configuration
// For the Persistent Disk configurations, an environment with a 256 GiB Persistent Disk is provisioned. As mentioned in @perf_model, the performance of Persistent Disks scales with the capacity of the disk. With a 256 GiB disk, the disk performance allocated to the environment is 13680 IOPS and 350 MiBps of throughput.

// As mentioned in @perf_model, performance for Hyperdisks is statically configured. Understanding the amount of performance resources is one of the core goals of this research. Therefore, we will compare three Hyperdisk configurations:
// 1. 3000 IOPS and 140 MiBps throughput (smallest possible size)
// 2. 8340 IOPS and 245 MiBps throughput (midpoint)
// 3. 13680 IOPS and 350 MiBps throughput (equal to Persistent Disks)

// ==== Project selection
// The first requirement for the experiment is defining which projects will be measured. Uber's backend monorepo contains over 15,000 projects, which is an amount that cannot be feasibly measured for this research. Instead, we will sample a subset of these projects for measurement. In order to ensure the relevancy of our data, the selected subset must represent the customers of the monorepo with sufficient breadth. Therefore, uniform sampling of all projects is not appropriate, as some individual organizations may have more projects than others. 

// In Uber's monorepo, projects are structured organizationally, where all projects within a given organization share a given parent directory. This characteristic can be leveraged to select a subset that accurately represents the breadth of the users of Uber's cloud environments. For each organization directory, we will select the project with the largest dependency count. With 94 organization, this approach yields 94 projects, where each project is the largest project within it's organization.

// ==== Measurement of build time
// #lorem(100)

// === Results
// #lorem(100)

// == IDE operations
// #lorem(100)

// == Git latency
// #lorem(100)

// == Conclusion
// #lorem(200)



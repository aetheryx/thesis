// can compare 5 pd concurrent vs. 5 hd concurrent


#import "setup.typ": setup
#show: setup

= Build performance
== Introduction
This chapter answers the _"How is build performance affected by migrating from Persistent Disks to Hyperdisks?"_ sub-question. As previously mentioned, the investigated application is Uber's cloud development environment, which was initially developed to improve the build performance of large-scale codebases compared to laptops. Therefore, build performance is considered one of the most relevant metrics to describe the overall performance of the environments. 

In order to compare the build performance between Persistent Disks and Hyperdisks, we will perform an experiment measuring how long it takes to build a number of large services.

// When it comes to measuring the overall performance of these environments, build performance is considered the primary metric:  



// The definition of _primary workloads_ is as follows: as previously mentioned, the  These environments allow engineers to perform many different tasks, as any software engineer does. By _primary workloads_, we specifically investigate the most commonly performed tasks by engineers, focusing on their core workflow. 

// Specifically, the primary workloads selected for investigation are build performance, IDE operations and git latency. Each of these workloads are individually investigated in this chapter, yielding data that is statistically analyzed. At the end of the chapter, the analysis is used to draw conclusions, combined with the context of the goal.

// == Build Performance
// As mentioned in the introduction of this research, Uber has adopted the concept of monorepos, which are a development strategy where multiple projects are located within the same repository and directly depend on each other. A result of this approach is that dependencies are not pre-built: in order for a project to be built and executed, it's dependencies must first be compiled, which involves reading the source code for each dependency and writing the build artifact to the disk. Once these dependencies have been built, subsequent compilations of projects continue to rely on the disk, in order to read the cached build artifacts.

// While we are able to define the various processes that involve the disk, the goal of this section is to precisely investigate the relevance of disk performance. In order to investigate this impact, we will perform an experiment comparing build time between environments using Persistent Disks and environments using Hyperdisks.

// === Setting up the experiment
// As previously mentioned, the experiment involves provisioning two cloud environments, where one uses Persistent Disks and the other uses Hyperdisks. This subsection further describes the exact details of this experiment, namely how the environments are configured, which projects are selected for measurement, and how build time is measured.

// ==== Environment configuration
// For the Persistent Disk configurations, an environment with a 256 GiB Persistent Disk is provisioned. As mentioned in @perf_model, the performance of Persistent Disks scales with the capacity of the disk. With a 256 GiB disk, the disk performance allocated to the environment is 13680 IOPS and 350 MiBps of throughput.

// As mentioned in @perf_model, performance for Hyperdisks is statically configured. Understanding the amount of performance resources is one of the core goals of this research. Therefore, we will compare three Hyperdisk configurations:
// 1. 3000 IOPS and 140 MiBps throughput (smallest possible size)
// 2. 8340 IOPS and 245 MiBps throughput (midpoint)
// 3. 13680 IOPS and 350 MiBps throughput (equal to Persistent Disks)

// Other than the disk configuration, other variables must be controlled. The hardware for the environments is identical: each environment is provisioned with 48 CPU cores and 96 GiB of RAM, and the same virtual machines are re-used for the environments, guaranteeing that the same hardware is used. Additionally, each environment is checked out to the same revision of the monorepo, ensuring that the same source code implementations are measured and the same toolchain versions are used.

// In order to provision the environments, we follow the instructions defined in @provisioning_hd.

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



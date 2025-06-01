#import "setup.typ": setup
#show: setup

= Primary workloads
== Introduction
This chapter answers the _"How can Hyperdisks be configured to match the performance of traditional disks in primary workloads, as measured by build performance, IDE operations and git latency?"_ sub-question. The definition of _primary workloads_ is as follows: as previously mentioned, the investigated application is Uber's cloud development environment. These environments allow engineers to perform many different tasks, as any software engineer does. By _primary workloads_, we specifically investigate the most commonly performed tasks by engineers, focusing on their core workflow. 

Specifically, the primary workloads selected for investigation are build performance, IDE operations and git latency. Each of these workloads are individually investigated in this chapter, yielding data that is statistically analyzed. At the end of the chapter, the analysis is used to draw conclusions, combined with the context of the goal.

== Build Performance
As mentioned in the introduction of this research, Uber has adopted the concept of monorepos, which are a development strategy where multiple projects are located within the same repository and directly depend on each other. A result of this approach is that dependencies are not pre-built: in order for a project to be built and executed, it's dependencies must first be compiled, which involves reading the source code for each dependency and writing the build artifact to the disk. Once these dependencies have been built, subsequent compilations of projects continue to rely on the disk, in order to read the cached build artifacts.

While we are able to define the various processes that involve the disk, the goal of this section is to precisely investigate the relevance of disk performance. In order to investigate this impact, we will perform an experiment comparing build time between environments using Persistent Disks and environments using Hyperdisks.

=== Setting up the experiment
As previously mentioned, the experiment involves provisioning two cloud environments, where one uses Persistent Disks and the other uses Hyperdisks. This subsection further describes the exact details of this experiment, namely how the environments are configured, which projects are selected for measurement, and how build time is measured.

==== Environment configuration
The primary goal of the experiment is understanding the relevance of disk performance. Therefore, all other variables must first be controlled. Other than the provisioned disk, the hardware for the environments is identical: each environment is provisioned with 48 CPU cores and 96 GiB of RAM.

// todo: define disk configs

In order to provision the environments, we follow the instructions defined in Chapter 1.2.

==== Project selection
The first requirement for the experiment is defining which projects will be used for the measurements. Uber's backend monorepo contains over 15,000 projects, which is an amount that cannot be feasibly measured for this research. Instead, we will sample a subset of these projects for measurement. In order to ensure the relevancy of our data, the selected subset must represent the customers of the monorepo with sufficient breadth. Therefore, uniform sampling of all projects is not appropriate, as some individual organizations may have more projects than others. 

In Uber's monorepo, projects are structured organizationally, where all projects within a given organization share a given parent directory. This characteristic can be leveraged to select a subset that accurately represents the breadth of the users of Uber's cloud environments. For each organization directory, we will uniformly sample 3 projects: the minimum, median and maximum projects compared by dependency count. This approach yields a total of 265 projects across all 94 organizations in the monorepo (some organizations have fewer than 3 projects).

==== Measurement of build time
#lorem(100)

=== Results
#lorem(100)

== IDE operations
#lorem(100)

== Git latency
#lorem(100)

== Conclusion
#lorem(200)



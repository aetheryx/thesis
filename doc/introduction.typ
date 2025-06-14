#import "setup.typ": setup
#show: setup

#import "background.typ": background_questions

// Een inleiding is een vooruitblik op de inhoud en structuur van het verslag. Je beschrijft kort de
// aanleiding tot dit project. Schrijf niet in de ik/jij/wij stijl, zet je project centraal. De woorden ik/jij/wij etc.
// zijn überhaupt verboden in je rapport (met uitzondering van voorwoord en reflectie). Schrijf ook niet over
// jezelf in de derde persoon (De Afstudeerder . . . ).
// De inleiding bevat:
// - achtergrondinformatie/onderwerp/beschrijving/context waarbinnen de opdracht is uitgevoerd;
// - Waarom het rapport is geschreven, m.a.w. wat de opdracht was die aangepakt c.q. opgelost diende te
// worden. Dit wordt ook wel de probleemstelling genoemd;
// - welke procedure er gevolgd is om tot een oplossing te komen;
// - De structuur van het rapport (leeswijzer). Dit is een vooruitblik op de inhoud en opbouw van het
// afstudeerrapport.

= Introduction
Since the 2000s, a number of large tech companies have adopted the concept of _monorepos_. A monorepo is defined as a software development strategy in which distinct projects are stored in the same repository. Monorepos offer a number of key advantages, such as improved dependency management and code re-use. Within a monorepo, projects can form direct source code dependencies on each other and re-use the same core libraries.

However, monorepos often come with significant scaling challenges, as they can scale up to thousands of projects and billions of lines of code. Even with highly optimized monorepos, it becomes apparent that high-performance hardware is necessary. Top-of-the-line laptops are still restricted by certain characteristics: laptops need to remain transportable, have considerable thermal constraints, and need to optimize power usage. Compiling large apps or running large test suites on these laptops proves to be difficult. In order to solve this problem, Uber has developed a cloud-based development environment, where a key advantage is that the cloud offers hardware that is significantly more powerful than what is found in laptops. 

There are many architectural similarities between cloud development environments and the laptops engineers would otherwise use. Cloud development environments run an operating system (Linux), are provisioned with a number of CPU cores, an amount of dedicated RAM, and a storage disk. This storage disk contains all of the files the user needs for development: the repositories they have cloned, any configuration files or local databases they use, and such. This brings us to the topic of this research: the storage disk for Uber's cloud development environment.

The type of storage disk used for the environments is known as a Persistent Disk, a form of network-attached block storage offered by the cloud provider. Recently, the cloud provider has introduced a new type of disk known as a Hyperdisk. The topic of this research is investigating the differences between Persistent Disks and Hyperdisks in the context of Uber's cloud development environments.

== Problem Statement
Now that the application and it's relevance to disk performance has been introduced, the problem statement of this research is defined as follows.

Uber's cloud development environment is a cloud-based application used by engineers to develop codebases in monorepos. These cloud development environments are currently provisioned with a storage device known as a Persistent Disk. The cloud provider has recently announced a new type of disk known as a Hyperdisk. Uber would like to investigate a migration from Persistent Disks to Hyperdisks: they need a thorough understanding of the differences between the disk types, including what their fundamental differences are, how the practical performance of cloud development environments is impacted by disk performance, and the effectiveness of Hyperdisk-specific features (such as storage pooling and snapshot speed).

// tbd
Now that the core problem has been identified, the main research question is formulated as follows: \
#box(inset: (left: 18pt))[
  _"What is the impact of Google Cloud Hyperdisks for Cloud Development Environments, as measured by build performance, disk utilization, compared to traditional persistent disks?"_
]

Before an answer to the main question can be provided, a number of background research topics must be investigated. These background questions are as follows:
#background_questions

With the background research in place, we formulate the following sub-questions in order to provide an answer to the main question:
#box(inset: (left: 18pt))[
  + _"How do the differences in the performance provisioning models between Persistent Disks and Hyperdisks impact the theoretical disk performance of Uber's CDE?"_
  + _"How does migrating from Persistent Disks to Hyperdisks affect the performance of Uber's CDE, as measured by build latency for large projects?"_
  + _"How do Hyperdisk Storage Pools affect disk capacity utilization compared to Persistent Disks?"_
]

== Research Methods
#lorem(100)

== Structure
#lorem(100)

// == Relevance to disk performance
// As previously mentioned, Uber has adopted the concept of monorepos for the vast majority of their codebases, and these monorepos are used by engineers using cloud development environments. Within the usage of monorepos, there are a number of scenarios where disk performance is assumed to be relevant. These assumptions are investigated in-depth in the core of this research, but they are introduced in this section to provide context.

// There are a number of scenarios related to building and executing projects. In monorepos, projects have direct source code dependencies on other projects and libraries in the same monorepo. When a new instance of the monorepo is cloned and a given project is built, the source code for all dependencies must first be compiled - this is known as a _cold build_. For large projects with many transient dependencies, a cold build could require millions of source code lines being read from the disk in order to be compiled. The more performant the disk is, the faster the source code can be read. However, subsequent builds may also depend on disk performance: when dependencies are cached, they still need to be read from the disk to create an executable build of the project. Therefore, the faster the cache can be read from the disk, the faster the project can be compiled.

// Outside of building and executing projects, disk performance plays a role in other operations as well. One such example is the `git status` command, which returns modified files across the monorepo, and is frequently used during the software development lifecycle. The implementation of this command recursively traverses all directories in the monorepo, requiring a significant amount of disk operations. Another example is project-wide code search: most IDE's provide a feature where directories can be scanned for text occurrences in files, where the IDE needs to read the contents of all source files in a given project. Traversing the directories recursively and reading the contents of the source code files are operations that rely on disk performance.

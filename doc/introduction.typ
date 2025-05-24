#import "setup.typ": setup
#show: setup

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
== Research Context
This section introduces the context in which the research is performed.

=== The application
Since the 2000s, a number of large tech companies have adopted the concept of _monorepos_. A monorepo is defined as a software development strategy in which distinct projects are stored in the same repository. Monorepos offer a number of key advantages, such as improved dependency management and code re-use. Within a monorepo, projects can form direct dependencies on each other and re-use the same core libraries. However, monorepos often come with significant scaling challenges, as they can scale up to thousands of projects and billions of lines of code. 

There are a number of modern tooling solutions that facilitate scaling monorepos, such as Bazel. However, even with highly optimized monorepos, it becomes apparent that high-performance hardware is necessary. As the majority of software engineers use laptops for their day-to-day work, they are still restricted by certain characteristics: laptops need to remain transportable, have considerable thermal constraints, and need to optimize power usage. Compiling large apps or running large test suites in monorepos proves to be difficult, even for top-of-the-line laptops.

In order to solve this problem, Uber has developed a cloud-based development environment. The key advantage of cloud-based development environments is that the cloud offers hardware that is significantly more powerful than what is found in laptops. This cloud development environment is the application relevant to this research.

=== Relevance to disk performance
As previously mentioned, Uber has adopted the concept of monorepos for the vast majority of their codebases, and these monorepos are used by engineers using cloud development environments. Within the usage of monorepos, there are a number of scenarios where disk performance is assumed to be relevant. These assumptions are investigated in-depth in the core of this research, but they are introduced in this section to provide context.

There are a number of scenarios related to building and executing projects. In monorepos, projects have direct source code dependencies on other projects and libraries in the same monorepo. When a new instance of the monorepo is cloned and a given project is built, the source code for all dependencies must first be compiled - this is known as a _cold build_. For large projects with many transient dependencies, a cold build could require millions of source code lines being read from the disk in order to be compiled. The more performant the disk is, the faster the source code can be read. However, subsequent builds may also depend on disk performance: when dependencies are cached, they still need to be read from the disk to create an executable build of the project. Therefore, the faster the cache can be read from the disk, the faster the project can be compiled.

Outside of building and executing projects, disk performance plays a role in other operations as well. One such example is the `git status` command, which returns modified files across the monorepo, and is frequently used during the software development lifecycle. The implementation of this command recursively traverses all directories in the monorepo, requiring a significant amount of disk operations. Another example is project-wide code search: most IDE's provide a feature where directories can be scanned for text occurrences in files, where the IDE needs to read the contents of all source files in a given project. Traversing the directories recursively and reading the contents of the source code files are operations that rely on disk performance.

== Problem Statement
Now that the application and it's relevance to disk performance has been introduced, the problem statement of this research is defined as follows.

Uber's cloud development environment is a cloud-based application used by engineers to develop codebases in monorepos. These cloud development environments are currently provisioned with a type of disk known as a Persistent Disk. The cloud provider has recently announced a new type of disk known as a Hyperdisk. Uber would like to investigate a migration from Persistent Disks to Hyperdisks, and needs to have a complete picture of the differences between the disk types, including what their fundamental differences are and how disk performance impacts the overall performance of the application.

Now that the core problem has been identified, we formulate the main research question as follows: \
#box(inset: (left: 18pt))[
  _"What is the impact of Google Cloud Hyperdisks for Cloud Development Environments, as measured by build performance, disk utilization, compared to traditional persistent disks?"_
]

In order to provide an answer to the main question, we will answer the following sub-questions: 
#box(inset: (left: 18pt))[
  + _"How can Hyperdisks be configured to match the raw performance of traditional disks in synthetic benchmarks, as measured by IOPS and data throughput?"_
  + _"How can Hyperdisks be configured to match the real-world performance of traditional disks, as measured by build performance, IDE indexing and git latency?"_
  + _"How is disk utilization affected by pooled Hyperdisks compared to persistent disks?"_
]

== Research Methods
#lorem(100)

== Structure
#lorem(100)

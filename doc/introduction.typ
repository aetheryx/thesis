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

In order to solve this problem, Uber has developed a cloud-based development environment. The key advantage of cloud-based development environments is that the cloud offers hardware that is significantly more powerful than what is found in laptops. This cloud development environment is the application that is investigated in this research.

=== Relevance to disk performance
As previously mentioned, Uber has adopted the concept of monorepos for the vast majority of their codebases, and these monorepos are used by engineers using cloud development environments. Within the usage of monorepos, there are a number of scenarios where disk performance is relevant.

// todo: summarize 4 sections below

One such scenario is cold compilations. In monorepos, projects have direct source code dependencies on other projects and libraries in the same monorepo. When a new instance of the monorepo is cloned and a given project is built, the source code for all dependencies must first be compiled. For large projects with many transient dependencies, this could mean that millions of source code lines have to be read from the disk in order to be compiled. The more performant the disk is, the faster the source code can be read.

Another scenario is related to cached dependencies. The previous paragraph explained that the source code for all dependencies must be compiled at least once. However, for subsequent compilations, dependencies are cached, so that they do not have to be recompiled. When the source code of a project has changed and it's dependencies are cached, these cached dependencies still need to be read from the disk to create an executable build of the project. Therefore, the faster the cached dependencies can be read from the disk, the faster the project can be compiled.

While the first two scenarios are related to building and executing projects, disk performance plays a role in other operations as well. As previously mentioned, monorepos are individual repositories often scaling up to millions of files. The vast amount of directories and files in monorepos can result in disk performance related bottlenecks in other scenarios. One such example is the `git status` command, which returns modified files across the monorepo, and is frequently used during the software development lifecycle. The implementation of this command recursively traverses all directories in the monorepo, requiring a significant amount of disk operations.

Another example is project-wide code search. Most IDE's provide a feature where directories can be scanned for text occurrences in files. For this search functionality, the IDE needs to read the contents of all source files in a given project. Traversing the directories recursively and reading the contents of the source code files are operations that rely on disk performance.

== Problem Statement
#lorem(100)

== Research Methods
#lorem(100)

== Structure
#lorem(100)

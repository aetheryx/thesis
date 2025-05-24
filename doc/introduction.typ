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
== Introduction
This section introduces the relevant contexts for the research. Namely, the application is introduced and its relation to disk performance is described. Further, the problem statement is mentioned, followed by the main question and sub questions. 

== Context of the application
Since the 2000s, a number of large tech companies have adopted the concept of _monorepos_. A monorepo is defined as a software development strategy in which distinct projects are stored in the same repository. Monorepos offer a number of key advantages, such as improved dependency management and code re-use. Within a monorepo, projects can form direct dependencies on each other and re-use the same core libraries. However, monorepos often come with significant scaling challenges, as they can scale up to thousands of projects and billions of lines of code. 

There are a number of modern tooling solutions that facilitate scaling monorepos, such as Bazel. However, even with highly optimized monorepos, it becomes apparent that high-performance hardware is necessary. As the majority of software engineers use laptops for their day-to-day work, they are still restricted by certain characteristics: laptops need to remain transportable, have considerable thermal constraints, and need to optimize power usage. Compiling large apps or running large test suites in monorepos proves to be difficult, even for top-of-the-line laptops.

In order to solve this problem, Uber has developed a cloud-based development environment. The key advantage of cloud-based development environments is that the cloud offers hardware that is significantly more powerful than what is found in laptops. Uber's cloud development environment is used daily by more than 4,000 software engineers.

== Relevance to disk performance
As previously mentioned, Uber has adopted the concept of monorepos for the vast majority of their codebases, and a key characteristic of monorepos are direct dependencies: projects within monorepos can depend on other projects and libraries within the same monorepo.

In order for monorepos to remain performant, it is important that dependencies are cached. This is especially relevant in compiled languages: if a given project has numerous dependencies, the source code of the dependencies should not be compiled every time the project is compiled. With proper caching, dependencies only need to be compiled the first time the project is built.

While caching dependencies allows us to avoid recompiling them, they still need to be used eventually. After the source code of the application is rebuilt, the cached dependencies are retrieved to build an executable binary. It is in this process that disk performance becomes most relevant. As the size of dependencies grows for a given project, the cached dependencies form a considerable amount of data that has to be read from the disk. 


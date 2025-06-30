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
Since the 2000s, the concept of a _monorepo_ has been growing in popularity in the software engineering industry: a monorepo is a software development strategy in which distinct projects are stored in the same repository. Nowadays, the vast majority of large tech companies have adopted monorepos, including Google, Microsoft, Meta and Uber #cite(<brousse-2019>). Monorepos offer a number of key advantages, such as improved dependency management and code re-use. Within a monorepo, projects can form direct source code dependencies on each other and re-use the same core libraries.

However, monorepos often come with significant scaling challenges, as they can scale up to thousands of projects and billions of lines of code. Even with highly optimized monorepos, it becomes apparent that high-performance hardware is necessary. Top-of-the-line laptops are still restricted by certain characteristics: laptops need to remain transportable, have considerable thermal constraints, and need to optimize power usage. Compiling large apps or running large test suites on these laptops proves to be difficult. In order to solve this problem, Uber has developed a cloud-based development environment (CDE), where a key advantage is that the cloud offers hardware that is significantly more powerful than what is found in laptops. In addition to Uber, various other large tech companies have adopted CDE's for a number of advantages #cite(<orosz-2023>).

There are many architectural similarities between Uber's CDE's and the laptops engineers would otherwise use. CDE's run a operating system (Linux), are provisioned with a number of CPU cores, an amount of dedicated RAM, and a storage disk. This storage disk contains all of the files the user needs for development: the repositories they have cloned, any configuration files or local databases they use, and such. This brings us to the topic of this research: the storage disk for Uber's CDE. 

Currently, the CDE's are provisioned with Persistent Disks, a form of network-attached block storage offered by the cloud provider. Recently, the cloud provider has introduced a new type of network-attached disk known as a Hyperdisk #cite(<google-cloud-2023>). The topic of this research is investigating a migration from Persistent Disks to Hyperdisks for Uber's CDE.

== Problem Statement
Now that the application and it's relevance to disk performance has been introduced, the problem statement of this research is defined as follows.

Uber's CDE is a cloud-based application used by engineers to develop codebases in monorepos. Currently, the CDE's provision a form of storage known as a Persistent Disk to store user files. The cloud provider has recently announced a new type of disk known as a Hyperdisk, and Uber would like to investigate a migration from Persistent Disks to Hyperdisks. More specifically, Uber needs a thorough understanding of what the fundamental differences between the disk types are, and how the performance of Uber's CDE is impacted by the migration. Additionally, Hyperdisks offer specific features such as storage capacity pooling, and Uber would like to understand how effective these features are for Uber's CDE.

Now that the core problem has been identified, the main research question is formulated as follows: \
#box(inset: (left: 18pt))[
  _"What is the impact of Hyperdisks compared to Persistent Disks for Uber's Cloud Development Environments, as measured by raw disk performance, monorepo build performance, and disk capacity utilization?"_
]

Before an answer to the main question can be provided, a number of background research topics must be investigated. These background questions are as follows:
#background_questions

With the background research in place, the following sub-questions are formulated in order to provide an answer to the main question:
#box(inset: (left: 18pt))[
  + _"How do the differences in the performance provisioning models of Persistent Disks and Hyperdisks impact the raw disk performance of Uber's CDE?"_
  + _"How does migrating Uber's CDE from Persistent Disks to Hyperdisks affect the build duration of projects?"_
  + _"How do Hyperdisk Storage Pools affect disk capacity utilization compared to Persistent Disks?"_
]

== Research Methods
Firstly, to understand how Hyperdisks can be provisioned, a considerable amount of desk research was performed reading through the documentation of various systems. In terms of the underlying cloud infrastructure, documentation from Google Cloud and Kubernetes proved to be relevant, and these findings are described in @disk_types_provisioned and @diff_between_pd_hd. Additionally, the architecture of Uber's CDE's was investigated in order to understand how the underlying infrastructure can be provisioned, and these findings are described in @section_prov_hd.

With the ability to provision Hyperdisks, the majority of this research consists of experiments and statistical analysis. In each of the chapters, various experiments are performed, often comparing quantified data between Persistent Disks and Hyperdisks. Each experiment is performed using the appropriate tools, which are described in the context leading up to each experiment. 

For certain experiments, advanced data aggregation or parsing is needed. For these experiments, the source code is available in the GitHub repository at #link("https://github.com/aetheryx/thesis"), and the relevant files are referenced in the context surrounding the experiment.

Additionally, the majority of the experiments contain graph visualisations, or have further statistical analysis performed on them. These visualisations are created in Python using the Matplotlib and Numpy libraries in Jupyter notebooks. For reference, the source code to generate each visualisation is available at #link("https://github.com/aetheryx/thesis/tree/main/graphs/src/graphs")[`thesis/graphs`].

Lastly, the content of this research paper itself is written using #link("https://typst.app")[Typst], a markup-based typesetting language. The source content for this paper is available at #link("https://github.com/aetheryx/thesis/tree/main/doc")[`thesis/doc`].

== Structure
The first chapter is the introduction, which describes the problem statement and goal of the research, as well as the applied research methodologies and the structure of the paper.

The second chapter contains the background research necessary to provide answers to the sub-questions. The relevant documentation provided by Google Cloud regarding their disk types are summarized, and a brief overview of how Uber's CDE provisions disks is provided, including the steps taken to provision a CDE using Hyperdisks.

The third, fourth and fifth chapters form the core content of this research paper. Each of these chapters answer their respective sub-questions, and each of these core chapters start with an introduction and end with a conclusion. The third chapter investigates performance impact in a theoretical sense: specifically, it measures how Hyperdisks affect the raw disk performance of Uber's CDE's, and hypothesizes how raw disk performance could theoretically affect real-world performance. The fourth chapter investigates performance impact in a practical sense, where the build duration of real-world projects is compared between Hyperdisks and Persistent Disks. Lastly, the fifth chapter investigates Hyperdisk Storage Pools, which are a Hyperdisk-specific feature that claims to optimize disk capacity utilization. 

Lastly, the sixth chapter provides a conclusive answer to the main question.


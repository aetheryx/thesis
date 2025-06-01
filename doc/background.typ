#import "@preview/codly:1.3.0": *
#import "setup.typ": setup
#show: setup

#let background_questions = box(inset: (left: 18pt))[
  + _"Which disk types does the application currently provision, and for what purpose is each disk type used?"_
  + _"What are the fundamental differences between Hyperdisks and Persistent Disks?"_
  + _"How can the application provision Hyperdisks instead of Persistent Disks?"_
]

= Background Research
== Introduction
In order to answer the main question, a considerable amount of background research is required. This section aims to provide this background research by answering the following questions:
#background_questions

== Disk types provisioned by the application
The application currently provisions two types of disks for different purposes. The first is the Persistent Disk, which is compared against Hyperdisks in this research. Both Persistent Disks and Hyperdisks are forms of network-attached storage. In addition to the Persistent Disk, the application also provisions a form of locally-attached storage. This section explains the difference between network-attached and locally-attached storage, and how the application leverages the different disk types.

=== Local and network-attached disks
The fundamental difference between local disks and network-attached disks is the way they interface with the virtual machine. Local disks have a direct hardware connection to the machine. Within the OSI model, this is considered the lowest layer: the physical layer. On the other hand, network-attached disks interface through a network connection to the machine, which is the third layer within the OSI model. These different attachment methods result in a number of different characteristics between the disks, which are highlighted as follows.

The first characteristic is performance. The performance of locally attached disks is an order of magnitude higher than network-attached disks, primarily due to the fact that they are attached at different layers within the OSI model. Specifically, local disks can scale up to 3.2 million IOPS and 12,480 MiBps of throughput, whereas network-attached disks can only scale up to 120,000 IOPS and 2,200 MiBps of throughput.

The second characteristic is data persistence. Local disks are ephemeral, meaning the data stored on them is discarded if the virtual machine they’re attached to is restarted. This makes local disks more suited for temporary storage use-cases, such as caching. On the other hand, network-attached disks are able to persist their data, making them more suited for long-running use-cases, such as databases. 

=== How the application uses both disks
As previously mentioned, the primary difference between the disk types is that locally attached disks are more performant but ephemeral, and network-attached disks are less performant but persisted. In order for the application to leverage advantages from both disks, each instance of the application is provisioned with a network-attached disk as well as a locally-attached disk, and each disk serves different purposes.

The network-attached disk is used as the primary form of storage for the user's files. Considering that local disks are ephemeral, they are not suited to store user files, as they would not be persisted across restarts. Specifically, the network-attached disk is used for the _home directory_ of a development environment. This includes various things, such as the source code for all repositories the user has cloned, or any local databases or configuration files the user needs. Each development environment is provisioned with 256 GiB of capacity.

The locally-attached disk is used to store the build output and the build cache. As mentioned in the introduction, a key characteristic of monorepos is that dependencies are cached on the disk. By storing this disk cache on a locally-attached disk, the environments can leverage the performance of locally-attached disks. Additionally, the lack of data persistence for locally-attached disks is acceptable, as it merely holds cached build output. It is important to note that locally attached disks are provisioned to virtual machines, and not instances of the application. Each virtual machine is provisioned with 6 TiB of local storage, and a given virtual machine holds around 12 instances of cloud development environments. Effectively, a group of 12 cloud development environments shares the same 6 TiB local disk.

== The differences between Persistent Disks and Hyperdisks
As previously mentioned, this research is primarily a comparison between two network-attached disk types, namely Persistent Disks and Hyperdisks. The application currently uses Persistent Disks. This section describes the differences between the two disk types.

Historically, Persistent Disks were the primary type of network-attached storage offered by the cloud provider. Hyperdisks were introduced more recently, in September 2022. While Persistent Disks have not been deprecated, several new CPU types offered by the cloud provider exclusively support Hyperdisks. Therefore, one could argue that the cloud provider has a long-term strategy to promote Hyperdisks as their primary network-attached disk offering.

Persistent Disks and Hyperdisks have various differences, two of which are most relevant to our research. The first difference lies in how performance is provisioned. The second difference is the pooling capability exclusive to Hyperdisks. These differences are further elaborated in the following sections.

=== Performance provisioning model
For Persistent Disks, disk performance is calculated per virtual machine, meaning that all Persistent Disks attached to a given virtual machine share the same pool of performance resources. The performance resources themselves are calculated by the sum of disk capacity attached to the machine. IOPS scales with 30 IOPS per GiB of capacity, plus an additional 6000 IOPS per machine. Throughput scales with 0.48 MiBps per GiB of capacity, plus an additional 240 MiBps per machine. As an example, consider a machine with 8 Persistent Disks that each have 256 GiB of capacity. In this scenario, the disks attached to the machine share a pool of 67.440 IOPS and 1.223 MiBps of throughput. Under equal contention, these resources are divided by the number of disks, effectively 8.430 IOPS and 152 MiBps of throughput per disk.

The performance provisioning model for Hyperdisks is fundamentally different. For them, performance is statically configured on a per-disk basis, and performance resources are not shared with other volumes attached to the same virtual machine. Each Hyperdisk has a baseline performance of 3.000 IOPS and 140 MiBps of throughput, where additional provisioned performance incurs cost. It is important to note that this additional cost for performance is factored into the cost of capacity: the cost of capacity for Hyperdisks is considerably lower than the cost of capacity for Persistent Disks. In the example model described in the previous paragraph, where each disk receives 8.430 IOPS and 152 MiBps of throughput under contention, the cost of Hyperdisks is nearly equal to the cost of Persistent Disks.

=== Storage pooling
Hyperdisks offer the concept of storage pools, which are pre-purchased collections of capacity and performance. For example, one could purchase a storage pool with 1 TiB of capacity, and attach disks to the pool that share this capacity. The advantage of this approach is that provisioned disk capacity does not count towards the pool capacity until the capacity is in use, i.e. bytes are written to the disk. 

As an example, consider a scenario of 8 cloud development environments. As mentioned previously, each environment is provisioned with 256 GiB of capacity. However, the majority of environments are underutilized: on average, each environment only needs to store 160 GiB of data. Using Persistent Disks, each instance needs to be provisioned with 256 GiB of capacity, totaling 2.048 GiB of capacity in total. However, using Hyperdisk Storage Pools, disks in the same pool share their provisioned capacity: as the average is 160 GiB of capacity across all instances, the storage pool only needs 1.280 GiB of capacity. Each instance of the application would still observe 256 GiB of capacity available, but this capacity is not considered in use until data is stored.

In addition to the ability to share capacity, the cloud provider states that Hyperdisk Storage Pools use various data reduction technologies to increase storage efficiency, presumably data deduplication and compression. The cloud provider does not provide in-depth detail regarding how these data reduction algorithms are implemented, nor what the expected reduction ratio is. Therefore, these claims are further investigated in Chapter TODO.

== Provisioning Hyperdisks for the application
The application currently provisions Persistent Disks for it's network-attached storage use-cases. This section provides a brief overview of the steps taken for the application to provision Hyperdisks instead of Persistent Disks.

=== How disks are provisioned
The application is built on Kubernetes, an orchestration system for containerised applications. Kubernetes is effectively an abstraction on top of the cloud provider used by the application. Practically, this means that the application provisions Persistent Disks by creating Kubernetes resources, and Kubernetes further interfaces with the cloud provider's API to provision the disk. The two relevant Kubernetes resources are the StorageClass resource and the PersistentVolumeClaim resource.

The StorageClass resource defines a specific class of storage that the application is able to provision. Storage classes define the type of underlying disk to provision, for example Persistent Disks or Hyperdisks. Additionally, they define related properties, such as backup policies or encryption strategies.

The PersistentVolumeClaim resource represents a specific provisioned disk. This resource defines which StorageClass is to be used, as well as the disk capacity for the disk and related properties.

=== Current Persistent Disk configuration
Currently, the application has a static StorageClass resource that specifies the Persistent Disk type. This storage class can be defined as follows:
#codly(header: align(center)[*persistent-disk.StorageClass.yaml*])
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: persistent-disk
parameters:
  type: pd-ssd # Specifies the Persistent Disk type for the cloud provider
```

As new instances of the application are provisioned, a PersistentVolumeClaim resource is created, and this PersistentVolumeClaim specifies that the Persistent Disk storage class should be used as follows:
#codly(header: align(center)[*my-pvc.PersistentVolumeClaim.yaml*])
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  storageClassName: persistent-disk # Refers to the storage class above
  resources:
    requests:
      storage: 256 GiB # Creates a 256 GiB disk
```

=== Provisioning Hyperdisks
In order to implement Hyperdisks, a new storage class is created. This storage class specifies that the underlying disk type is a Hyperdisk. Additionally, the storage class defines a number of properties specific to Hyperdisks. The performance resources are defined, meaning the number of IOPS and the throughput in MiBps. This new storage class can be defined as follows:
#codly(header: align(center)[*hyperdisk.StorageClass.yaml*])
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: hyperdisk
parameters:
  type: hyperdisk-balanced
  provisioned-iops-on-create: "3000"
  provisioned-throughput-on-create: "140Mi"
```

If Hyperdisk Storage Pools are used, the storage class for Hyperdisks must additionally specify the name of the storage pool that disks using the storage class should be attached to.
#codly(header: align(center)[*hyperdisk.StorageClass.yaml*])
```diff
 parameters:
   type: hyperdisk-balanced
+  storage-pool: "projects/hva/zones/europe-west/storagePools/my-pool"
```

Additionally, in this case, the storage pool itself must be provisioned. As Hyperdisk Storage Pools are a concept specific to the cloud provider, they cannot be provisioned through Kubernetes. Hyperdisk Storage Pools can be created using the `gcloud` command line tool as follows:
```bash
gcloud compute storage-pools create "my-pool" \
    --project=hva --zone=europe-west4 \
    --storage-pool-type=hyperdisk-balanced \
    --provisioned-capacity=10240 # Capacity in GiB
```

Once the storage class is created, the PersistentVolumeClaims that the application creates can specify the new storage class as follows:
#codly(header: align(center)[*my-pvc.PersistentVolumeClaim.yaml*])
```diff
 spec:
-   storageClassName: persistent-disk
+   storageClassName: hyperdisk
```

With these changes in place, the application provisions Hyperdisks instead of Persistent Disks.

== Conclusion
The application currently uses two kinds of storage types: locally attached storage, which is high performance but not suited for long-term storage, and network-attached storage, which is slower but suited for long-term storage. For network-attached storage, the application currently uses Persistent Disks, and performance for Persistent Disks is shared between other Persistent Disks attached to the same virtual machine. This is fundamentally different for Hyperdisks, where the performance is statically configured on a per-disk basis.

In terms of implementation details, the application uses Kubernetes as an abstraction layer on top of cloud resources. Disk types are defined using Kubernetes StorageClass resources, and disks are provisioned using PersistentVolumeClaim resources. The application can migrate from Persistent Disks to Hyperdisks by creating a new StorageClass for Hyperdisks, and specifying this new storage class when provisioning PersistentVolumeClaims. 


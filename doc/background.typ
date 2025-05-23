#import "@preview/codly:1.3.0": *
#import "setup.typ": setup
#show: setup

= Background Research
== Introduction
In order to answer the main question, a considerable amount of background research is required. This section of the report aims to provide answers to these questions. Namely, the various disk types offered by the cloud provider are introduced and explained, and the steps necessary to provision different disk types for the application are described.

== Disk types
The disks offered by the cloud provider can be categorized in various ways. One of these classifications is the attachment method, which describes how disks are attached to virtual machines: disks can either be *locally attached* or *network-attached*. This research is primarily a comparison between two network-attached storage types, namely Persistent Disks and Hyperdisks. However, local disks are also used by the application, and provide important context regarding the overall relevance of disk performance for the application. Therefore, this section provides an overview of the difference between locally attached and network-attached disks, and then further describes the differences between types of network-attached disks.

=== Local and network-attached disks
The fundamental difference between local disks and network-attached disks is the way they interface with the virtual machine. Local disks have a direct hardware connection to the machine. Within the OSI model, this is considered the lowest layer: the physical layer. On the other hand, network-attached disks rely on a network connection to the machine, which is the third layer within the OSI model. Additionally, network-attached disks are typically located farther away physically. These different attachment methods result in a number of different characteristics between the disks, which are highlighted as follows.

The first characteristic is performance. The performance of locally attached disks is an order of magnitude higher than network-attached disks, primarily due to the fact that they are attached at different layers within the OSI model. Specifically, local disks can scale up to 3.2 million IOPS and 12,480 MiBps of throughput, whereas network-attached disks can only scale up to 120,000 IOPS and 2,200 MiBps of throughput.

The second characteristic is data persistence. Local disks are ephemeral, meaning the data stored on them is discarded if the virtual machine they’re attached to is restarted. This makes local disks more suited for temporary storage use-cases, such as caching. On the other hand, network-attached disks are able to persist their data, making them more suited for long-running use-cases, such as databases. 

=== Network-attached disk types
As previously mentioned, this research is primarily a comparison between two network-attached disk types, namely Persistent Disks and Hyperdisks. The application currently uses Persistent Disks. This section describes the differences between the two disk types.

Historically, Persistent Disks were the primary type of network-attached storage offered by the cloud provider. Hyperdisks were introduced in September 2022. While Persistent Disks have not been deprecated, several new CPU types offered by the cloud provider exclusively support Hyperdisks. Therefore, one could argue that the cloud provider has a long-term strategy to promote Hyperdisks as the primary network-attached disk offering.

Persistent Disks and Hyperdisks have various differences, two of which are most relevant to our research. The first difference lies in how performance is provisioned. The second difference is the pooling capability exclusive to Hyperdisks. These differences are further elaborated in the next sections.

=== Performance provisioning model
For Persistent Disks, disk performance is calculated per virtual machine, meaning that all Persistent Disks attached to a given virtual machine share the same pool of performance resources. The performance resources themselves are calculated by the sum of disk capacity attached to the machine. IOPS scales with 30 IOPS per GiB of capacity, plus an additional 6000 IOPS per machine. Throughput scales with 0.48 MiBps per GiB of capacity, plus an additional 240 MiBps per machine. As an example, consider a machine with 8 Persistent Disks that each have 256 GiB of capacity. In this scenario, the disks attached to the machine share a pool of 67.440 IOPS and 1.223 MiBps of throughput. Under equal contention, these resources are divided by the number of disks, effectively 8.430 IOPS and 152 MiBps of throughput per disk.

For Hyperdisks, performance is statically configured on a per-disk basis, and performance resources are not shared with other volumes attached to the same virtual machine. Each Hyperdisk has a baseline performance of 3.000 IOPS and 140 MiBps of throughput, and additional provisioned performance incurs cost. It is important to note that the additional cost for performance is factored into the cost of capacity: the cost of capacity for Hyperdisks is significantly lower than the cost of capacity for Persistent Disks. In the example model described in the previous paragraph, where each disk receives 8.430 IOPS and 152 MiBps of throughput under contention, the cost of Hyperdisks is nearly equal to the cost of Persistent Disks.

=== Storage pooling
Hyperdisks offer the concept of storage pools, which are pre-purchased collections of capacity and performance. For example, one could purchase a storage pool with 1 TiB of capacity, and attach disks to the pool that share this capacity. The advantage of this approach is that provisioned disk capacity does not count towards the pool capacity until the capacity is in use, i.e. bytes are written to the disk. 

As an example, consider a distributed application with 8 instances. Suppose that the disk capacity usage of each instance fluctuates over time, and that a given instance could use up to 256 GiB of capacity, but the average is only 192 GiB. Using Persistent Disks, each instance needs to be provisioned with 256 GiB of capacity, totaling 2.048 GiB of capacity in total.

However, using Hyperdisk Storage Pools, disks in the same pool share their provisioned capacity: as the average is 192 GiB of capacity across all instances, the storage pool only needs 1.536 GiB of capacity. Each instance of the application would still observe 256 GiB of capacity available, but this capacity is not considered in use until data is stored.

In addition to the ability to share capacity, GCP states that Hyperdisk Storage Pools use various data reduction technologies to increase storage efficiency, presumably data deduplication and compression. GCP does not provide in-depth detail regarding how these data reduction algorithms are implemented, nor what the expected reduction ratio is. Therefore, these claims are further investigated in Chapter TODO.

== Provisioning Hyperdisks for the application
The application currently uses both locally attached disks and network-attached disks. For the network-attached disks, the application currently provisions Persistent Disks. This section provides a brief overview of the steps taken for the application to provision Hyperdisks.

=== How disks are provisioned
The application is built on Kubernetes, an orchestration system for containerised applications. Kubernetes is effectively an abstraction on top of the cloud provider used by the application. Practically, this means that the application provisions Persistent Disks by creating Kubernetes resources, and Kubernetes interfaces with the cloud provider API to provision the disk. The two relevant Kubernetes resources are the StorageClass resource and the PersistentVolumeClaim resource.

The StorageClass resource defines a specific class of storage that the application is able to provision. Storage classes define the type of underlying disk to provision, for example Persistent Disks or Hyperdisks. Additionally, they define related properties, such as backup policies or encryption strategies.

The PersistentVolumeClaim resource represents a specific provisioned disk. This resource defines which StorageClass is to be used, as well as the disk capacity for the disk and related properties.

=== Current Persistent Disk configuration
Currently, the application has a static StorageClass resource that specifies the Persistent Disk type. This StorageClass can be defined as follows:
#codly(header: align(center)[*persistent-disk.StorageClass.yaml*])
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: persistent-disk
parameters:
  type: pd-ssd
```

As new instances of the application are provisioned, a PersistentVolumeClaim resource is created, and this PersistentVolumeClaim specifies that the Persistent Disk storage class should be used as follows:
#codly(header: align(center)[*my-pvc.PersistentVolumeClaim.yaml*])
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  storageClassName: persistent-disk
  resources:
    requests:
      storage: 256 GiB # Creates a 256 GiB disk
```

=== Provisioning Hyperdisks
In order to implement Hyperdisks, a new storage class is created. This storage class specifies that the underlying disk type is a Hyperdisk. Additionally, the storage class defines a number of properties specific to Hyperdisks. The performance resources are defined, meaning the number of IOPS and the throughput in MiBps. 
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

Additionally, in this case, the storage pool itself must be provisioned. As Hyperdisk Storage Pools are highly specific to GCP, they cannot be provisioned through Kubernetes. Hyperdisk Storage Pools can be created using the `gcloud` command line tool as follows:
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

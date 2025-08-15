#[
  #set heading(outlined: false, numbering: none)
  = Abstract
]
This paper investigates the impact of migrating Uber's Cloud Development Environments from Persistent Disks to Hyperdisks according to three criteria: raw disk performance, project build duration in monorepos, and disk capacity utilization. A variety of experiments are conducted, including synthetic experiments to understand the low-level behavior of various technologies, as well as practical experiments to determine real-world impact.

The results of the experiments indicate various advantages and disadvantages of Hyperdisks. Hyperdisks significantly reduce raw disk performance compared to Persistent Disks, as Hyperdisks provision performance statically, negating the performance advantage of resource sharing for bursty workloads. Despite the reduction in raw disk performance, Hyperdisks have a minimal impact on build performance in monorepos for Uber's CDE: build durations increase by 0,9% on average. This is because monorepos can be configured to use ephemeral storage for disk-heavy workloads. Lastly, Hyperdisk Storage Pools proved to be extremely effective at reducing total storage capacity, with estimations of up to 68,5%. 

Overall, adopting Hyperdisks is a sensible strategy. First, the storage utilization improvements result in significant cost savings. Second, the fact that build durations are minimally impacted implies that the majority of users will not be negatively affected. Finally, for the users who are negatively affected by the reduction in raw disk performance, their issues can be mitigated by provisioning additional performance, which can be funded using the cost savings from the capacity optimizations.

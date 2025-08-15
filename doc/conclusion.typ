#import "lib/setup.typ": setup
#show: setup

// De conclusies
// In het hoofdstuk 'conclusies' formuleer je een kort antwoord op je probleemvraag.
// (onderzoeksvraag/probleemstelling). Uitgebreide motiveringen zijn hier uit den boze, want die staan al
// in de kernhoofdstukken. De conclusies zijn echter gebaseerd op het uitgevoerde literatuur- en
// praktijkonderzoek en de vergelijking tussen die twee onderzoeksgebieden.
// Conclusies zijn gevolgtrekkingen. Ze geven aan in hoeverre de probleemstelling is opgelost en wat de
// betrouwbaarheid is van het verrichte onderzoek. Onthoud:
// • conclusies moeten begrijpelijk, kort en informatief zijn;
// • conclusies mogen geen nieuwe informatie bevatten: de onderbouwing moet in de hoofdstukken terug
// te vinden zijn;
// • zet conclusies altijd in de tegenwoordige tijd.
// N.B. Het is niet zo dat conclusies een samenvatting overbodig maken, want ze komen daarin slechts
// beknopt terug.

= Conclusion
An answer to the main question can now be derived from the answers to each of the sub-questions. To reiterate, the main question is as follows: _"What is the impact of Hyperdisks compared to Persistent Disks for Uber's Cloud Development Environments, as measured by raw disk performance, monorepo build performance, and disk capacity utilization?"_

Firstly, the impact on raw disk performance is investigated in @perf_prov. The fundamental difference is that Hyperdisks allocate performance statically per disk, and Persistent Disks allocate performance shared in a pool of disks. Under equal configurations, pooled performance is much more advantageous for Uber's CDEs: without it, raw disk performance is severely reduced, by up to 10 times. In conclusion, Hyperdisks severely reduce raw disk performance, although additional performance can be allocated at additional cost.

The next chapter, @build_perf, investigates how the build duration of projects in monorepos is impacted by Hyperdisks. Despite the fact that Hyperdisks reduce raw disk performance, build duration proves to be minimally impacted: across the monorepos, Hyperdisks result in an average 0,9% increase in build duration. This is due to the fact that the monorepos can be configured to use ephemeral storage for disk-heavy workloads. In conclusion, Hyperdisks minimally impact the build duration of projects in monorepos.

Lastly, chapter @disk_cap investigates how Hyperdisk Storage Pools affect disk utilization. Thin provisioning is estimated to reduce total storage capacity significantly, by up to 68,5%. Data reduction is determined to be minimally relevant to Uber's CDEs. Lastly, a subset of production CDEs is cloned and provisioned in a storage pool in order to predict capacity reduction in practice. A 68,28% reduction in total capacity is observed, improving storage utilization from 30,74% to 96,91%. In conclusion, Hyperdisk Storage Pools significantly improve storage utilization for Uber's CDE fleet, reducing total storage capacity by up to 68,5%.

To conclude: by adopting Hyperdisks for Uber's CDE, raw disk performance is significantly reduced, build duration is minimally impacted, and disk capacity utilization is significantly improved. Overall, adoption of Hyperdisks is a sensible strategy. Firstly, the storage utilization improvements result in significant cost savings. Secondly, the fact that build duration is minimally impacted implies that the majority of users will not be affected negatively. And lastly, for the users who are negatively affected by the reduction in raw performance, their problems can be mitigated by provisioning extra performance for them, which can be funded using the cost savings from the capacity optimizations.
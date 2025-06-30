// Inleiding: Aanleiding, Onderwerp, Onderzoeksvraag (doelstelling), Deelvragen, Structuur
// Kernhoofdstukken: Theoretisch kader & methodologie, Resultaten in het onderzoeksverslag: de argumenten, (deelconclusies: sub-standpunten), 
// Laatste hoofdstuk: Conclusie(s), hoofdstandpunt(en), aanbeveling(en)

// De indeling van een afstudeerrapport volgt een vaste volgorde:
// - omslag/voorblad;
// - titelpagina;
// - (voorwoord);
// - Samenvatting;
// - Inhoudsopgave (nummer de hoofdstukken tot bronnen);
// - Inleiding;
// - het kerngedeelte;
// - conclusies;
// - aanbevelingen;
// - (noten);
// - bronnenlijst;
// - (nawoord/reflectie);
// - (begrippenlijst);
// - bijlage(n) (nummer de bijlagen apart).
// De onderdelen die tussen haakjes staan zijn facultatief.

#let glossary_entries = (
  cde: (
    short: "CDE",
    long: "cloud development environment",
    description: "An on-demand, pre-configured development environment that runs in the cloud."
  ),
  bazel: (
    short: "Bazel",
    description: "A build system built by Google to create scalable monorepos."
  ),
  monorepo: (
    short: "monorepo",
    description: "A source code repository that holds multiple distinct projects that can form source code dependencies on each other, as well as core libraries."
  )
)

#import "setup.typ": setup
#show: setup

#import "@preview/glossy:0.8.0": *

#show: init-glossary.with(glossary_entries)


// title
#include "cover.typ"
#pagebreak()

// abstract
#include "abstract.typ"
#pagebreak()

// toc
#outline(title: "Table of Contents", depth: 3)
#pagebreak()

// glossary
#set heading(numbering: none)
#glossary(groups: (""), show-all: true)
#pagebreak()

// introduction
#include "introduction.typ"
#pagebreak()

// background research
#include "background.typ"
#pagebreak()

// core content
#include "perf_prov.typ"
#pagebreak()
#include "builds.typ"
#pagebreak()
#include "disk_cap.typ"
#pagebreak()

// conclusion
#include "conclusion.typ"
#pagebreak()

// bibliography
#bibliography("bibliography.bib", style: "apa")
#pagebreak()

// appendix
#include "appendix.typ"

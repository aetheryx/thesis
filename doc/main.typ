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

#import "lib/setup.typ": setup
#show: setup

#import "@preview/glossy:0.8.0": *
#import "lib/glossy-theme.typ": glossy-theme
#show: init-glossary.with(yaml("lib/glossary.yaml"))

// title
#include "cover.typ"
#pagebreak()

// abstract
#include "abstract.typ"
#pagebreak()

// toc
#place(outline(title: "Table of Contents", depth: 2))
#pagebreak()

// glossary
#[
  #set heading(numbering: none, bookmarked: false, outlined: false)
  #glossary(groups: (""), show-all: true, theme: glossy-theme)
  #pagebreak()  
]

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

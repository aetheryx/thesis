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

#import "setup.typ": setup
#show: setup

// title
#include "cover.typ"
#pagebreak()

// abstract
#include "abstract.typ"
#pagebreak()

// toc
#outline(title: "Table of Contents")
#pagebreak()

// introduction
#include "introduction.typ"

// core content
#include "background.typ"
#pagebreak()
#include "perf_prov.typ"
#include "primary.typ"

// conclusion
#include "conclusion.typ"

#include "appendix.typ"
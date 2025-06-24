// Omslag/voorblad
// Op de omslag komt minstens het volgende te staan:
// - titel;
// - (ondertitel);
// - naam organisatie of bedrijf;
// - auteursnaam;
// - naam of namen van begeleider(s) van de HvA en vanuit het bedrijf.
// De informatie op de omslag wordt overzichtelijk weergegeven. De belangrijkste informatie is de titel met
// eventuele ondertitel. Deze informatie neemt de meeste ruimte in beslag en komt over het algemeen
// bovenaan in het midden te staan. De overige informatie plaats je rechts onderaan op de omslag.

// De titelpagina
// Op de titelpagina komt in ieder geval dezelfde informatie als op de omslag te staan. Deze informatie
// wordt aangevuld. De titelpagina bevat geen citaten, geen dankwoorden en geen illustraties, maar wel:
// - titel(s);
// - auteursnaam (-namen), naam en voorletter(s), studentennummer en telefoonnummer;
// - plaats en datum;
// - versie;
// - naam van de onderwijsinstelling;
// - naam van de opleiding/studierichting/leerroute;
// - begeleidende docent van de HvA;
// - bedrijf, afdeling, adres en telefoonnummer;
// - bedrijfsbegeleider;
// - stageperiode (semester, studiejaar).

#import "setup.typ": setup
#show: setup

#image("images/hva-logo.png")

#align(center, text(22pt)[
  Investigating Google Cloud Hyperdisks for Uber's Cloud Development Environment
])

#v(1fr)

#let authors = grid(
  columns: (1fr, 1fr, 1fr),
  align: center + top,
  [
    *Author* \
    Zain Ali \
    #link("mailto:mhzy.ali@gmail.com")
  ], [
    *Thesis Supervisor* \
    Ian Bradford \
    #link("mailto:i.m.bradford@hva.nl") \
  ], [
    *Company Supervisor* \
    Matas Antanas \
    #link("mailto:mstrukci@uber.com")
  ]
)

#let orgs = grid(
  columns: (1fr, 1fr),
  align: center + top,
  [
    *Institution* \
    Hogeschool van Amsterdam \
    Wibautstraat 3b \
    FDMCI
  ],
  [
    *Company* \
    Uber B.V. \
    Burgerweeshuispad 301 \
    Developer Platform
  ]
)

#grid(
  rows: auto,
  row-gutter: 28pt,
  authors, orgs
)

#v(2fr)

#align(center + bottom)[
  Version 0.1 \
  23 May 2025
]
#import "setup.typ": setup
#show: setup

#image("HvA-HBO-ICT-zwart-RGB.png")

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
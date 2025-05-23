// shared settings
#set heading(numbering: "1.")
#set text(
  font: "libertinus serif",
  size: 12pt
)

// set up codly
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
#codly(
  languages: codly-languages,
  zebra-fill: none
)

// title
#include "title.typ"
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
#include "core.typ"

// conclusion
#include "conclusion.typ"


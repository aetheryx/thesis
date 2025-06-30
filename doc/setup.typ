// shared settings
#let setup(doc) = {
  set heading(numbering: "1.")
  set text(
    font: "libertinus serif",
    size: 12pt
  )

  show link: set text(rgb("#0857c9"))
  show cite: set text(rgb("#0857c9"))

  // set up codly
  import "@preview/codly:1.3.0": *
  import "@preview/codly-languages:0.1.1": *
  show: codly-init.with()
  codly(
    languages: codly-languages,
    zebra-fill: luma(245)
  )

  set raw(syntaxes: "syntaxes/promql.sublime-syntax")

  doc
}

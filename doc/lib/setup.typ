// shared settings
#let setup(doc) = {
  set heading(numbering: "1.")
  set text(
    font: "libertinus serif",
    size: 12pt
  )
  set page(numbering: "1")

  show heading.where(level: 3) : set heading(bookmarked: false)
  show heading.where(level: 4) : set heading(bookmarked: false)
  show heading.where(level: 5) : set heading(bookmarked: false)

  show link: set text(rgb("#0857c9"))
  // show ref.where(): set text(rgb("#0857c9"))
  show ref: it => {
    if it.element != none {
      set text(rgb("#0857c9"))
      it 
    } else {
      it
    }
  }
  show cite: set text(rgb("#0857c9"))
  show footnote: set text(rgb("#0857c9"))

  // set up codly
  import "@preview/codly:1.3.0": *
  import "@preview/codly-languages:0.1.1": *
  show: codly-init.with()
  codly(
    languages: codly-languages,
    zebra-fill: luma(245)
  )

  set raw(syntaxes: "./promql.sublime-syntax")

  doc
}

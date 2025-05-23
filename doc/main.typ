#import "setup.typ": setup
#show: setup

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


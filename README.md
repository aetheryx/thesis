# thesis
The supplemental repository for my Bachelor's thesis: Investigating Google Cloud Hyperdisks for Cloud Development Environments

## Contents
- [`doc/`](doc/): Contains the contents of the thesis document itself, written in the [Typst](https://typst.app/) markup language
- [`graphs/`](graphs/): Contains the Jupyter notebooks used to create visualisations of experiment results, as well as the raw CSV data containing the results themselves
- [`noise/`](noise/): Contains the scripts used to aggregate sampled noisy neighbor occurrences (see Section 3.4.2)
- [`strace/`](strace/): Contains the scripts used to quantify and analyze disk operations made by Bazel, using the `strace` tool (see Section 4.3.1)
- [`data-reduction`](data-reduction/): Contains the scripts used to investigate data reduction algorithms in storage pools (see Section 5.3)

#!/bin/bash

# Usage: cat report.json | ./de-identify.sh <threshold>

# The threshold defines a limit on on stratifier population size. All strata
# with a population smaller than threshold, will be combined into one strata
# with the sum of all population sizes. If the combined size is still smaller
# than threshold, the count will be masked.
jq --arg threshold "${1:-10}" -f de-identify.jq

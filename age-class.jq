include "util";

["age-class", "count"],
(.group[1].stratifier[3].stratum[] | [.value.text, count(.population[0])])
| @csv

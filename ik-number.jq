include "util";

["ik-number", "count"],
(.group[1].stratifier[0].stratum[] | [.value.text, count(.population[0])])
| @csv

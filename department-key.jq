include "util";

["department-key", "count"],
(.group[1].stratifier[1].stratum[] | [.value.text, count(.population[0])])
| @csv

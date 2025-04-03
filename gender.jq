include "util";

["gender", "count"],
(.group[1].stratifier[2].stratum[] | [.value.text, count(.population[0])])
| @csv

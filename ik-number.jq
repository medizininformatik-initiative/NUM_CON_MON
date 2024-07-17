["ik-number", "count"],
(.group[1].stratifier[0].stratum[] | [.value.text, .population[0].count])
| @csv

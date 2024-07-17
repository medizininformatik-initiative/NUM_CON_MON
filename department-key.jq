["department-key", "count"],
(.group[1].stratifier[1].stratum[] | [.value.text, .population[0].count])
| @csv

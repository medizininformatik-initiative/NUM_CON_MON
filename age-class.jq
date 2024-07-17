["age-class", "count"],
(.group[1].stratifier[3].stratum[] | [.value.text, .population[0].count])
| @csv

["gender", "count"],
(.group[1].stratifier[2].stratum[] | [.value.text, .population[0].count])
| @csv

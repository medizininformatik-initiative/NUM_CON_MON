# Function to process a stratifier and combine its low-count strata
def process_stratifier(stratifier):

  stratifier as $stratifier |

  # Separate strata into those below threshold and those not
  stratifier.stratum // [] | [.[] |
    . as $stratum |
    ($stratum.population[0].count | tonumber) as $count |
    if $count < ($threshold | tonumber) then
      {
        below_threshold: true,
        original: $stratum
      }
    else
      {
        below_threshold: false,
        original: $stratum
      }
    end
  ] as $processed_strata |

  # Create the new stratifier
  {
    stratum: (
      # First, collect all objects that need to be de-identified
      ($processed_strata | map(select(.below_threshold == true))) as $below_threshold_items |

      # Keep all strata that are above threshold
      ($processed_strata | map(select(.below_threshold == false).original)) +

      # If there are any below-threshold strata, combine them
      if ($below_threshold_items | length) > 0 then
        # Sum all counts
        $below_threshold_items | map(.original.population[0].count) | add as $combined_count |

        [{
          # Combine all texts with a comma
          value: {
            text: ($below_threshold_items | map(.original.value.text) | join(", "))
          },
          population: (if $combined_count < $threshold then [
            {
              _count: {
                extension: [{
                  url: "http://hl7.org/fhir/StructureDefinition/data-absent-reason",
                  valueCode: "masked"
                }]
              },
              code: $below_threshold_items[0].original.population[0].code
            }
          ] else [
            {
              count: $combined_count,
              code: $below_threshold_items[0].original.population[0].code
            }
          ] end)
        }]
      else
        []
      end
    ),
    code: $stratifier.code,
  };

# Process the entire MeasureReport
. as $report |
{
  # Copy all fields from the original report
  "date": $report.date,

  # Process the group array
  "group": [
    # First group element - copy as is
    $report.group[0],

    # Second group element - process its stratifiers
    {
      # Process each stratifier
      "stratifier": [
        # For each stratifier, process its strata
        $report.group[1].stratifier[] | process_stratifier(.)
      ],

      # Copy the population from the original
      "population": $report.group[1].population
    }
  ],

  "type": $report.type,
  "resourceType": $report.resourceType,
  "measure": $report.measure,
  "extension": $report.extension,
  "status": $report.status,
  "period": $report.period
}

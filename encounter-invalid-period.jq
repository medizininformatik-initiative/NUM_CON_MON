# use via:
# blazectl --server http://localhost:8080/fhir download Encounter -q 'status=finished&_count=1000' | jq -rf encounter-invalid-period.jq > encounter-invalid-period.csv

# strptime may need "%Y-%m-%dT%H:%M:%SZ" depending on date format
select(
  .period.start == null or .period.end == null or
  (.period.start | strptime("%Y-%m-%d")) > (.period.end | strptime("%Y-%m-%d"))
)
| [.id, .period.start, .period.end]
| @csv

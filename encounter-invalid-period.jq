# use via:
# blazectl --server http://localhost:8080/fhir download Encounter -q 'status=finished&_count=1000' | jq -rf encounter-invalid-period.jq > encounter-invalid-period.csv

select(
  .period.start == null or .period.end == null or
  (.period.start | 'sub("(?<h>[+-][0-9]{2}):(?<m>[0-9]{2})$"; "\(.h)\(.m)") | strptime("%Y-%m-%dT%H:%M:%S%z") | mktime)
  > (.period.end | 'sub("(?<h>[+-][0-9]{2}):(?<m>[0-9]{2})$"; "\(.h)\(.m)") | strptime("%Y-%m-%dT%H:%M:%S%z") | mktime)
)
| [.id, .period.start, .period.end]
| @csv

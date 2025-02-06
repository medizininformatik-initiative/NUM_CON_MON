#!/bin/bash -e

create_bundle() {
  auth="$1"
  if ! doc_ref_id=$(get_doc_ref_id "$auth")
  then
    echo "$doc_ref_id"
    exit 1
  fi

  report=$(cat "$report_file")
  doc_ref_url="01"
  report_url="02"

  tz=$(date +"%z")  # e.g. "+0100"
  tz=$(echo "$tz" | sed -E 's/^([+-][0-9]{2})([0-9]{2})$/\1:\2/') # +0100 -> +01:00
  # -> this can be done with %:z, but '%:z' is not supported at all versions of the date command

  date="$(date +"%Y-%m-%dT%H:%M:%S")${tz}"

bundle=$(cat <<END
{
  "resourceType": "Bundle",
  "type": "transaction",
  "entry": [
    {
      "resource": {
        "resourceType": "DocumentReference",
        "masterIdentifier": {
          "value": "$proj_ident_val",
          "system": "$proj_ident_sys"
        },
        "author": [
          {
            "type": "Organization",
            "identifier": {
              "value": "$author_ident_val",
              "system": "$author_ident_sys"
            }
          }
        ],
        "docStatus": "final",
        "date": "$date",
        "content": [
          {
            "attachment": {
              "contentType": "application/fhir+xml",
              "url": "$report_url"
            }
          }
        ],
        "status": "current"
      },
      "fullUrl": "$doc_ref_url",
      "request": {
        "url": "",
        "method": ""
      }
    },
    {
      "resource": $report,
      "fullUrl": "$report_url",
      "request": {
        "url": "MeasureReport",
        "method": "POST"
      }
    }
  ]
}

END
)

  if [[ $doc_ref_id != "" ]]; then
    bundle=$(echo "$bundle" | jq -c "
                .entry[0].request.url = \"DocumentReference/$doc_ref_id\" |
                .entry[0].resource.id = \"$doc_ref_id\" |
                .entry[0].request.method = \"PUT\"" )
  else
    bundle=$(echo "$bundle" | jq -c "
                .entry[0].request.url = \"DocumentReference\" |
                .entry[0].request.method = \"POST\"")
  fi
  echo "$bundle"
}

usage() {
    echo "Usage: $0 <report-file> <report-server>"
    echo "       $0 <report-file> <report-server> [-u <user> -p <password>]"
    echo "       $0 <report-file> <report-server> [-i <issuer-url> -c <client-id> -s <client-secret>]"
    exit 1
}

if [[ $# -lt 2 ]]; then
    usage
fi

report_file="$1"
report_server="$2"
author_ident_sys="http://medizininformatik-initiative.de/sid/author-identifier"
author_ident_val="num-con-mon-script"
proj_ident_sys="http://medizininformatik-initiative.de/sid/project-identifier"
proj_ident_val="num-con-mon"

user=""
password=""
issuer_url=""
client_id=""
client_secret=""

read_http_args() {
    while getopts ":u:p:i:c:s:" opt; do
            case $opt in
                u)
                    user="$OPTARG"
                    ;;
                p)
                    password="$OPTARG"
                    ;;
                i)
                    issuer_url="$OPTARG"
                    ;;
                c)
                    client_id="$OPTARG"
                    ;;
                s)
                    client_secret="$OPTARG"
                    ;;
                *)
                    echo "Unknown option: -$OPTARG"
                    usage
                    ;;
            esac
        done
}

get_matching_identifier_refs() {
    auth="$1"
    if [ "$auth" == "no-auth" ]; then
        response=$(blazectl download --server "$report_server" DocumentReference \
                                              --query "identifier=$proj_ident_sys|$proj_ident_val")
        echo "$response"
    elif [ "$auth" == "basic-auth" ]; then
        response=$(blazectl download --server "$report_server" DocumentReference \
                                     --query "identifier=$proj_ident_sys|$proj_ident_val"\
                                     --user "$user" --password "$password")
        echo "$response"
    else
        oauth_response=$(curl -s -X POST "$issuer_url" \
                            -H "Content-Type: application/x-www-form-urlencoded" \
                            -d "grant_type=client_credentials" \
                            -d "client_id=$client_id" \
                            -d "client_secret=$client_secret")
        fhir_report_bearer_token=$(echo "$oauth_response" | jq -r '.access_token')

        response=$(blazectl download --server "$report_server" DocumentReference \
                                             --query "identifier=$proj_ident_sys|$proj_ident_val"\
                                             --token "$fhir_report_bearer_token")
        echo "$response"
    fi
}

get_doc_ref_id() {
    auth="$1"
    matching_refs=$(get_matching_identifier_refs "$auth")

    count=$(echo "$matching_refs" | jq -s 'length')

    if [[ "$count" -gt 1 ]]; then
        echo "Error: Multiple DocumentReferences exist for masterIdentifier {system: '$proj_ident_sys', value: '$proj_ident_val'}"
        exit 1
    elif [[ "$count" -eq 1 ]]; then
        doc_id=$(echo "$matching_refs" | jq -r '.id')
        echo "$doc_id"
    else
        echo ""
    fi
}

http_send_bundle() {
    auth="$1"
    bundle_dir="$2"
    if [ "$auth" == "no-auth" ]; then
        response=$(blazectl upload --server "$report_server" "$bundle_dir")
        echo "$response"
    elif [ "$auth" == "basic-auth" ]; then
        response=$(blazectl upload --server "$report_server" "$bundle_dir" --user "$user" --password "$password")
        echo "$response"
    else
        oauth_response=$(curl -s -X POST "$issuer_url" \
                            -H "Content-Type: application/x-www-form-urlencoded" \
                            -d "grant_type=client_credentials" \
                            -d "client_id=$client_id" \
                            -d "client_secret=$client_secret")
        fhir_report_bearer_token=$(echo "$oauth_response" | jq -r '.access_token')

        response=$(blazectl upload --server "$report_server" "$bundle_dir" --token "$fhir_report_bearer_token")
        echo "$response"
    fi
}

if [[ $# == 2 ]]; then
    echo "Using FHIR URL without authentication."
    auth="no-auth"
else
    read_http_args "${@:3}"

    if [[ -n "$user" && -n "$password" ]]; then
        echo "Using FHIR URL with user/password authentication."
        auth="basic-auth"

    elif [[ -n "$issuer_url" && -n "$client_id" && -n "$client_secret" ]]; then
        echo "Using FHIR URL with OAuth2 client credentials."
        auth="oauth"
    else
        echo "Error: Missing required arguments for FHIR URL authentication."
        usage
    fi
fi

if ! bundle=$(create_bundle "$auth")
then
  echo "$bundle"
  exit 1
fi

# Writing bundle into a file because curl can't handle big data directly as argument
bundle_dir=$(mktemp -d)
echo "$bundle" > "$bundle_dir"/bundle.json

http_send_bundle "$auth" "$bundle_dir"

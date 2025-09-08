#!/bin/bash
# Usage: ./start.sh [local]

source elastic.env
JSON_FILE="./assets/all_songs_data.json"
INDEX_NAME="songs"

case $# in
  0)
    export RUN_ENV=local
    ;;
  1)
    if [ "$1" != "local" ]; then
        export RUN_ENV=$1
    else
      echo "Invalid argument. Use 'local'."
      exit 1
    fi
    ;;
  *)
    echo "Usage: $0 [local]"
    exit 1
    ;;
esac

function start_serverless() {
    echo -e "\nStarting serverless project"
    read -r PROJECT_ID ES_URL ES_USERNAME ES_PASSWORD < <(echo $(curl -s -X POST $ES_SERVERLESS_URL \
        -H "Authorization: ApiKey $ES_SERVERLESS_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
        "name": "demo-project",
        "region_id": "gcp-us-central1",
        "optimized_for": "general_purpose"
        }' | jq -r '.id, .endpoints.elasticsearch, .credentials.username, .credentials.password'))

    echo "PROJECT_ID=$PROJECT_ID"
    echo "ES_URL=$ES_URL"
    echo "ES_USERNAME=$ES_USERNAME"
    echo "ES_PASSWORD=$ES_PASSWORD"

    echo -e "\nRUN_ENV=$RUN_ENV" >> elastic.env
    echo -e "\nPROJECT_ID=$PROJECT_ID" >> elastic.env
    export ES_URL=$ES_URL


    while true; do
        sleep 10
        PHASE=$(curl -s -X GET $ES_SERVERLESS_URL/$PROJECT_ID/status \
            -H "Authorization: ApiKey $ES_SERVERLESS_API_KEY" \
            -H "Content-Type: application/json" | jq -r '.phase')
        if [ "$PHASE" == "initialized" ]; then
            break
        fi
    done

    export ES_API_KEY=$(curl -s -X POST $ES_URL/_security/api_key \
        -u $ES_USERNAME:$ES_PASSWORD \
        -H "Content-Type: application/json" \
        -d '{"name": "demo-key"}' | jq -r .encoded)
    echo "ES_API_KEY=$ES_API_KEY"
}

function load_data() {
    echo -e "\nLoading data into serverless Elasticsearch"

    jq -c -r --arg index_name $INDEX_NAME '.[] | {"index": {"_index": $index_name}}, .' "$JSON_FILE" > bulk_payload.json
    curl -s -X POST $ES_URL/_bulk \
    -H "Content-Type: application/x-ndjson" \
    -H "Authorization: ApiKey $ES_API_KEY" \
    --data-binary "@bulk_payload.json" > /dev/null
    rm bulk_payload.json
}

function start_mcp() {
    echo -e "\nStarting MCP Docker container"
    case $RUN_ENV in
      local)
        docker run --rm -d -p 8080:8080 -e ES_URL -e ES_API_KEY --name mcp docker.elastic.co/mcp/elasticsearch http
        ;;
      *)
        echo "Invalid runtime environment: $RUN_ENV"
        exit 1
        ;;
    esac
}

function start_adk() {
    echo -e "\nStarting ADK"
    case $RUN_ENV in
      local)
        nohup adk web agents > /dev/null 2>&1 &
        google-chrome http://localhost:8000 &
        ;;
      *)
        echo "Invalid runtime environment: $RUN_ENV"
        exit 1
        ;;
    esac
}


start_serverless
load_data
start_mcp
start_adk
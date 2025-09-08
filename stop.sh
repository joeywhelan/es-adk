#!/bin/bash
# Usage: ./stop.sh [local]

source elastic.env

function stop_serverless() {
    echo -e "\nStopping serverless project"
    curl -s -X DELETE $ES_SERVERLESS_URL/$PROJECT_ID \
        -H "Authorization: ApiKey $ES_SERVERLESS_API_KEY"
    sed -i "/^PROJECT_ID=$PROJECT_ID/d" elastic.env
}

function stop_mcp() {
    echo -e "\nStopping MCP server"
    case $RUN_ENV in
      local)
        docker ps -q --filter "ancestor=docker.elastic.co/mcp/elasticsearch" | xargs -r docker stop
        ;;
      *)
        echo "Invalid runtime environment: $RUN_ENV"
        exit 1
        ;;
    esac
}

function stop_adk() {
    echo -e "\nStopping ADK"
    case $RUN_ENV in
      local)
        pkill adk
        ;;
      *)
        echo "Invalid runtime environment: $RUN_ENV"
        exit 1
        ;;
    esac
}

stop_serverless
stop_mcp
stop_adk
sed -i "/^RUN_ENV=$RUN_ENV/d" elastic.env
sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' elastic.env



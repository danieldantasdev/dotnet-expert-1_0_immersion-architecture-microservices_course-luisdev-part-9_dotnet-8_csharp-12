#!/bin/bash

while true
    do
    result=$(curl http://rabbitmq:15672/api/health/checks/port-listener/15672 -s -u  guest:guest | grep '\"status\":\"ok\"')
    if [ ! -z "$result" ]
    then
        break
    fi
    sleep 2
done

curl -X PUT http://rabbitmq:15672/api/exchanges/%2F/payment-service -u guest:guest -H 'Content-Type: application/json'  -d '{"type":"topic","durable":true}'
curl -X PUT http://rabbitmq:15672/api/exchanges/%2F/order-service -u guest:guest -H 'Content-Type: application/json'  -d '{"type":"topic","durable":true}'
curl -X PUT http://rabbitmq:15672/api/queues/%2f/order-service%2fpayment-accepted -u guest:guest  -H 'Content-Type: application/json' -d '{ "auto_delete": false, "durable": true, "arguments": {}}'
curl -X PUT http://rabbitmq:15672/api/queues/%2f/payment-service%2forder-created -u guest:guest  -H 'Content-Type: application/json' -d '{ "auto_delete": false, "durable": true, "arguments": {}}'
# API Gateway Workshop

## Docker Compose 
Definição de serviços e portas
Service|Port|URL
-|-|-
Keycloak|8080|http://localhost:8080
Mongo|27017
Postgres|5432
ElasticSearch|9200
Kibana|5601|http://localhost:5601
Prometheus|9090
Grafana|3080|http://localhost:3080
Zipkin|9411|http://localhost:9411
Cors-Test|4000|http://localhost:4000
RabbitMQ|15672|http://localhost:15672
Kong|8443 (Proxy) / 8002 (GUI)|  GUI - http://localhost:8002<br>Proxy - https://localhost:8443
AwesomeShop Orders|8070

## Kong

### Controle de Tráfego (parte 1)

- **Routing** - Criação de rotas para os serviços (Request Transformer Plugin)

#### Service
Config|Value
-|-
Name|awesomeshop-orders-api
URL|http://awesomeshop-orders-api:80

**Rota no service: GET**
Config|Value
-|-
Name|get-orders
Strip Path|off

**Rota no service: POST**
Config|Value
-|-
Name|post-orders
Strip Path|off

**Alteração de rota**
Alteração na rota get-orders
Config|Value
-|-
Path|/api/orders/(?<id>.*)
Strip Path|on


Plugin Request Transformer na rota get-orders

Config|Value
-|-
Config.Append.Querystring|id:$(uri_captures[1])
Config.Replace.Uri|/api/orders
Config.Remove.QueryString|id

### Observabilidade (parte 1)
* **Logging** para identificação das requisições (direcionando para o ELK 

Config|Value
-|-
Plugin|HTTP Log
Config.Mehtod|POST 
Config.Http Endpoint|http://elasticsearch:9200/kong/_doc/


### Segurança

* **Autenticação** por KeyAuth no serviço

Config|Value
-|-
Config.Key In Header|on
Config.Key Names|apikey

* Criaçao de **Consumer** para permitir utilizar o gateway

Config|Value
-|-
Name|orders-client
Credentials| KeyAuth (API Key aleatória)

* **Autorização** por grupos de acesso
Plugin ACL

Route|Config.Allow
-|-
get-orders|readers
post-orders|writers

Consumer orders-client
ACL > Add Group to Consumer > Readers

* Ativação de **CORS**
    - Ativação de método OPTIONS na rota
    - Ativação de plugin CORS no Serviço
        Config|Value
        -|-
        Methods|GET, POST, OPTIONS
        Origin| http://localhost:4000

    - CORS Test
    
    Config|Value
    -|-
    URL|https://localhost:8443/api/orders/<ID>
    Authetication Type|API Key
    Value| <apikey>


* **Restrição por IP**
Plugin Global IP Restriction

Config|Value
-|-
Allow|192.100.10.1
Message|Forbidden

>Pegar o client_ip no log e adicionar a lista

* **Detecção por bot** padrão e customizado
Plugin Global BOT Detection

Config|Value
-|-
Deny|Postman.*

Referência: https://github.com/Kong/kong/blob/master/kong/plugins/bot-detection/rules.lua

* Certificado SSL 
```bash
curl --cacert ./certs/localhost-ca.pem https://localhost:8443
```

### Controle de Tráfego (parte 2)
* **Throttling** usando rate-limit por consumer

Plugin Rate Limit no Consumer

Config|Value
-|-
Config.Minute|10

> Ver os headers retornados

* **Cache** para requisições GET
Proxy Caching na rota get-orders

Config|Value
-|-
Content-Type|application/json; charset=utf-8
Cache TTL|10
Strategy|memory
> Ver os headers retornados

* Transformação de response

Plugin Response Transformer na rota get-orders

Config|Value
-|-
Config.RemoveJSON|totalPrice,createdAt

>Veja o resultado da requisição sem os campos

### Observabilidade (parte 2)

* **Metrics** com Prometheus e Grafana (Dashboard - https://grafana.com/grafana/dashboards/7424)
    - Plugin Global Prometheus


* **Tracing** com Zipkin

Plugin Global ZipKin
Config|Value
-|-
Http Endpoint|http://zipkin:9411/api/v2/spans
Sample Ratio|1


### OAuth - JWT

Plugin JWT para o serviço

Config|Value
-|-
Config.Claims To Verify|exp
Config.Key Claim Name|kong-consumer

Consumer orders-api (jwt credentials)
Config|Value
-|-
Key|orders-client
Algorithm|RSA256
RSA public-key| Pegar em http://localhost:8080/realms/master/protocol/openid-connect/certs a chave com valores { "kty": "RSA","alg": "RS256", "use": "sig", }


> Desabilitar API Key

### Keycloak Mapeado
* Criação de serviço com acesso ao Keycloak
* Criação de rota 

Config|Value
-|-
Name|keycloak-token
Method|POST
Path|/auth/token

Plugin Request Transformer na Rota

Config|Value
-|-
Config.Config.Replace.Uri|/realms/master/protocol/openid-connect/token

### Extras

* **Pre-function and Post Function**


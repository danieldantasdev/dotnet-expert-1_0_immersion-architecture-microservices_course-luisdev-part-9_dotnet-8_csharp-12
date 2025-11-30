# Keycloak

## Acessando o Keycloak
* Acesse o Keycloak através do endereço http://localhost:8080
* Clique em **Administration Console**
* Utilize o usuário e senha  ```admin``` para logar


## Criando um client
* Acesse a lista de clientes em **Clients** no menu lateral esquerdo
* Clique em **Create**
* Em **Client Id** informe ```orders-client```
* Em **Client Protocol** mantenha ```openid-connect```
* Clique em **Save**
* Em **Access Type** escolha ```confidential```
* Defina **Implicit Flow Enabled** como ```on```
* Defina **Service Accounts Enabled** como ```on```
* Em **Valid Redirect URIs** informe ```https://jwt.ms``` 
* Em **Advanced Settings** altere o campo **Access Token Lifespan** para ```1 day``` e clique em **Save** (o valor padrão é 1 minuto e isso dificulta os testes)
* Clique em **Save**
* Clique em **Service Account Roles**, remova todas as _roles_ em **Assigned Roles** 
* Clique em **Credentials** no topo da página e copie o valor do campo **Secret**. Este valor deverá ser usado como ```client_secret```.

> Agora é possível fazer uma chamada a API do KeyCloak para requisitar um token de acesso para administração do *realm*

> Remover as _roles_ que são habilitadas por padrão permite a geração de _tokens_ mais enxutos

```bash
curl --location --request POST 'http://localhost:8080/realms/master/protocol/openid-connect/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'client_id=orders-client' \
--data-urlencode 'client_secret=Y77qZLCgJDzHG4S6aS3IxuZmdALJXHzl' \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode 'scope=openid'

{
    "access_token": "eyJh...7ZLw",
    "expires_in": 36000,
    "refresh_expires_in": 0,
    "token_type": "Bearer",
    "id_token": "eyJh...7ZLw",
    "not-before-policy": 0,
    "scope": "openid email profile"
}
```


## Mapeando uma claim
* Acesse a lista de clientes em **Clients** no menu lateral esquerdo
* Acesse o cliente ```orders-client```
* Acesse o menu **Mappers** e clique em **Create**
* Defina o nome como ```username```
* Em **Mapper Type** selecione o valor ```Hardcoded Claim```
* Em **Token Claim Name** informe ```kong-consumer```
* Em **Claim Value** informe ```orders-client```
* Em **Claim Json Type** selecione ```string```
* Clique em **Save**.

Ao gerar o _token_, a _claim_  ```kong-consumer``` estará disponível mostrando o nome do consumidor do Kong atribuído como _claim_.


## Criando um usuário
* Acesse **Users** no menu lateral esquerdo
* Clique em **Add user** 
* Em **username** coloque ```johndoe```
* Em **email** coloque ```john@doe.com```
* Defina **User Enabled** como ```on```
* Clique em **Save**
* Clique em **Credentials**
* Defina o **Password** e **Password Confirmation** como ```pwd```
* **Temporary** como ```off```
* Clique em **Set password** e na sequência **Set password**

> Agora é possível gerar um token de usuário usando a aplicação ```orders-client```.

```bash
curl --location --request POST 'http://localhost:8080/realms/master/protocol/openid-connect/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'client_id=orders-client' \
--data-urlencode 'client_secret=Y77qZLCgJDzHG4S6aS3IxuZmdALJXHzl' \
--data-urlencode 'grant_type=password' \
--data-urlencode 'username=johndoe' \
--data-urlencode 'password=pwd'
```

> Pegue a URL do token em http://localhost:8080/realms/master/.well-known/openid-configuration

## Conectar via OpenId
Acesse o endereço abaixo e será possível fazer o login de forma interativa. Utilize o usuário ```johndoe``` e senha ```pwd```.

http://localhost:8080/realms/master/protocol/openid-connect/auth?client_id=orders-client&redirect_uri=https://jwt.ms&grant_type=implicit&response_type=token



## Adicionando grupos ao usuário
* No menu lateral esquerdo acesse **Groups** 
* Clique em **New**
* Informe o nome ```orders-users``` 
* Clique em **Save**
* No menu lateral esquerdo acesse **Users**
* Clique em **View all users**
* Clique em **Edit** no usuário ```johndoe```
* Selecione a aba **Groups**
* Clique em ```orders-users``` e sem seguida clique em **Join**
* No menu lateral esquerdo clique em **Clients**
* Selecione ```orders-client```
* Clique em **Mappers** e em seguida em **Create**
* Em **Name** informe ```groups```
* Em **Mapper type** informe ```Group Membership```
* Em **Token claim name** informe ```groups```
* Clique em **Save**

Requisite novamente um _token_ para o usuário ```johndoe``` e agora será possível recuperar a _claim groups_.

## Adicionando papéis (roles) ao usuário
* No menu lateral esquerdo clique em **Clients**
* Selecione ```orders-client```
* Clique em **Roles** em seguida em **Add Role**
* Em **Role Name** informe ```writer``` e clique em **Save**
* Volte a tela de _roles_ e repita o procedimento para criar a _role_ ```reader```.
* No menu lateral esquerdo acesse **Users**
* Clique em **View all users**
* Clique em **Edit** no usuário ```johndoe```
* Clique em **Role Mappings**
* Em **Client Roles** selecione ```orders-client```
* Fique a vontade para escolher as _roles_ que foram definidas previamente. Para adicionar a _role_ clique em **Add selected**

## Melhorando a visualização das roles
* Retorne ao cliente ```orders-client```
* Clique em **Mappers** em seguida em **Add builtin**
* Marque **Client Roles** e clique em **Add selected**
* Para ficar mais claro a utilização da _claim_ no _token_ clique em **Edit** em **client roles**.
* Altere **Token Claim Name** para ```roles```.
* Clique em **Save**
> Ao requisitar o _token_ haverá duas _claims_ mostrando as _roles_ para evitar isso, edite o ```orders-client```, vá até **Client Scopes** e remova ```roles``` de **Assigned Default Client Scopes**.

## Alterando o Client Scope 
* No menu lateral esquerdo clique em **Clients**
* Selecione ```orders-client```
* Clique em **Client Scopes**
* Em **Assigned Default Client Scopes** mantenha somente ```profile``` e ```email``` 
* Em **Assigned Optional Client Scopes** mantenha somente ```offline_access```

> Ao requisitar um novo _token_ ele virá somente com algumas informações.
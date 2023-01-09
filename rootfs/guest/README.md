# Flask 실행하는 법

## 파이썬 패키지 설치

- python 3.10 버전과 그에 따른 pip 를 설치한다.
- 다음과 같은 패키지들을 설치한다.
  - `pip3 install wheel six scikit-learn flask redis pillow pyaes Chameleon pandas tensorflow grpcio igraph torch torchvision`

## Flask 의 실행

로컬에서 직접 Flask 를 실행하고 싶다면 아래 명령어를 입력한다.  
--debug 옵션을 붙인 이유는 Flask 서버 상에 로그 출력되고,  
핫 리로드가 지원되기 때문이다.

```sh
FLASK_APP=daemon.py FLASK_RUN_PORT=5000 python3 -m flask --debug run
```

## Flask 서버에 요청 보내기

Flask 서버를 실행한 후, HTTP 요청은 다음과 같이 보낼 수 있다.

### Hello 요청

```sh
curl --request POST 'http://127.0.0.1:5000/invoke?function=hello&redishost=127.0.0.1&redispasswd=passwd' \
--header 'Content-Type: application/json' \
--data-raw '{}'
```

### Allocate 요청

```sh
curl --request POST 'http://127.0.0.1:5000/invoke?function=allocate&redishost=127.0.0.1&redispasswd=passwd' \
--header 'Content-Type: application/json' \
--data-raw '{ "size": 5 }'
```

### Image 요청

image 요청의 경우, redis 세팅을 해놓지 않으면 요청의 응답에 실패한다.  
본인이 세팅한대로 redishost 와 redispasswd 값을 수정해야 한다.

```sh
curl --request POST 'http://127.0.0.1:5000/invoke?function=image&redishost=127.0.0.1&redispasswd=passwd' \
--header 'Content-Type: application/json' \
--data-raw '{
    "input_object_key": "100kb.jpg",
    "output_object_key_prefix": "outputimg-"
}'
```

### Sleep 요청

0.5 초 동안 sleep 을 하는 요청을 보낸다.  

```sh
curl --request POST 'http://127.0.0.1:5000/invoke?function=sleep&redishost=127.0.0.1&redispasswd=passwd' \
--header 'Content-Type: application/json' \
--data-raw '{
    "second": 0.5
}'
```

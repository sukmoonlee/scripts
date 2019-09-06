# Certification Report Script
인증서 자동 추출 스크립트

## 스크립트 소개
* TLS(Transport Layer Security)는 Trasnport Layer 위에 존재하는 암호화 규약으로 Application 입장에서는 SSL(Security Socket Layer)라고 불리는 통신 방식
* TLS 통신을 지원하기 위해서는 암호화를 위한 키가 필요하여, 이를 이용해서 해당 서버의 신원을 확인하는 용도로 사용
* 서버에서 운영중인 인증서를 Socket, Process, File 등을 검출해서 결과를 리포트 하는 역할
  (Open Source 및 Vendor Software에 내장된 인증서를 모두 검출하기 위한 목적)

## 실행환경 분석
 * 실행 권한(root privilege) 필요
 * 필수 프로그램 설치 확인 (openssl, lsof, readelf)

## 사용법
 * 아래와 같이 cert_report.sh 를 root 권한으로 실행
<pre><code>
[smlee@instance-1:/home/smlee/report/cert] $ sudo ./cert_report.sh
 Certification Report (instance-1, 20190307, 4.2.46(2)-release)

cert_socket_chk.sh                                         [  OK  ]
cert_program_chk.sh                                        [  OK  ]
cert_file_chk.sh                                           [  OK  ]

+--------+--------------+----------------------------------------------------------------+-------------------------------------------------------------------+
| Port   | Program      | File                                                           | Expire Date (Organization/CommonName)                             |
+--------+--------------+----------------------------------------------------------------+-------------------------------------------------------------------+
| :::443 | (9496) httpd | /etc/letsencrypt/archive/gcloud.sukmoonlee.com/fullchain11.pem | Dec  4 23:07:46 2019 (Let's Encrypt/Let's Encrypt Authority X3)   |
+--------+--------------+----------------------------------------------------------------+-------------------------------------------------------------------+
|        |              | /etc/letsencrypt/archive/gcloud.sukmoonlee.com/cert10.pem      | Sep  8 00:19:12 2019 (Let's Encrypt/Let's Encrypt Authority X3)   |
|        |              | /etc/letsencrypt/archive/gcloud.sukmoonlee.com/fullchain10.pem | Sep  8 00:19:12 2019 (Let's Encrypt/Let's Encrypt Authority X3)   |
|        |              | /etc/pki/tls/certs/localhost.crt                               | Feb 24 12:23:28 2020 (SomeOrganization/instance-1)                |
|        |              | /etc/letsencrypt/archive/gcloud.sukmoonlee.com/chain10.pem     | Mar 17 16:40:46 2021 (Digital Signature Trust Co./DST Root CA X3) |
+--------+--------------+----------------------------------------------------------------+-------------------------------------------------------------------+
</code></pre>

 * 인증서 저장경로가 다른 경우 디렉토리 지정 옵션(-s)를 활용
<pre><code>
[smlee@instance-1:/home/smlee/report/cert] $ sudo ./cert_report.sh -s /home/smlee/go/
 Certification Report (instance-1, 20190307, 4.2.46(2)-release)

cert_socket_chk.sh                                         [  OK  ]
cert_program_chk.sh                                        [  OK  ]
cert_file_chk.sh                                           [  OK  ]

+--------+--------------+-------------------------------------------------------------+-----------------------------------------------------------------+
| Port   | Program      | File                                                        | Expire Date (Organization/CommonName)                           |
+--------+--------------+-------------------------------------------------------------+-----------------------------------------------------------------+
| :::443 | (9496) httpd |                                                             | Dec  4 23:07:46 2019 (Let's Encrypt/Let's Encrypt Authority X3) |
+--------+--------------+-------------------------------------------------------------+-----------------------------------------------------------------+
|        |              | /home/smlee/go/src/golang.org/x/net/http2/h2demo/rootCA.pem | May  4 20:46:05 2017 (Bradfitzinc/localhost)                    |
|        |              | /home/smlee/go/src/golang.org/x/net/http2/h2demo/server.crt | Nov 27 20:50:27 2015 (Bradfitzinc/localhost)                    |
+--------+--------------+-------------------------------------------------------------+-----------------------------------------------------------------+
</code></pre>

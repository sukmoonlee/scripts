# Certification Check Script
인증서 정보 및 지원 프로토콜 확인 스크립트

## 스크립트 소개
* TLS(Transport Layer Security)는 Trasnport Layer 위에 존재하는 암호화 규약으로 Application 입장에서는 SSL(Security Socket Layer)라고 불리는 통신 방식
* TLS 통신을 지원하기 위해서는 암호화를 위한 키가 필요하여, 이를 이용해서 해당 서버의 신원을 확인하는 용도로 사용
* 인증서 정보 및 지원 프로토콜을 외부에서 스크립트로 확인하는 역할
* OpenSSL 1.0.2/1.1.1 기반으로 SSLv3, TLSv1, TLSv1.1, TLS1.2, TLS1.3 중심으로 지원 프로토콜 확인

## 실행환경 분석
 * 필수 프로그램 설치 확인 (openssl)

## 사용법
 * 아래와 같이 cert_check.sh 에 파라메터를 입력하여 수행
<pre><code>
$ git clone https://github.com/sukmoonlee/scripts.git
$ cd scripts/cert/
$ ./cert_check.sh www.naver.com:443
Certification Check Script (home, 20200915, 4.2.46(2)-release)

Check URL - www.naver.com:443
    issuer=C = US, O = DigiCert Inc, CN = DigiCert SHA2 Secure Server CA
    notBefore=May 30 00:00:00 2020 GMT
    notAfter=Jun  8 12:00:00 2022 GMT
    SHA1 Fingerprint=FE:5B:A9:4A:1F:56:F2:60:F2:DD:34:D2:55:B3:D1:C5:EF:13:2C:0F

Report Protocol
    +------------+----------------------------------+------------+
    | Protocol   | Cipher                           | Support    |
    +------------+----------------------------------+------------+
    | TLSv1      | ECDHE-RSA-AES128-SHA             | O          |
    | TLSv1.1    | ECDHE-RSA-AES128-SHA             | O          |
    | TLSv1.2    | ECDHE-RSA-AES128-GCM-SHA256      | O          |
    | TLSv1.3    | TLS_AES_256_GCM_SHA384           | O          |
    | ssl3       |                                  | X          |
    | dtls1      |                                  | X          |
    | dtls1_2    |                                  | X          |
    +------------+----------------------------------+------------+
</code></pre>

 * 파라메터가 없는 경우에 로컬 시스템을 점검
<pre><code>

$ ./cert_check.sh
Certification Check Script (home, 20200915, 4.2.46(2)-release)

+-----------------+------------------+-------------------------------------------+
| Local Address   | PID/Program name | Certification Information (KST +0900)     |
+-----------------+------------------+-------------------------------------------+
| 127.0.0.1:443   | -                | 2020-07-11 18:59:54 ~ 2020-10-09 18:59:54 | C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
+-----------------+------------------+-------------------------------------------+

$ ./cert_check.sh -a
Certification Check Script (home, 20200915, 4.2.46(2)-release)

+-----------------+------------------+-------------------------------------------+
| Local Address   | PID/Program name | Certification Information (KST +0900)     |
+-----------------+------------------+-------------------------------------------+
| 127.0.0.1:80    | -                |                                           |
| 127.0.0.1:443   | -                | 2020-07-11 18:59:54 ~ 2020-10-09 18:59:54 | C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
+-----------------+------------------+-------------------------------------------+
</code></pre>

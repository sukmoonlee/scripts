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
<pre><code>$ git clone https://github.com/sukmoonlee/scripts.git
$ cd scripts/cert/
$ bash ./cert_check.sh www.naver.com:443
Certification Check Script (home, 20210525, 4.2.46(2)-release, OpenSSL 1.1.1g FIPS  21 Apr 2020)

Check URL - www.naver.com:443
    issuer=C = US, O = DigiCert Inc, CN = DigiCert SHA2 Secure Server CA
    subject=C = KR, ST = Gyeonggi-do, L = Seongnam-si, O = NAVER Corp., CN = *.www.naver.com
    notBefore=May 30 00:00:00 2020 GMT
    notAfter=Jun  8 12:00:00 2022 GMT
    SHA1 Fingerprint=FE:5B:A9:4A:1F:56:F2:60:F2:DD:34:D2:55:B3:D1:C5:EF:13:2C:0F

Report Protocol
    +----------+-------+-----------------------------+
    | Protocol | allow | Cipher                      |
    +----------+-------+-----------------------------+
    | TLSv1    |   O   | ECDHE-RSA-AES128-SHA        |
    | TLSv1.1  |   O   | ECDHE-RSA-AES128-SHA        |
    | TLSv1.2  |   O   | ECDHE-RSA-AES128-GCM-SHA256 |
    | TLSv1.3  |   O   | TLS_AES_256_GCM_SHA384      |
    | ssl3     |   X   |                             |
    | dtls1    |   X   |                             |
    | dtls1_2  |   X   |                             |
    +----------+-------+-----------------------------+
</code></pre>

 * 파라메터가 없는 경우에 로컬 시스템 점검
<pre><code>$ sudo bash cert_check.sh
Certification Check Script (home, 20210525, 4.2.46(2)-release, OpenSSL 1.1.1g FIPS  21 Apr 2020)

+---------------+----------------+-------------+-------------------------------------------+
| Listen Socket | Test Socket    | PID/Program | Certification Information (KST +0900)     |
+---------------+----------------+-------------+-------------------------------------------+
| 0.0.0.0:22    | 127.0.0.1:22   | 894/sshd    |                                           |
| 0.0.0.0:443   | 127.0.0.1:443  | 6752/httpd  | 2021-06-17 21:37:17 ~ 2021-09-15 21:37:16 | >>> C = US, O = Let's Encrypt, CN = R3
| 0.0.0.0:80    | 127.0.0.1:80   | 6752/httpd  |                                           |
+---------------+----------------+-------------+-------------------------------------------+

Check URL - 127.0.0.1:443
    issuer=C = US, O = Let's Encrypt, CN = R3
    subject=CN = home.sukmoonlee.com
    notBefore=Jun 17 12:37:17 2021 GMT
    notAfter=Sep 15 12:37:16 2021 GMT
    SHA1 Fingerprint=B0:97:CB:72:EA:CC:5D:70:37:C4:77:FF:C6:BF:FF:AB:99:5F:6E:C8

Report Protocol
    +----------+-------+-----------------------------+
    | Protocol | allow | Cipher                      |
    +----------+-------+-----------------------------+
    | TLSv1    |   X   | 0000                        |
    | TLSv1.1  |   X   | 0000                        |
    | TLSv1.2  |   O   | ECDHE-RSA-AES256-GCM-SHA384 |
    | tls1_3   |   X   |                             |
    | ssl3     |   X   |                             |
    | DTLSv1   |   X   | 0000                        |
    | DTLSv1.2 |   X   | 0000                        |
    +----------+-------+-----------------------------+
</code></pre>
 
 * 로컬 시스템에서 사용 중인 TLS 포트만 확인하는 경우 (-r 옵션 사용)
<pre><code>$ sudo bash cert_check.sh -r
Certification Check Script (home, 20210525, 4.2.46(2)-release, OpenSSL 1.1.1g FIPS  21 Apr 2020)

+---------------+---------------+-------------+-------------------------------------------+
| Listen Socket | Test Socket   | PID/Program | Certification Information (KST +0900)     |
+---------------+---------------+-------------+-------------------------------------------+
| 0.0.0.0:443   | 127.0.0.1:443 | 6752/httpd  | 2021-06-17 21:37:17 ~ 2021-09-15 21:37:16 | >>> C = US, O = Let's Encrypt, CN = R3
+---------------+---------------+-------------+-------------------------------------------+

Check URL - 127.0.0.1:443
    issuer=C = US, O = Let's Encrypt, CN = R3
    subject=CN = home.sukmoonlee.com
    notBefore=Jun 17 12:37:17 2021 GMT
    notAfter=Sep 15 12:37:16 2021 GMT
    SHA1 Fingerprint=B0:97:CB:72:EA:CC:5D:70:37:C4:77:FF:C6:BF:FF:AB:99:5F:6E:C8

Report Protocol
    +----------+-------+-----------------------------+
    | Protocol | allow | Cipher                      |
    +----------+-------+-----------------------------+
    | TLSv1    |   X   | 0000                        |
    | TLSv1.1  |   X   | 0000                        |
    | TLSv1.2  |   O   | ECDHE-RSA-AES256-GCM-SHA384 |
    | tls1_3   |   X   |                             |
    | ssl3     |   X   |                             |
    | DTLSv1   |   X   | 0000                        |
    | DTLSv1.2 |   X   | 0000                        |
    +----------+-------+-----------------------------+
</code></pre>

# Certification Check Script
인증서 정보 및 지원 프로토콜 확인 스크립트

## 스크립트 소개
* TLS(Transport Layer Security)는 Trasnport Layer 위에 존재하는 암호화 규약으로 Application 입장에서는 SSL(Security Socket Layer)라고 불리는 통신 방식
* TLS 통신을 지원하기 위해서는 암호화를 위한 키가 필요하여, 이를 이용해서 해당 서버의 신원을 확인하는 용도로 사용
* 인증서 정보 및 지원 프로토콜을 외부에서 스크립트로 확인하는 역할
* OpenSSL 1.0.2 기반으로 SSLv3, TLSv1, TLSv1.1, TLS1.2 중심으로 지원 프로토콜 확인

## 실행환경 분석
 * 필수 프로그램 설치 확인 (openssl)

## 사용법
 * 아래와 같이 cert_check.sh 에 파라메터를 입력하여 수행
<pre><code>
$ git clone https://github.com/sukmoonlee/scripts.git
$ cd scripts/cert/
$ ./cert_check.sh
Usage: ./cert_check.sh -h {Hostname/IP} -p {Port}
$ ./cert_report.sh -h www.naver.com -p 443
Certification Check Script (instance-1, 20190917, 4.2.46(2)-release)

Check URL - www.naver.com:443
    issuer= /C=US/O=DigiCert Inc/OU=www.digicert.com/CN=GeoTrust RSA CA 2018
    notBefore=May  8 00:00:00 2019 GMT
    notAfter=Apr 20 12:00:00 2020 GMT
    SHA1 Fingerprint=19:14:2D:5A:3A:EF:5E:EE:3B:C8:6B:34:3A:CB:40:35:97:C4:1E:22

Report Protocol
    +------------+----------------------------------+------------+
    | Protocol   | Cipher                           | Support    |
    +------------+----------------------------------+------------+
    | TLSv1      | ECDHE-RSA-AES128-SHA             | O          |
    | TLSv1.1    | ECDHE-RSA-AES128-SHA             | O          |
    | TLSv1.2    | ECDHE-RSA-AES128-GCM-SHA256      | O          |
    | SSLv3      | 0000                             | X          |
    | dtls1      |                                  | X          |
    +------------+----------------------------------+------------+
</code></pre>

 * 아래와 같이 URL 형식으로 입력도 가능
<pre><code>
$ ./cert_check.sh www.kisa.or.kr:443
Certification Check Script (instance-1, 20190917, 4.2.46(2)-release)

Check URL - www.kisa.or.kr:443
    issuer= /C=US/O=DigiCert Inc/OU=www.digicert.com/CN=DigiCert SHA2 High Assurance Server CA
    notBefore=Sep 11 00:00:00 2019 GMT
    notAfter=Jun 29 12:00:00 2020 GMT
    SHA1 Fingerprint=6D:1A:D5:DC:AB:1E:28:F9:60:FF:88:05:3C:58:3B:F6:4E:9B:7C:3F

Report Protocol
    +------------+----------------------------------+------------+
    | Protocol   | Cipher                           | Support    |
    +------------+----------------------------------+------------+
    | TLSv1      | AES128-SHA                       | O          |
    | TLSv1.1    | AES128-SHA                       | O          |
    | TLSv1.2    | AES128-SHA                       | O          |
    | SSLv3      | AES128-SHA                       | O          |
    | DTLSv1     | 0000                             | X          |
    +------------+----------------------------------+------------+

$ ./cert_check.sh www.google.com:443
Certification Check Script (instance-1, 20190917, 4.2.46(2)-release)

Check URL - www.google.com:443
    issuer= /C=US/O=Google Trust Services/CN=GTS CA 1O1
    notBefore=Aug 23 10:20:09 2019 GMT
    notAfter=Nov 21 10:20:09 2019 GMT
    SHA1 Fingerprint=C7:A3:9E:ED:D0:3A:A8:C8:95:DD:22:84:CB:75:17:9D:0F:D0:ED:45

Report Protocol
    +------------+----------------------------------+------------+
    | Protocol   | Cipher                           | Support    |
    +------------+----------------------------------+------------+
    | TLSv1      | ECDHE-RSA-AES128-SHA             | O          |
    | TLSv1.1    | ECDHE-RSA-AES128-SHA             | O          |
    | TLSv1.2    | ECDHE-RSA-AES128-GCM-SHA256      | O          |
    | SSLv3      | 0000                             | X          |
    | dtls1      |                                  | X          |
    +------------+----------------------------------+------------+
</code></pre>

# Shared Library Check Script
공유 라이브러리 확인 스크립트

## 스크립트 소개
* 설치 및 운영중인 프로그램 라이브러리 확인을 통해서 실행 환경 비교, 바이너리 동작 환경 검증으로 활용
* 라이브러리 파일의 Size와 Digest를 통한 버전별, 서버별 환경 비교 확인

## 사용법
* 바이너리 파일을 이용한 분석
<pre><code>
$ git clone https://github.com/sukmoonlee/scripts.git
$ cd scripts/library/
$ ./program_library_report.sh /usr/sbin/httpd
 Program Library Report Script (instance-1, 20190617, 4.2.46(2)-release)
+----------------------------------+---------+---------------------+----------------------------------+-----------------------------+
| Filename                         | Size    | Date                | Digest                           | Link Symbol                 |
+----------------------------------+---------+---------------------+----------------------------------+-----------------------------+
| /usr/sbin/httpd (*)              | 523688  | 2019-07-30 02:20:00 | 7f77c66114b9fbb70b3696db0617b846 |                             |
| /usr/lib64/ld-2.17.so            | 163400  | 2019-07-03 22:52:30 | e0a10e3bf4d527193c879eb454bf9954 | /lib64/ld-linux-x86-64.so.2 |
| /usr/lib64/libapr-1.so.0.4.8     | 198600  | 2017-11-29 06:45:35 | 6b36143da30eb524c80d89c823640b4f | /lib64/libapr-1.so.0        |
| /usr/lib64/libaprutil-1.so.0.5.2 | 172288  | 2014-06-10 11:30:48 | b49eb03995b512d492970b5ab428e15d | /lib64/libaprutil-1.so.0    |
| /usr/lib64/libcrypt-2.17.so      | 40664   | 2019-07-03 22:52:32 | cc7271d249bb9b66ab2754c6b9d37d1d | /lib64/libcrypt.so.1        |
| /usr/lib64/libc-2.17.so          | 2151672 | 2019-07-03 22:52:33 | e71942bace284a55c807838ba2d72e7d | /lib64/libc.so.6            |
| /lib64/libdb-5.3.so              | 1850464 | 2018-04-11 14:31:47 | 2f75db5976d2e43b3e6d42dadec48cde |                             |
| /usr/lib64/libdl-2.17.so         | 19288   | 2019-07-03 22:52:30 | 4067e916a24d98911f137f2067524dac | /lib64/libdl.so.2           |
| /usr/lib64/libexpat.so.1.6.0     | 173320  | 2016-11-29 07:26:58 | f2d1fd6927b15c92e2a2e6f9844f15e5 | /lib64/libexpat.so.1        |
| /lib64/libfreebl3.so             | 11448   | 2018-05-16 08:56:10 | 27d7380095572a557bb0236cdddc3b18 |                             |
| /usr/lib64/libpcre.so.1.2.0      | 402384  | 2017-08-02 12:08:00 | bcbb7c51ebe503462b8bd5830b3217a7 | /lib64/libpcre.so.1         |
| /usr/lib64/libpthread-2.17.so    | 141968  | 2019-07-03 22:52:32 | 32ee534a93a6282c529453cd838f4af1 | /lib64/libpthread.so.0      |
| /lib64/libselinux.so.1           | 155784  | 2018-10-31 06:43:05 | e3706e3e568713cc820612ebf7324374 |                             |
| /usr/lib64/libuuid.so.1.3.0      | 20112   | 2019-03-14 19:37:30 | a5e57a44010129ee814d773fab515167 | /lib64/libuuid.so.1         |
+----------------------------------+---------+---------------------+----------------------------------+-----------------------------+
</code></pre>

* 구동중인 프로세서를 이용한 분석
<pre><code>
$ sudo ./process_library_report.sh $(pgrep httpd)
 Process Library Report Script (instance-1, 20190617, 4.2.46(2)-release)
+-----------------------------------------------------+---------+---------------------+----------------------------------+
| Filename                                            | Size    | Date                | Digest                           |
+-----------------------------------------------------+---------+---------------------+----------------------------------+
| /usr/sbin/httpd (*)                                 | 523688  | 2019-07-30 02:20:00 | 7f77c66114b9fbb70b3696db0617b846 |
| /usr/lib64/httpd/modules/libphp5.so                 | 4588224 | 2018-10-31 04:33:41 | 5892a4c3857b006f7bb61b7d76cac3cb |
| /usr/lib64/httpd/modules/mod_access_compat.so       | 11304   | 2019-07-30 02:20:00 | eaad21e46a33e59f2b9f170467697925 |
| /usr/lib64/httpd/modules/mod_actions.so             | 11256   | 2019-07-30 02:20:00 | 1ccbd22dc4dd6868fc7187dec97bc97e |
| /usr/lib64/httpd/modules/mod_alias.so               | 15464   | 2019-07-30 02:20:00 | 6caa5101913e0f32a374cc6b251ce829 |
| /usr/lib64/httpd/modules/mod_allowmethods.so        | 11232   | 2019-07-30 02:20:00 | 94e698b0f157f1a529f2f1bc7e6c838e |
| /usr/lib64/httpd/modules/mod_auth_basic.so          | 15416   | 2019-07-30 02:20:00 | a6083f8fe6eb511e07cde8fa18f5ef18 |
| /usr/lib64/httpd/modules/mod_auth_digest.so         | 36168   | 2019-07-30 02:20:00 | e6d00a97ab11f2e0be05e473bf543711 |
| /usr/lib64/httpd/modules/mod_authn_anon.so          | 11240   | 2019-07-30 02:20:00 | 25230ae912d028b64c457b5401addc74 |
| /usr/lib64/httpd/modules/mod_authn_core.so          | 15456   | 2019-07-30 02:20:00 | 62a43208701d17e47879840fd566b935 |
| /usr/lib64/httpd/modules/mod_authn_dbd.so           | 15360   | 2019-07-30 02:20:00 | 802b6885c7f589d93fae98206e69a710 |
| /usr/lib64/httpd/modules/mod_authn_dbm.so           | 11280   | 2019-07-30 02:20:00 | 231da3fe95d6457df0e164e563ab49fc |
| /usr/lib64/httpd/modules/mod_authn_file.so          | 11264   | 2019-07-30 02:20:00 | 7a1e3fac392960a9f97dc586e6682ceb |
| /usr/lib64/httpd/modules/mod_authn_socache.so       | 19632   | 2019-07-30 02:20:00 | 3572644b758988197971e0f1295d248e |
| /usr/lib64/httpd/modules/mod_authz_core.so          | 23832   | 2019-07-30 02:20:00 | 0efde025ce997c71cb09eea531edec7c |
| /usr/lib64/httpd/modules/mod_authz_dbd.so           | 15392   | 2019-07-30 02:20:00 | bb43adc61d84478083c9b38f1d20a18c |
| /usr/lib64/httpd/modules/mod_authz_dbm.so           | 11296   | 2019-07-30 02:20:00 | 7cbd5066acac53d4b4e68f917010760b |
| /usr/lib64/httpd/modules/mod_authz_groupfile.so     | 11280   | 2019-07-30 02:20:00 | 7153c221133bf7b7bb8ccc38acb55c39 |
| /usr/lib64/httpd/modules/mod_authz_host.so          | 11280   | 2019-07-30 02:20:00 | fedd60202d858856531ed6ecea2633b4 |
| /usr/lib64/httpd/modules/mod_authz_owner.so         | 11224   | 2019-07-30 02:20:00 | adf831dabd7a49b36f6c88747ecbf237 |
| /usr/lib64/httpd/modules/mod_authz_user.so          | 7128    | 2019-07-30 02:20:00 | d76dcff2d39f78f772997a8cb0bd39fd |
| /usr/lib64/httpd/modules/mod_autoindex.so           | 40160   | 2019-07-30 02:20:00 | a9607e5cbbc621e3fe7527f97f06659b |
| /usr/lib64/httpd/modules/mod_cache_disk.so          | 36184   | 2019-07-30 02:20:00 | 48b7347a389b49378a91120094e4a5c9 |
| /usr/lib64/httpd/modules/mod_cache.so               | 73368   | 2019-07-30 02:20:00 | 86e3507040f592a9acaf0d482fe1f838 |
| /usr/lib64/httpd/modules/mod_cgi.so                 | 27808   | 2019-07-30 02:20:00 | 688ea9dca304eccd32be9e4eb9c24ad8 |
| /usr/lib64/httpd/modules/mod_data.so                | 11184   | 2019-07-30 02:20:00 | 88c22be84549920d8f0de8360d8b3d84 |
| /usr/lib64/httpd/modules/mod_dav_fs.so              | 57208   | 2019-07-30 02:20:00 | a6aa62d8b64497deb188e3c69822bf85 |
| /usr/lib64/httpd/modules/mod_dav_lock.so            | 19728   | 2019-07-30 02:20:00 | 9757ce26554bb59d024f8b7dbbed6505 |
| /usr/lib64/httpd/modules/mod_dav.so                 | 102520  | 2019-07-30 02:20:00 | 663690acac1f3c0739982107657079c2 |
| /usr/lib64/httpd/modules/mod_dbd.so                 | 23712   | 2019-07-30 02:20:00 | df28d1b02e52aa31c82ed98c54a55c65 |
| /usr/lib64/httpd/modules/mod_deflate.so             | 31920   | 2019-07-30 02:20:00 | b9a937b8a906739b635f5b81f367fde1 |
| /usr/lib64/httpd/modules/mod_dir.so                 | 11264   | 2019-07-30 02:20:00 | c0c83da9f7431ceaefef28d3cca228c7 |
| /usr/lib64/httpd/modules/mod_dumpio.so              | 11280   | 2019-07-30 02:20:00 | 07d322031903eccb9951dc573dde40db |
| /usr/lib64/httpd/modules/mod_echo.so                | 11256   | 2019-07-30 02:20:00 | bcb05387ec816ff0603b46c92998da40 |
| /usr/lib64/httpd/modules/mod_env.so                 | 11264   | 2019-07-30 02:20:00 | e6b70ba603555da8d7e8a16c92c565f6 |
| /usr/lib64/httpd/modules/mod_expires.so             | 15400   | 2019-07-30 02:20:00 | c5a517b7a62fa3799d63001fd6e0ca8e |
| /usr/lib64/httpd/modules/mod_ext_filter.so          | 23632   | 2019-07-30 02:20:00 | c80d934f189a52846433fea08e02f734 |
| /usr/lib64/httpd/modules/mod_filter.so              | 19512   | 2019-07-30 02:20:00 | 9a052c06de5bc549359ae5c1f762e807 |
| /usr/lib64/httpd/modules/mod_headers.so             | 23848   | 2019-07-30 02:20:00 | 8cdb94263dd1260cf011dee474ce7969 |
| /usr/lib64/httpd/modules/mod_include.so             | 52624   | 2019-07-30 02:20:00 | 69be72fe4fb1e67e84c37b30db7ec209 |
| /usr/lib64/httpd/modules/mod_info.so                | 28208   | 2019-07-30 02:20:00 | 2137be193b0594bf5b7f35280d9faf09 |
| /usr/lib64/httpd/modules/mod_lbmethod_bybusyness.so | 11216   | 2019-07-30 02:20:00 | 5bb7b174915b8a3213f1b0394d445ddd |
| /usr/lib64/httpd/modules/mod_lbmethod_byrequests.so | 11216   | 2019-07-30 02:20:00 | 24449784d625faca1738f1b27d4ccd52 |
| /usr/lib64/httpd/modules/mod_lbmethod_bytraffic.so  | 11208   | 2019-07-30 02:20:00 | fff7b5f6020d5b082dcc0058ea3f2f35 |
| /usr/lib64/httpd/modules/mod_lbmethod_heartbeat.so  | 15408   | 2019-07-30 02:20:00 | deb10a5db1932056ccf04436255da191 |
| /usr/lib64/httpd/modules/mod_log_config.so          | 28296   | 2019-07-30 02:20:00 | dccbb70f41cdffb958be789616facf9a |
| /usr/lib64/httpd/modules/mod_logio.so               | 11304   | 2019-07-30 02:20:00 | 5a30b45565e029e0b37171858f38dd45 |
| /usr/lib64/httpd/modules/mod_lua.so                 | 117184  | 2019-07-30 02:20:00 | e7fcbc6fd820b42dc8e6ee8d59bf94ec |
| /usr/lib64/httpd/modules/mod_mime_magic.so          | 27816   | 2019-07-30 02:20:00 | 8443494670af39cc405f8b02db7eea2f |
| /usr/lib64/httpd/modules/mod_mime.so                | 19608   | 2019-07-30 02:20:00 | 88356a3c4fc0669806ac38f512e7e60b |
| /usr/lib64/httpd/modules/mod_mpm_prefork.so         | 31968   | 2019-07-30 02:20:00 | 6f3cd5ca71d396a7c6aa7d4654412640 |
| /usr/lib64/httpd/modules/mod_negotiation.so         | 36096   | 2019-07-30 02:20:00 | b6c0cc7e098fcf02f684b07118b7bbff |
| /usr/lib64/httpd/modules/mod_proxy_ajp.so           | 52512   | 2019-07-30 02:20:00 | 4ee3fce8a965bb8cf3613d3133655e61 |
| /usr/lib64/httpd/modules/mod_proxy_balancer.so      | 48264   | 2019-07-30 02:20:00 | 68d804fe62ee75898fefbc6baf8ce6e6 |
| /usr/lib64/httpd/modules/mod_proxy_connect.so       | 19480   | 2019-07-30 02:20:00 | bcf1f5bade61a70f4925ba5528e541d8 |
| /usr/lib64/httpd/modules/mod_proxy_express.so       | 11280   | 2019-07-30 02:20:00 | 58947fcae2715d4da21965aab5920fa8 |
| /usr/lib64/httpd/modules/mod_proxy_fcgi.so          | 19456   | 2019-07-30 02:20:00 | 30d748c5c64a7e990e75bc852cc64c61 |
| /usr/lib64/httpd/modules/mod_proxy_fdpass.so        | 11248   | 2019-07-30 02:20:00 | 3ad100119dd61b4c61377068cceecd98 |
| /usr/lib64/httpd/modules/mod_proxy_ftp.so           | 44280   | 2019-07-30 02:20:00 | d3f7d9418932be039d2e8b73d203bab8 |
| /usr/lib64/httpd/modules/mod_proxy_http.so          | 40040   | 2019-07-30 02:20:00 | 7862d9894b878fac00d583d58ceb11bb |
| /usr/lib64/httpd/modules/mod_proxy_scgi.so          | 19544   | 2019-07-30 02:20:00 | 73d6405524e5c76ea8eaec5b29cf8ffd |
| /usr/lib64/httpd/modules/mod_proxy.so               | 118928  | 2019-07-30 02:20:00 | b8322b6b51ae1475d883f97eb314c565 |
| /usr/lib64/httpd/modules/mod_proxy_wstunnel.so      | 19440   | 2019-07-30 02:20:00 | f8d0c9012dc20caefc6144353dc5063c |
| /usr/lib64/httpd/modules/mod_remoteip.so            | 15392   | 2019-07-30 02:20:00 | d99fc6c664d35bdc13fc1a039089dac5 |
| /usr/lib64/httpd/modules/mod_reqtimeout.so          | 15416   | 2019-07-30 02:20:00 | c8f4a5b6f909d4e40e5259f89fd9e7b4 |
| /usr/lib64/httpd/modules/mod_rewrite.so             | 69128   | 2019-07-30 02:20:00 | 01c904044acb063f002f4052617e28b6 |
| /usr/lib64/httpd/modules/mod_setenvif.so            | 15408   | 2019-07-30 02:20:00 | be9c1aa2201d1ccd8670b9136df4ebf8 |
| /usr/lib64/httpd/modules/mod_slotmem_plain.so       | 11328   | 2019-07-30 02:20:00 | f775135b8ee895094c3aa5d9be73e8d5 |
| /usr/lib64/httpd/modules/mod_slotmem_shm.so         | 15488   | 2019-07-30 02:20:00 | fe675072a811012daf6ddffb5361a984 |
| /usr/lib64/httpd/modules/mod_socache_dbm.so         | 15408   | 2019-07-30 02:20:00 | c876de871d301740a8fa24e954a3d836 |
| /usr/lib64/httpd/modules/mod_socache_memcache.so    | 11280   | 2019-07-30 02:20:00 | 9351b68875ff8a5ae862a859a7ef21fc |
| /usr/lib64/httpd/modules/mod_socache_shmcb.so       | 23656   | 2019-07-30 02:20:00 | a456f3504af40e9a9f601de14928ffac |
| /usr/lib64/httpd/modules/mod_ssl.so                 | 219520  | 2019-07-30 02:20:00 | 68384daa83cd341903bc2247e5f633a3 |
| /usr/lib64/httpd/modules/mod_status.so              | 23552   | 2019-07-30 02:20:00 | 2da3cc4dc05e3f53ab70961756f8b94d |
| /usr/lib64/httpd/modules/mod_substitute.so          | 15368   | 2019-07-30 02:20:00 | 0e351fac2552c2ee4b7cb6af2f7d285e |
| /usr/lib64/httpd/modules/mod_suexec.so              | 11256   | 2019-07-30 02:20:00 | 01bdb478b45733baa887b7bf8dd1790a |
| /usr/lib64/httpd/modules/mod_systemd.so             | 11200   | 2019-07-30 02:20:00 | 3a0192adf92421e34530957bbc32e3cf |
| /usr/lib64/httpd/modules/mod_unique_id.so           | 11224   | 2019-07-30 02:20:00 | a0aea73e61f2f47ef51596ba323bdb1d |
| /usr/lib64/httpd/modules/mod_unixd.so               | 15392   | 2019-07-30 02:20:00 | 42dd165d3ae4d7964b1abcb680b40198 |
| /usr/lib64/httpd/modules/mod_userdir.so             | 11264   | 2019-07-30 02:20:00 | 67f3d79717dcb438b54d914757750ea5 |
| /usr/lib64/httpd/modules/mod_version.so             | 11200   | 2019-07-30 02:20:00 | a3fd906024da56e948e8042cbac35da3 |
| /usr/lib64/httpd/modules/mod_vhost_alias.so         | 11272   | 2019-07-30 02:20:00 | 9f45ef74eebd9b847159a5881293e86e |
| /usr/lib64/ld-2.17.so                               | 163400  | 2019-07-03 22:52:30 | e0a10e3bf4d527193c879eb454bf9954 |
| /usr/lib64/libapr-1.so.0.4.8                        | 198600  | 2017-11-29 06:45:35 | 6b36143da30eb524c80d89c823640b4f |
| /usr/lib64/libaprutil-1.so.0.5.2                    | 172288  | 2014-06-10 11:30:48 | b49eb03995b512d492970b5ab428e15d |
| /usr/lib64/libattr.so.1.1.0                         | 19896   | 2018-04-11 09:40:42 | 27b956649d392f1bdd81e484c5da9bfe |
| /usr/lib64/libbz2.so.1.0.6                          | 68192   | 2015-11-20 14:04:52 | 76b2cb61009d55a068d6fda4a8453a6c |
| /usr/lib64/libc-2.17.so                             | 2151672 | 2019-07-03 22:52:33 | e71942bace284a55c807838ba2d72e7d |
| /usr/lib64/libcap.so.2.22                           | 20032   | 2017-08-03 04:17:59 | 48f0a28b723b6138efb99745a07308ee |
| /usr/lib64/libcom_err.so.2.1                        | 15920   | 2018-10-31 04:03:17 | 88498d13cb80279a267d0e190a676edd |
| /usr/lib64/libcrypt-2.17.so                         | 40664   | 2019-07-03 22:52:32 | cc7271d249bb9b66ab2754c6b9d37d1d |
| /usr/lib64/libcrypto.so.1.0.2k                      | 2516624 | 2019-03-12 19:12:18 | ca4df6c203f26968ef56fe7f4635382f |
| /usr/lib64/libcurl.so.4.3.0                         | 435192  | 2019-07-30 02:19:45 | e49bb6021cc0803de4297c493f53d7b0 |
| /usr/lib64/libdb-5.3.so                             | 1850464 | 2018-04-11 14:31:47 | 2f75db5976d2e43b3e6d42dadec48cde |
| /usr/lib64/libdl-2.17.so                            | 19288   | 2019-07-03 22:52:30 | 4067e916a24d98911f137f2067524dac |
| /usr/lib64/libdw-0.172.so                           | 330464  | 2018-10-31 04:36:30 | 812cb41992c27221923ce1fb9543ef84 |
| /usr/lib64/libelf-0.172.so                          | 100008  | 2018-10-31 04:36:30 | 08084e39db076dd0d17c0bbab82d690d |
| /usr/lib64/libexpat.so.1.6.0                        | 173320  | 2016-11-29 07:26:58 | f2d1fd6927b15c92e2a2e6f9844f15e5 |
| /usr/lib64/libexslt.so.0.8.17                       | 87368   | 2014-06-10 15:12:11 | b7d17f83a961e61480589437aea9c29b |
| /usr/lib64/libfreebl3.so                            | 11448   | 2018-05-16 08:56:10 | 27d7380095572a557bb0236cdddc3b18 |
| /usr/lib64/libfreetype.so.6.14.0                    | 795608  | 2019-01-30 02:26:04 | 6c7847b0f7e62785be30360570bf6ddb |
| /usr/lib64/libgcc_s-4.8.5-20150702.so.1             | 88776   | 2019-04-24 23:25:34 | 2eb040327ae633bc22813dad21f1c1ff |
| /usr/lib64/libgcrypt.so.11.8.2                      | 535064  | 2017-08-03 00:54:39 | 835f23ee5d4341cd129e047afcd77d22 |
| /usr/lib64/libgmp.so.10.2.0                         | 495712  | 2017-08-03 10:12:21 | f4a790af8f3b1ce76067dff0612dfd1f |
| /usr/lib64/libgpg-error.so.0.10.0                   | 19384   | 2014-06-10 17:46:48 | f069049506b74b762a0d943156557e91 |
| /usr/lib64/libgssapi_krb5.so.2.2                    | 320400  | 2019-01-30 02:32:28 | bce034ecde8e6cb3f8e51f1456aa9847 |
| /usr/lib64/libidn.so.11.6.11                        | 208920  | 2015-11-22 02:00:47 | 413000c70ef18130e61a15281ef30c76 |
| /usr/lib64/libjpeg.so.62.1.0                        | 285408  | 2018-10-31 02:15:23 | e6b4c767ff9de786439eb59469d2a603 |
| /usr/lib64/libk5crypto.so.3.1                       | 210824  | 2019-01-30 02:32:28 | 722e85d8fbd7802cd577fa8c0e840bfb |
| /usr/lib64/libkeyutils.so.1.5                       | 15688   | 2014-06-10 11:17:55 | b9cb197dc16e99f25498a0643b7bb3e4 |
| /usr/lib64/libkrb5.so.3.3                           | 967848  | 2019-01-30 02:32:28 | 06973390660228304e2ab9a9bcf93408 |
| /usr/lib64/libkrb5support.so.0.1                    | 67104   | 2019-01-30 02:32:28 | 18c3748be29d7ffd9d61298f4cd51a76 |
| /usr/lib64/liblber-2.4.so.2.10.7                    | 61952   | 2019-01-30 02:43:36 | 33ccf1049001af0d5a9d0d0892c8b4c5 |
| /usr/lib64/libldap-2.4.so.2.10.7                    | 352608  | 2019-01-30 02:43:36 | 4f01b9faaf2202a86d1058376f059ea7 |
| /usr/lib64/liblua-5.1.so                            | 193864  | 2016-11-06 11:47:35 | 3b971e1ed18e5247491da570f9e09c64 |
| /usr/lib64/liblzma.so.5.2.2                         | 157424  | 2016-11-06 00:27:57 | 81615f916ede2689b4ff90b3524b6e20 |
| /usr/lib64/libm-2.17.so                             | 1137024 | 2019-07-03 22:52:32 | 69c5db7af5f90423f749f9f73d00680f |
| /usr/lib64/libnsl-2.17.so                           | 115848  | 2019-07-03 22:52:31 | 38cf86271c1741bd76c852baa598395a |
| /usr/lib64/libnspr4.so                              | 251832  | 2018-05-16 18:46:24 | 1d68cba3e09e65cef52b47694fa50f11 |
| /usr/lib64/libnss3.so                               | 1249576 | 2019-02-01 06:34:54 | 2f7bfa661ca7e18fe1db51905cd66f67 |
| /usr/lib64/libnss_files-2.17.so                     | 61624   | 2019-07-03 22:52:30 | 80123ceb1905942c7f1fe4467008aded |
| /usr/lib64/libnssutil3.so                           | 199008  | 2019-01-30 02:38:11 | 314be13b635572798e46607ad81aeccd |
| /usr/lib64/libpcre.so.1.2.0                         | 402384  | 2017-08-02 12:08:00 | bcbb7c51ebe503462b8bd5830b3217a7 |
| /usr/lib64/libplc4.so                               | 20096   | 2018-05-16 18:46:24 | 0cd965693986ffdb4e1102a6e142887d |
| /usr/lib64/libplds4.so                              | 15800   | 2018-05-16 18:46:24 | ebad465be31aab5e81bf366eb848fab5 |
| /usr/lib64/libpng15.so.15.13.0                      | 179296  | 2015-12-10 01:31:20 | ba4b378a776d268d9eb29b6a2770ce69 |
| /usr/lib64/libpthread-2.17.so                       | 141968  | 2019-07-03 22:52:32 | 32ee534a93a6282c529453cd838f4af1 |
| /usr/lib64/libresolv-2.17.so                        | 105824  | 2019-07-03 22:52:30 | 255252acf64e156d33157792975b652f |
| /usr/lib64/librt-2.17.so                            | 43776   | 2019-07-03 22:52:32 | 6fd91a36e229d3f4421a5876e24dc9f6 |
| /usr/lib64/libsasl2.so.3.0.0                        | 121320  | 2018-04-11 13:20:57 | cdb754306bb2dd645058d1247949d4de |
| /usr/lib64/libselinux.so.1                          | 155784  | 2018-10-31 06:43:05 | e3706e3e568713cc820612ebf7324374 |
| /usr/lib64/libsmime3.so                             | 164288  | 2019-02-01 06:34:54 | 330e555ea50df664b3854d56a9a433b2 |
| /usr/lib64/libsqlite3.so.0.8.6                      | 753232  | 2015-11-20 17:39:02 | c6e37c209c0138489525a47b989f1044 |
| /usr/lib64/libssh2.so.1.0.1                         | 174184  | 2019-07-30 02:22:42 | ed90fbfbf7f819a6413ddaa93c00a57c |
| /usr/lib64/libssl3.so                               | 340976  | 2019-02-01 06:34:54 | f1b1756c9813a722f002b4254005d5f8 |
| /usr/lib64/libssl.so.1.0.2k                         | 470360  | 2019-03-12 19:12:18 | 3ca1b4cc78a276ac69c4638866064783 |
| /usr/lib64/libstdc++.so.6.0.19                      | 991616  | 2019-04-24 23:24:58 | 5c1b8ff0deb0f86a7d84a671be99c77a |
| /usr/lib64/libsystemd-daemon.so.0.0.12              | 28128   | 2019-07-31 17:16:02 | 8920e5286d3c7ea537d5c5f8b89e2bb8 |
| /usr/lib64/libt1.so.5.1.2                           | 299824  | 2014-06-10 13:18:56 | 2136fc5200cceec62cdafa4a88ccc604 |
| /usr/lib64/libtidy-0.99.so.0.0.0                    | 400992  | 2017-05-25 04:31:15 | 3407a4bbd41eff01261ff3b3fd3c92d9 |
| /usr/lib64/libuuid.so.1.3.0                         | 20112   | 2019-03-14 19:37:30 | a5e57a44010129ee814d773fab515167 |
| /usr/lib64/libX11.so.6.3.0                          | 1318800 | 2018-10-31 05:30:18 | ce791da306c5d619605cda7afbd00127 |
| /usr/lib64/libXau.so.6.0.0                          | 15512   | 2014-06-10 09:56:42 | 8564d822addb1893f143144e843fe487 |
| /usr/lib64/libxcb.so.1.1.0                          | 165976  | 2018-10-31 01:40:43 | 2f4ff23a9ffe9775032eb05a435dd814 |
| /usr/lib64/libxml2.so.2.9.1                         | 1509376 | 2016-06-23 23:36:19 | 18fd94949f573337f0393c120cded9d2 |
| /usr/lib64/libXpm.so.4.11.0                         | 74504   | 2017-08-02 13:14:55 | 5f7f159697d61059bda2bc7c9b37e811 |
| /usr/lib64/libxslt.so.1.1.28                        | 258344  | 2014-06-10 15:12:11 | 0b8c46e4b6e3d3f41829c79223195646 |
| /usr/lib64/libzip.so.2.1.0                          | 57952   | 2014-06-10 12:44:41 | 63e754d0c93c2003385177dbb6a8548b |
| /usr/lib64/libz.so.1.2.7                            | 90248   | 2018-10-31 05:24:39 | c80358226abb9ea1b5d76bc10844084d |
| /usr/lib64/mysql/libmysqlclient.so.18.0.0           | 3135712 | 2018-08-17 00:06:36 | fbf9c7c0343623b03867f06e75797ee5 |
| /usr/lib64/php/modules/bcmath.so                    | 32688   | 2018-10-31 04:33:41 | e90891af43200102362c3f7a1a48adc6 |
| /usr/lib64/php/modules/curl.so                      | 74776   | 2018-10-31 04:33:41 | 699e3b956df417ad9259c8118d3df4e8 |
| /usr/lib64/php/modules/dom.so                       | 176600  | 2018-10-31 04:33:41 | 2a5335671ccf85be02fd7af57fd2f2c6 |
| /usr/lib64/php/modules/fileinfo.so                  | 2713464 | 2018-10-31 04:33:41 | 34fa5697344df3bd6a00bdef945f8dab |
| /usr/lib64/php/modules/gd.so                        | 345168  | 2018-10-31 04:33:41 | e2196ab8b9742e266103c27d8733eb2f |
| /usr/lib64/php/modules/json.so                      | 44784   | 2018-10-31 04:33:41 | 7093a23f3a443d4394ebd6ff13c8d176 |
| /usr/lib64/php/modules/mbstring.so                  | 1305768 | 2018-10-31 04:33:41 | bbbcef5fd9053c183f9546c34e417a9f |
| /usr/lib64/php/modules/mysqli.so                    | 146096  | 2018-10-31 04:33:41 | c4ac4c757512d76825071f438df87557 |
| /usr/lib64/php/modules/mysql.so                     | 58024   | 2018-10-31 04:33:41 | d21f40148079a9c5ccf8a7d5961e87bd |
| /usr/lib64/php/modules/pdo_mysql.so                 | 33256   | 2018-10-31 04:33:41 | e4e65441b17f98c80bbaaa54b6554ee1 |
| /usr/lib64/php/modules/pdo.so                       | 116408  | 2018-10-31 04:33:41 | 493798eb533b10ccba57e8d2561e88ec |
| /usr/lib64/php/modules/pdo_sqlite.so                | 29240   | 2018-10-31 04:33:41 | 5effc1f1c10a99eb2e4ea41e167b2758 |
| /usr/lib64/php/modules/phar.so                      | 272112  | 2018-10-31 04:33:41 | f1ce6101f8853f1f877006abe6bc052a |
| /usr/lib64/php/modules/posix.so                     | 32976   | 2018-10-31 04:33:41 | de72c9db6f9fbd0c68d7f0606332efaf |
| /usr/lib64/php/modules/sqlite3.so                   | 51472   | 2018-10-31 04:33:41 | 9682e0fcc0c1cf076d80f98e37ac7371 |
| /usr/lib64/php/modules/sysvmsg.so                   | 19984   | 2018-10-31 04:33:41 | 84252b5cc0eef89f15d408e56212ddc9 |
| /usr/lib64/php/modules/sysvsem.so                   | 11568   | 2018-10-31 04:33:41 | 3d13951ee074db16ae01d5cafc8d086d |
| /usr/lib64/php/modules/sysvshm.so                   | 15792   | 2018-10-31 04:33:41 | d57aad4ca5c17a8a0c6beccb26a92f47 |
| /usr/lib64/php/modules/tidy.so                      | 54000   | 2019-04-26 19:50:23 | 8edf7f34720d8323e2d5f44e3d25296c |
| /usr/lib64/php/modules/wddx.so                      | 36832   | 2018-10-31 04:33:41 | c1bfdaab23b53148bf25864142d06322 |
| /usr/lib64/php/modules/xmlreader.so                 | 33008   | 2018-10-31 04:33:41 | 439abecc5ad545ef1735579833211ab1 |
| /usr/lib64/php/modules/xmlwriter.so                 | 49240   | 2018-10-31 04:33:41 | af3f461629f5cbf0de1a1b86b3a566c0 |
| /usr/lib64/php/modules/xsl.so                       | 37176   | 2018-10-31 04:33:41 | 22e80e1a97a07ba34835ad33c4a08ce1 |
| /usr/lib64/php/modules/zip.so                       | 58496   | 2018-10-31 04:33:41 | 41b1aafeb56a1616c80ec51f1fd4789f |
+-----------------------------------------------------+---------+---------------------+----------------------------------+
</code></pre>

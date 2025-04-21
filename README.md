# forwarders

fluentbit, filbeat 등등 테스트 및 배포용 레포지토리.  그 때 그 때 설정하다보니까 기억이 잘 안남. 템플릿도 잡아놓고 특히 쿠버네티스용 차트 설정으로도 좀 만들어 놔야지

## fluentbit


```sh
helm repo add bitnami https://charts.bitnami.com/bitnami


helm pull bitnami/fluent-bit --version 3.0.0

helm install my-fluent-bit bitnami/fluent-bit --version 3.0.0
```

- 헬름차트 선택
  - 공식 or bitnami의 fluentbit 단독 헬름차트가 가장 무난
  - 단독 차트가 버전 패치도 빠름
  - fluentbit은 멀티아웃풋을 지원하므로, 다른 플랫폼과 묶인 차트 보다는 단독차트가 범용성도 가장 좋음 

- 프로덕션에서 사용시 다음 설정을 별도로 설정해줘야 함. default가 아님
- `DB` 설정: offset 관리. 파일 읽기(in_tail) 수행시 어디까지 읽었는지 기억하다가 프로세스 재시작 상황시 해당지점부터 작업 시작
- `Storage` 설정: 전송실패시 buffer

## fluentbit vs. filebeat

- fluentbit
  - 멀티 아웃풋 지원
  - 쿠버네티스 환경에 자주 쓰임 (CNCF)
  - 로그, 메트릭 용도로 다양한 daemonset이 배포되는데, fluentbit로 한 번에 해결하면 pod 수도 줄고 간편함
    - 물론 각 전용 도구(promtail, node exporter)가 더 디테일한 정보와 기능이 많기 때문에 각자 환경에 맞춰서 적당한걸 고르면됨
  - fluentd 로 전송시
    - fluentd에선 추가 플러그인 설치없이 데이터를 받을 수 있고 멀티프로세싱도 됨

- filebeat
  - 멀티 아웃풋 미지원. 필요시 별도 프로세스 띄워야 함.
  - 원래는 logstash or elasticsearch에 보내는 용도
  - fluentd로 전송시,
    - fleuntd에선 별도 플러그인 설치 필요
    - 널리 쓰이긴 하지만 공식 플러그인은 아니고 소규모 커뮤니티에 의해 관리되는 오픈소스임. 버전 패치도 최근엔 없음. 멀티프로세싱 미지원(지원된다고 말은 하는데 멀티포트 방식임)
    - fluentd 기본 지원된 in-tcp 플러그인으로도 beats 데이터를 수신하면서 멀티프로세싱을 할 수도 있으나, "비츠프로토콜"은 아님. 전용 플러그인을 써야 logstash와 동일한 통신규격이 됨
  - Offset 기능 Default로 활성화되어 있음 (registry 파일)




---
| 구분                 | Fluent Bit                                                                 | Filebeat                                                                                      |
|----------------------|----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| **멀티 아웃풋**       | ✅ 동시에 여러 대상(ES, S3, Kafka 등) 전송 가능                            | ❌ 단일 출력만 지원                                                                           |
| **쿠버네티스**        | 🔵 CNCF 프로젝트, DaemonSet 배포 최적화                                     | 🔵 가능하나 Elastic Stack 연동에 초점                                                         |
| **리소스 사용량**     | 5MB 메모리 사용 (초경량)                                                   | 30MB 메모리 사용 (상대적 무거움)                                                              |
| **Offset 관리**       | DB 파일로 수동 설정 필요                                                   | Registry 파일에 기본 활성화                                                                   |
| **플러그인 생태계**   | 50+ 공식 출력 플러그인                                                     | Beats 커뮤니티 플러그인 의존                                                                   |
| **Fluentd 연동**      | 🔹 기본 플러그인 지원(in-forward)<br>🔹 멀티프로세싱 가능                               | 🔹 beats 입력 플러그인은 공식적으로 멀티프로세싱 지원하지만, 실제로는 멀티포트 방식이라 미지원에 가까움<br>🔹 단, 쿠버네티스 환경에서는 Replica를 통해 간접적 멀티프로세싱 효과를 낼 수 있음 |
| **데이터 처리**       | 로그/메트릭/트레이스 복합 처리                                              | 주로 로그 수집에 특화                                                                         |

# forwarders

fluent-bit, Filebeat 등등 테스트 및 배포용 레포지토리.  그 때 그 때 설정하다보니까 기억이 잘 안남. 템플릿도 잡아놓고 특히 쿠버네티스용 차트 설정으로도 좀 만들어 놔야지

## fluent-bit vs. Filebeat

- fluent-bit
  - 멀티 아웃풋 지원
  - 쿠버네티스 환경에 자주 쓰임 (CNCF)
  - 로그, 메트릭 용도로 다양한 daemonset이 배포되는데, fluent-bit로 한 번에 해결하면 pod 수도 줄고 간편함
    - 물론 각 전용 도구(promtail, node exporter)가 더 디테일한 정보와 기능이 많기 때문에 각자 환경에 맞춰서 적당한걸 고르면됨
  - fluentd 로 전송시
    - fluentd에선 추가 플러그인 설치없이 데이터를 받을 수 있고 멀티프로세싱도 됨
  - 리눅스에선 아주 잘 됨
  - 윈도우 환경에서 이슈가 너무 많음
    - 메모리 버퍼 제어가 안되는 이슈
    - 파일버퍼 사용시 문제
    - 각종 Crash 되는 문제
    - 서비스 종료시 TCP연결해제 관련하여 꼬여서 서비스 중지가 안됨
    - fluentd와 호환문제(메시지가 깨져서 fluentd의 buffer에서 읽어들이지 못하고 멈춤)

- Filebeat
  - 멀티 아웃풋 미지원. 필요시 별도 프로세스 띄워야 함.
  - 원래는 logstash or elasticsearch에 보내는 용도
  - fluentd로 전송시,
    - fleuntd에선 별도 플러그인 설치 필요
    - 널리 쓰이긴 하지만 공식 플러그인은 아니고 소규모 커뮤니티에 의해 관리되는 오픈소스임. 버전 패치도 최근엔 없음. 멀티프로세싱 미지원(지원된다고 말은 하는데 멀티포트 방식임)
    - fluentd 기본 플러그인 in-http, in-tcp 등으로도 beats 데이터를 수신하면서 멀티프로세싱을 할 수도 있으나, "비츠프로토콜"은 아님. 전용 플러그인을 써야 logstash와 동일한 통신규격이 됨
  - Offset 기능 Default로 활성화되어 있음 (registry 파일)
  - 윈도우 환경에서도 꽤 잘 수행됨


---
| 구분                 | fluent-bit                                                                 | Filebeat                                                                                      |
|----------------------|----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| **멀티 아웃풋**       | ✅ 동시에 여러 대상(ES, S3, Kafka 등) 전송 가능                            | ❌ 단일 출력만 지원                                                                           |
| **쿠버네티스**        | 🔵 CNCF 프로젝트, DaemonSet 배포 최적화                                     | 🔵 가능하나 Elastic Stack 연동에 초점                                                         |
| **리소스 사용량**     | 5MB 메모리 사용 (초경량)                                                   | 30MB 메모리 사용 (상대적 무거우나 여전히 경량)                                                              |
| **Offset 관리**       | - 수동 설정 필요<br> - input데이터를 읽어들인 후 DB파일에 기록                                               | - 기본 활성화<br> - 외부로 전송 성공 후 ack받으면 Registry파일에 기록<br> 외부 전송 실패시 input데이터 읽기 일시중지                                                                   |
| **플러그인 생태계**   | 50+ 공식 출력 플러그인                                                     | Beats 커뮤니티 플러그인 의존                                                                   |
| **Fluentd에서**      | 🔹 기본 플러그인 지원(in-forward)<br>🔹 멀티프로세싱 가능<br>🔹 윈도우 버전 fluent-bit과 호환성 충돌                               | 🔹 beats 입력 플러그인은 공식적으로 멀티프로세싱 지원하지만, 실제로는 멀티포트 방식이라 미지원에 가까움<br>🔹 단, 쿠버네티스 환경에서는 Replica를 통해 간접적 멀티프로세싱 효과를 낼 수 있음 |
| **데이터 처리**       | 로그/메트릭/트레이스 복합 처리                                              | 주로 로그 수집에 특화                                                                         |

## 파일 고유성 식별 방식 fingerprint vs. inode+DeviceId

- 파일 고유성 식별이 중요한 이유: 로그 중복/누락 방지
- 누락케이스
  - forwarder가 신규 생성된 파일을 과거에 읽었던 파일로 오인하는 경우, 신규파일을 읽지 않으므로 누락됨
- 중복케이스
  - forwarder가 과거에 읽었던 파일을 신규 생성된 파일로 오인하는 경우, 과거파일을 다시 읽으므로 중복됨
- forwarder의 파일 고유성 인식이 잘못되는 경우가 파일로테이션 등 특정상황에 따라 종종 발생할 수 있음
- 따라서 다음과 같이 forwarder의 파일 고유성 식별 방식을 이해하고 있어야 이슈발생시 트러블슈팅 및 대응이 가능하다.

### inode+DeviceId (Filebeat 구버전과 fluent-bit)

- inode
  - 신규파일 생성시 할당되는 고유 메타데이터이며, 파일 삭제시에 free된다.
  - 리눅스에선 Inode, 윈도우에선 윈도우 File Id를 활용하는데, 파일 고유성 식별 관점에선 사실상 동일개념이라고 봐도 무방
  - 단점: Inode 재사용 문제
    - free된 inode는 다른 파일이 신규생성될 때 재할당될 수 있다.
    - inode 재사용으로 인한 문제가능성은 극히 낮으나, 0% 보장이 안 됨
- Deviceid
  - 파일시스템(파티션, 디스크, 네트워크 스토리지 등)의 고윳값
  - 단점
    - 다른 파일시스템으로 이전시 신규파일로 취급됨
    - 데이터 백업시 이런 이슈 발생할 가능성이 있음
- 특징
  - 파일명/경로는 로그파일 수집대상을 지정할 때 사용할 뿐, 파일 고유성 식별에 사용되지 않는다.
  - 파일이 이름변경(rename), 이동(move)되어도 inode+DeviceId가 여전히 유지되므로 Filebeat는 동일한 파일로 취급한다.
  - rename, move(mv)는 대부분의 OS환경에서 표준 기능이기 때문에 Filebeat 외에 fluent-bit 등 여러 forwarder들도 보편적으로 동일하게 동작하는 부분이다.

### fingerprint (Filebeat 9버전대 default)

- Filebeat 최신버전에서 default로 채택하는 방법
- 파일 앞부분 일부 내용을 fingerprint(지문)처럼 사용
- 파일 이동/복사/변경에 상관없이 앞부분 내용이 동일하면 고유한 동일파일로 취급
- inode+deviceid 방식의 단점을 극복하기 위해 사용됨
- 단, 로그 중복 가능성이 없어야 한다. 로그 앞부분에 시간, uuid, 서버번호, 로그타입 등이 있어서 고유성을 보장하는 형식이어야 안전함.

## 전형적인 파일 로테이션(롤링) 방법

- 로그파일를 읽을 때 상당수의 중복/누락 이슈는 파일로테이션(백업,아키이빙) 시점에 발생한다.
  - e.g.) forwarder가 파일을 덜 읽었는데 해당 파일이 변조되는 경우 몇 라인이 누락
  - e.g.) forwarder가 특정 파일을 인식하지 못하여 해당 파일의 로그 전체가 누락되는 경우 등
- 따라서 자주 활용되는 파일로테이션 방법을 이해하고 있어야 한다.

### SequenceNumber (UNIX에서 전통적인 방식)

```dir
/my/file.log   <-- 현재(실시간) 로그파일 (활성파일, Active File)
/my/file.log.1 <-- 가장 최근에 로테이션됨 (로테이션파일, Rotated File)
/my/file.log.2 <-- 로테이션 수행 전 file.log.1이었던 파일 
/my/file.log.3 <-- 로테이션 수행 전 file.log.2이었던 파일
(...)
/my/file.log.N <-- 가장 오래된 로그(이후엔 삭제되거나 별도 아카이브)
```

- rename (현대적인 대부분 로거의 기본방식)
  - 로테이션파일은 기존 활성파일이 단순 rename된 것이므로, 활성파일이었을 때의 inode를 그대로 유지한다.
  - 로테이션 후 실시간 로그는 신규 활성파일에 적재된다.
    - => 새로운 file.log가 만들어진 것
  - forwarder가 `/my/*`경로 전체를 모니터링하고 있다면 로테이션이 발생해도 중복/누락없이 로그를 수집한다. (로테이션파일도 읽기대상으로 지정해야 함)
- copy and truncate (구시대 방식)
  - 활성파일은 그대로 유지되고, 로테이션파일이 "신규 생성"되는 방식
  - 활성파일을 copy하여 로테이션파일로 남긴 후, 활성파일의 내용을 비운다(truncate).
  - 로테이션 전후로 활성파일은 inode가 유지되며, 로테이션파일은 신규생성되었으므로 신규inode가 할당됨
  - 대표적으로, 로거가 아닌 별도 앱 (`/etc/logrotate` 등)으로 로그파일을 관리할 때 이렇게 되는데, 요즘은 비주류 방식
<!-- - 로그 누락 예시
  - forwarder가 활성파일을 덜 읽었을 때, 로테이션 수행시 -->

### DateSuffix

```dir
/my/file_20250601.log
/my/file_20250602.log
/my/file_20250603.log
(...)
```

- 항상 해당 시간에 대응하는 파일이 신규 생성되는 방식

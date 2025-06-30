# Filebeat for windows

## 윈도우에서 filebeat 설치 및 서비스로 실행

- 공홈에서 zip or msi 다운로드
  - 둘 다 구성파일 거의 동일
    - msi로 설치시 실행/설정파일: `C:\Program Files\Elastic\Beats\9.0.1\filebeat\`
    - msi로 설치시 레지스트리파일: `C:\ProgramData\filebeat\data\registry\data\`
  - 실무 환경에서는 제공되는 서비스 설치 스크립트를 이용해 Filebeat를 윈도우 서비스로 등록하고 실행해야 함
  - 설정파일 변경시 다시 서비스 등록할 필요는 없고, 서비스 재시작만 하면 됨

```powershell
# filebeat 디렉토리 안에 filebeat를 윈도우 서비스로 설치하는 스크립트가 있음 
# 관리자 권한 Powershell에서 스크립트 실행
# OS의 스크립트 보안정책에 의해 차단된 경우 다음과 같이 해당 파일만 일시허용하면서 실행가능
PowerShell.exe -ExecutionPolicy UnRestricted -File .\install-service-filebeat.ps1
```

- 서비스 설치후 `작업관리자-서비스`에서 확인가능
  - 안보이면 윈도 앱 실행에서 `services.msc`로 진입

## 서비스 삭제시

- uninstall 스크립트도 filebeat설치경로에 있음

```sh
# 서비스 삭제 후 재설치시 서비스 삭제 대기 중으로 에러가 난다면, 이 명령어로 완전삭제 가능 
sc delete filebeat
```

## 파일 고유성 식별 방식 fingerprint vs. inode+DeviceId

- 파일 고유성 식별이 중요한 이유: 로그 중복/누락 방지
- 누락케이스
  - filebeat가 신규 생성된 파일을 과거에 읽었던 파일로 오인하는 경우, 신규파일을 읽지 않으므로 누락됨
- 중복케이스
  - filebeat가 과거에 읽었던 파일을 신규 생성된 파일로 오인하는 경우, 과거파일을 다시 읽으므로 중복됨
- filebeat의 파일 고유성 인식이 잘못되는 경우가 파일로테이션 등 특정상황에 따라 종종 발생할 수 있음
- 따라서 다음과 같이 filebeat의 파일 고유성 식별 방식을 이해하고 있어야 이슈발생시 트러블슈팅 및 대응이 가능하다.

### inode+DeviceId (Filebeat 구버전)

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
  - 파일이 이름변경(rename), 이동(move)되어도 inode+DeviceId가 여전히 유지되므로 filebeat는 동일한 파일로 취급한다.
  - rename, move(mv)는 대부분의 OS환경에서 표준 기능이기 때문에 filebeat 외에 fluent-bit 등 여러 forwarder들도 보편적으로 동일하게 동작하는 부분이다.

### fingerprint (Filebeat 9버전대 default)

- Filebeat 최신버전에서 default로 채택하는 방법
- 파일 앞부분 일부 내용을 fingerprint(지문)처럼 사용
- 파일 이동/복사/변경에 상관없이 앞부분 내용이 동일하면 고유한 동일파일로 취급
- inode+deviceid 방식의 단점을 극복하기 위해 사용됨
- 단, 로그 중복 가능성이 없어야 한다. 로그 앞부분에 시간, uuid, 서버번호, 로그타입 등이 있어서 고유성을 보장하는 형식이어야 안전함.

## 전형적인 파일 로테이션(롤링) 방법

- 로그파일를 읽을 때 상당수의 중복/누락 이슈는 파일 로테이션 상황에 발생한다.
- 따라서 자주 나오는 파일로테이션 방법을 이해하고 있어야 한다.

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
- copy and truncate (구시대 방식)
  - 활성파일은 그대로 유지되고, 로테이션파일이 "신규 생성"되는 방식
  - 활성파일을 copy하여 로테이션파일로 남긴 후, 활성파일의 내용을 비운다(truncate).
  - 로테이션 전후로 활성파일은 inode가 유지되며, 로테이션파일은 신규생성되었으므로 신규inode가 할당됨
  - 대표적으로, 로거가 아닌 별도 앱 `/etc/logrotate`으로 로그파일을 관리할 때 이렇게 된다.
  - 비권장 방식

### DateSuffix 로테이션을 쓸 때 신규파일 인식 방법

```dir
/my/file_20250601.log
/my/file_20250602.log
/my/file_20250603.log
(...)
```

- 항상 해당 시간에 대응하는 파일이 신규 생성되는 방식

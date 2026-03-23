# Filebeat for windows

## 윈도우에서 filebeat 설치 및 서비스로 실행

- 공홈에서 zip or msi 다운로드
  - 둘 다 구성파일 거의 동일
    - msi로 설치시 실행/설정파일: `C:\Program Files\Elastic\Beats\9.0.1\filebeat\`
    - msi로 설치시 레지스트리파일: `C:\ProgramData\filebeat\data\registry\data\`
    - `9.0.6, 9.1.0부터 윈도우 버전 기본경로 변경`
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

- uninstall 스크립트도 filebeat설치경로에 있음. 관리자 권한 파워쉘로 실행

```sh
# 서비스 삭제 후 재설치시 서비스 삭제 대기 중으로 에러가 난다면, 이 명령어로 완전삭제 가능 
sc delete filebeat
```

```sh
# 또는 

# 관리자 권한 Powershell에서 스크립트 실행
.\uninstall-service-filebeat.ps1

# OS의 스크립트 보안정책에 의해 차단된 경우 다음과 같이 해당 파일만 일시허용하면서 실행가능
PowerShell.exe -ExecutionPolicy UnRestricted -File .\uninstall-service-filebeat.ps1
```

## filebeat 클린 삭제 

- 아래 내용은 편의상 스크립트로 나타낸 것으로, 윈도우특성상 권한문제 등으로 막힐 수 있음
- 주석 내용을 똑같이 UI에서 처리해도 상관없음

```sh
# 1. 서비스 중지 (또는 services.msc에서 삭제)
Stop-Service filebeat -Force

# 2. 서비스 제거 (filebeat 설치경로에서 실행)
.\uninstall-service-filebeat.ps1  # 또는 sc.exe delete filebeat 

# 3. Filebeat 설치 경로 삭제
Remove-Item -Recurse -Force "C:\Program Files\Filebeat"

# 4. Filebeat 메타데이터 경로 삭제
Remove-Item -Recurse -Force "$env:ProgramData\filebeat"
```

## filebeat 버전 선택 및 변경시 요령(Elastic 정책상 약간 특이하므로 반드시 참고)

- `가급적 최신 릴리즈 선택`하고, 안정성이 극단적으로 중요시 과거 Major의 마지막 버전 선택(Minor 기준 X)
- beat는 릴리즈 주기가 빠르며, 빠르게 지원 중단됨. LTS 개념 없음
- `신규 Minor버전 릴리즈시, 이전 Minor버전은 거의 지원중단 수준임`
  - 보안패치도 잘 안함
  - 이전 Minor 버전을 굳이 고른다면, 반드시 릴리즈 날짜 체크할 것
  - `Elastic 정책상, 직전 Minor버전의 최신 Patch버전 선택은 딱히 좋은 선택이 아님`
  - 중간 숫자 Minor버전은 사실상 patch레벨로 보는게 좋음
- 업그레이드시 호환성
  - 여느 소프트웨어처럼 메이저 버전 내에서는 과거 버전 설정 호환성을 지원
  - 미호환 가능성이 있을시, 공식 문서에서 "Breaking Changes"로 별도 정리해주므로 이것만 참고하면 됨
  - https://www.elastic.co/docs/release-notes/beats/breaking-changes

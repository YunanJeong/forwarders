# Filebeat for windows

## 윈도우에서 filebeat 설치 및 서비스로 실행

- 공홈에서 zip or msi 다운로드
  - 둘 다 구성파일 거의 동일
    - msi로 설치시 실행/설정파일: `C:\Program Files\Elastic\Beats\9.0.1\filebeat\`
    - msi로 설치시 레지스트리파일: `C:\ProgramData\filebeat\data\registry\data\`
  - 프로덕션 환경에서 윈도우 서비스로 실행시, 포함된 서비스 설치 스크립트를 실행해야 함
  - 서비스 최초 설치 후 설정파일 변경시 서비스 재시작만하면 반영됨

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

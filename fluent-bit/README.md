# fluent-bit

## fluent-bit Native

```sh
# Single line install for Debian
curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh

# 프로덕션 시 자동 재시작 활성화 잊지말기
sudo systemctl enable fluent-bit

sudo systemctl start fluent-bit
sudo systemctl status fluent-bit
```

- 설정파일 경로: /etc/fluent-bit/fluent-bit.conf (서비스 설정파일 or status 체크로도 확인가능)

```sh
/etc/fluent-bit/
├── fluent-bit.conf # 설정 파일 핵심
├── parsers.conf    # 여기에 파서를 미리 작성 후 호출하여 사용가능  # 기본 제공 파서들 있음
└── plugins.conf    # 플러그인 경로 설정. default 비활성화
```

- 설정파일 변경 후 restart하면 반영

## fluentbit 헬름 차트

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

- bitnami/fluent-bit
  - 기본 deployment로 배포되며, daemonset 모드 활성화시 deployment는 자동으로 비활성화
  - daemonset 모드의 default 설정은 쿠버네티스 내 로그(호스트의 시스템 로그 및 컨테이너앱 로그) 수집을 목표로 하고있음.
  - 배포 모드 상관없이 이 외 모니터링 대상은 직접설정 및 엑스트라볼륨 설정 필요

# 버퍼 관련 설정

- 메모리/디스크 버퍼 크기 설정, 활성화 여부, default 정리하기
- input/output/service 어떤 플러그인에서 쓸 수 있는지 확인
- AI한테 물어보면 지엽적인 부분에서 계속 틀리기 때문에, 문서 기반 테스트해서 검증 필요
- https://docs.fluentbit.io/manual/administration/backpressure
- https://docs.fluentbit.io/manual/administration/buffering-and-storage
- fluent-bit에선 기본적으로 memory 버퍼는 항상 있으며, filesystem 버퍼 활성화시 파일버퍼가 secondary buffer로 사용되는 개념임

## [SERVICE]

- **storage.path /foo/bar/**
  - 파일버퍼 경로 지정
  - default: 없음
  - 파일버퍼 활성화를 위한 [SERVICE]에서 최소 필요 설정
- **storage.max_chunks_up 128**
  - 파일버퍼 활성화시, 메모리버퍼의 청크 개수 제한
  - default: 128
  - 파일버퍼 활성화시에만 적용됨 ([INPUT]에서 `storage.type filesystem`). 메모리버퍼 단독사용시 무시됨.
  - 설정된 청크 개수 초과시 파일버퍼로 넘어감
  - **단일 청크의 크기는 약 2MB이며, 이는 fluent-bit 엔진 내부에서 관리. 커스텀X**
- **storage.backlog.mem_limit 5M**
  - 백로그 데이터 메모리 용량 제한
  - default: 5M
  - 파일버퍼 데이터를 다음 플러그인으로 전송하려면, 파일버퍼를 메모리로 읽어야 하는데 이 때 한도를 설정하는 것
  - 장기간 전송 실패 등으로 파일버퍼에 누적량(backlog)이 많을 때, 한번에 메모리를 과점유하지 않기 위해 쓰는 옵션

## [INPUT]

- **storage.type memory**
  - 파일 버퍼 사용 여부 결정
  - default: memory
  - 값 예시
    - memory: 메모리버퍼만 사용
    - filesystem: 파일버퍼를 추가하여 사용(메모리 버퍼와 함께 동작함). 파일버퍼 활성화를 위한 [INPUT]에서 최소 필요 설정
- **Mem_Buf_Limit**
  - 메모리버퍼 총량 제한
  - default: 제한 없음
  - 값 예시: 500M,2G 등 용량기술
  - 메모리버퍼 단독 사용시에만 적용(`storage.type memory`). 파일버퍼 활성화시 무시됨.

### [INPUT-tail플러그인전용]

- **Buffer_Chunk_Size 32k**
  - 파일읽기 1회에 사용되는 메모리버퍼(1회에 읽는 양)
  - default: 32k
  - 클수록 read 횟수 줄어서 CPU 부하 감소 => read 성능 향상 => 대규모 데이터 처리시 유리(메모리 점유는 늘어남)
  - **TIP) 성능최적화에 쓸 수 있긴한데, 일반적으로 default로 두는 것 무방**
  - **이 옵션의 chunk는 tail 플러그인 전용 단위로, storage 관련 옵션에서 다루는 Fluent Bit 엔진의 청크와는 다르다. 여러 tail chunk가 모여 하나의 엔진 청크가 만들어진다.**
- **Buffer_Max_Size 32k**
  - 로그라인 1줄에 대한 용량 제한 (초과시 짤림)
  - default: 32k
  - **TIP) 기본값이 좀 부족한 감이 있음. 로그손실방지를 위해 기본 1M 맞춰두고 하는게 편했음**

## [OUTPUT]

- **storage.total_limit_size**
  - 목적지 별 파일 버퍼 총량 제한
  - default: 없음
  - 값 예시: 500M, 2G 등 용량 기술
  - 파일 버퍼 활성화 여부는 input에서 하지만, 크기 제한은 이 옵션으로 output에서 한다.
    - 동일 input에 여러 output이 있을 수 있기 때문에 개별 output에서 제어해야 함

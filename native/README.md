# 버퍼 관련 설정

- 메모리/디스크 버퍼 크기 설정, 활성화 여부, default 정리하기
- input/output/service 어떤 플러그인에서 쓸 수 있는지 확인
- AI한테 물어보면 지엽적인 부분에서 계속 틀리기 때문에, 문서 기반 테스트해서 검증 필요
- https://docs.fluentbit.io/manual/administration/backpressure

- fluent-bit에선 기본적으로 memory 버퍼는 항상 있으며, filesystem 버퍼 활성화시 파일버퍼가 secondary buffer로 사용되는 개념임

## [SERVICE]

- storage.max_chunks_up
  - 파일버퍼 활성화시, 메모리버퍼의 사이즈를 결정
  - 초과시 파일버퍼로 데이터가 넘어감
- storage.backlog.mem_limit: 백로그 데이터 메모리 한도
  - default: 5M
  - 디스크 버퍼에 있는 데이터를 다음 플러그인으로 전송하려면, 디스크 버퍼를 메모리로 읽어야 하는데 이 때 한도를 설정하는 것
  - 장기간 전송 실패 등으로 디스크 버퍼에 누적량(backlog)이 많을 때, 한번에 메모리를 과점유하지 않기 위해 쓰는 옵션

## [INPUT]

- Mem_Buf_Limit
  - 메모리 버퍼 크기 제한
  - default: 제한 없음
  - 메모리 버퍼만 단독 사용시 적용됨
  - 파일 버퍼 활성화시 무시됨. [service]의 storage.max_chuncks_up으로 메모리 버퍼 크기를 조정
- storage.type
  - default: memory

### [INPUT-tail플러그인전용]

- Buffer_Chunk_Size: 내부 처리용 청크 사이즈
- Buffer_Max_Size: 로그라인 한 줄에 대한 크기 제한. 초과시 짤림

## [OUTPUT]

- storage.total_limit_size
  - 파일 버퍼 크기 제한
  - default: 제한 없음

---------------------------------------------------------
??????????????????
왜 storage.type은 input 에만 쓰고, storage.total_limit_size는 output에만 쓰지?
storage.type filesystem으로 설정한 인풋 파일 버퍼랑 아웃풋 파일 버퍼는 다른건가?

일단 AI 답변 정리 (문서기반 팩트체크 아직 안됨)
=>  input에서랑 연걸된 output에서의 파일 버퍼는 같은거다
=> 만약 input에서 storage.type memory인데 연결된 output에 storage.total_limit_size가 있으면 무시된다.
(fluent-bit는 항상 멀티 인풋, 멀티 아웃풋임을 감안해야 함)
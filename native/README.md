# 버퍼 관련 설정

- 메모리/디스크 버퍼 크기 설정, 활성화 여부, default 정리하기
- input/output/service 어떤 플러그인에서 쓸 수 있는지 확인
- AI한테 물어보면 지엽적인 부분에서 계속 틀리기 때문에, 문서 기반 테스트해서 검증 필요
- https://docs.fluentbit.io/manual/administration/backpressure

- list
  - Mem_Buf_Limit
  - Buffer_Max_Size
  - storage.backlog.mem_limit 5M  
  - storage.max_chunks_up
  - storage.type memory
  - storage.type filesystem


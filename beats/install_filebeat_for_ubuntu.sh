# 다운로드 링크 출처: 공홈
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-9.0.8-amd64.deb
sudo dpkg -i filebeat-9.0.8-amd64.deb

# 호스트  부팅시 자동실행 활성화
sudo systemctl enable filebeat

# Ubuntu 서비스 조회:                        sudo systemctl status filebeat
# DEB 설치시, 설정파일 경로:                  /etc/filebeat/filebeat.yml
# DEB 설치시, 로그 및 오프셋 레지스트리 경로:  /var/lib/filebeat

# 시작
# sudo systemctl start filebeat
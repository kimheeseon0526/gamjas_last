# GAMJAS 🥔 여행 플랫폼 프로젝트
(6/9 ~ 7/9 팀 프로젝트 완료 | 7/16 ~ 개인 리빌드 진행 중)

GAMJAS는 지하철 노선도 + Kakao Map API를 기반으로  
사용자에게 여행 정보와 미션 투어 기능을 제공하는 웹 플랫폼입니다.

---

## 📌 주요 기능
- Kakao Map 기반 지하철 노선도 시각화
- 여행 정보 장소 조회 (축제, 명소, 맛집)
- 지하철역 반경 기반 추천 장소 표시
- 미션 수행 → 감자티켓 지급 → 경품 응모
- 후기 작성 기능

---

## 🛠️ 기술 스택

- ![Java](https://img.shields.io/badge/Java-FF0000?style=for-the-badge&logo=java&logoColor=white)
- ![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)
- ![jQuery](https://img.shields.io/badge/jQuery-0769AD?style=for-the-badge&logo=jquery&logoColor=white)
- ![HTML5](https://img.shields.io/badge/HTML5-E34F26?style=for-the-badge&logo=html5&logoColor=white)
- ![CSS3](https://img.shields.io/badge/CSS3-1572B6?style=for-the-badge&logo=css3&logoColor=white)
- ![MVC](https://img.shields.io/badge/MVC%20Pattern-0078D7?style=for-the-badge&logo=microsoft&logoColor=white)
- ![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)
- ![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)

---

## 📅 리빌드 주요 변경사항

### 26.03.12 - 지하철 노선도 분기선 처리 개선

- 2호선 `branch_group` 값 불일치로 인한 분기선 누락 → DB 수정
- 1호선 다계열(경인·경부·1호·경원선) odr 충돌로 polyline 꼬임
  → 노선별 버킷 분리 후 순서대로 이어붙이기 + 경부선 odr 재정렬 + 경의중앙선 구간 필터링

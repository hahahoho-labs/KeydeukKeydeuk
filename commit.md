## 이 명령어가 하는 일

1. **현재 작업 디렉토리 확인**:
   - pwd로 현재 위치 확인
   - 서브모듈 디렉토리가 아닌 메인 프로젝트 루트에서 실행해야 함
   - 만약 서브모듈 디렉토리에 있다면 메인 프로젝트로 이동
2. git status로 staged된 파일을 확인합니다
3. staged된 파일이 0개면 자동으로 모든 수정/새 파일을 git add합니다
4. git diff를 실행하여 커밋할 변경사항을 분석합니다
5. diff를 분석하여 여러 개의 독립적인 논리적 변경사항이 있는지 확인합니다
6. 여러 개의 변경사항이 감지되면 더 작은 커밋으로 나누는 것을 제안합니다
7. 각 커밋(또는 나누지 않는 경우 단일 커밋)에 대해 Conventional Commit 포맷으로 커밋 메시지를 생성합니다

## Conventional Commit 규격

커밋 메시지 구조:
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]

### 커밋 타입

- feat: 새로운 기능 추가 (MINOR in Semantic Versioning)
- fix: 버그 수정 (PATCH in Semantic Versioning)
- docs: 문서 변경
- style: 코드 포맷팅, 세미콜론 누락 등 (코드 변경 없음)
- refactor: 코드 리팩토링 (버그 수정이나 기능 추가 없음)
- perf: 성능 개선
- test: 테스트 추가 또는 수정
- chore: 빌드 프로세스, 도구 변경 등
- ci: CI/CD 관련 변경
- build: 빌드 시스템이나 외부 의존성 변경

### 중요 규칙

- **모든 커밋 메시지는 영어로 작성해야 합니다**
- **현재형, 명령형으로 작성** (예: add, fix, update)
- **첫 번째 줄은 72자 이하로 제한**
- **Breaking Change가 있는 경우 느낌표(!)를 타입 뒤에 추가하거나 footer에 BREAKING CHANGE: 명시**

## 커밋 분할 가이드라인

다음 기준에 따라 커밋 분할을 고려합니다:

1. **다른 관심사**: 코드베이스의 관련 없는 부분에 대한 변경
2. **다른 변경 타입**: 기능, 수정, 리팩토링 등을 혼합하는 경우
3. **파일 패턴**: 다른 타입의 파일 변경 (예: 소스 코드 vs 문서)
4. **논리적 그룹핑**: 별도로 이해하거나 리뷰하기 쉬운 변경사항
5. **크기**: 분해하면 더 명확해질 수 있는 매우 큰 변경사항

## 커밋 메시지 예시

좋은 커밋 메시지:

- feat: add user authentication system
- fix: resolve memory leak in rendering process
- docs: update API documentation for new endpoint
- refactor: simplify error handling logic in parser
- style: reorganize component structure for readability
- perf: optimize database query performance
- test: add unit tests for user registration form
- chore: update package dependencies
- ci: adjust GitHub Actions workflow
- build: update build configuration
- feat!: change authentication API structure

## 중요 사항

- **⚠️ 작업 디렉토리 확인 필수**: 반드시 pwd로 현재 위치를 확인하고 메인 프로젝트 루트에서 실행하세요
- **에러 발생 시**: 반드시 해당 서브모듈 동기화를 먼저 실행하세요
- **특정 파일이 이미 staged된 경우**: 해당 파일들만 커밋합니다
- **staged된 파일이 없는 경우**: 자동으로 모든 수정된 파일과 새 파일을 stage합니다
- **커밋 전에 diff를 검토**: 메시지가 변경사항과 일치하는지 확인합니다

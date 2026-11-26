<!-- SPDX-License-Identifier: MIT -->
<!-- SPDX-FileCopyrightText: 2026 c0z0c <c0z0c@hotmail.com> -->

# McpConsole 배포 패키지

- 터미널 에뮬레이터와 연결 관리자를 통합한 Windows 데스크톱 애플리케이션
- 로컬 셸, SSH2, Telnet, 시리얼 포트, FTP/SFTP, HTTP, MCP 서버 연결 지원
- UI 기능을 CLI와 OLE COM 자동화 인터페이스로 제어 가능

## 디렉터리 구조

```text
Release\
  README.md                  배포 문서
  release\
    <버전>\McpConsole.exe    버전별 실행 파일 (예: release\0.6.1.25\McpConsole.exe)
```

- `McpConsole.exe`에 UI, CLI, COM 어댑터 포함
- 별도 애플리케이션 바이너리 없이 단일 실행 파일로 배포

## 설치 및 업데이트

1. **.NET 10 Desktop Runtime (x64)** 설치
   - 프레임워크 종속 배포 방식으로 런타임은 실행 파일에 포함하지 않음
   - 실행 파일 크기 약 9MB
2. `release\<버전>\McpConsole.exe`를 설치 대상 디렉터리에 복사
3. 실행 파일 실행
   - 최초 실행 시 실행 파일과 동일한 디렉터리에 기본 설정 파일 생성
   - 기존 설정 파일 유지

| 파일 | 설명 |
|---|---|
| `config.ini` | 전역 설정: 언어, 글꼴, 색상 테마, 스크롤백 버퍼, 로그 디렉터리 등 |
| `session.json` | 저장된 세션 목록 |
| `window.json` | 창 위치 및 크기 |
| `mcpconsole_lang.json` | UI 언어 리소스 (English, 한국어 및 추가 언어) |
| `mcp.json`, `com\` | MCP 서버 정의 및 COM 어댑터 구성 파일 |

- 버전 업데이트 시 새 버전의 `McpConsole.exe`로 교체
- 기존 사용자 설정 유지
- `도움말 → 업데이트 확인 → 지금 확인`: GitHub 최신 릴리스 조회
- `도움말 → 업데이트 확인 → 자동 업그레이드`: 시작 시 7일 간격으로 릴리스 확인
- 업데이트 설치 전 사용자 확인
- 다운로드한 실행 파일의 SHA-256 검증 후 실행 파일 교체

## 주요 기능

### 세션 연결

- **세션 관리자**에서 세션을 두 번 클릭해 연결
- `Local` 폴더에 `cmd`, `PowerShell`, `Git Bash`, `WSL` 세션 제공
- `Alt+Q`: 빠른 연결 대화상자 (SSH2, Telnet, Serial, 로컬 셸)
- `Alt+C`: 연결 대화상자
- `Alt+숫자`: 해당 순번의 탭으로 이동
- URI 스킴을 사용한 연결 주소 입력 지원: `ssh://user@host:22`, `telnet://host`, `serial://COM3@115200`
- 연결이 종료된 세션에서 `Enter` 입력 시 재연결

### 터미널 조작

- 마우스 드래그로 텍스트 선택
- 더블클릭으로 단어 선택, 트리플클릭으로 해당 라인 선택
- 마우스 오른쪽 버튼으로 복사 및 붙여넣기 컨텍스트 메뉴 표시
- 복사: `Ctrl+Shift+C`; 선택 영역이 있을 때 `Ctrl+C` 지원
- 붙여넣기: `Ctrl+V` 또는 `Shift+Insert`
- 확대/축소: `Ctrl+휠`, `Ctrl+=`, `Ctrl+-`, `Ctrl+0`
- 전체 화면: `F11`; Hex 보기: `Ctrl+Shift+X`
- 링크 열기: `Ctrl+클릭`
- 스크롤백 탐색: 마우스 휠 또는 `Shift+PageUp`/`Shift+PageDown`
- 한글 입력기가 전각 상태이면 상태 표시줄의 입력기 표시를 주황색으로 표시
  - 입력기 표시를 두 번 클릭해 반각 상태로 전환

### 설정 및 로그

- `옵션 → 전역 옵션...`에서 언어, 글꼴, 색상 테마, 스크롤백 버퍼, 로그 디렉터리 설정
- 설정 대화상자에서 확인을 선택하면 변경 사항 적용 및 저장
- 전역 옵션은 신규 세션의 기본값으로 적용
- 저장된 세션은 세션별 옵션 유지
- 세션 출력은 타임스탬프와 함께 메모리 버퍼에 저장
- `파일 → 로그 세션 기록`: 세션 출력을 로그 파일에 기록
- `파일 → 버퍼를 파일로 저장`: 메모리 버퍼를 파일로 내보내기
- `보기` 메뉴에서 메뉴 막대, 도구 모음, 상태 표시줄, 탭 막대, 세션 관리자, 명령 창 표시 여부 설정

## 명령줄 인터페이스 (CLI)

- 실행 중인 McpConsole 인스턴스에 명령 전달
- UI 인스턴스 또는 `McpConsole.exe host`로 실행한 헤드리스 호스트 필요
- 아래 예시의 `mcpconsole`은 `McpConsole.exe`를 가리키는 별칭
  - `Set-Alias mcpconsole C:\경로\McpConsole.exe`

```powershell
mcpconsole list                                               # 열린 세션 조회
$id = mcpconsole open --protocol local --shell C:\Windows\System32\cmd.exe  # 세션 생성 및 ID 출력
mcpconsole send $id 'echo hello\r'                            # 입력 전송 (\r, \n, \e, \xNN 이스케이프 지원)
mcpconsole wait $id hello ; mcpconsole text $id               # 출력 대기 및 터미널 버퍼 조회
mcpconsole tail $id -n 50 ; mcpconsole grep $id -in error     # 세션 로그 조회 및 검색
mcpconsole set appearance.fontSize 14 --save                  # 설정 변경 및 저장
mcpconsole commands                                           # 명령 목록 조회
mcpconsole --help                                             # 사용법 조회
```

- 종료 코드
  - `0`: 성공
  - `1`: 명령 오류
  - `2`: 사용법 오류
  - `3`: 실행 중인 인스턴스 없음
  - `4`: 시간 초과
  - `5`: 권한 오류
- McpConsole이 UI 모드로 실행되면 호출한 `cmd` 또는 PowerShell 프로세스는 완료를 기다리지 않음
- 순차 실행이 필요하면 `Start-Process -Wait -NoNewWindow` 사용

## OLE COM 자동화

```powershell
McpConsole.exe com-status      # COM 어댑터 설치 및 등록 상태 조회
McpConsole.exe com-install     # COM 어댑터 설치 및 등록
McpConsole.exe com-uninstall   # COM 어댑터 등록 해제
```

- 관리자 권한 설치: 시스템 전체에 등록
- 일반 사용자 권한 설치: 현재 사용자 범위에 등록

## AI 도구 연동 (MCP)

```powershell
McpConsole.exe ai-clients                 # 지원 AI 도구 및 등록 상태 조회
McpConsole.exe ai-register claude         # Claude Code에 McpConsole MCP 서버 등록
McpConsole.exe ai-unregister claude       # Claude Code 등록 해제
```

- 지원 도구: Claude Code, Claude Desktop, Codex, Antigravity
- 등록된 AI 도구에서 터미널 출력 조회, 입력 전송, 세션 생성 가능
- UI 경로: `도구 → MCP 등록`

## 알려진 제한 사항

- 한글 입력기가 전각 상태로 전환될 수 있음
  - 상태 표시줄의 입력기 표시를 두 번 클릭해 반각 상태로 전환
- PowerShell 5.1 프로필에서 `Write-Progress`가 실행되는 동안 터미널에 색상 잔상이 발생할 수 있음

## 버전 이력

| 버전 | 변경 사항 |
|---|---|
| 1.1.0 | **세션관리.** 세션 관리자에서 끌어 놓기로 순서 변경 및 폴더 이동, 정렬, 복제(Ctrl+끌기, 저장된 비밀번호 포함) 지원. Telnet, 시리얼, 로컬 셸의 로그인 자동 입력 추가. |
| 1.0.1 | **디버그 모드 추가.** 전역 옵션에서 켜면 프로그램 동작 로그를 로그 디렉터리의 `mcpconsole.log`에 기록. 한글 입력기 상태 변화와 포커스 이동을 추적해 전각 전환 원인 분석 가능. 일반 문자 입력은 기록하지 않음. |
| 0.6.2 | **최초 공개 버전.** 로컬 셸(cmd, PowerShell, Git Bash, WSL), SSH2, Telnet, 시리얼, FTP/SFTP, HTTP, MCP 세션 지원. 탭 분할 및 드래그 앤 드롭, 세션 관리자, 밀리초 타임스탬프 세션 로그, 화면 검색, Hex 보기, 10개 색상 테마, 한국어 및 English UI 제공. UI, CLI, OLE COM 공통 자동화 명령 및 AI 도구 MCP 연동. |

* 버전 이력 변경 사항 간단 내용만, 코드 없음
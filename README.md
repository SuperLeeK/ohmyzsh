# ohmyzsh-bootstrap

맥 초기화 직후 **한 줄**로 oh-my-zsh + 테마/플러그인 + 기본 개발툴(adb/scrcpy/git 등) + Node 스택(nvm/yarn/ts-node) + 필수 GUI 앱까지 자동 세팅합니다.

---

## 🚀 One‑liner (curl)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/SuperLeeK/ohmyzsh/main/install.sh)"
```
설치 스크립트 실행 시 어떤 항목들을 설치할지 묻는 프롬프트가 나타납니다.
숫자를 콤마(`,`)로 구분하여 원하시는 번호들만 입력하시면 됩니다 (예: `1,2,4`).

1. **Oh My Zsh** (Zsh, 플러그인, NVM, Node 스택 등)
2. **Homebrew Apps** (CLI 툴 및 기본 GUI 앱)
3. **App Store Apps** (mas CLI를 활용한 앱스토어 앱 설치)
4. **Web Apps** (바로가기 생성 방식의 웹앱 설치)

### 옵션 실행 예시
- cask(GUI 앱) 설치 없이 최소 설치:
```bash
WITH_CASKS=0 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/SuperLeeK/ohmyzsh/main/install.sh)"
```
- 점프 도구를 `zoxide`로 지정:
```bash
JUMP_IMPL=zoxide /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/SuperLeeK/ohmyzsh/main/install.sh)"
```

---

## 무엇이 설치되나요?

### 1. Shell/테마/플러그인
- **oh-my-zsh** (테마: `robbyrussell`)
- 플러그인: `zsh-autosuggestions`, `zsh-syntax-highlighting`
- 점프 도구: 기본 `autojump` (원하면 `JUMP_IMPL=zoxide`로 zoxide 사용)
- **Node 스택**: `nvm`(brew 설치) → Node **LTS 자동 설치** → `npm`(Node 포함) → `yarn`(corepack 또는 npm) → `ts-node`(npm -g)

### 2. CLI 툴 & GUI 앱 (Homebrew)
- `git`, `android-platform-tools`(adb/fastboot), `scrcpy`, `ffmpeg`
- `jq`, `ripgrep`, `fd`, `fzf`(키바인딩 자동설치), `wget`, `curl`, `tree`
- `gh`(GitHub CLI), `openssl`, `python@3.12`, `gnu-sed`, `coreutils`, `watch`
- `iTerm2`, `Visual Studio Code`, `Rectangle`(cask 실패시 릴리스 DMG로 자동 폴백)
- **QtScrcpy**: Homebrew cask가 없으므로 **아키텍처 자동 감지** 후 릴리스 DMG를 직접 다운로드하여 설치

### 3. App Store Apps
- `app_store_app_list.txt` 파일에 정의된 앱스토어 앱들을 `mas`를 통해 자동 설치합니다.

### 4. Web Apps
- `web_app_list.txt` 파일에 정의된 웹앱(URL)들을 `~/Applications/WebApps` 경로에 바로가기 앱(`.app`) 형태로 생성해 드립니다.

---

## .zshrc 기본값
- 테마: `robbyrussell`
- 플러그인: `git zsh-autosuggestions zsh-syntax-highlighting` (+ autojump가 설치되어 있으면 자동 추가)
- **Jump 우선순위**: `zoxide`가 있으면 `j` 명령으로 zoxide, 없으면 autojump 로드
- **nvm 초기화** 포함 (brew 경로 기반)
- 자주 쓰는 alias:
  ```zsh
  alias gs='git status'
  alias ga='git add'
  alias gcm='git commit -m'
  alias z='code ~/.zshrc'
  alias s='source ~/.zshrc'
  ```

---

## 리포 구조 (파일 커스터마이징)
```
.
├─ install.sh                  # 메인 설치 스크립트 (선택형 프롬프트 포함)
├─ zsh/
│  ├─ .zshrc                   # 고정 zshrc (main)
│  ├─ .zsh_env                 # 환경변수 및 PATH 설정
│  ├─ .zsh_aliases             # 단축 명령어 (alias) 선언
│  ├─ .zsh_functions           # zsh 함수 선언
│  └─ .zsh_projects            # 유저 개인 프로젝트 커스텀 설정
├─ plugins.txt                 # oh-my-zsh 외부 플러그인 목록
├─ app_store_app_list.txt      # 앱스토어용 앱 ID 목록 파일
└─ web_app_list.txt            # 웹앱 목록 파일
```

- `plugins.txt`에는 **외부(git) 플러그인만** 나열합니다.
- **앱스토어 앱 커스텀 (`app_store_app_list.txt`)**
  - 형식: `"앱이름"|"앱ID"` (예: `"KakaoTalk"|"869223134"`)
- **웹앱 커스텀 (`web_app_list.txt`)**
  - 형식: `"실행할브라우저"|"웹앱이름"|"URL"` (예: `"chrome"|"ChatGPT"|"https://chatgpt.com/"`)

---

## 트러블슈팅
- **`brew: command not found`**
  - 스크립트가 자동 설치/경로 등록하지만, 새 셸이 필요할 수 있습니다. 터미널을 재실행하거나 `exec zsh`.
- **VS Code 실행 후 터미널 창이 남음 (`[프로세스 완료됨]`)**
  - Terminal.app: 설정 → 프로필 → 셸 → “셸이 종료되면: 창 닫기”
  - iTerm2: Preferences → Profiles → General → “When command exits: Close”

---

## 보안/주의사항
- 보안상, 원하면 이 리포를 포크하여 **본인 계정의 raw URL**로 설치하세요.
- 스크립트는 macOS 전용입니다(Xcode CLT 설치 포함).

---

## 라이선스
MIT

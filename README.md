# ohmyzsh-bootstrap

맥 초기화 직후 **한 줄**로 oh-my-zsh + 테마/플러그인 + 기본 개발툴(adb/scrcpy/git 등) + Node 스택(nvm/yarn/ts-node) + 필수 GUI 앱까지 자동 세팅합니다.

---

## 🚀 One‑liner (curl)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/SuperLeeK/ohmyzsh/main/install.sh)"
```

### 옵션 실행 예시
- cask(GUI 앱) 설치 없이 최소 설치:
```bash
WITH_CASKS=0 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/SuperLeeK/ohmyzsh/main/install.sh)"
```
- 점프 도구를 `zoxide`로 지정:
```bash
JUMP_IMPL=zoxide /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/SuperLeeK/ohmyzsh/main/install.sh)"
```
- QtScrcpy 특정 버전/URL로 강제(기본은 아키텍처 자동선택):
```bash
QTSCRCPY_URL="https://github.com/barry-ran/QtScrcpy/releases/download/v3.3.1/QtScrcpy-mac-arm64-Qt6.5.3-v3.3.1.dmg" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/SuperLeeK/ohmyzsh/main/install.sh)"
```
- Rectangle cask 실패 시 폴백 URL 지정:
```bash
RECTANGLE_URL="https://github.com/rxhanson/Rectangle/releases/download/v0.90/Rectangle0.90.dmg" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/SuperLeeK/ohmyzsh/main/install.sh)"
```

---

## 무엇이 설치되나요?

### Shell/테마/플러그인
- **oh-my-zsh** (테마: `robbyrussell`)
- 플러그인: `zsh-autosuggestions`, `zsh-syntax-highlighting`
- 점프 도구: 기본 `autojump` (원하면 `JUMP_IMPL=zoxide`로 zoxide 사용)

### CLI 툴 (Homebrew formulae)
- `git`, `android-platform-tools`(adb/fastboot), `scrcpy`, `ffmpeg`
- `jq`, `ripgrep`, `fd`, `fzf`(키바인딩 자동설치), `wget`, `curl`, `tree`
- `gh`(GitHub CLI), `openssl`, `python@3.12`
- `gnu-sed`, `coreutils`, `watch`
- **Node 스택**: `nvm`(brew 설치) → Node **LTS 자동 설치** → `npm`(Node 포함) → `yarn`(corepack 또는 npm) → `ts-node`(npm -g)

### GUI 앱 (Homebrew casks + URL 폴백)
- `iTerm2`, `Visual Studio Code`, `Rectangle`(cask 실패시 릴리스 DMG로 자동 폴백)
- **QtScrcpy**: Homebrew cask가 없으므로 **아키텍처 자동 감지** 후 릴리스 DMG를 직접 다운로드하여 설치
  - arm64: `QtScrcpy-mac-arm64-Qt6.5.3-v3.3.1.dmg`
  - x64: `QtScrcpy-mac-x64-Qt5.15.2-v3.3.1.dmg`

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

## 리포 구조
```
.
├─ install.sh          # 메인 설치 스크립트 (idempotent)
├─ zsh/
│  └─ .zshrc           # 고정 zshrc
└─ plugins.txt         # oh-my-zsh 외부 플러그인 목록
```

- `plugins.txt`에는 **외부(git) 플러그인만** 나열합니다.
  ```
  https://github.com/zsh-users/zsh-autosuggestions.git
  https://github.com/zsh-users/zsh-syntax-highlighting.git
  ```

---

## 사용 방법

### 최초 설치
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/SuperLeeK/ohmyzsh/main/install.sh)"
exec zsh   # 새 프롬프트 적용
```

### 재실행(업데이트/추가 설치)
- 스크립트는 여러 번 실행해도 안전합니다(idempotent).
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/SuperLeeK/ohmyzsh/main/install.sh)"
```

---

## 커스터마이징
- 더 설치하고 싶은 **CLI**는 `install.sh`의 `BREW_FORMULAE=( ... )` 배열에 추가
- 더 설치하고 싶은 **GUI 앱**은 `BREW_CASKS=( ... )` 배열에 추가
- 테마를 바꾸려면 `zsh/.zshrc`의 `ZSH_THEME` 수정
- 외부 플러그인은 `plugins.txt`에 git URL을 추가하면 자동 설치/업데이트

---

## 트러블슈팅
- **`brew: command not found`**
  - 스크립트가 자동 설치/경로 등록하지만, 새 셸이 필요할 수 있습니다. 터미널을 재실행하거나 `exec zsh`.
- **`[oh-my-zsh] autojump not found`**
  - 스크립트가 `autojump`를 설치합니다. 그래도 뜬다면:
    ```zsh
    brew install autojump
    exec zsh
    ```
  - 또는 `zoxide`로 전환해 사용:
    ```bash
    JUMP_IMPL=zoxide /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/SuperLeeK/ohmyzsh/main/install.sh)"
    ```
- **VS Code 실행 후 터미널 창이 남음 (`[프로세스 완료됨]`)**
  - Terminal.app: 설정 → 프로필 → 셸 → “셸이 종료되면: 창 닫기”
  - iTerm2: Preferences → Profiles → General → “When command exits: Close”
- **권한 문제**
  - `install.sh` 직접 실행 시:
    ```bash
    chmod +x install.sh && ./install.sh
    ```

---

## 보안/주의사항
- 보안상, 원하면 이 리포를 포크하여 **본인 계정의 raw URL**로 설치하세요.
- 스크립트는 macOS 전용입니다(Xcode CLT 설치 포함).

---

## 라이선스
MIT

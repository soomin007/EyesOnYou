# 배포 자동화 — GitHub Pages

`git push origin main` 하면 자동으로 빌드되어 `https://<user>.github.io/EyesOnYou/`에 올라가는 환경.

---

## 1회 셋업 (한 번만)

### 1. Godot에서 Web 프리셋 만들기

1. Godot 4.6에서 프로젝트 열기
2. 메뉴 → **Project → Export...**
3. **Add...** → **Web** 선택
4. 우측 옵션 패널에서 **Variant → Thread Support** 체크 **해제** (중요!)
   - 이유: GitHub Pages는 SharedArrayBuffer 헤더 못 보내서, Threads 켠 export는 작동 안 함.
   - 단일 스레드 export는 성능 살짝 떨어지지만 이 게임 규모에선 체감 없음.
5. **Export Path**: `build/index.html` (또는 비워둬도 됨 — 워크플로가 지정)
6. 좌하단 **Save Presets** 또는 그냥 창 닫으면 자동 저장됨
7. 결과: 프로젝트 루트에 `export_presets.cfg` 파일 생성됨

### 2. cfg 파일 커밋

```bash
git add export_presets.cfg
git commit -m "chore: Web export preset 추가 (GitHub Pages 자동 배포용)"
```

### 3. GitHub repo Pages 활성화

1. GitHub에서 EyesOnYou repo 열기
2. **Settings → Pages**
3. **Source**: `Deploy from a branch`
4. **Branch**: `gh-pages` / `(root)` 선택 → **Save**
   - (gh-pages 브랜치는 첫 워크플로 실행 후 자동 생성됨. 안 보이면 워크플로 한 번 돌고 다시 와서 선택)

### 4. 첫 배포

```bash
git push origin main
```

- GitHub Actions 탭에서 워크플로 진행 상황 확인 가능
- 처음엔 Godot 바이너리(~80MB) + export template(~600MB) 다운로드라 5~7분 걸림
- 두 번째부터는 캐시 사용해 1~2분

---

## 동작 흐름

```
git push origin main
    ↓
.github/workflows/deploy.yml 실행
    ↓
Ubuntu runner에서:
  1. Godot 4.6 바이너리 + export template 다운로드(첫 회) / 캐시 사용
  2. export_presets.cfg의 "Web" 프리셋으로 빌드
  3. build/ 디렉토리에 index.html, .wasm, .pck 등 생성
  4. peaceiris/actions-gh-pages@v4가 build/를 gh-pages 브랜치로 푸시
    ↓
GitHub Pages가 gh-pages 브랜치를 https://<user>.github.io/EyesOnYou/ 에 서빙
```

---

## 트러블슈팅

### "export_presets.cfg가 없어요" 에러
→ 셋업 1단계를 안 했음. Godot 에디터에서 Web 프리셋 만들고 cfg 커밋.

### "Web 프리셋이 없어요" 에러
→ cfg는 있는데 프리셋 이름이 다름. Godot에서 프리셋 이름을 정확히 `Web`으로 변경하거나, 워크플로의 `EXPORT_PRESET` env 변수를 실제 이름으로 수정.

### 빌드는 되는데 게임이 검은 화면
→ Threads Support 끄지 않았을 가능성. Godot 에디터에서 다시 확인하고 cfg 커밋.

### "Export templates not found"
→ Godot 버전과 export template 버전 불일치. 워크플로의 `GODOT_VERSION` env가 실제 사용 중인 버전과 같은지 확인.

### gh-pages 브랜치가 안 만들어짐
→ 워크플로 권한 문제. repo Settings → Actions → General → Workflow permissions에서 "Read and write permissions" 선택.

### itch.io에 올릴 때
→ 별개로 manual export. Godot에서 export → zip → itch에 업로드.
   itch는 "SharedArrayBuffer" 옵션 켜서 Threads ON 빌드 가능 → 성능 ↑.
   GitHub Pages용(Threads OFF)과 itch용(Threads ON) 두 프리셋 만들어 두면 편함.

---

## 같은 패턴을 enigma에도 적용하려면

1. enigma repo에 동일한 `.github/workflows/deploy.yml` 복사
2. enigma 프로젝트에서 Web 프리셋 똑같이 만들기 (Threads off)
3. cfg 커밋, push → 자동 배포

워크플로 yaml은 게임 이름 의존성 없어서 그대로 복붙 가능.

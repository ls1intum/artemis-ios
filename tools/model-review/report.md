# Offline read-only model canvas report

Status: complete under `/tmp/artemis-feedback-plan/model-viewer`; no app/main/Apollon repository was modified, no commit or PR created.

## Deliverable

Copy the complete `dist/` folder into each native app's resources, preserving paths and licenses. Core files are `index.html`, `artemis-model-review-1.0.0.js`, and `artemis-model-review-1.0.0.css`. Reproducible source archive: `/tmp/artemis-feedback-plan/model-viewer/artemis-model-review-1.0.0-source.tar.gz`. Runtime archive: `/tmp/artemis-feedback-plan/model-viewer/artemis-model-review-1.0.0-runtime.tar.gz`. Source/lock/build/test/license instructions are in `README.md`, `src/`, `build.mjs`, `package.json`, and `package-lock.json`. No runtime dependency directory is shipped.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `LICENSE` | 1,089 | `b6a81f9556563f4fa0b272c03b8e59eab34bfa0366696ff7f94d26522af382bd` |
| `THIRD-PARTY-NOTICES.txt` | 1,214 | `2b15811510bab20525d8e8be3062f4bdc9b5064bd1b75975efa911026b8a7102` |
| `artemis-model-review-1.0.0.css` | 564,395 | `2cc0cd9d92a1889a87a74865dac837dcc4c15d5e6ce21d6d42cf48722616239b` |
| `artemis-model-review-1.0.0.js` | 1,658,232 | `3372e8626604db06b12aea1794f9a422441d769f49d64978e935f2baa2d4c644` |
| `artemis-model-review-1.0.0.js.LEGAL.txt` | 4,390 | `a068db62c76f86d311558e79186e874da4dae64b9e96f7b13368b00bb4084ca7` |
| `index.html` | 755 | `cb3ec537ea6d97ce551fd1cb1a69258652bad7c7b9763b548f8a83e40d7f09b7` |

The runtime JS/CSS/HTML together total 2,223,382 bytes. Fonts are inside CSS. Full license inventory is in `dist/THIRD-PARTY-NOTICES.txt`, with copied texts in `dist/licenses/`.

## Contract

`window.ArtemisModelReview.isReady` becomes true after synchronous bundle initialization. `renderBase64(base64UTF8JSON)` accepts the requested model/diagramType/feedback/selectedReference/darkMode envelope unchanged and returns `{ok:true}` or `{ok:false,error:string}`. Optional `ready()` and `renderError(message)` Android callbacks, and `modelReady`/`modelError` iOS message handlers are available; original `selectElement(reference)` Android and `modelSelection.postMessage({reference})` iOS callbacks remain as specified.

The first original feedback reference matching an element/member/relationship is retained in selection callbacks; otherwise callbacks use raw element IDs. No callback payload deviations. Identifiers survive official Apollon normalization/migration. Input Unicode is decoded with fatal UTF-8 validation, so malformed encoding cannot silently corrupt identifiers.

## Fresh verification

`npm run build` succeeded. An extracted source archive with a fresh npm dependency installation also built the identical manifest. Two consecutive builds produced byte-identical `dist/manifest.json` (verified with `cmp`). `npm test` passed **6 unit tests and 48 browser cases**: 24 cases each on Chromium and WebKit, using the actual local `file:` bundle. Logs are `proof/build.txt`, `proof/full-tests.txt`, and `proof/browser-results.json`. TDD red evidence is retained in `proof/tdd-red.txt`, `proof/browser-red.txt`, `proof/theme-red.txt`, `proof/handles-red.txt`, and `proof/compatibility-red.txt`; these are expected historical failures before implementation/fixes. The complete final run is green.

Verified diagram type families: ClassDiagram, ObjectDiagram, ActivityDiagram, UseCaseDiagram, CommunicationDiagram, ComponentDiagram, DeploymentDiagram, PetriNet, ReachabilityGraph, SyntaxTree, Flowchart, BPMN, Sfc. Every node and edge in each supported representative fixture is present in the rendered DOM. Legacy 2.0.0 and 3.0.0 class fixtures also render and retain member/relationship references.

Behavior checks cover UTF-8 text including emoji and Chinese; Android and iOS callbacks; element/member/relationship selection; host-selected feedback reference; malformed Base64/UTF-8/JSON/payload/model; empty model; missing/cyclic containment; error replacement and recovery; same-model updates without remounting; dark-mode updates; model node content and positions unchanged by editing keys, drag, double-click, paste and drop; invisible/inert authoring handles; working pan and zoom; no runtime HTTP(S) resource requests during loading/rendering; CSP-blocked outbound fetch; blocked arbitrary link navigation.

Proof screenshots for all 13 types are `proof/chromium-*.png` and `proof/webkit-*.png`; selected dark and error states are included. Root owns native UX captures. Representative proof images were visually inspected. `proof/offline-audit.json` records zero external JS imports, four embedded font URLs, and no Worker constructor. No dynamic export/WASM/PDF module is bundled. No tokens, authentication, remote URL or server calls exist in the resource contract.

## Read-only implementation

Official `@tumaet/apollon` version 5.3.1 is pinned exactly and resolved from npm, rather than built from the local reference checkout (whose package metadata was 5.3.0). It is configured with readonly, no controls, no keyboard shortcuts, no popups, no tagging, no collaboration. Public `setElementHighlights` and `revealAssessment` handle view-only highlighting/selection. The wrapper never calls model editing or assessment writing APIs and never sends a modified model to native code.

Input documents are independently decoded and may undergo Apollon's official format/geometry normalization in memory. The original caller's source object is not shared with JavaScript, and feedback/selection are not injected into the model. CSS hides connection handles without removing the geometry needed by routing. CSP rejects network/worker/frame navigation capabilities; capture-phase guards reject editing and data transfer gestures. The bundle uses Apollon's synchronous edge-routing fallback so no file/module workers need to execute in native WebViews.

## Compatibility limits

The untouched upstream deployment fixture includes a non-cardinal interface target handle `right-top`. Apollon 5.3.1 omits that one relationship from its rendered DOM (7/8). The original is retained as `fixtures/deployment-diagram-upstream.json`; the supported representative deployment fixture changes only that target handle to `right`, keeps all IDs, and renders 8/8. The wrapper explicitly rejects non-cardinal component/deployment interface handles before creating the editor. The untouched original fixture now produces `{ok:false,error:string}`, a visible unavailable state, and the existing native error callback; browser regression cases verify zero rendered nodes/edges rather than a partial canvas on both engines. The message states: “This model uses an unsupported connection handle and cannot be displayed completely.” Missing endpoint IDs also fail validation. No production ID or handle rewriting was introduced. This guard is scoped to component/deployment interfaces; other diagram-specific handle combinations continue to follow upstream behavior.

Input limits: 12 MiB encoded Base64, 2,000 nodes, 5,000 relationships. Near-limit synchronous routing performance has not been measured on physical devices. Browser compatibility proof includes Chromium/WebKit desktop engines; actual Android/iOS WebView and accessibility UX verification belongs to the native integration tasks.

## Source provenance and reproducibility

Node 24.22.1, npm 11.19.1, esbuild 0.28.2, Playwright 1.64.1. Official tarball integrity is retained in package-lock.json and README.md. `npm ci && npm run build`; install Playwright Chromium/WebKit once and run `npm test`. Build-time dependency downloads are separate from the fully offline runtime. Native redistributions must retain the notices/legal/license files. The versioned resource and source archives exclude `node_modules`.

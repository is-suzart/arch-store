# Changes Implemented — Arch Store

Baseado no [`planejamento.md`](planejamento.md), todas as 5 seções foram implementadas.

---

## 1. Handlers de Arquivos Locais (.pkg, .flatpakref)

### `packaging/arch/arch-store.desktop`
- Adicionado `application/vnd.archlinux.package` ao `MimeType` para registrar o app como handler de pacotes Arch Linux.

### `src-rust/src/main.rs`
- Processa argumentos CLI (`std::env::args()`) e armazena o caminho do arquivo em `ARCH_STORE_FILE_ARG` para uso posterior pelo backend.

### `src-rust/src/presentation/backend.rs`
- Novo método `installLocalFile(path)` — detecta extensão e executa:
  - `.pkg.tar.zst` / `.pkg.tar.xz` → `pkexec pacman -U --noconfirm`
  - `.flatpakref` → `flatpak install --user -y`
- Novo método `getFileArg()` — retorna o caminho do arquivo passado via CLI para o QML.
- Novas signals/invokables expostas ao QML.

### `presentation/main.qml`
- `Component.onCompleted` agora verifica `backend.getFileArg()` e, se houver, abre automaticamente o modal de terminal e inicia a instalação.

---

## 2. Notificações no Sistema

### `src-rust/Cargo.toml`
- Adicionada dependência `notify-rust = "4"` (notificações nativas via D-Bus).

### `src-rust/src/presentation/backend.rs`
- Função `send_notification(title, body)` que dispara notificações nativas do desktop.
- Chamada no final de `stream_command()` — notifica sucesso ou falha ao término de instalação/desinstalação/atualização.
- Signal `nativeNotification` exposta ao QML para uso futuro.

---

## 3. Configurações: Ocultar AUR e Flatpak

### `src-rust/src/domain/usecases/install_package.rs`
- `execute()` agora aceita `&AppConfig` e bloqueia instalação de AUR/Flatpak se `enable_aur`/`enable_flatpak` for `false`.

### `src-rust/src/domain/usecases/uninstall_package.rs`
- Mesma lógica de bloqueio por configuração.

### `src-rust/src/presentation/backend.rs`
- `installPackage()` e `uninstallPackage()` agora passam `config` para os use cases.

### `presentation/view/UpdatesView.qml`
- Tabs de categorias (Pacman/AUR/Flatpak) agora são dinâmicos — construídos com base em `backend.getConfigBool()`.
- Abas de fontes desabilitadas não aparecem.

### `presentation/view/SettingsView.qml`
- Indicadores visuais de disponibilidade dos binários:
  - "✓ yay/paru detectado" ou "✗ Nenhum helper AUR encontrado"
  - "✓ Flatpak detectado" ou "✗ Flatpak não encontrado"
- Toggle desabilitado se o binário não existir no sistema.
- Auto-desativação na inicialização se binário ausente.

---

## 4. Correção das Traduções (QTranslator)

### `src-rust/src/presentation/localization.h`
- Header C++ declarando `setup_qt_translator()`.

### `src-rust/src/presentation/localization.cpp`
- Implementação que:
  1. Detecta o locale do sistema via `QLocale::system()`.
  2. Busca o arquivo `.qm` correspondente no diretório `locale/`.
  3. Instancia `QTranslator` e chama `QCoreApplication::installTranslator()`.

### `src-rust/build.rs`
- Adicionado `localization.cpp` ao `CxxQtBuilder`.

### `src-rust/src/main.rs`
- Chama `setup_qt_translator()` logo após inicializar `QGuiApplication`, passando o diretório `locale/` resolvido.
- Nova função `resolve_locale_path()` com fallback para diretórios relativos e absolutos.

---

## 5. Adaptação para Sistemas Recém-Instalados

### `src-rust/src/presentation/backend.rs`
- `BackendRust::default()` agora verifica na inicialização:
  - `which flatpak` → `flatpak_binary_found`
  - `which yay` / `which paru` → `aur_helper_found`
- Novos métodos `isFlatpakInstalled()` e `isAurHelperInstalled()` expostos ao QML.

### `presentation/view/SettingsView.qml`
- Exibe status de disponibilidade (seção 3 acima).
- Toggles desabilitados e config forçada para `false` se binário não existir.

---

## Arquivos Modificados/Criados

| Arquivo | Tipo |
|---|---|
| `src-rust/Cargo.toml` | Modificado |
| `src-rust/build.rs` | Modificado |
| `src-rust/src/main.rs` | Modificado |
| `src-rust/src/presentation/backend.rs` | Modificado |
| `src-rust/src/domain/usecases/install_package.rs` | Modificado |
| `src-rust/src/domain/usecases/uninstall_package.rs` | Modificado |
| `src-rust/src/presentation/localization.h` | **Criado** |
| `src-rust/src/presentation/localization.cpp` | **Criado** |
| `packaging/arch/arch-store.desktop` | Modificado |
| `presentation/main.qml` | Modificado |
| `presentation/view/UpdatesView.qml` | Modificado |
| `presentation/view/SettingsView.qml` | Modificado |

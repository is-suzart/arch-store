mod config;
mod data;
mod domain;
mod presentation;

use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QString, QUrl};
use std::ffi::CString;

extern "C" {
    fn register_system_icon_provider(engine_ptr: *mut std::ffi::c_void);
    fn setup_qt_translator(app_ptr: *mut std::ffi::c_void, locale_dir: *const std::ffi::c_char);
}

fn main() {
    std::env::set_var("QML_XHR_ALLOW_FILE_READ", "1");
    cxx_qt::init_qml_module!("ArchStore");

    // Configura o ambiente de logging (env RUST_LOG=arch_store=info)
    if std::env::var("RUST_LOG").is_ok() {
        eprintln!("[arch-store] starting backend...");
    }

    // Processa argumentos de linha de comando
    let args: Vec<String> = std::env::args().collect();
    let file_arg = args.iter().skip(1).find(|a| !a.starts_with('-'));
    if let Some(path) = file_arg {
        // Se um caminho de arquivo foi passado, armazena para o backend usar depois
        std::env::set_var("ARCH_STORE_FILE_ARG", path);
    }

    // Qt application
    let mut app = QGuiApplication::new();
    if let Some(mut app_pinned) = app.as_mut() {
        app_pinned.as_mut().set_application_name(&QString::from("Arch Store"));
        app_pinned.as_mut().set_application_version(&QString::from(env!("CARGO_PKG_VERSION")));
        app_pinned.as_mut().set_organization_name(&QString::from("arch-store"));

        // Configura o tradutor Qt baseado no locale do sistema
        let locale_dir = resolve_locale_path();
        let c_locale_dir = CString::new(locale_dir).unwrap_or_default();
        let raw_app = unsafe {
            app_pinned.as_mut().get_unchecked_mut() as *mut QGuiApplication as *mut std::ffi::c_void
        };
        unsafe {
            setup_qt_translator(raw_app, c_locale_dir.as_ptr());
        }
    }

    // QML engine
    let mut engine = QQmlApplicationEngine::new();

    // Registra o image provider para ícones do sistema
    if let Some(mut engine_pinned) = engine.as_mut() {
        let raw_engine = unsafe {
            engine_pinned.as_mut().get_unchecked_mut() as *mut QQmlApplicationEngine as *mut std::ffi::c_void
        };
        unsafe {
            register_system_icon_provider(raw_engine);
        }
    }

    // Encontra o arquivo QML relativo ao executável ou ao diretório de trabalho
    let qml_path = resolve_qml_path();
    let qml_modules_path = resolve_qml_modules_path();
    if let Some(mut engine_pinned) = engine.as_mut() {
        engine_pinned.as_mut().add_import_path(&QString::from(qml_modules_path.as_str()));
        engine_pinned.as_mut().load(&QUrl::from(qml_path.as_str()));
    }

    let code = if let Some(mut app_pinned) = app.as_mut() {
        app_pinned.as_mut().exec()
    } else {
        1
    };

    std::process::exit(code);
}

/// Localiza o main.qml buscando em locais comuns.
fn resolve_qml_path() -> String {
    let candidates = [
        // Desenvolvimento: executando de src-rust/
        "../presentation/main.qml",
        // Instalado: ao lado do executável em /usr/share/arch-store/
        "presentation/main.qml",
        // Instalado globalmente:
        "/usr/share/arch-store/presentation/main.qml",
    ];

    // Verificar variável de ambiente
    if let Ok(path) = std::env::var("ARCH_STORE_QML") {
        return path;
    }

    // Verificar candidatos relativos ao executável
    if let Ok(exe) = std::env::current_exe() {
        if let Some(exe_dir) = exe.parent() {
            for c in &candidates {
                let full = exe_dir.join(c);
                if full.exists() {
                    return full.to_string_lossy().to_string();
                }
            }
        }
    }

    // Verificar candidatos relativos ao diretório corrente
    for c in &candidates {
        if std::path::Path::new(c).exists() {
            return c.to_string();
        }
    }

    // Fallback
    "presentation/main.qml".to_string()
}

/// Localiza o diretório qml_modules buscando em locais comuns.
fn resolve_qml_modules_path() -> String {
    let candidates = [
        "../qml_modules",
        "qml_modules",
        "/usr/share/arch-store/qml_modules",
    ];

    if let Ok(path) = std::env::var("ARCH_STORE_QML_MODULES") {
        return path;
    }

    if let Ok(exe) = std::env::current_exe() {
        if let Some(exe_dir) = exe.parent() {
            for c in &candidates {
                let full = exe_dir.join(c);
                if full.exists() {
                    return full.to_string_lossy().to_string();
                }
            }
        }
    }

    for c in &candidates {
        if std::path::Path::new(c).exists() {
            return c.to_string();
        }
    }

    "qml_modules".to_string()
}

/// Localiza o diretório de traduções (locale) buscando em locais comuns.
fn resolve_locale_path() -> String {
    let candidates = [
        "../locale",
        "locale",
        "/usr/share/arch-store/locale",
    ];

    if let Ok(exe) = std::env::current_exe() {
        if let Some(exe_dir) = exe.parent() {
            for c in &candidates {
                let full = exe_dir.join(c);
                if full.exists() {
                    return full.to_string_lossy().to_string();
                }
            }
        }
    }

    for c in &candidates {
        if std::path::Path::new(c).exists() {
            return c.to_string();
        }
    }

    "locale".to_string()
}

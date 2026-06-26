// build.rs — cxx-qt code generation
use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    CxxQtBuilder::new_qml_module(QmlModule::new("ArchStore").version(1, 0))
        .file("src/presentation/backend.rs")
        .cpp_file("src/presentation/system_icon_provider.cpp")
        .build();
}

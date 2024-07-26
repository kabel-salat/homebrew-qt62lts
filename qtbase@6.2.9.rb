class QtbaseAT629 < Formula
  desc "Qt 6.2.9 LTS Base Framework"
  homepage "https://www.qt.io/"
  url "https://github.com/qt/qtbase/archive/refs/tags/v6.2.9-lts-lgpl.tar.gz"
  sha256 "ba6633234bca294d6be4a8eb3fb80a4e44b436498ce2e3624dde81291678bc53"
  license all_of: [
    "BSD-3-Clause",
    "GFDL-1.3-no-invariants-only",
    "GPL-2.0-only",
    { "GPL-3.0-only" => { with: "Qt-GPL-exception-1.0" } },
    "LGPL-3.0-only",
  ]

  depends_on "cmake@3.22" => [:build, :test]
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "python@3.9" => :build
  depends_on "vulkan-headers" => [:build, :test]
  depends_on "vulkan-loader" => [:build, :test]
  depends_on "molten-vk" => [:build, :test]
  depends_on xcode: :build

  # Huge thank you to this guy
  # https://github.com/petere/homebrew-postgresql
  # Dude is probably the coolest guy ever
  # I Would totally buy him a beer
  # I mean that's why they call it homebrew haha
  # haha ha 
  depends_on "postgresql@9.6"
  depends_on "openssl@1.1"
  depends_on "libb2"
  depends_on "md4c"
  depends_on "dbus"
  depends_on "brotli"
  depends_on "double-conversion"
  depends_on "freetype"
  depends_on "harfbuzz"
  depends_on "sqlite"
  depends_on "mysql@5.7"
  depends_on "icu4c"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "pcre2"
  depends_on "zstd"
  depends_on "glib"

  uses_from_macos "cups"
  uses_from_macos "krb5"
  uses_from_macos "libxslt"
  uses_from_macos "zlib"

  fails_with gcc: "5"

  patch do
    url "https://almostd.one/musescore4/qt62lts/patches/qt6/qtbase/fix_molten_vk_header_path.patch"
    sha256 "580858d427ccef557dc01a3ad2e9da20e2ef18530f323f3d1c78ae7381adf344"
    directory "."
  end

  patch do
    url "https://almostd.one/musescore4/qt62lts/patches/qt6/qtbase/fix_zstd_cmake_handling.patch"
    sha256 "b5650d5b0226e5cc00de3c0d29f10069527e722f4e141765f7fbeb69de2cc40d"
    directory "."
  end

  patch do
    url "https://almostd.one/musescore4/qt62lts/patches/qt6/qtbase/modify_pkgconfig_to_allow_unofficial_brew.patch"
    sha256 "d4c47d56962d18a7c9c4df552c7cb315d2ead72395fc07a76e0195c11aaaed8b"
    directory "."
  end

  patch do
    url "https://almostd.one/musescore4/qt62lts/patches/qt6/qtbase/prevent_cmake_symlink_empty_failure.patch"
    sha256 "7673797fb2665a97776766f2bab1947cfe2f06327b638f14aebceb08afc082e7"
    directory "."
  end

  def install
    # Allow -march options to be passed through, as Qt builds
    # arch-specific code with runtime detection of capabilities:
    # https://bugreports.qt.io/browse/QTBUG-113391
    ENV.runtime_cpu_detection

    config_args = %W[
      -system-freetype \
      -system-harfbuzz \
      -system-sqlite \
      -system-libb2 \
      -system-zlib \
      -prefix #{HOMEBREW_PREFIX} \
      -extprefix Qt6
      -archdatadir share/qt \
      -datadir share/qt \
      -hostdatadir share/qt/mkspecs \
      -nomake examples \
      -release \
      -headersclean \
      -framework 
    ]

    # We prefer CMake `-DQT_FEATURE_system*=ON` arg over configure `-system-*` arg
    # since the latter may be ignored when auto-detection fails.
    #
    # We disable clang feature to avoid linkage to `llvm`. This is how we have always
    # built on macOS and it prevents complicating `llvm` version bumps on Linux.
    cmake_args = std_cmake_args(install_prefix: HOMEBREW_PREFIX, find_framework: "FIRST") + %w[
      -DFEATURE_pkg_config=ON \
      -DQT_FEATURE_relocatable=OFF \
      -DCMAKE_OSX_DEPLOYMENT_TARGET=10.14 \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DODBC_ROOT=/usr/local/opt/libiodbc \
      -DPostgreSQL_ROOT=/usr/local/opt/postgresql@9.6 \
      -DSQLite3_ROOT=/usr/local/opt/sqlite \
      -DMySQL_ROOT=/usr/local/opt/mysql@5.7 \
      -DOPENSSL_ROOT_DIR=/usr/local/opt/openssl@1.1 \
      -Dmd4c_DIR=/usr/local/opt/md4c \
      -DQT_FEATURE_system_harfbuzz=ON 
    ]

    system "./configure", *config_args, "--", *cmake_args
    system "cmake", "--build", "."
    system "cmake", "--install", "."

    # inreplace lib/"cmake/Qt6/qt.toolchain.cmake", "#{Superenv.shims_path}/", ""

    return unless OS.mac?

    # The pkg-config files installed suggest that headers can be found in the
    # `include` directory. Make this so by creating symlinks from `include` to
    # the Frameworks' Headers folders.
    # Tracking issues:
    # https://bugreports.qt.io/browse/QTBUG-86080
    # https://gitlab.kitware.com/cmake/cmake/-/merge_requests/6363
    lib.glob("*.framework") do |f|
      # Some config scripts will only find Qt in a "Frameworks" folder
      frameworks.install_symlink f
      include.install_symlink f/"Headers" => f.stem
    end

    bin.glob("*.app") do |app|
      libexec.install app
      bin.write_exec_script libexec/app.basename/"Contents/MacOS"/app.stem
    end

    # Modify unofficial pkg-config files to fix up paths and use frameworks.
    # Also move them to `libexec` as they are not guaranteed to work for users,
    # i.e. there is no upstream or Homebrew support.
    lib.glob("pkgconfig/*.pc") do |pc|
      inreplace pc do |s|
        s.gsub! " -L${libdir}", " -F${libdir}", false
        s.gsub! " -lQt6", " -framework Qt", false
        s.gsub! " -Ilib/", " -I${libdir}/", false
      end
      (libexec/"lib/pkgconfig").install pc
    end
  end

  def caveats
    <<~EOS
      You can add Homebrew's Qt to QtCreator's "Qt Versions" in:
        Preferences > Qt Versions > Link with Qt...
      pressing "Choose..." and selecting as the Qt installation path:
        #{HOMEBREW_PREFIX}
    EOS
  end

  test do
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION #{Formula["cmake"].version})

      project(test VERSION 1.0.0 LANGUAGES CXX)

      set(CMAKE_CXX_STANDARD 17)
      set(CMAKE_CXX_STANDARD_REQUIRED ON)

      set(CMAKE_AUTOMOC ON)
      set(CMAKE_AUTORCC ON)
      set(CMAKE_AUTOUIC ON)

      find_package(Qt6 COMPONENTS Core Gui Widgets Sql Concurrent REQUIRED)

      add_executable(test
        main.cpp
      )

      target_link_libraries(test PRIVATE Qt6::Core Qt6::Widgets
        Qt6::Sql Qt6::Concurrent Qt6::Gui
      )
    EOS

    (testpath/"main.cpp").write <<~EOS
      #undef QT_NO_DEBUG
      #include <QCoreApplication>
      #include <QSqlDatabase>
      #include <QImageReader>
      #include <QDebug>

      int main(int argc, char *argv[])
      {
        QCoreApplication app(argc, argv);
        Q_ASSERT(QSqlDatabase::isDriverAvailable("QSQLITE"));
        const auto &list = QImageReader::supportedImageFormats();
        for(const char* fmt:{"jpeg", "png", "gif"
          }) {
          Q_ASSERT(list.contains(fmt));
        }
        return 0;
      }
    EOS

    system "cmake", testpath
    system "make"
    system "./test"

    ENV.delete "CPATH" if MacOS.version > :mojave
    system bin/"qmake", testpath/"test.pro"
    system "make"
    system "./test"
  end
end

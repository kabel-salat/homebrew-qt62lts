class Qtquick3dAT629 < Formula
  desc "Qt 6.2.9 LTS Quick 3D Module"
  homepage "https://www.qt.io/"
  url "https://github.com/qt/qtquick3d/archive/refs/tags/v6.2.9-lts-lgpl.tar.gz"
  sha256 "8532536965d3081513aba022bf34e11e3afa761666360d3e04fa2af432a82229"
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
  depends_on "qt@6.2.9"

  def install
    qt_prefix = Formula["qt@6.2.9"].opt_prefix

    mkdir "build" do
      system "qt-configure-module", "..", "--", "-DCMAKE_INSTALL_PREFIX=#{qt_prefix}", *std_cmake_args
      system "cmake", "--build", "."
      system "cmake", "--install", "."
    end
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <QCoreApplication>
      #include <QtQuick3D>
      int main(int argc, char *argv[]) {
        QCoreApplication app(argc, argv);
        return 0;
      }
    EOS

    qt_prefix = Formula["qt@6.2.9"].opt_prefix
    system ENV.cxx, "test.cpp", "-I#{qt_prefix}/include", "-I#{qt_prefix}/include/QtQuick3D", "-L#{qt_prefix}/lib", "-lQt6Quick3D", "-o", "test"
    system "./test"
  end
end

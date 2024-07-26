class CmakeAT322 < Formula
  desc "Cross-platform make"
  homepage "https://www.cmake.org/"
  version "3.22.1"
  url "https://github.com/Kitware/CMake/releases/download/v#{version}/cmake-#{version}.tar.gz"
  sha256 "0e998229549d7b3f368703d20e248e7ee1f853910d42704aa87918c213ea82c0"
  license "BSD-3-Clause"
  head "https://gitlab.kitware.com/cmake/cmake.git", branch: "master"

  conflicts_with "cmake", because: "it conflicts with the newer version of cmake"

  livecheck do
    url "https://cmake.org/download/"
    regex(/href=.*?cmake[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  uses_from_macos "ncurses"

  def install
    args = %W[
      --prefix=#{prefix}
      --no-system-libs
      --parallel=#{ENV.make_jobs}
      --datadir=/share/cmake
      --docdir=/share/doc/cmake
      --mandir=/share/man
      --system-zlib
      --system-bzip2
      --system-curl
    ]

    system "./bootstrap", *args, "--", *std_cmake_args,
                                      "-DCMake_INSTALL_BASH_COMP_DIR=#{bash_completion}",
                                      "-DCMake_INSTALL_EMACS_DIR=#{elisp}",
                                      "-DCMake_BUILD_LTO=ON"
    system "make"
    system "make", "install"

    # Remove conflicting symlinks if they exist.
    rm_rf %W[
      #{bin}/ccmake
      #{bin}/cmake
      #{bin}/cpack
      #{bin}/ctest
    ]

    # Install unversioned symlinks.
    %w[ccmake cmake cpack ctest].each do |prog|
      bin.install_symlink "#{prefix}/bin/#{prog}" => prog
    end
  end

  def caveats
    <<~EOS
      This version of CMake conflicts with the upstream cmake.
      If you are using this, we assume it is because you wish to compile older Qt frameworks.
      Unversioned symlinks for cmake, ccmake, cpack, and ctest have been installed into:
        #{opt_bin}
    EOS
  end

  test do
    (testpath/"CMakeLists.txt").write("find_package(Ruby)")
    system bin/"cmake", "."

    # Verify that the binary symlinks work.
    assert_predicate bin/"cmake", :exist?
    assert_predicate bin/"ccmake", :exist?
    assert_predicate bin/"cpack", :exist?
    assert_predicate bin/"ctest", :exist?
  end
end

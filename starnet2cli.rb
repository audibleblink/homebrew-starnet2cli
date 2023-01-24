class Starnet2cli < Formula
  desc "Removes stars from astrophotography images using ML models"
  homepage "https://www.starnetastro.com/"
  url "https://starnetastro.com/wp-content/uploads/2022/03/StarNetv2CLI_MacOS.zip"
  version "2"
  sha256 "35f0c11f49a1bde466e317565e75beb32b57ebfead85379c23cc3953c1c42fc7"
  license :public_domain

  depends_on :macos

  def install
    chmod 0755, "starnet++"
    libexec.install "starnet++"

    # use libexec over lib because these are x86_64 dylibs and ARM users
    # may also install libtensorflow through homebrew, creating a conflict
    libexec.install "libtensorflow.2.dylib"
    libexec.install "libtensorflow_framework.2.dylib"
    share.install "starnet2_weights.pb"

    (bin/"starnet++").write <<~EOS
      #!/bin/sh

      cleanup() {
        rm -f starnet2_weights.pb
      }
      trap cleanup RETURN EXIT SIGINT SIGKILL

      # the binary statically defines the weight path
      # so we have to link it to the CWD
      ln -sf "#{share}/starnet2_weights.pb" . 

      # define a load path since the libs are not in the same dir as the bin
      DYLD_LIBRARY_PATH=#{libexec} command "#{libexec}/starnet++" "$@"
    EOS
  end

  def caveats
    <<~EOS
      If this an M1/M2 mac, starnet2 requires Rosetta 2 to be installed. If you've
      installed x64_86 applications previously, starnet2 may already work. If not,
      you can install Rosetta 2 manually with:

      /usr/sbin/softwareupdate --install-rosetta
    EOS
  end

  test do
    output = shell_output("#{bin}/starnet++")
    assert_match "StarNet++", output
  end
end

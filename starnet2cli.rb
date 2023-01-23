class Starnet2cli < Formula
  desc "Removes stars from astrophotography images using ML models"
  homepage "https://www.starnetastro.com/"
  url "https://starnetastro.com/wp-content/uploads/2022/03/StarNetv2CLI_MacOS.zip"
  version "2"
  sha256 "35f0c11f49a1bde466e317565e75beb32b57ebfead85379c23cc3953c1c42fc7"
  license :puclic_domain

  depends_on :macos

  def install
    libexec.install "libtensorflow.2.dylib"
    libexec.install "libtensorflow_framework.2.dylib"
    share.install "starnet2_weights.pb"

    # Patch the Homebrew libexec path into the binary
    system "install_name_tool -add_rpath #{libexec} starnet++"
    chmod 0755, "starnet++"
    libexec.install "starnet++"

    (bin/"starnet++").write <<~EOS
      #!/bin/sh

      cleanup() {
        rm -f starnet2_weights.pb
      }
      trap cleanup RETURN EXIT SIGINT SIGKILL

      # the binary statically defines the weight path
      # so we have to link it to the CWD
      ln -sf "#{share}/starnet2_weights.pb" . 
      command "#{libexec}/starnet++" "$@"
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

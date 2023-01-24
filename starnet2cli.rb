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

      # delete the symlink on process exit
      cleanup() {
        rm -f starnet2_weights.pb
      }
      trap cleanup RETURN EXIT SIGINT SIGKILL

      # the binary hardcodes the weights path so we have to symlink it to the CWD
      ln -sf "#{share}/starnet2_weights.pb" . 

      # define a load path since the libs are not in the same dir as the bin
      DYLD_LIBRARY_PATH=#{libexec} command "#{libexec}/starnet++" "$@"
    EOS
  end

  def caveats
    if Hardware::CPU.arm?
      <<~EOS

        \e[0;32;49m+ ATTENTION ARM (M1/M2) USERS\e[0m

        StarNet2 is not an ARM binary and requires Rosetta 2. If you've
        installed x64_86 applications previously, StarNet2 may already work. If not,
        you can install Rosetta 2 manually with:

          /usr/sbin/softwareupdate --install-rosetta

      EOS
    end
  end

  test do
    output = shell_output("#{bin}/starnet++")
    assert_match "StarNet++", output
  end
end

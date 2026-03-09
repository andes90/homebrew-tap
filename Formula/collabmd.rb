class Collabmd < Formula
  desc "Collaborative markdown vault server"
  homepage "https://github.com/andes90/collabmd"
  url "https://github.com/andes90/collabmd/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "2330a0aa29ca9b1f868ec0481996cfad289bbd9615f6f7d4363b2aa07b8e57d8"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec/"bin/collabmd"
  end

  test do
    require "timeout"

    (testpath/"vault").mkpath
    (testpath/"vault/test.md").write("# Hello from Homebrew\n")

    port = free_port
    log_path = testpath/"collabmd.log"
    pid = spawn(
      bin/"collabmd",
      testpath/"vault",
      "--no-tunnel",
      "--host", "127.0.0.1",
      "--port", port.to_s,
      out: log_path,
      err: log_path
    )

    begin
      output = nil

      Timeout.timeout(15) do
        loop do
          output = shell_output("curl -fsS http://127.0.0.1:#{port}/health").strip
          break if output == "ok"

          sleep 1
        rescue ErrorDuringExecution
          sleep 1
        end
      end

      assert_equal "ok", output
    ensure
      begin
        Process.kill("TERM", pid)
      rescue Errno::ESRCH
        nil
      end

      begin
        Process.wait(pid)
      rescue Errno::ECHILD
        nil
      end
    end
  end
end

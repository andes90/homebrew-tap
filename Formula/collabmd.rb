class Collabmd < Formula
  desc "Collaborative markdown vault server"
  homepage "https://github.com/andes90/collabmd"
  url "https://github.com/andes90/collabmd/archive/refs/tags/v0.1.24.tar.gz"
  sha256 "a4c06858690874974d5349fd5eb109a1828e8418bd863b6d99fe2e862d9b3fad"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args(prefix: false), "--include=dev"
    system "npm", "run", "build"
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

    health_output = nil

    Timeout.timeout(15) do
      loop do
        health_output = shell_output("curl -fsS http://127.0.0.1:#{port}/health", 2).strip
        break if health_output == "ok"
      rescue ErrorDuringExecution
        sleep 1
      else
        sleep 1 if health_output != "ok"
      end
    end

    assert_equal "ok", health_output

    asset_response = shell_output("curl -i -fsS http://127.0.0.1:#{port}/assets/css/style.css", 2)
    assert_match "Content-Type: text/css; charset=utf-8", asset_response
    assert_match "--color-bg", asset_response
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

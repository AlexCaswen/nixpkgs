{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
  openssl,
}:

buildGoModule {
  pname = "setec";
  version = "0-unstable-2026-09-30";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "setec";
    rev = "1ef5b44191cf4f4d8d731a18a6f9b7b8b70bc643";
    hash = "sha256-X5DiwADxUkQTazfFD1vbcMh/DZTlfa8cBj6iYhLTny0=";
  };

  # Preserve the C sources and headers needed by the TPM simulator tests.
  proxyVendor = true;
  vendorHash = "sha256-/Z6e+9DA42l95yF05Xm5uv9pGdEC8yGiPF5/xabrg6o=";

  subPackages = [ "cmd/setec" ];

  ldflags = [
    "-s"
    "-w"
  ];

  checkInputs = [ openssl ];

  # The default check phase only tests subPackages, but the tests live in
  # the libraries used by the CLI and server.
  checkPhase = ''
    runHook preCheck
    go test -p "$NIX_BUILD_CORES" ./...
    runHook postCheck
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    # The upstream command library returns 2 for help requests.
    status=0
    $out/bin/setec help > help.txt 2>&1 || status=$?
    test "$status" -eq 2
    grep -F "Run the setec server." help.txt
    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--version=branch" ];
  };

  meta = {
    description = "Secrets management service and CLI built on Tailscale";
    homepage = "https://github.com/tailscale/setec";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ AlexCaswen ];
    mainProgram = "setec";
  };
}

{
  lib,
  stdenv,
  fetchFromGitHub,
  buildPythonPackage,
  isPyPy,
  pythonAtLeast,

  setuptools,

  # tests
  pytestCheckHook,
  llvm,
  libxml2,

  withStaticLLVM ? true,
}:

buildPythonPackage rec {
  pname = "llvmlite";
  version = "0.44.0";
  pyproject = true;

  disabled = isPyPy || pythonAtLeast "3.14";

  src = fetchFromGitHub {
    owner = "numba";
    repo = "llvmlite";
    tag = "v${version}";
    hash = "sha256-ZIA/JfK9ZP00Zn6SZuPus30Xw10hn3DArHCkzBZAUV0=";
  };

  build-system = [ setuptools ];

  buildInputs = [ llvm ] ++ lib.optionals withStaticLLVM [ libxml2.dev ];

  postPatch = lib.optionalString withStaticLLVM ''
    substituteInPlace ffi/build.py --replace-fail "--system-libs --libs all" "--system-libs --libs --link-static all"
  '';

  # Set directory containing llvm-config binary
  env.LLVM_CONFIG = "${llvm.dev}/bin/llvm-config";

  nativeCheckInputs = [ pytestCheckHook ];

  # https://github.com/NixOS/nixpkgs/issues/255262
  preCheck = ''
    cd $out
  '';

  __impureHostDeps = lib.optionals stdenv.hostPlatform.isDarwin [ "/usr/lib/libm.dylib" ];

  passthru = lib.optionalAttrs (!withStaticLLVM) { inherit llvm; };

  meta = {
    changelog = "https://github.com/numba/llvmlite/blob/v${version}/CHANGE_LOG";
    description = "Lightweight LLVM python binding for writing JIT compilers";
    downloadPage = "https://github.com/numba/llvmlite";
    homepage = "http://llvmlite.pydata.org/";
    license = lib.licenses.bsd2;
  };
}

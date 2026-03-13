{
  lib,
  python3Packages,
  fetchFromGitHub,
}:
python3Packages.buildPythonPackage rec {
  pname = "glmocr";
  version = "0.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "zai-org";
    repo = "glm-ocr";
    rev = "f78c8c3a164b499ac6e77408845d65078070f1d6";
    hash = "sha256-5h2vTTCuBazB4RoWhOSiqY33bLilOnNzG/FG/YTePuU=";
  };

  build-system = with python3Packages; [
    setuptools
    wheel
  ];

  nativeBuildInputs = with python3Packages; [
    pythonRelaxDepsHook
  ];

  pythonRemoveDeps = [
    "opencv-python" # provided by opencv4
  ];

  dependencies = with python3Packages; [
    pillow
    numpy
    requests
    pydantic
    wordfreq
    pyyaml
    portalocker
    python-dotenv

    # Layout detection
    torch
    torchvision
    transformers
    sentencepiece
    accelerate
    opencv4

    # PDF support
    pypdfium2

    # Flask server
    flask
  ];

  pythonImportsCheck = ["glmocr"];

  # Tests require network access and API keys
  doCheck = false;

  meta = {
    description = "Optical Character Recognition powered by GLM";
    homepage = "https://github.com/zai-org/glm-ocr";
    license = lib.licenses.asl20;
    maintainers = [];
    mainProgram = "glmocr";
  };
}

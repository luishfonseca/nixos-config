{
  lib,
  python3Packages,
  fetchFromGitHub,
  fetchPypi,
}:

let
  pyzotero = python3Packages.buildPythonPackage rec {
    pname = "pyzotero";
    version = "1.10.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-kOxAQOWiYYK54rDqp5RUZLy09XxxCxQYwczRm7XM96c=";
    };

    build-system = with python3Packages; [ hatchling ];

    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail 'requires = ["uv_build>=0.8.14,<0.9.0"]' 'requires = ["hatchling"]' \
        --replace-fail 'build-backend = "uv_build"' 'build-backend = "hatchling.build"'
    '';

    dependencies = with python3Packages; [
      feedparser
      bibtexparser
      httpx
      whenever
    ];

    pythonImportsCheck = [ "pyzotero" ];
    doCheck = false;

    meta = {
      description = "Python wrapper for the Zotero API";
      homepage = "https://github.com/urschrei/pyzotero";
      license = lib.licenses.gpl3Only;
    };
  };
in

python3Packages.buildPythonApplication rec {
  pname = "zotero-mcp-server";
  version = "0.1.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "54yyyu";
    repo = "zotero-mcp";
    rev = "ed67779db28435e5d5e0e1546a1937cd39245893";
    hash = "sha256-Y8qnKb6vfBeiNgjP1s5hZgDebFSNx2sm0bGB5vgb0jM=";
  };

  build-system = with python3Packages; [ hatchling ];

  nativeBuildInputs = with python3Packages; [ pythonRelaxDepsHook ];

  pythonRelaxDeps = true;

  dependencies = with python3Packages; [
    pyzotero
    mcp
    fastmcp
    python-dotenv
    markitdown
    pydantic
    requests
    chromadb
    sentence-transformers
    openai
    google-genai
    pymupdf
    ebooklib
    tiktoken
  ];

  pythonImportsCheck = [ "zotero_mcp" ];
  doCheck = false;

  meta = {
    description = "MCP server for Zotero integration with AI assistants";
    homepage = "https://github.com/54yyyu/zotero-mcp";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "zotero-mcp";
  };
}

from pathlib import Path

from tests.validate_configs import validate


def test_valid_fixture_passes():
    assert validate(Path("tests/fixtures/valid/opencode.json"),
                    Path("tests/fixtures/valid")) == []


def test_absolute_path_rejected():
    errs = validate(Path("tests/fixtures/invalid/absolute-path.json"),
                    Path("tests/fixtures/invalid"))
    assert any("absolute path" in e for e in errs)


def test_bad_model_rejected():
    errs = validate(Path("tests/fixtures/invalid/bad-model.json"),
                    Path("tests/fixtures/invalid"))
    assert any("model" in e for e in errs)


def test_missing_instruction_rejected():
    errs = validate(Path("tests/fixtures/invalid/missing-instruction.json"),
                    Path("tests/fixtures/invalid"))
    assert any("instruction" in e for e in errs)

#!/bin/bash

set -e

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


function try-load-dotenv {
    if [ ! -f "$THIS_DIR/.env" ]; then
        echo "No .env file found"
        return 1
    fi
    if [ -f "$THIS_DIR/.env" ]; then
        set -o allexport
        source "$THIS_DIR/.env"
        set +o allexport
    fi
}

function install {
    python -m pip install --upgrade pip
    python -m pip install --editable "$THIS_DIR/[dev]"
}

function lint {
    pre-commit run --all-files
}

# execute tests that are not marked as `slow`
function test:quick {
    run-tests -m "not slow" ${@:-"$THIS_DIR/tests/"}
}

# function test:quick {
#     # save the exit status of tests
#     PYTEST_EXIT_STATUS=0 # this is to make sure move commands run even if tests fail
#     python -m pytest -m 'not slow' "$THIS_DIR/tests/" \
#         --cov "$THIS_DIR/packaging_practice" \
#         --cov-report html \
#         --cov-report term \
#         --cov-report xml \
#         --junitxml="$THIS_DIR/test-reports/results.xml" \
#         --cov-fail-under 50 || (( PYTEST_EXIT_STATUS += $? ))
    
#     mv coverage.xml "$THIS_DIR/test-reports/"
#     mv htmlcov "$THIS_DIR/test-reports/"
#     return $PYTEST_EXIT_STATUS
# }

function test {

    ## example usage:
    # ./run.sh test
    # ./run.sh test tests/test_slow.py
    # ./run.sh test tests/test_slow.py::test__slow_add

    # run only specific tests, if none are specified then run all
    PYTEST_EXIT_STATUS=0 # this is to make sure move commands run even if tests fail
    python -m pytest "${@:-$THIS_DIR/tests/}" \
        --cov "$THIS_DIR/packaging_practice" \
        --cov-report html \
        --cov-report term \
        --cov-report xml \
        --junitxml="$THIS_DIR/test-reports/results.xml" \
        --cov-fail-under 50 || (( PYTEST_EXIT_STATUS += $? ))
    
    mv coverage.xml "$THIS_DIR/test-reports/"
    mv htmlcov "$THIS_DIR/test-reports/"
    return $PYTEST_EXIT_STATUS
}

# function test:ci {

#     ## example usage:
#     # ./run.sh test
#     # ./run.sh test tests/test_slow.py
#     # ./run.sh test tests/test_slow.py::test__slow_add

#     # run only specific tests, if none are specified then run all
#     PYTEST_EXIT_STATUS=0 # this is to make sure move commands run even if tests fail
#     python -m pytest "${@:-$THIS_DIR/tests/}" \
#         --cov "$THIS_DIR/packaging_practice" \
#         --cov-report html \
#         --cov-report term \
#         --cov-report xml \
#         --junitxml="$THIS_DIR/test-reports/results.xml" \
#         --cov-fail-under 50 || (( PYTEST_EXIT_STATUS += $? ))
    
#     mv coverage.xml "$THIS_DIR/test-reports/"
#     mv htmlcov "$THIS_DIR/test-reports/"
#     return $PYTEST_EXIT_STATUS
# }

# execute tests against the installed package; assumes the wheel is already installed
function test:ci {
    pip list
    INSTALLED_PKG_DIR="$(python -c 'import packaging_practice; print(packaging_practice.__path__[0])')"
    # in CI, we must calculate the coverage for the installed package, not the src/ folder
    COVERAGE_DIR="$INSTALLED_PKG_DIR" run-tests
}

# (example) ./run.sh test tests/test_states_info.py::test__slow_add
function run-tests {
    PYTEST_EXIT_STATUS=0
    python -m pytest ${@:-"$THIS_DIR/tests/"} \
        --cov "${COVERAGE_DIR:-$THIS_DIR/src}" \
        --cov-report html \
        --cov-report term \
        --cov-report xml \
        --junit-xml "$THIS_DIR/test-reports/report.xml" \
        --cov-fail-under 50 || ((PYTEST_EXIT_STATUS+=$?))
    mv coverage.xml "$THIS_DIR/test-reports/" || true
    mv htmlcov "$THIS_DIR/test-reports/" || true
    mv .coverage "$THIS_DIR/test-reports/" || true
    return $PYTEST_EXIT_STATUS
}

function test:wheel-locally {
    deactivate || true
    rm -rf test-env || true
    python -m venv test-env
    source test-env/bin/activate
    clean || true
    pip install build
    build
    pip install ./dist/*.whl
    pip install pytest pytest-cov
    test:ci
    deactivate || true
}

function serve-coverage-report {
    python -m http.server --directory "$THIS_DIR/htmlcov/" 8000
}


function lint:ci {
    SKIP=no-commit-to-branch pre-commit run --all-files
}

function build {
    python -m build --sdist --wheel "$THIS_DIR/"
}

function release:test {
    lint
    clean
    build
    publish:test
}

function release:prod {
    lint
    clean
    build
    publish:prod
}

function publish:test {
    try-load-dotenv || true
    twine upload dist/* \
    --repository testpypi \
    --username=__token__ \
    --password="$TEST_PYPI_TOKEN" \
    --verbose
}

function publish:prod {
    load-dotenv || true
    twine upload dist/* \
    --repository pypi \
    --username=__token__ \
    --password="$PROD_PYPI_TOKEN"
}


function clean {
    rm -rf dist build coverage.xml test-reports
    find . \
      -type d \
      \( \
        -name "*cache*" \
        -o -name "*.dist-info" \
        -o -name "*.egg-info" \
        -o -name "*htmlcov" \
      \) \
      -not -path "*env/*" \
      -exec rm -r {} + || true

    find . \
      -type f \
      -name "*.pyc" \
      -not -path "*env/*" \
      -exec rm {} +
}

function start {
    echo "start task not implemented"
}

function default {
    start
}

function help {
    echo "$0 <task> <args>"
    echo "Tasks:"
    compgen -A function | cat -n
}

TIMEFORMAT="Task completed in %3lR"
time ${@:-help}

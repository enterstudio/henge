#!/bin/bash

TMP_DIR="/tmp/henge/cmd-tests"
TMP_STDOUT="${TMP_DIR}"/test-stdout
TMP_STDERR="${TMP_DIR}"/test-stderr

HENGE_ROOT=$(dirname "${BASH_SOURCE}")/../..

# in order to store stderr and stdout in different places, we need to store them into files
# this is why we need tmp directory
function initTmp(){
    mkdir -p ${TMP_DIR}
    rm -f ${TMP_STDOUT} ${TMP_STDERR}
}


# regular henge run, verify right exit code
function test_exitCodeSuccess() {
   henge ${HENGE_ROOT}/test/fixtures/complex/docker-compose.yml
    if [[ "${exit_code}" -eq "0" ]]; then
        return 0
    else
        return 1
    fi

}

# test right exit code when compose file doesn't exist
function test_fileNotExist(){
    henge nonexiting_file
    local exit_code=$?
    if [[ "${exit_code}" -ne "0" ]]; then
        return 0
    else
        return 1
    fi
}

# Utility function compere actual henge output with expected output
function compereOutput(){
    local dockerComposeFile=${1}
    local expectedOutput=${2}
    henge ${dockerComposeFile} > ${TMP_DIR}/compereOutput
    
    # skip ref,secret,uri field  - they are different every time
    diff --suppress-common-lines -y ${TMP_DIR}/compereOutput ${expectedOutput} \
        | grep -vE "ref\:|secret|uri\:" | tee ${TMP_STDOUT}
    if [[ "$(cat ${TMP_STDOUT} | wc -l)" -ne "0" ]]; then
        return 1
    else
        return 0
    fi
}


# check conversion for complex app
function test_complex(){
    compereOutput "${HENGE_ROOT}/test/fixtures/complex/docker-compose.yml" "${HENGE_ROOT}/test/fixtures/complex/docker-compose.converted.yaml"
    return $?
}


# Run all "test_*" function from this file.
function runTests() {
    local failedTests=""
    #get all function names that are begginig with "test_"
    for testFce in $(declare -F | cut -f 3 -d ' ' | grep "test_");do 
        echo "* Running ${testFce}"
        eval ${testFce} 2>$TMP_STDERR >$TMP_STDOUT 
        local exit_code=$?
        if [[ $exit_code -ne 0 ]]; then
            failedTests="${failedTests} ${testFce}"
            echo "  TEST FAILED"
            echo "  stderr:"
            cat $TMP_STDERR
            echo ""
            echo "  stdout:"
            cat $TMP_STDOUT
        else
            echo "  test OK"
        fi
    done

    if [[ "$(echo $failedTests | wc -w)" -ne "0" ]]; then
        echo ""
        echo "FAILED TESTS: $failedTests"
        return 1
    else
        return 0
    fi
}


initTmp
runTests


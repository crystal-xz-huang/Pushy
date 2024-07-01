#!/bin/dash

# ==============================================================================
# TEST06: PUSHY-RM
# ==============================================================================

SCRIPT_DIR=$(pwd)
PATH="$SCRIPT_DIR:$PATH"

TEST_DIR=$(mktemp -d)
cd "$TEST_DIR" || exit 1

CORRECT_OUTPUT=$(mktemp)
MY_OUTPUT=$(mktemp)

trap 'rm -rf "$TEST_DIR" "$CORRECT_OUTPUT" "$MY_OUTPUT"' INT TERM EXIT

test_command() {
    test_no=$1
    test_name=$2
    expected=$3
    actual=$4
    correct_status=$5
    my_status=$6

    if diff "$expected" "$actual" > /dev/null && [ "$correct_status" -eq "$my_status" ]; then
        # print "passed" in green text
        echo "Test $test_no $test_name - \033[32mpassed\033[0m"
    else 
        # print "failed" in red text
        echo "Test $test_no $test_name - \033[31mfailed\033[0m"
        if [ "$correct_status" -ne "$my_status" ]; then
            echo "Expected exit status of \033[32m$correct_status\033[0m but received \033[31m$my_status\033[0m" 
        fi

        if ! diff "$expected" "$actual" > /dev/null; then
            # print the difference in the expected and actual output 
            echo "\033[31mMy output (left) did not match expected output (right)\033[0m"
            diff --color=always -y "$actual" "$expected"  
        fi
        exit 1
    fi
}

check_file_removed_from_index() {
    if [ -f ".pushy/index/$1" ]; then
        echo "Error: '$1' was not removed from the index" >> "$MY_OUTPUT"
    fi
}

check_file_removed_from_working_directory() {
    if [ -f "$1" ]; then
        echo "Error: '$1' was not removed from the working directory" >> "$MY_OUTPUT"
    fi
}

check_file_still_in_working_directory() {
    if [ ! -f "$1" ]; then
        echo "Error: '$1' was removed from the working directory" >> "$MY_OUTPUT"
    fi
}

# --------------------------------------------------------------------------------------------------------------------------
# Testing incorrect usage 
# --------------------------------------------------------------------------------------------------------------------------

# Test 1: no .pushy directory
touch file1 
(pushy-rm "file1") > "$MY_OUTPUT" 2>&1
my_status=$?
(2041 pushy-rm "file1") > "$CORRECT_OUTPUT" 2>&1
correct_status=$?

test_name="(no previous init): no .pushy directory initialized"
test_command "1 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 2: incorrect usage - no arguments
(pushy-init && pushy-rm) > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-rm) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(incorrect usage): no arguments"
test_command "2 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 3: incorrect usage - no filenames
(pushy-init && pushy-rm --force --cached) > "$MY_OUTPUT" 2>&1
pushy-rm --cached --force >> "$MY_OUTPUT" 2>&1
pushy-rm --cached >> "$MY_OUTPUT" 2>&1
pushy-rm --force >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy
(2041 pushy-init && 2041 pushy-rm --force --cached) > "$CORRECT_OUTPUT" 2>&1
2041 pushy-rm --cached --force >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-rm --cached >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-rm --force >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(incorrect usage): no filenames"
test_command "3 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 4: incorrect usage - invalid options
pushy-init > /dev/null 2>&1
(pushy-rm -abcde) > "$MY_OUTPUT" 2>&1
(pushy-rm -force) >> "$MY_OUTPUT" 2>&1
(pushy-rm --force -cached) >> "$MY_OUTPUT" 2>&1
(pushy-rm --cache -) >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy
2041 pushy-init > /dev/null 2>&1
(2041 pushy-rm -abcde) > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm -force) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force -cached) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cache -) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(incorrect usage): invalid options"
test_command "4 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing invalid filenames 
# --------------------------------------------------------------------------------------------------------------------------
# Test 5: incorrect usage - invalid filenames
pushy-init > /dev/null 2>&1
(pushy-rm '.') > "$MY_OUTPUT" 2>&1            
(pushy-rm _file2) >> "$MY_OUTPUT" 2>&1      
(pushy-rm "hi/file1") >> "$MY_OUTPUT" 2>&1 
(touch "A*F^N" && pushy-add "A*F^N" && pushy-rm "A*F^N") >> "$MY_OUTPUT" 2>&1     # invalid file exists and staged in the index
my_status=$?
rm -rf .pushy  

2041 pushy-init > /dev/null 2>&1
(2041 pushy-rm '.') > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm _file2) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm "hi/file1") >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-add "A*F^N" && 2041 pushy-rm "A*F^N") >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy "A*F^N"

test_name="(incorrect usage): invalid filenames"
test_command "5 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing untracked files 
# --------------------------------------------------------------------------------------------------------------------------
# Test 6: files not in working directory
touch file1 file2
pushy-init > /dev/null 2>&1
(pushy-rm file1 hi) > "$MY_OUTPUT" 2>&1
(pushy-rm --cached file1 hi) >> "$MY_OUTPUT" 2>&1
(pushy-rm --force file1 hi) >> "$MY_OUTPUT" 2>&1
(pushy-rm --cached --force file1 hi) >> "$MY_OUTPUT" 2>&1
(pushy-rm --force --cached file1 hi) >> "$MY_OUTPUT" 2>&1
# file1 is now in the index
(pushy-add file1 && pushy-rm file1 hi) >> "$MY_OUTPUT" 2>&1
(pushy-add file1 && pushy-rm --cached file1 hi) >> "$MY_OUTPUT" 2>&1
(pushy-add file1 && pushy-rm --force file1 hi) >> "$MY_OUTPUT" 2>&1
(pushy-add file1 && pushy-rm --cached --force file1 hi) >> "$MY_OUTPUT" 2>&1
(pushy-add file1 && pushy-rm --force --cached file1 hi) >> "$MY_OUTPUT" 2>&1
# file1 is now committed and in the repository
(touch file1 && pushy-add file1 && pushy-commit -m "commit 1" && pushy-rm file1 hi) >> "$MY_OUTPUT" 2>&1
(touch file1 && pushy-add file1 && pushy-commit -m "commit 1" && pushy-rm --cached file1 hi) >> "$MY_OUTPUT" 2>&1
(touch file1 && pushy-add file1 && pushy-commit -m "commit 1" && pushy-rm --force file1 hi) >> "$MY_OUTPUT" 2>&1
(touch file1 && pushy-add file1 && pushy-commit -m "commit 1" && pushy-rm --cached --force file1 hi) >> "$MY_OUTPUT" 2>&1
(touch file1 && pushy-add file1 && pushy-commit -m "commit 1" && pushy-rm --force --cached file1 hi) >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
(2041 pushy-rm file1 hi) > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached file1 hi) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force file1 hi) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached --force file1 hi) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force --cached file1 hi) >> "$CORRECT_OUTPUT" 2>&1
# file1 is now in the index
(2041 pushy-add file1 && 2041 pushy-rm file1 hi) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-add file1 && 2041 pushy-rm --cached file1 hi) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-add file1 && 2041 pushy-rm --force file1 hi) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-add file1 && 2041 pushy-rm --cached --force file1 hi) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-add file1 && 2041 pushy-rm --force --cached file1 hi) >> "$CORRECT_OUTPUT" 2>&1
# file1 is now committed and in the repository
(touch file1 && 2041 pushy-add file1 && 2041 pushy-commit -m "commit 1" && 2041 pushy-rm file1 hi) >> "$CORRECT_OUTPUT" 2>&1
(touch file1 && 2041 pushy-add file1 && 2041 pushy-commit -m "commit 1" && 2041 pushy-rm --cached file1 hi) >> "$CORRECT_OUTPUT" 2>&1
(touch file1 && 2041 pushy-add file1 && 2041 pushy-commit -m "commit 1" && 2041 pushy-rm --force file1 hi) >> "$CORRECT_OUTPUT" 2>&1
(touch file1 && 2041 pushy-add file1 && 2041 pushy-commit -m "commit 1" && 2041 pushy-rm --cached --force file1 hi) >> "$CORRECT_OUTPUT" 2>&1
(touch file1 && 2041 pushy-add file1 && 2041 pushy-commit -m "commit 1" && 2041 pushy-rm --force --cached file1 hi) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file is not in the pushy repository): not in working directory"
test_command "6 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"


# Test 7: in working directory but not in the index or any commits
touch file1 _file2
pushy-init > /dev/null 2>&1
(pushy-rm file1 file2) > "$MY_OUTPUT" 2>&1      # file1 is not in the pushy repository
(pushy-rm file1 _file2) >> "$MY_OUTPUT" 2>&1    # file1 is not in the pushy repository 
(pushy-rm --cached file1 _file2) >> "$MY_OUTPUT" 2>&1
(pushy-rm --force file1 _file2) >> "$MY_OUTPUT" 2>&1
(pushy-rm --cached --force file1 _file2) >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1 _file2

touch file1 _file2
2041 pushy-init > /dev/null 2>&1
(2041 pushy-rm file1 file2) > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm file1 _file2) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached file1 _file2) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force file1 _file2) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached --force file1 _file2) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1 _file2

test_name="(file is not in the pushy repository): not in the index"
test_command "7 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing files that have been added to the staging index 
# --------------------------------------------------------------------------------------------------------------------------
# Test 8: files have been added to the staging index but not committed (staged changes)
(touch file1 && pushy-init && pushy-add file1) > /dev/null 2>&1
(pushy-rm file1) > "$MY_OUTPUT" 2>&1           # should not remove the files from the staging index
(pushy-rm --cached file1) >> "$MY_OUTPUT" 2>&1 # should remove the files from the staging index only
my_status=$?
check_file_removed_from_index "file1"
check_file_still_in_working_directory "file1"
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1) > /dev/null 2>&1
(2041 pushy-rm file1) > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached file1) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file has has staged changes in the index): cached"
test_command "8 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 9: files have been added to the staging index but not committed (staged changes)
(touch file1 && pushy-init && pushy-add file1) > /dev/null 2>&1
(pushy-rm file1) > "$MY_OUTPUT" 2>&1           # should not remove the files from the staging index
(pushy-rm --cached --force file1) >> "$MY_OUTPUT" 2>&1 # should remove the files from the staging index only
my_status=$?
check_file_removed_from_index "file1"
check_file_still_in_working_directory "file1"
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1) > /dev/null 2>&1
(2041 pushy-rm file1) > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached --force file1) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file has has staged changes in the index): cached and force"
test_command "9 " "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 10: files have been added to the staging index but not committed (staged changes)
(touch file1 && pushy-init && pushy-add file1) > /dev/null 2>&1
(pushy-rm file1) > "$MY_OUTPUT" 2>&1                    # should not remove the files from the staging index
(pushy-rm --force --cached file1) >> "$MY_OUTPUT" 2>&1  # should remove the files from the staging index only
my_status=$?
check_file_removed_from_index "file1"
check_file_still_in_working_directory "file1"
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1) > /dev/null 2>&1
(2041 pushy-rm file1) > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force --cached file1) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file has has staged changes in the index): force and cached"
test_command 10 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"


# Test 11: files have been added to the staging index but not committed (staged changes)
(touch file1 && pushy-init && pushy-add file1) > /dev/null 2>&1
(pushy-rm file1) > "$MY_OUTPUT" 2>&1                    # should not remove the files from the staging index
(pushy-rm --force file1) >> "$MY_OUTPUT" 2>&1 # should remove the files from the staging index and working directory
my_status=$?
check_file_removed_from_index "file1"
check_file_removed_from_working_directory "file1"
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1) > /dev/null 2>&1
(2041 pushy-rm file1) > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force file1) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file has has staged changes in the index): force"
test_command 11 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing files that have been added to the staging index and modified since last add
# --------------------------------------------------------------------------------------------------------------------------
# Test 12: files have been added to the staging index but modified since last add
(touch file1 && pushy-init && pushy-add file1 && echo "hello" > file1) > /dev/null 2>&1
(pushy-rm file1) > "$MY_OUTPUT" 2>&1           # should not remove the files 
(pushy-rm --cached file1) >> "$MY_OUTPUT" 2>&1 # should not remove the files 
my_status=$?
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && echo "hello" > file1) > /dev/null 2>&1
(2041 pushy-rm file1) > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached file1) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file in index is different to both the working file and the repository): cached"
test_command 12 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 13: files have been added to the staging index but modified since last add
(touch file1 && pushy-init && pushy-add file1 && echo "hello" > file1) > /dev/null 2>&1
(pushy-rm file1) > "$MY_OUTPUT" 2>&1                    # should not remove the files 
(pushy-rm --cached --force file1) >> "$MY_OUTPUT" 2>&1  # should remove the files from the staging index only
my_status=$?
check_file_removed_from_index "file1"
check_file_still_in_working_directory "file1"
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && echo "hello" > file1) > /dev/null 2>&1
(2041 pushy-rm file1) > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached --force  file1) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file in index is different to both the working file and the repository): cached and force"
test_command 13 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 13: files have been added to the staging index but modified since last add
(touch file1 && pushy-init && pushy-add file1 && echo "hello" > file1) > /dev/null 2>&1
(pushy-rm file1) > "$MY_OUTPUT" 2>&1                    # should not remove the files 
(pushy-rm --force --cached file1) >> "$MY_OUTPUT" 2>&1  # should remove the files from the staging index only
my_status=$?
check_file_removed_from_index "file1"
check_file_still_in_working_directory "file1"
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && echo "hello" > file1) > /dev/null 2>&1
(2041 pushy-rm file1) > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force --cached file1) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file in index is different to both the working file and the repository): force and cached"
test_command 14 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 14: files have been added to the staging index but modified since last add
(touch file1 && pushy-init && pushy-add file1 && echo "hello" > file1) > /dev/null 2>&1
(pushy-rm file1) > "$MY_OUTPUT" 2>&1                    # should not remove the files 
(pushy-rm --force file1) >> "$MY_OUTPUT" 2>&1  # should remove the files 
my_status=$?
check_file_removed_from_index "file1"
check_file_removed_from_working_directory "file1"
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && echo "hello" > file1) > /dev/null 2>&1
(2041 pushy-rm file1) > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force file1) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file in index is different to working file): force"
test_command 15 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 15: files have been added to the staging index but modified since last add
(touch file1 && pushy-init && pushy-add file1 && echo "hello" > file1) > /dev/null 2>&1
(pushy-rm file1) > "$MY_OUTPUT" 2>&1                            # should not remove the files 
(pushy-rm --force --cached --force file1) >> "$MY_OUTPUT" 2>&1  # should remove the files 
my_status=$?
check_file_removed_from_index "file1"
check_file_still_in_working_directory "file1"
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && echo "hello" > file1) > /dev/null 2>&1
(2041 pushy-rm file1) > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force --cached --force file1) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file in index is different to working file): force and cached and force"
test_command 16 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing files that are added and committed to the repository (file is same as repo)
# --------------------------------------------------------------------------------------------------------------------------
# Test 17: file is added and committed to the repository (same as repo)
(touch file1 && pushy-init && pushy-add file1 && pushy-commit -m "commit0") > /dev/null 2>&1
(pushy-rm file1) > "$MY_OUTPUT" 2>&1                            # should remove the file
my_status=$?
check_file_removed_from_index "file1"
check_file_removed_from_working_directory "file1"
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && 2041 pushy-commit -m "commit0") > /dev/null 2>&1
(2041 pushy-rm file1) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file is same as repo): no options"
test_command 17 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 18: file is added and committed to the repository (same as repo)
(touch file1 && pushy-init && pushy-add file1 && pushy-commit -m "commit0") > /dev/null 2>&1
(pushy-rm --cached file1) > "$MY_OUTPUT" 2>&1       # should remove the file from the index only
my_status=$?
check_file_removed_from_index "file1"
check_file_still_in_working_directory "file1"
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && 2041 pushy-commit -m "commit0") > /dev/null 2>&1
(2041 pushy-rm --cached file1) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file is same as repo): cached"
test_command 18 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 19: file is added and committed to the repository (same as repo)
(touch file1 && pushy-init && pushy-add file1 && pushy-commit -m "commit0") > /dev/null 2>&1
(pushy-rm --force file1) > "$MY_OUTPUT" 2>&1       # should remove the file from the index and working directory
my_status=$?
check_file_removed_from_index "file1"
check_file_removed_from_working_directory "file1"
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && 2041 pushy-commit -m "commit0") > /dev/null 2>&1
(2041 pushy-rm --force file1) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file is same as repo): force"
test_command 19 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing files that are added and committed to the repository but modified since last commit (file is different to repo)
# --------------------------------------------------------------------------------------------------------------------------
# Test 20: file modified since most recent commit
(touch file1 && pushy-init && pushy-add file1 && pushy-commit -m "commit0" && echo "123" > file1) > /dev/null 2>&1
(pushy-rm file1) > "$MY_OUTPUT" 2>&1       # should not remove the file
my_status=$?
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && 2041 pushy-commit -m "commit0" && echo "123" > file1) > /dev/null 2>&1
(2041 pushy-rm file1) > "$CORRECT_OUTPUT" 2>&1  # file1' in the repository is different to the working file
correct_status=$?
rm -rf .pushy file1

test_name="(file in the repository is different to the working file): no options"
test_command 20 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 21: file modified since most recent commit
(touch file1 && pushy-init && pushy-add file1 && pushy-commit -m "commit0" && echo "123" > file1) > /dev/null 2>&1
(pushy-rm --cached file1) > "$MY_OUTPUT" 2>&1     # should remove the file from the index only
check_file_still_in_working_directory "file1"
check_file_removed_from_index "file1"
my_status=$?
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && 2041 pushy-commit -m "commit0"  && echo "123" > file1) > /dev/null 2>&1
(2041 pushy-rm --cached file1) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file in the repository is different to the working file): cached"
test_command 21 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 22: file modified since most recent commit 
(touch file1 && pushy-init && pushy-add file1 && pushy-commit -m "commit0" && echo "123" > file1) > /dev/null 2>&1
(pushy-rm --force file1) > "$MY_OUTPUT" 2>&1     # should remove the file from the index and working directory
my_status=$?
check_file_removed_from_index "file1"
check_file_removed_from_working_directory "file1"
rm -rf .pushy file1

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && 2041 pushy-commit -m "commit0"  && echo "123" > file1) > /dev/null 2>&1
(2041 pushy-rm --force file1) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1

test_name="(file in the repository is different to the working file): force"
test_command 22 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing files that are in the repository but not in the latest commits
# --------------------------------------------------------------------------------------------------------------------------
# Test 23: file is same as its last commit but not in the latest commit
(touch file1 && pushy-init && pushy-add file1 && pushy-commit -m "commit0" && touch file2 && pushy-add file2 && pushy-commit -m "commit1") > /dev/null 2>&1
(pushy-rm file1) > "$MY_OUTPUT" 2>&1       # should remove the file
my_status=$?
check_file_removed_from_index "file1"
check_file_removed_from_working_directory "file1"
rm -rf .pushy file1 file2

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && 2041 pushy-commit -m "commit0" && touch file2 && 2041 pushy-add file2 && 2041 pushy-commit -m "commit1") > /dev/null 2>&1
(2041 pushy-rm file1) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1 file2

test_name="(file same as repo but not in the latest commit): no options"
test_command 23 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 24: file is same as its last commit but not in the latest commit (file3 not in the repo)
(touch file1 && pushy-init && pushy-add file1 && pushy-commit -m "commit0" && touch file2 && pushy-add file2 && pushy-commit -m "commit1") > /dev/null 2>&1
(touch file3 && pushy-add file3) > /dev/null 2>&1
(pushy-rm file1 file2 file3 file4) > "$MY_OUTPUT" 2>&1                      # should fail (file3 has staged changes)
(pushy-rm --cached file1 file2 file3 file4) >> "$MY_OUTPUT" 2>&1            # should fail (file3 has staged changes)
(pushy-rm --force --cached file1 file2 file3 file4) >> "$MY_OUTPUT" 2>&1    # should work (remove from index only)
(pushy-add file1 file2 file3 file4) >> "$MY_OUTPUT" 2>&1                    # should re-add the files to the index
(pushy-rm --force file1 file2 file3 file4) >> "$MY_OUTPUT" 2>&1             # should work (remove from index and working directory)
my_status=$?
rm -rf .pushy file1 file2 file3 file4

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && 2041 pushy-commit -m "commit0" && touch file2 && 2041 pushy-add file2 && 2041 pushy-commit -m "commit1") > /dev/null 2>&1
(touch file3 && 2041 pushy-add file3) > /dev/null 2>&1
(2041 pushy-rm file1 file2 file3 file4) > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached file1 file2 file3 file4) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force --cached file1 file2 file3 file4) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-add file1 file2 file3 file4) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force file1 file2 file3 file4) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1 file2 file3 file4

test_name="(file same as repo but not in the latest commit): different options"
test_command 24 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing files that are in the repository that have been modified since last commit
# --------------------------------------------------------------------------------------------------------------------------

# Test 25: file is modified since its last commit and not in the latest commit
(touch file1 && pushy-init && pushy-add file1 && pushy-commit -m "commit0" && echo "123" > file1 && touch file2 && pushy-add file2 && pushy-commit -m "commit1") > /dev/null 2>&1
(pushy-rm file1) > "$MY_OUTPUT" 2>&1       # should fail
my_status=$?
rm -rf .pushy file1 file2

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && 2041 pushy-commit -m "commit0" && echo "123" > file1 && touch file2 && 2041 pushy-add file2 && 2041 pushy-commit -m "commit1") > /dev/null 2>&1
(2041 pushy-rm file1) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1 file2

test_name="(file in the repo is different to the working file): no options"
test_command 25 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"


# Test 26: file is modified since its last commit and not in the latest commit
(touch file1 && pushy-init && pushy-add file1 && pushy-commit -m "commit0" && echo "123" > file1 && touch file2 && pushy-add file2 && pushy-commit -m "commit1") > /dev/null 2>&1
(pushy-rm --cached file1) > "$MY_OUTPUT" 2>&1       # should work
my_status=$?
check_file_still_in_working_directory "file1"
check_file_removed_from_index "file1"
rm -rf .pushy file1 file2

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && 2041 pushy-commit -m "commit0" && echo "123" > file1 && touch file2 && 2041 pushy-add file2 && 2041 pushy-commit -m "commit1") > /dev/null 2>&1
(2041 pushy-rm --cached file1) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1 file2

test_name="(file in the repo is different to the working file): cached"
test_command 26 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 27: file is modified since its last commit and not in the latest commit
(touch file1 && pushy-init && pushy-add file1 && pushy-commit -m "commit0" && echo "123" > file1 && touch file2 && pushy-add file2 && pushy-commit -m "commit1") > /dev/null 2>&1
(pushy-rm --force file1) > "$MY_OUTPUT" 2>&1       # should work
my_status=$?
check_file_removed_from_index "file1"
check_file_removed_from_working_directory "file1"
rm -rf .pushy file1 file2

(touch file1 && 2041 pushy-init && 2041 pushy-add file1 && 2041 pushy-commit -m "commit0" && echo "123" > file1 && touch file2 && 2041 pushy-add file2 && 2041 pushy-commit -m "commit1") > /dev/null 2>&1
(2041 pushy-rm --force file1) > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1 file2

test_name="(file in the repo is different to the working file): force"
test_command 27 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing pushy-rm 
# --------------------------------------------------------------------------------------------------------------------------
pushy-init > /dev/null 2>&1
echo 1 >a 
echo 2 >b
pushy-add a b > "$MY_OUTPUT" 2>&1
pushy-commit -m "first commit" >> "$MY_OUTPUT" 2>&1
echo 3 >c
echo 4 >d
pushy-add c d >> "$MY_OUTPUT" 2>&1
pushy-rm --cached a c >> "$MY_OUTPUT" 2>&1
pushy-commit -m "second commit" >> "$MY_OUTPUT" 2>&1
pushy-show 0:a >> "$MY_OUTPUT" 2>&1
pushy-show 1:a >> "$MY_OUTPUT" 2>&1
pushy-show :a  >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy a b c d

2041 pushy-init > /dev/null 2>&1
echo 1 >a
echo 2 >b
2041 pushy-add a b > "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m "first commit" >> "$CORRECT_OUTPUT" 2>&1
echo 3 >c
echo 4 >d
2041 pushy-add c d >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-rm --cached  a c >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m "second commit" >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show 0:a >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show 1:a >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show :a  >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy a b c d

test_name="rm show"
test_command "28" "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"


pushy-init > /dev/null 2>&1
touch a b
pushy-add a b > /dev/null 2>&1
pushy-commit -m "first commit" > "$MY_OUTPUT" 2>&1
pushy-rm a >> "$MY_OUTPUT" 2>&1
pushy-commit -m "second commit" >> "$MY_OUTPUT" 2>&1
pushy-add a >> "$MY_OUTPUT" 2>&1
pushy-commit -m "second commit" >> "$MY_OUTPUT" 2>&1
pushy-rm --cached b >> "$MY_OUTPUT" 2>&1
pushy-commit -m "second commit" >> "$MY_OUTPUT" 2>&1
pushy-rm b >> "$MY_OUTPUT" 2>&1
pushy-add b >> "$MY_OUTPUT" 2>&1
pushy-rm b >> "$MY_OUTPUT" 2>&1
pushy-commit -m "third commit" >> "$MY_OUTPUT" 2>&1
pushy-rm b >> "$MY_OUTPUT" 2>&1
pushy-commit -m "fourth commit" >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy a b

2041 pushy-init > /dev/null 2>&1
touch a b
2041 pushy-add a b > /dev/null 2>&1
2041 pushy-commit -m "first commit" > "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm a) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-commit -m "second commit") >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-add a) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-commit -m "second commit") >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached b) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-commit -m "second commit") >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm b) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-add b) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm b) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-commit -m "third commit") >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm b) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-commit -m "fourth commit") >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy a b

test_name="rm add"
test_command "29" "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 29: 
pushy-init > /dev/null 2>&1
echo 1 >a
echo 2 >b
echo 3 >c
pushy-add a b c > /dev/null 2>&1
pushy-commit -m "first commit" > "$MY_OUTPUT" 2>&1
echo 4 >>a
echo 5 >>b
echo 6 >>c # different to the repo and the index
echo 7 >d
echo 8 >e
pushy-add b c d > /dev/null 2>&1 # c has staged changes (index and repo different)
echo 9 >b
pushy-rm a >> "$MY_OUTPUT" 2>&1
pushy-rm b >> "$MY_OUTPUT" 2>&1
pushy-rm c >> "$MY_OUTPUT" 2>&1 # c has staged changes
pushy-rm d >> "$MY_OUTPUT" 2>&1
pushy-rm e >> "$MY_OUTPUT" 2>&1
pushy-rm --cached a >> "$MY_OUTPUT" 2>&1
pushy-rm --cached b >> "$MY_OUTPUT" 2>&1
pushy-rm --cached c >> "$MY_OUTPUT" 2>&1 # c has staged changes
pushy-rm --cached d >> "$MY_OUTPUT" 2>&1
pushy-rm --cached e >> "$MY_OUTPUT" 2>&1
pushy-rm --force a >> "$MY_OUTPUT" 2>&1
pushy-rm --force b >> "$MY_OUTPUT" 2>&1
pushy-rm --force c >> "$MY_OUTPUT" 2>&1
pushy-rm --force d >> "$MY_OUTPUT" 2>&1
pushy-rm --force e >> "$MY_OUTPUT" 2>&1
pushy-commit -m "second commit" >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy a b c d e

2041 pushy-init > /dev/null 2>&1
echo 1 >a
echo 2 >b
echo 3 >c
2041 pushy-add a b c > /dev/null 2>&1
2041 pushy-commit -m "first commit" > "$CORRECT_OUTPUT" 2>&1
echo 4 >>a
echo 5 >>b
echo 6 >>c
echo 7 >d
echo 8 >e
2041 pushy-add b c d > /dev/null 2>&1
echo 9 >b
(2041 pushy-rm a) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm b) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm c) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm d) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm e) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached a) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached b) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached c) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached d) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --cached e) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force a) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force b) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force c) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force d) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force e) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-commit -m "second commit") >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy a b c d e

test_name="rm errors"
test_command "30" "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# subset1_19: rm options
pushy-init > /dev/null 2>&1
echo 1 >a
echo 2 >b
echo 3 >c
pushy-add a b c > /dev/null 2>&1
pushy-commit -m "first commit" > "$MY_OUTPUT" 2>&1
echo 4 >>a
echo 5 >>b
echo 6 >>c
echo 7 >d
echo 8 >e 
pushy-add b c d e > /dev/null 2>&1
echo 9 >b
echo 0 >d
pushy-rm --cached a c >> "$MY_OUTPUT" 2>&1
pushy-rm --force --cached b >> "$MY_OUTPUT" 2>&1
pushy-rm --force --cached e >> "$MY_OUTPUT" 2>&1
pushy-rm --force d >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy a b c d e
# a - deleted from index
# b - deleted from index
# c - deleted from index
# e - untracked

2041 pushy-init > /dev/null 2>&1
echo 1 >a
echo 2 >b
echo 3 >c
2041 pushy-add a b c > /dev/null 2>&1
2041 pushy-commit -m "first commit" > "$CORRECT_OUTPUT" 2>&1
echo 4 >>a
echo 5 >>b
echo 6 >>c
echo 7 >d
echo 8 >e
2041 pushy-add b c d e > /dev/null 2>&1
echo 9 >b
echo 0 >d
(2041 pushy-rm --cached a c) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force --cached b) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force --cached e) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-rm --force d) >> "$CORRECT_OUTPUT" 2>&1
(2041 pushy-status) >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy a b c d e

test_name="rm options"
test_command "31" "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"
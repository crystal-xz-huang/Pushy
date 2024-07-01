#!/bin/dash

# ==============================================================================
# TEST06: PUSHY-STATUS
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

# --------------------------------------------------------------------------------------------------------------------------
# Testing incorrect usage
# --------------------------------------------------------------------------------------------------------------------------

# Test 1: no .pushy directory
pushy-status > "$MY_OUTPUT" 2>&1
my_status=$?

2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
correct_status=$?

test_name="(no previous init): no .pushy directory"
test_command 1 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 2: incorrect usage
pushy-init > /dev/null 2>&1
pushy-status "hello" > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy 

2041 pushy-init > /dev/null 2>&1
2041 pushy-status "hello" > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy 

test_name="(incorrect usage): pushy-status \"hello\""
test_command 2 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 3: incorrect usage
pushy-init > /dev/null 2>&1
pushy-status "hello" "world" > "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
2041 pushy-status "hello" "world" > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(incorrect usage): pushy-status \"hello\" \"world\""
test_command 3 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing file in 1 stage only
# --------------------------------------------------------------------------------------------------------------------------

# file in cwd only - untracked
pushy-init > /dev/null 2>&1
echo "hello" > file
pushy-status > "$MY_OUTPUT" 2>&1                # file not in repo
my_status=$?
rm -rf .pushy file

2041 pushy-init > /dev/null 2>&1
echo "hello" > file
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file

test_name="(untracked): file in cwd only"
test_command 4 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# file in index only
pushy-init > /dev/null 2>&1
echo "hello" > file
pushy-add file > /dev/null 2>&1
pushy-status > "$MY_OUTPUT" 2>&1                # added to index
rm file
pushy-status >> "$MY_OUTPUT" 2>&1               # added to index, file deleted
my_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
echo "hello" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
rm file
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy 

test_name="(added to index, file deleted): file in index only"
test_command 5 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# file in repo only
pushy-init > /dev/null 2>&1
echo "hello" > file
pushy-add file > /dev/null 2>&1
pushy-commit -m "commit 0" > /dev/null 2>&1
pushy-status > "$MY_OUTPUT" 2>&1                # file same as repo
pushy-rm file > /dev/null 2>&1
pushy-add file  >> "$MY_OUTPUT" 2>&1            # pushy-add: error: can not open 'a'
pushy-status >> "$MY_OUTPUT" 2>&1               # file deleted, deleted from index
my_status=$?
rm -rf .pushy file

2041 pushy-init > /dev/null 2>&1
echo "hello" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-commit -m "commit 0" > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
2041 pushy-rm file > /dev/null 2>&1
2041 pushy-add file >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file

test_name="(file deleted, deleted from index): file in repo only"
test_command 6 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing files in 2 stages only
# --------------------------------------------------------------------------------------------------------------------------

# file in cwd and index only
pushy-init > /dev/null 2>&1
echo "hello" > file
pushy-add file > /dev/null 2>&1
pushy-status > "$MY_OUTPUT" 2>&1                # added to index
pushy-commit -m "commit 0" >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1               # file same as repo
pushy-rm file > /dev/null 2>&1          
pushy-status >> "$MY_OUTPUT" 2>&1               # file deleted from cwd and index
pushy-commit -a -m "commit 1" >> "$MY_OUTPUT" 2>&1 
pushy-status >> "$MY_OUTPUT" 2>&1               # no output
echo "hello" > file
pushy-add file > /dev/null 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1               # added to index
my_status=$?
rm -rf .pushy file

2041 pushy-init > /dev/null 2>&1
echo "hello" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m "commit 0" >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-rm file > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -a -m "commit 1" >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
echo "hello" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file

test_name="(added to index): file in cwd and index, same"
test_command 7 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# file in cwd and index only, file changed
pushy-init > /dev/null 2>&1
touch file
pushy-add file > /dev/null 2>&1
pushy-status > "$MY_OUTPUT" 2>&1                # added to index
echo "hello" > file
pushy-status >> "$MY_OUTPUT" 2>&1               # added to index, file changed
my_status=$?
rm -rf .pushy file

2041 pushy-init > /dev/null 2>&1
touch file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
echo "hello" > file
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file

test_name="(added to index, file changed): file in cwd and index, different"
test_command 8 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# file in index and repo, file deleted from cwd 
pushy-init > /dev/null 2>&1
echo "hello" > file
pushy-add file > /dev/null 2>&1
pushy-status > "$MY_OUTPUT" 2>&1                # added to index
rm file                                         
pushy-status >> "$MY_OUTPUT" 2>&1               # added to index, file deleted 
pushy-commit -m "commit 0" >> "$MY_OUTPUT" 2>&1 
pushy-status >> "$MY_OUTPUT" 2>&1               # file deleted (not in cwd nor in index)
my_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
echo "hello" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
rm file
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m "commit 0" >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy 

test_name="(file deleted): file in index and repo - add, delete from cwd, commit"
test_command 9 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# file in index and repo, file deleted from cwd 
pushy-init > /dev/null 2>&1
echo "hello" > file
pushy-add file > /dev/null 2>&1
pushy-status > "$MY_OUTPUT" 2>&1                # added to index
pushy-commit -m "commit 0" >> "$MY_OUTPUT" 2>&1 
pushy-status >> "$MY_OUTPUT" 2>&1               # same as repo
rm file                                         
pushy-status >> "$MY_OUTPUT" 2>&1               # file deleted
pushy-commit -m "commit 1" >> "$MY_OUTPUT" 2>&1 # nothing to commit
my_status=$?
rm -rf .pushy

2041 pushy-init > /dev/null 2>&1
echo "hello" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m "commit 0" >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
rm file
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m "commit 1" >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy

test_name="(file deleted): file in index and repo - add, commit, file deleted from cwd"
test_command 10 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"


# file in cwd and repo only, file deleted from index (pushy-rm --cached) and added back to the cwd  
pushy-init > /dev/null 2>&1
echo "hello" > file
pushy-add file > /dev/null 2>&1
pushy-commit -m "commit 0" > /dev/null 2>&1
pushy-status > "$MY_OUTPUT" 2>&1                # same as repo
pushy-rm --cached file > /dev/null 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1               # deleted from index
echo "hello" > file
pushy-status >> "$MY_OUTPUT" 2>&1               # deleted from index
echo "12345" > file
pushy-status >> "$MY_OUTPUT" 2>&1               # deleted from index
pushy-add file > /dev/null 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1               # file changed, changes staged for commit
my_status=$?
rm -rf .pushy file

2041 pushy-init > /dev/null 2>&1
echo "hello" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-commit -m "commit 0" > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
2041 pushy-rm --cached file > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
echo "hello" > file
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
echo "12345" > file
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-add file > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file

test_name="(file changed, changes staged for commit): file deleted from index, added back to cwd and changed"
test_command 11 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Testing file in cwd, index and repo (all 3)
# --------------------------------------------------------------------------------------------------------------------------

echo "Testing file in cwd, index and repo (all 3 stages)"

# file same in all 3
pushy-init > /dev/null 2>&1
echo "hello" > file1
touch file2
pushy-add file1 file2 > /dev/null 2>&1
pushy-commit -m "commit 0" > "$MY_OUTPUT" 2>&1 
pushy-status >> "$MY_OUTPUT" 2>&1            # file1 and file2 same as repo
echo "world" > file1
echo "world" > file2
pushy-commit -a -m "commit 1" >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1           # file1 and file2 same as repo
my_status=$?
rm -rf .pushy file1 file2

2041 pushy-init > /dev/null 2>&1
echo "hello" > file1
touch file2
2041 pushy-add file1 file2 > /dev/null 2>&1
2041 pushy-commit -m "commit 0" > "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
echo "world" > file1
echo "world" > file2
2041 pushy-commit -a -m "commit 1" >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1 file2

test_name="(same as repo): file same in all 3 stages"
test_command 12 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# file in cwd and repo only, file deleted from index (pushy-rm --cached) and added back to the cwd  
pushy-init > /dev/null 2>&1
echo "hello" > file
pushy-add file > /dev/null 2>&1
pushy-commit -m "commit 0" > /dev/null 2>&1
pushy-status > "$MY_OUTPUT" 2>&1                # same as repo
pushy-rm --cached file > /dev/null 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1               # deleted from index
echo "hello" > file
pushy-add file > /dev/null 2>&1                 
pushy-status >> "$MY_OUTPUT" 2>&1               # same as repo
my_status=$?
rm -rf .pushy file

2041 pushy-init > /dev/null 2>&1
echo "hello" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-commit -m "commit 0" > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
2041 pushy-rm --cached file > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
echo "hello" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file

test_name="(same as repo): add, commit, file deleted from index, added back to cwd"
test_command 13 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"


# file different in cwd and index, same as repo
pushy-init > /dev/null 2>&1
echo "hello" > file
pushy-add file > /dev/null 2>&1             
pushy-commit -m "commit 0" > /dev/null 2>&1 
pushy-status > "$MY_OUTPUT" 2>&1            # file same as repo
echo "world" > file                         
pushy-add file > /dev/null 2>&1            
pushy-status >> "$MY_OUTPUT" 2>&1           # file changed, changes staged for commit
echo "abcde" > file                         
pushy-commit -m "commit 1" > /dev/null 2>&1 
pushy-status >> "$MY_OUTPUT" 2>&1           # file changed, changes not staged for commit
my_status=$?
rm -rf .pushy file

2041 pushy-init > /dev/null 2>&1
echo "hello" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-commit -m "commit 0" > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
echo "world" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
echo "abcde" > file
2041 pushy-commit -m "commit 1" > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file

test_name="(file changed, changes not staged for commit): file different in cwd and index"
test_command 14 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# file different in cwd and index, same as repo
pushy-init > /dev/null 2>&1
echo "hello" > file
pushy-add file > /dev/null 2>&1
pushy-commit -m "commit 0" > /dev/null 2>&1
pushy-status > "$MY_OUTPUT" 2>&1            # file same as repo
echo "world" > file
pushy-add file > /dev/null 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1           # file changed, changes staged for commit
my_status=$?
rm -rf .pushy file

2041 pushy-init > /dev/null 2>&1
echo "hello" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-commit -m "commit 0" > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
echo "world" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file

test_name="(file changed, changes not staged for commit): file different in cwd and index, same as repo"
test_command 15 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# file different in cwd and repo, same as index
pushy-init > /dev/null 2>&1
echo "hello" > file
pushy-add file > /dev/null 2>&1
pushy-commit -m "commit 0" > /dev/null 2>&1
pushy-status > "$MY_OUTPUT" 2>&1            # file same as repo
echo "world" > file
pushy-status >> "$MY_OUTPUT" 2>&1           # file changed, changes staged for commit
my_status=$?
rm -rf .pushy file

2041 pushy-init > /dev/null 2>&1
echo "hello" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-commit -m "commit 0" > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
echo "world" > file
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file

test_name="(file changed, changes staged for commit): file different in cwd and repo, same as index"
test_command 16 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# cwd =/= index =/= repo
pushy-init > /dev/null 2>&1
echo "hello" > file
pushy-add file > /dev/null 2>&1
pushy-commit -m "commit 0" > /dev/null 2>&1
pushy-status > "$MY_OUTPUT" 2>&1            # file same as repo
echo "world" > file
pushy-add file > /dev/null 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1           # file changed, changes staged for commit
echo "hello" > file
pushy-status >> "$MY_OUTPUT" 2>&1           # file changed, different changes staged for commit
my_status=$?
rm -rf .pushy file

2041 pushy-init > /dev/null 2>&1
echo "hello" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-commit -m "commit 0" > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
echo "world" > file
2041 pushy-add file > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
echo "hello" > file
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file

test_name="(file changed, different changes staged for commit): file different in all 3"
test_command 17 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# --------------------------------------------------------------------------------------------------------------------------
# Other tests
# --------------------------------------------------------------------------------------------------------------------------

# Multiple commits
pushy-init > /dev/null 2>&1
touch file1 file2 file3 file4
pushy-add file1 > /dev/null 2>&1
pushy-commit -m "commit 0" > /dev/null 2>&1
pushy-status > "$MY_OUTPUT" 2>&1
pushy-add file2 > /dev/null 2>&1
echo "hello" > file1
pushy-commit -a -m "commit 1" > /dev/null 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
echo "world" > file2
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-commit -a -m "commit 2" > /dev/null 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
echo "hello" > file3
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-commit -a -m "commit 3" > /dev/null 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
echo "world" > file4
pushy-status >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1 file2 file3 file4

2041 pushy-init > /dev/null 2>&1
touch file1 file2 file3 file4
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-commit -m "commit 0" > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
2041 pushy-add file2 > /dev/null 2>&1
echo "hello" > file1
2041 pushy-commit -a -m "commit 1" > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
echo "world" > file2
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -a -m "commit 2" > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
echo "hello" > file3
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -a -m "commit 3" > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
echo "world" > file4
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1 file2 file3 file4

test_name="(multiple commits): add, commit, status"
test_command 18 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"


# Test 19: file in cwd and repo, but not in index 
pushy-init > /dev/null 2>&1
touch file1 file2 file3
pushy-add file1 > /dev/null 2>&1
pushy-status > "$MY_OUTPUT" 2>&1
pushy-commit -m "commit 0" > /dev/null 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-add file2 file3 > /dev/null 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
echo "hello" > file1
echo "world" > file2
echo "abcde" > file3
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-commit -a -m "commit 1" > /dev/null 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-rm file1 >> "$MY_OUTPUT" 2>&1             # file1 in repo, but not in index nor in cwd
pushy-rm --cached file2 >> "$MY_OUTPUT" 2>&1    # file2 in repo and cwd, but not in index
rm file3                                        # file3 in repo and index, but not in cwd
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-commit -a -m "commit 2" > /dev/null 2>&1  # file3 is removed from index
pushy-status >> "$MY_OUTPUT" 2>&1               
pushy-add file1 >> "$MY_OUTPUT" 2>&1            # pushy-add: error: can not open 'file1'
pushy-add file2 >> "$MY_OUTPUT" 2>&1            
pushy-add file3 >> "$MY_OUTPUT" 2>&1            # pushy-add: error: can not open 'file3'
pushy-status >> "$MY_OUTPUT" 2>&1
touch file3
pushy-add file3 >> "$MY_OUTPUT" 2>&1            
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-commit -a -m "commit 3" >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy file1 file2 file3

2041 pushy-init > /dev/null 2>&1
touch file1 file2 file3
2041 pushy-add file1 > /dev/null 2>&1
2041 pushy-status > "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m "commit 0" > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-add file2 file3 > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
echo "hello" > file1
echo "world" > file2
echo "abcde" > file3
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -a -m "commit 1" > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-rm file1 >> "$CORRECT_OUTPUT" 2>&1           # file1 in repo, but not in index nor in cwd
2041 pushy-rm --cached file2 >> "$CORRECT_OUTPUT" 2>&1  # file2 in repo and cwd, but not in index
rm file3 # file3 in repo and index, but not in cwd
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -a -m "commit 2" > /dev/null 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1    
2041 pushy-add file1 >> "$CORRECT_OUTPUT" 2>&1 # error: can not open 'file1' (can only add files that are in cwd and repo)
2041 pushy-add file2 >> "$CORRECT_OUTPUT" 2>&1 # file2 is added to index
2041 pushy-add file3 >> "$CORRECT_OUTPUT" 2>&1 # error: can not open 'file3' 
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
touch file3
2041 pushy-add file3 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -a -m "commit 3" >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy file1 file2 file3

test_name="(deleted from index): file in cwd and repo, but not in index"
test_command 19 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 20: subset1_20
pushy-init > /dev/null 2>&1
touch a b c d e f g h 
pushy-add a b c d e f > "$MY_OUTPUT" 2>&1
pushy-commit -m "first commit" >> "$MY_OUTPUT" 2>&1
echo hello >a
echo hello >b
echo hello >c
pushy-add a b >> "$MY_OUTPUT" 2>&1
echo world >a
rm d 
pushy-rm e >> "$MY_OUTPUT" 2>&1
pushy-add g >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy a b c d e f g h
# a - file changed, different changes staged for commit
# b - file changed, changes staged for commit
# c - file changed, changes not staged for commit
# d - file deleted
# e - file deleted, deleted from index
# f - same as repo
# g - added to index
# h - untracked

2041 pushy-init > /dev/null 2>&1
touch a b c d e f g h
2041 pushy-add a b c d e f > "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m "first commit" >> "$CORRECT_OUTPUT" 2>&1
echo hello >a
echo hello >b
echo hello >c
2041 pushy-add a b >> "$CORRECT_OUTPUT" 2>&1
echo world >a
rm d
2041 pushy-rm e >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-add g >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy a b c d e f g h

test_name="(subset1_20): file changed, different changes staged for commit"
test_command 20 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"

# Test 21: subset1_22 - rm add rm show

pushy-init > /dev/null 2>&1
echo hello >a
pushy-add a > "$MY_OUTPUT" 2>&1
pushy-commit -m commit-0 >> "$MY_OUTPUT" 2>&1
pushy-rm a >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-commit -m commit-1 >> "$MY_OUTPUT" 2>&1
pushy-status >> "$MY_OUTPUT" 2>&1
echo world >a 
pushy-status >> "$MY_OUTPUT" 2>&1
pushy-commit -m commit-2 >> "$MY_OUTPUT" 2>&1
pushy-add a >> "$MY_OUTPUT" 2>&1
pushy-commit -m commit-2 >> "$MY_OUTPUT" 2>&1
pushy-rm a >> "$MY_OUTPUT" 2>&1
pushy-commit -m commit-3 >> "$MY_OUTPUT" 2>&1
pushy-show :a >> "$MY_OUTPUT" 2>&1
pushy-show 0:a >> "$MY_OUTPUT" 2>&1
pushy-show 1:a >> "$MY_OUTPUT" 2>&1
pushy-show 2:a >> "$MY_OUTPUT" 2>&1
pushy-show 3:a >> "$MY_OUTPUT" 2>&1 
pushy-show 4:a >> "$MY_OUTPUT" 2>&1
my_status=$?
rm -rf .pushy a

2041 pushy-init > /dev/null 2>&1
echo hello >a
2041 pushy-add a > "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m commit-0 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-rm a >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m commit-1 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
echo world >a
2041 pushy-status >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m commit-2 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-add a >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m commit-2 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-rm a >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-commit -m commit-3 >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show :a >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show 0:a >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show 1:a >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show 2:a >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show 3:a >> "$CORRECT_OUTPUT" 2>&1
2041 pushy-show 4:a >> "$CORRECT_OUTPUT" 2>&1
correct_status=$?
rm -rf .pushy a

test_name="(subset1_22): rm add rm show"
test_command 21 "$test_name" "$CORRECT_OUTPUT" "$MY_OUTPUT" "$correct_status" "$my_status"



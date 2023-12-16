#!/bin/bash

# check if zstd is installed
if ! command -v zstd &> /dev/null; then
    echo "zstd is not installed. Please install zstd to continue."
    echo "For Ubuntu/Debian, run the following command: sudo apt-get install zstd" 
    exit 1
fi

# Navigate to the home directory
cd

# Starting search path
START_PATH="/"

# Directory name to search for
DIR_NAME="go-quai"

# Find directories with the given name, then sort them by depth, and pick the first one
echo -e "----- Searching for go-quai directory... -----\n"
GO_QUAI_DIR=$(find "$START_PATH" -type d -name "$DIR_NAME" 2>/dev/null | awk -F'/' '{ print NF-1 " " $0 }' | sort -n | head -n 1 | cut -d' ' -f2-)
if [[ -z "$GO_QUAI_DIR" ]]; then
    echo -e "----- go-quai directory not found. Exiting... -----\n"
    echo -e "----- To fix the error, make sure to have go-quai in the home directory. -----"
    exit 1
else
    echo -e "----- Found directory: $GO_QUAI_DIR. Proceeding... ----- \n"
fi

echo -e "----- Stopping node and stratum -----\n"
pkill -9 quai-stratum
cd "$GO_QUAI_DIR"
make stop
cd
echo -e "\n----- Node and stratum stopped -----\n"

echo -e "----- Removing database and nodelogs -----\n"
rm -rf "$GO_QUAI_DIR"/nodelogs ~/.quai
echo -e "----- Database and nodelogs cleared -----\n"

FILE1_PATH=$(find "$START_PATH" -type f -name "quai_colosseum_backup" 2>/dev/null | head -n 1)
FILE2_PATH=$(find "$START_PATH" -type f -name "quai-colosseum-backup" 2>/dev/null | head -n 1)
if [[ -z "$FILE1_PATH" ]] && [[ -z "$FILE2_PATH" ]]; then
    echo -e "----- Outdated unzipped snapshot not found. Proceeding... -----\n"
else
    echo -e "----- Removing prior unzipped snapshot -----\n"
    rm -rf ~/quai_colosseum_backup ~/quai-colosseum-backup
    echo -e "----- Prior unzipped snapshot removed -----\n"
fi

FILE3_PATH=$(find "$START_PATH" -type f -name "quai_colosseum_backup.tar.gz" 2>/dev/null | head -n 1)
FILE4_PATH=$(find "$START_PATH" -type f -name "quai_colosseum_backup.tar.zst" 2>/dev/null | head -n 1)
if [[ -z "$FILE3_PATH" ]]; then
    echo -e "----- Outdated quai_colosseum_backup.tar.gz not found. Proceeding... -----\n"
else
    echo -e "----- Removing prior snapshot gzip -----\n"
    rm -rf ~/quai_colosseum_backup.tar.zst ~/quai_colosseum_backup.tar.gz
    echo -e "----- Prior snapshot gzip removed -----\n"
fi

echo -e "----- Downloading new snapshot -----\n"
wget https://archive.quai.network/quai_colosseum_backup.tar.zst
echo -e "\n----- New snapshot downloaded -----\n"

echo -e "----- Extracting new snapshot -----\n"
tar -I 'zstd -T0' -xvf quai_colosseum_backup.tar.zst
echo -e "\n----- New snapshot extracted -----\n"

echo -e "----- Coping extracted snapshot into db -----\n"
cp -r quai-colosseum-backup ~/.quai
echo -e "----- New snapshot copied into db -----\n"

echo -e "----- Pulling latest code -----\n"
cd "$GO_QUAI_DIR"
git fetch --all
NODE_LATEST_TAG=$(curl -s "https://api.github.com/repos/dominant-strategies/go-quai/tags" | jq -r '.[0].name')
git checkout "$NODE_LATEST_TAG"
echo -e "\n----- Latest code pulled -----\n"

echo -e "----- Building latest code -----\n"
make go-quai
echo -e "\n----- Latest code built -----\n"

echo -e "----- Restarting node -----\n"
make run
echo -e "\n----- Node restarted -----\n"

echo -e "----- Download script complete -----\n"
echo -e "To check your node's status, run the following command: \n"
echo -e "tail -f nodelogs/* | grep Appended\n"

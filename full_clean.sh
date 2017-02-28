#!/usr/bin/env bash
#
# Fully clean all build remnants
#


echo -e "\n\t\033[1m=== \033[36;1mCLEANING FULL BUILD STRUCTURE\033[0m \033[1m===\033[0m\n"

echo -ne " \033[33;1m*\033[0m Removing directory \"\033[36;1m./build/\033[0m\"..."
rm -rf ./build/
echo -e "\033[33;1mOK\033[0m"

echo -ne " \033[33;1m*\033[0m Removing directory \"\033[36;1m./dist/\033[0m\"..."
rm -rf ./dist/
echo -e "\033[33;1mOK\033[0m"

echo -ne " \033[33;1m*\033[0m Removing all directories ending with \"\033[36;1m.egg-info/\033[0m\"..."
rm -rf ./*.egg-info/
echo -e "\033[33;1mOK\033[0m"

echo -e "\n\t\033[1m=== \033[36;1mFULL CLEANUP COMPLETE\033[0m \033[1m===\033[0m\n"


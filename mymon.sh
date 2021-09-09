#!/bin/bash -e
# This script is an experiment to clone litecoin into a 
# brand new coin + blockchain.
# The script will perform the following steps:
# 1) create first a docker image with ubuntu ready to build and run the new coin daemon
# 2) clone GenesisH0 and mine the genesis blocks of main, test and regtest networks in the container (this may take a lot of time)
# 3) clone litecoin
# 4) replace variables (keys, merkle tree hashes, timestamps..)
# 5) build new coin
# 6) run 4 docker nodes and connect to each other
# By default the script uses the regtest network, which can mine blocks
# instantly. If you wish to switch to the main network, simply change the 
# CHAIN variable below

# change the following variables to match your new coin
COIN_NAME="mymon"
COIN_UNIT="MYM"
# 42 million lite coins at total
TOTAL_SUPPLY=1500000
MAINNET_PORT="54321"
TESTNET_PORT="54322"
PHRASE="Keka is very Deka"
# First letter of the wallet address. Check https://en.bitcoin.it/wiki/Base58Check_encoding
PUBKEY_CHAR="20"
# leave CHAIN empty for main network, -regtest for regression network and -testnet for test network
CHAIN="-regtest"

# dont change the following variables unless you know what you are doing
GENESISHZERO_REPOS=https://github.com/lhartikk/GenesisH0
LITECOIN_REPOS=https://github.com/litecoin-project/litecoin.git
LITECOIN_PUB_KEY=040184710fa689ad5023690c80f3a49c8f13f8d45b8c857fbcbc8bc4a8e4d3eb4b10f4d4604fa08dce601aaf0f470216fe1b51850b4acf21b179c45070ac7b03a9
LITECOIN_MERKLE_HASH=97ddfbbae6be97fd6cdf3e7ca13232a3afff2353e29badfab7f73011edd4ced9
LITECOIN_MAIN_GENESIS_HASH=12a765e31ffd4059bada1e25190f6e98c99d9714d334efa41a195a7e7e04bfe2
LITECOIN_TEST_GENESIS_HASH=4966625a4b2851d9fdee139e56211a0d88575f59ed816ff5e6a63deb4e3e29a0
LITECOIN_REGTEST_GENESIS_HASH=530827f38f93b43ed12af0b3ad25a288dc02ed74d6d7857862df51fc56c416f9
COIN_NAME_LOWER=${COIN_NAME,,}
COIN_NAME_UPPER=${COIN_NAME^^}
DIRNAME=$(dirname $0)
DOCKER_NETWORK="172.18.0"

if [ $DIRNAME =  "." ]; then
    DIRNAME=$PWD
fi




generate_genesis_block()
{
    if [ ! -d GenesisH0 ]; then
        git clone $GENESISHZERO_REPOS
        pushd GenesisH0
    else
        pushd GenesisH0
        git pull
    fi

    if [ ! -f ${COIN_NAME}-main.txt ]; then
        echo "Mining genesis block... this procedure can take many hours of cpu work.."
        python genesis.py -a scrypt -z $PHRASE 2>&1 | tee ${COIN_NAME}-main.txt
    else
        echo "Genesis block already mined.."
        cat ${COIN_NAME}-main.txt
    fi

    if [ ! -f ${COIN_NAME}-test.txt ]; then
        echo "Mining genesis block of test network... this procedure can take many hours of cpu work.."
        python genesis.py  -t 1486949366 -a scrypt -z $PHRASE 2>&1 | tee ${COIN_NAME}-test.txt
    else
        echo "Genesis block already mined.."
        cat ${COIN_NAME}-test.txt
    fi

    if [ ! -f ${COIN_NAME}-regtest.txt ]; then
        echo "Mining genesis block of regtest network... this procedure can take many hours of cpu work.."
        python genesis.py -t 1296688602 -b 0x207fffff -n 0 -a scrypt -z $PHRASE 2>&1 | tee ${COIN_NAME}-regtest.txt
    else
        echo "Genesis block already mined.."
        cat ${COIN_NAME}-regtest.txt
    fi


    popd
}
generate_genesis_block
#export GOERIL_HOST_ADDR=0x22ff293e14F1EC3A09B137e9e06084AFd63adDF9
#export GOERIL_RPC=https://ethereum-goerli-rpc.allthatnode.com
#export GOERIL_FDAIX=0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00

export MUMBAI_HOST_ADDR=0xEB796bdb90fFA0f28255275e16936D25d3418603
export MUMBAI_FDAIX_ADDR=0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f
export MUMBAI_RPC=https://matic-mumbai.chainstacklabs.com
forge create --rpc-url $MUMBAI_RPC --private-key $PRIVATE_KEY FlowSender --constructor-args $MUMBAI_HOST_ADDR $MUMBAI_FDAIX_ADDR

# shellcheck disable=SC2046
cast send 0x9afF42d99b711c830873eE726F9e6FfC7B69CDa3 "gainDaiX()" --rpc-url $MUMBAI_RPC --private-key $PRIVATE_KEY --gas-limit $(cast estimate 0x9afF42d99b711c830873eE726F9e6FfC7B69CDa3 "gainDaiX()" --rpc-url $MUMBAI_RPC --private-key $PRIVATE_KEY + 10000)

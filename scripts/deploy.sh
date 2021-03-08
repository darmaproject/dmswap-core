echo "deploy begin....."

mkdir -p ./deployments

TF_CMD=node_modules/.bin/truffle-flattener

echo "" >  ./deployments/DMSwapV2Factory.full.sol
cat  ./scripts/head.sol >  ./deployments/DMSwapV2Factory.full.sol
$TF_CMD ./contracts/DMSwapV2Factory.sol >>  ./deployments/DMSwapV2Factory.full.sol


echo "" >  ./deployments/DMSwapV2Pair.full.sol
cat  ./scripts/head.sol >  ./deployments/DMSwapV2Pair.full.sol
$TF_CMD ./contracts/DMSwapV2Pair.sol >>  ./deployments/DMSwapV2Pair.full.sol

echo "deploy end....."
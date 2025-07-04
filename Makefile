-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil zktest

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit && forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit
install :; 	
	forge install foundry-rs/forge-std --no-commit && \
	forge install openzeppelin/openzeppelin-contracts@v5.3.0 --no-commit && \
	forge install smartcontractkit/chainlink-brownie-contracts --no-commit && \
	forge install cyfrin/foundry-devops@0.2.2 --no-commit

install-git :; 	
	forge install foundry-rs/forge-std && \
	forge install openzeppelin/openzeppelin-contracts@v5.3.0 && \
	forge install smartcontractkit/chainlink-brownie-contracts && \
	forge install cyfrin/foundry-devops@0.2.2

# Update Dependencies
update:; forge update

build:; forge build --sizes src/

test :; forge test 

zktest :; foundryup-zksync && forge test --zksync && foundryup

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

lcov :; forge coverage --report lcov

coverage :; forge coverage

# NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

# ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
# 	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
# endif

# deploy:
# 	@forge script script/DeployBasicNft.s.sol:DeployBasicNft $(NETWORK_ARGS)

# mint:
# 	@forge script script/Interactions.s.sol:MintBasicNft ${NETWORK_ARGS}

# deployMood:
# 	@forge script script/DeployMoodNft.s.sol:DeployMoodNft $(NETWORK_ARGS)

# mintMoodNft:
# 	@forge script script/Interactions.s.sol:MintMoodNft $(NETWORK_ARGS)

# flipMoodNft:
# 	@forge script script/Interactions.s.sol:FlipMoodNft $(NETWORK_ARGS)

# zkdeploy: 
# 	@forge create src/OurToken.sol:OurToken --rpc-url http://127.0.0.1:8011 --private-key $(DEFAULT_ZKSYNC_LOCAL_KEY) --legacy --zksync
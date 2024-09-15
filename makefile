
-include .env

ifeq ($(network),sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --broadcast --verify -vvvv 
	CHAIN_ID := 11155111	
endif

ifeq ($(network),ethereum)
	NETWORK_ARGS := --rpc-url $(ETHEREUM_RPC_URL) --broadcast --verify -vvvv 
	CHAIN_ID := 1	
endif

ifeq ($(network),amoy)
	EXPLORER_API_KEY := --etherscan-api-key $(POLYGONSCAN_API_KEY) --verifier-url https://api-amoy.polygonscan.com/api
	NETWORK_ARGS := --rpc-url $(AMOY_RPC_URL) $(EXPLORER_API_KEY) --broadcast --verify -vvvv
	CHAIN_ID := 80002
endif

ifeq ($(network),polygon)
	EXPLORER_API_KEY := --etherscan-api-key $(POLYGONSCAN_API_KEY) --verifier-url https://api.polygonscan.com/api
	NETWORK_ARGS := --rpc-url $(POLYGON_RPC_URL) $(EXPLORER_API_KEY) --broadcast --verify -vvvv 
	CHAIN_ID := 137	
endif


ifneq ($(constructor_signature),)
	CONSTRUCTOR_COMMAND := $(shell cast abi-encode "$(constructor_signature)" $(input_parameters))
	VERIFY_COMMAND := $(contract_address) $(contract) --chain-id $(CHAIN_ID) --constructor-args $(CONSTRUCTOR_COMMAND) $(EXPLORER_API_KEY) --watch
else
	VERIFY_COMMAND := $(contract_address) $(contract) --chain-id $(CHAIN_ID) $(EXPLORER_API_KEY) --watch
endif 


run_test:;
	@forge test --fork-url $(SEPOLIA_RPC_URL) -vvvv

run_coverage:;
	@forge coverage --mp "test/unit/*" --report lcov

coverage_report:;
	@genhtml lcov.info --branch-coverage --output-dir coverage

deploy:;
	@forge script script/Deploy.s.sol $(NETWORK_ARGS)

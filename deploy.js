import { readFileSync, writeFileSync } from 'fs';
import { ethers } from 'ethers';

// Private key is injected by platform into .deployer-env.json before deploy runs
const { DEPLOYER_PRIVATE_KEY } = JSON.parse(readFileSync('.deployer-env.json', 'utf8'));
const PRIVATE_KEY  = DEPLOYER_PRIVATE_KEY;
const RPC          = 'https://mainnet.base.org';
const CHAIN_ID     = 8453;
const NETWORK_NAME = 'Base';

async function main() {
  console.log(`Connecting to ${NETWORK_NAME}...`);
  const provider = new ethers.JsonRpcProvider(RPC, CHAIN_ID);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

  console.log(`Deploying from address: ${wallet.address}`);

  const abi = JSON.parse(readFileSync('build/DegenGame.abi.json', 'utf8'));
  const bytecode = JSON.parse(readFileSync('build/DegenGame.bytecode.json', 'utf8'));

  const factory = new ethers.ContractFactory(abi, bytecode, wallet);
  
  console.log('Sending deployment transaction...');
  const contract = await factory.deploy();
  await contract.waitForDeployment();

  const contractAddress = await contract.getAddress();
  console.log(`DegenGame deployed successfully to: ${contractAddress}`);

  const deploymentInfo = {
    contractAddress,
    network: NETWORK_NAME,
    chainId: CHAIN_ID,
    deployedAt: new Date().toISOString()
  };

  writeFileSync('deployment-info.json', JSON.stringify(deploymentInfo, null, 2));
  console.log('Deployment info saved to deployment-info.json');
}

main().catch((error) => {
  console.error('Deployment failed:', error);
  process.exit(1);
});

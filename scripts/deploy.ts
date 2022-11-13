import { ethers } from "hardhat"

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Token = await ethers.getContractFactory("NFTLocker");
  const token = await Token.deploy(["0x845a007D9f283614f403A24E3eB3455f720559ca"]); // arg:target contract address
  console.log("Token address:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })

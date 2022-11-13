import { Signer } from "ethers";
import { ethers } from "hardhat";

export const deploy = async (owner: Signer) => {
    const TestNFTcollection = await ethers.getContractFactory("TestNFTcolleciton")
    const testNFT = await TestNFTcollection.connect(owner).deploy()
    await testNFT.deployed()
  
    const NFTLocker = await ethers.getContractFactory("NFTLocker")
    const nftLocker = await NFTLocker.connect(owner).deploy(testNFT.address)
    await nftLocker.deployed()
  
    return { testNFT, nftLocker }
  }
  
  export default deploy
import { loadFixture, time, mine } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { deploy } from "./deploy";

describe("NFTLocker", function () {
  const fixture = async () => {
    const [owner, admin, account, ...others] = await ethers.getSigners()
    const contracts = await deploy(owner)

    return { ...contracts, owner, admin, account, others }
  }

  describe("integration", () => {
    it("deposit→withdraw", async () => {
      const { testNFT, nftLocker,owner, account,others } = await loadFixture(fixture)
      const [minter1, minter2, minter3] = others
      await testNFT.connect(owner).pause(false)
      await testNFT.connect(account).mint(3, { value: ethers.utils.parseEther("1") });
      await testNFT.connect(minter1).mint(3, { value: ethers.utils.parseEther("1") });

      await testNFT.connect(account).setApprovalForAll(nftLocker.address,true)
      await testNFT.connect(minter1).setApprovalForAll(nftLocker.address,true)
      
      let blockNum = await ethers.provider.getBlockNumber();
      let block = await ethers.provider.getBlock(blockNum);
      let timestamp = block.timestamp;

      // deposit     
      await expect(nftLocker.connect(account).deposit(1))
        .to.emit(nftLocker, 'StartLock')
        .withArgs(account.address,1,1,timestamp+1)

      await expect(nftLocker.connect(account).deposit(3))
        .to.emit(nftLocker, 'StartLock')
        .withArgs(account.address,2,3,timestamp+2)

      await expect(nftLocker.connect(account).deposit(4))
      .to.be.revertedWith("You are not the owner of NFT.")

      await expect(nftLocker.connect(minter1).deposit(4))
        .to.emit(nftLocker, 'StartLock')
        .withArgs(minter1.address,3,4,timestamp+4)

      // owner check
      expect(await  testNFT.connect(account).ownerOf(1))
        .to.equal(nftLocker.address)
      expect(await  testNFT.connect(account).ownerOf(3))
        .to.equal(nftLocker.address)
      expect(await  testNFT.connect(account).ownerOf(4))
        .to.equal(nftLocker.address)
      
      // tokensOfOwner
      expect(await nftLocker.connect(account).tokensOfOwner(account.address))
      .to.deep.equals([1, 2])
      expect(await nftLocker.connect(account).tokensOfOwner(minter1.address))
      .to.deep.equals([3])

      // tokenURI
      expect(await nftLocker.connect(account).tokenURI(1))
      .to.equals('https://test.com/json/1.json')
      expect(await nftLocker.connect(account).tokenURI(2))
      .to.equals('https://test.com/json/3.json')
      expect(await nftLocker.connect(account).tokenURI(3))
      .to.equals('https://test.com/json/4.json')

      // sbt
      await expect(nftLocker.connect(account).transferFrom(account.address,minter1.address,1))
        .to.be.reverted
      await expect(nftLocker.connect(account).setApprovalForAll(minter1.address,true))
        .to.be.reverted
      await expect(nftLocker.connect(account).approve(minter1.address,1))
        .to.be.reverted

      // withdraw
      await expect(nftLocker.connect(minter1).withdraw(1))
      .to.be.revertedWith("You are not the owner of NFT(SBT).")

      await expect(nftLocker.connect(account).withdraw(1))
        .to.emit(nftLocker, 'EndLock')
        .withArgs(account.address,1,1,timestamp+9)

      await expect(nftLocker.connect(minter1).withdraw(3))
        .to.emit(nftLocker, 'EndLock')
        .withArgs(minter1.address,3,4,timestamp+10)

      // owner check
      expect(await  testNFT.connect(account).ownerOf(1))
        .to.equal(account.address)
      expect(await  testNFT.connect(account).ownerOf(4))
        .to.equal(minter1.address)

      // tokensOfOwner
      expect(await nftLocker.connect(account).tokensOfOwner(account.address))
      .to.deep.equals([2])

      expect(await nftLocker.connect(account).tokenURI(2))
      .to.equals('https://test.com/json/3.json')
      expect(await nftLocker.connect(account).tokensOfOwner(minter1.address))
      .to.deep.equals([])
    })
  })

  describe("supportsInterfaces", () => {
    it("ERC721", async () => {
      const { nftLocker } = await loadFixture(fixture)
      expect(await nftLocker.supportsInterface("0x80ac58cd")).to.be.true
    })
    it("ERC721Metadata", async () => {
      const { nftLocker } = await loadFixture(fixture)
      expect(await nftLocker.supportsInterface("0x5b5e139f")).to.be.true
    })
    it("ERC165", async () => {
      const { nftLocker } = await loadFixture(fixture)
      expect(await nftLocker.supportsInterface("0x01ffc9a7")).to.be.true
    })
  })

})
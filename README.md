# NFTLocker

External smart contracts for NFT locks.
Pull requests are accepted from all web3 engineers!!

# Why

We would like to create a mechanism to retrofit the NFT locking function.

# How

- Specify the contract address you want to target when deploying.
- Setapprovalforall NFTlocker contracts for the NFT contract you want to deposit.
- Holder passes tokenID to deposit function
- NFTs are deposited in the NFTlocker and NFTs (SBTs) with the same picture are sent to the wallet. (like a certificate of deposit).
- When withdrawing, put the NFTlocker tokenID in the withdraw function and it will be returned. The certificate of deposit will be burned.


### Japanese
- 対象にしたいコントラクトアドレスをデプロイ時に指定する
- 預けたいNFTのコントラクトに対して、NFTlockerのコントラクトをsetapprovalforallする
- ホルダーがdeposit関数にtokenIDを渡す
- NFTはNFTlockerに預けられて、同じ絵柄のNFT（SBT）がウォレットに送られてくる。（預かり証みたいな感じ）
- 引き出すときは、withdraw関数にNFTlockerのtokenIDを入れると返してくれる。預かり証はバーンされる。

# Target Contracts

contracts>NFTLocker.sol

That's all.
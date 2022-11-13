// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface INFTCollection {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function safeTransferFrom(address from,address to,uint256 tokenId) external payable;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
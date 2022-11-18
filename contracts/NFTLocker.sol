// SPDX-License-Identifier: MIT
// Thanks to Keisuke OHNO, a great engineer
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interface/INFTCollection.sol";

contract NFTLockerCore is Ownable{
    address public  developerAddress = 0x6A1Ebf8f64aA793b4113E9D76864ea2264A5d482;
    address public TARGET_CONTRACT_ADDRESS;
    bytes32 internal constant ADMIN = keccak256("ADMIN");
    mapping(uint256 => address) SBTTokenIdByholder;
    mapping(uint256 => uint256) SBTTokenIdByTokenId;
    uint256 public sbtNextIndex = 0;
    bool public isSBT = true;

    INFTCollection NFTCollection;

    event StartLock(address indexed holder,
        uint256 indexed sbtTokenId,uint256 indexed originalTokenId, uint256 startTime);
    event EndLock(address indexed holder,
        uint256 indexed sbtTokenId,uint256 indexed originalTokenId, uint256 endTime);
}

abstract contract NFTLockeradmin is NFTLockerCore,AccessControl,ERC721Holder,ERC721Enumerable{
    function supportsInterface(bytes4 interfaceId) public view virtual 
        override(AccessControl,ERC721Enumerable) returns (bool) {
        return
        interfaceId == type(IAccessControl).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    // modifier
    modifier onlyAdmin() {
        require(hasRole(ADMIN, msg.sender), "You are not authorized.");
        _;
    }

    // onlyOwner
    function setAdminRole(address[] memory admins) external onlyOwner{
        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(ADMIN, admins[i]);
        }
    }

    function revokeAdminRole(address[] memory admins) external onlyOwner{
        for (uint256 i = 0; i < admins.length; i++) {
            _revokeRole(ADMIN, admins[i]);
        }
    }

    // function setCollection(address _address) external onlyAdmin{
    //     NFTCollection = INFTCollection(_address);
    // }

    function setIsSBT(bool _state) external onlyAdmin {
       isSBT = _state;
    }

    function setDeveloperAddress(address _address) external onlyAdmin {
       developerAddress = _address;
    }

    function donationWithdraw() external onlyAdmin {
        (bool os, ) = payable(developerAddress).call{value: address(this).balance}("");
        require(os);
    }
}

contract NFTLocker is NFTLockeradmin{
    // constructor() ERC721("NFT Locker" , "NFTL"){
    // }
    constructor(address _address) ERC721("NFT Locker" , "NFTL"){
        TARGET_CONTRACT_ADDRESS = _address;
        NFTCollection = INFTCollection(TARGET_CONTRACT_ADDRESS);

        _setRoleAdmin(ADMIN, ADMIN);
        _setupRole(ADMIN, msg.sender);  // set owner as admin
    }

    // ==========================================================================
    // Locker session
    // ==========================================================================
    // external
    //function deposit(address _contractAddress , uint256 _tokenId )external{
    function deposit(uint256 _originalTokenId)external{
        require(NFTCollection.ownerOf(_originalTokenId) == msg.sender, "You are not the owner of NFT.");

        // deposit
        NFTCollection.safeTransferFrom(msg.sender, address(this) , _originalTokenId);

        // receipt
        sbtNextIndex++;
        SBTTokenIdByTokenId[sbtNextIndex] = _originalTokenId;
        SBTTokenIdByholder[sbtNextIndex] = msg.sender;
        _safeMint(msg.sender, sbtNextIndex );
        emit StartLock(msg.sender,sbtNextIndex,_originalTokenId,block.timestamp);
    }

    function withdraw(uint256 _sbtTokenId )external payable{
        require(ownerOf(_sbtTokenId) == msg.sender, "You are not the owner of NFT(SBT)." );
        uint256 _originalTokenId = SBTTokenIdByTokenId[_sbtTokenId];

        // withdraw
        NFTCollection.safeTransferFrom(address(this),msg.sender,_originalTokenId);
        SBTTokenIdByholder[_sbtTokenId] = address(0);
        _burn(_sbtTokenId);
        emit EndLock(msg.sender,_sbtTokenId,_originalTokenId,block.timestamp);
    }

    // ==========================================================================
    // view session
    // ==========================================================================
    function thisaddress()external view returns(address){
        return address(this);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalToken = sbtNextIndex;
            uint256 resultIndex = 0;

            for(uint256 tokenId = 1; tokenId <= totalToken; tokenId++) {
                if(SBTTokenIdByholder[tokenId] == _owner){
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    // override
    function tokenURI(uint256 _sbtTokenId) public view override returns (string memory) {
        return NFTCollection.tokenURI(SBTTokenIdByTokenId[_sbtTokenId]);
    }

    // ==========================================================================
    // sbt session
    // ==========================================================================
    function _beforeTokenTransfer( address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override{
        require( isSBT == false || from == address(0) || to == address(0), "transfer is prohibited");
        super._beforeTokenTransfer(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(IERC721,ERC721) {
        require( isSBT == false , "setApprovalForAll is prohibited");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public virtual override(IERC721,ERC721) {
        require( isSBT == false , "approve is prohibited");
        super.approve(to, tokenId);
    }
}
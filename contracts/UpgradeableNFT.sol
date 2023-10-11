// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./utils/TransferHelper.sol";

/// @custom:security-contact snowpear@snowpear.com
contract SnowpearNFT_V1 is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC721PausableUpgradeable, AccessControlUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINTER_ROLE   = keccak256("MINTER_ROLE");
    
    /// @custom:storage-location snowpear.storage.SnowpearNFTStorage_V1
    struct SnowpearNFTStorage_V1 {
        string _baseTokenURI;
    }

    // keccak256(abi.encode(uint256(keccak256("snowpear.storage.SnowpearNFTStorage_V1")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SnowpearNFTStorageLocation_V1 = 0x8d7339b6db4fc51a7c5628cf2d22bc6698cbbb4c83673fa92478550d90e47f00;

    function _getSnowpearNFTStorage_V1() private pure returns (SnowpearNFTStorage_V1 storage $) {
        assembly {
            $.slot := SnowpearNFTStorageLocation_V1
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // 0x8129fc1c
    function initialize() initializer public virtual {
        __ERC721_init("SnowpearNFT", "EST");

        __ERC721URIStorage_init();
        __ERC721Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
        __ERC721Enumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(OPERATOR_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());

    }

    function pause() public onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId, string memory uri) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function setBaseURI(string memory baseURI) public onlyRole(OPERATOR_ROLE) {
        SnowpearNFTStorage_V1 storage $ = _getSnowpearNFTStorage_V1();
        $._baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory){
        SnowpearNFTStorage_V1 storage $ = _getSnowpearNFTStorage_V1();
        return $._baseTokenURI;
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address) internal virtual override onlyRole(OPERATOR_ROLE) {}
}

contract SnowpearNFT_V2 is SnowpearNFT_V1{
    
    /// @custom:storage-location snowpear.storage.SnowpearNFTStorage_V2
    struct SnowpearNFTStorage_V2 {
        address _mintFeeAddr;
    }

    // keccak256(abi.encode(uint256(keccak256("snowpear.storage.SnowpearNFTStorage_V2")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SnowpearNFTStorageLocation_V2 = 0xef35e773039f786ad801f9f0a9b74dc19874929234bbfa673b033f12e86a9e00;

    event MintFeeAddressTransfered(address indexed previousOwner, address indexed newOwner);
    function _getSnowpearNFTStorage_V2() private pure returns (SnowpearNFTStorage_V2 storage $) {
        assembly {
            $.slot := SnowpearNFTStorageLocation_V2
        }
    }

    error InvalidMintFeeAddrOwner();

    modifier onlyMintFeeAddr() {
        _checkMintFeeAddr();
        _;
    }

    function _checkMintFeeAddr() internal view  {
        SnowpearNFTStorage_V2 storage $ = _getSnowpearNFTStorage_V2();
        if($._mintFeeAddr != _msgSender()){
            revert InvalidMintFeeAddrOwner();
        }
    }

    // 0x8129fc1c
    function initialize() reinitializer(2) public override  {
        SnowpearNFTStorage_V2 storage $ = _getSnowpearNFTStorage_V2();
        $._mintFeeAddr = _msgSender();
    }

    function withdrawETH(uint256 amount) public onlyRole(OPERATOR_ROLE){
        SnowpearNFTStorage_V2 storage $ = _getSnowpearNFTStorage_V2();
		TransferHelper.safeTransferETH($._mintFeeAddr, amount);
	}

    function transferMintFeeAddress(address _mintFeeAddr) public onlyMintFeeAddr{
        SnowpearNFTStorage_V2 storage $ = _getSnowpearNFTStorage_V2();
        $._mintFeeAddr = _mintFeeAddr;
        emit MintFeeAddressTransfered(_msgSender(), _mintFeeAddr);
    }
}
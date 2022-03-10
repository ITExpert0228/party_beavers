// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract PartyBeaverUpgradeable is ERC721Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    mapping (uint256 => TokenMeta) private _tokenMeta;

    string baseURI;
    uint256 private pricePBT;
    address seller;
    uint256 maxSupply;
    bool isSaleActive;

    struct TokenMeta {
        uint256 id;
        uint256 price;
        bool sale;
    }

    function initialize() public initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        ERC721Upgradeable.__ERC721_init("PartyBeaver", "PartyBeaver");
        setBaseURI("http://partybeavers.io:8080/token/");
        pricePBT = 41000000000000000; // 0.041 ether
        seller = 0x14b11f28F3b47a3e04beA9dAA557A7e93448F8e0;
        maxSupply = 9055;
        isSaleActive = false;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view override virtual returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public virtual onlyOwner {
        baseURI = _newBaseURI;
    }
    
    /**
     * @dev Token Seller Address for receiving payment.
     * in child contracts.
     */
    function _seller() internal view returns (address) {
        return seller;
    }

    /**
     * @dev Ready Mint Flag for starting Sales.
     * in child contracts.
     */
    function _isSaleActive() internal view returns (bool) {
        return isSaleActive;
    }

    function setSaleActive(bool _newisSaleActive) public onlyOwner {
        isSaleActive = _newisSaleActive;
    }
    
    /**
     * @dev Max Tokens Supply for minting tokens.
     * in child contracts.
     */
    function totalSupply() external  view returns (uint256) {
        return maxSupply;
    }
    
    function _maxSupply() internal view returns (uint256) {
        return maxSupply;
    }

    function setMaxSupply(uint256 _newSupply) public onlyOwner {
        maxSupply = _newSupply;
    }
    

    function getAllOnSale () public view virtual returns( TokenMeta[] memory ) {
        TokenMeta[] memory tokensOnSale = new TokenMeta[](_tokenIds.current());
        uint256 counter = 0;

        for(uint i = 1; i < _tokenIds.current() + 1; i++) {
            if(_tokenMeta[i].sale == true) {
                tokensOnSale[counter] = _tokenMeta[i];
                counter++;
            }
        }
        return tokensOnSale;
    }

    /**
     * @dev sets maps token to its price
     * @param _tokenId uint256 token ID (token number)
     * @param _sale bool token on sale
     * @param _price unit256 token price
     * 
     * Requirements: 
     * `tokenId` must exist
     * `price` must be more than 0
     * `owner` must the msg.owner
     */
    function setTokenSale(uint256 _tokenId, bool _sale, uint256 _price) public {
        require(_exists(_tokenId), "Sale set of Non Existent Token");
        require(_price > 0, "Price for sale needs to bigger than 0 ether");
        require(ownerOf(_tokenId) == _msgSender());

        _tokenMeta[_tokenId].sale = _sale;
        setTokenPrice(_tokenId, _price);
    }

    /**
     * @dev sets maps token to its price
     * @param _tokenId uint256 token ID (token number)
     * @param _price uint256 token price
     * 
     * Requirements: 
     * `tokenId` must exist
     * `owner` must the msg.owner
     */
    function setTokenPrice(uint256 _tokenId, uint256 _price) public {
        require(_exists(_tokenId), "Price set of Non Existent token");
        require(ownerOf(_tokenId) == _msgSender());
        _tokenMeta[_tokenId].price = _price;
    }

    function tokenPrice(uint256 tokenId) public view virtual returns (uint256) {
        require(_exists(tokenId), "Price query for Non Existent token");
        return _tokenMeta[tokenId].price;
    }

    function tokenMintedCount() public view virtual returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev sets token meta
     * @param _tokenId uint256 token ID (token number)
     * @param _meta TokenMeta 
     * 
     * Requirements: 
     * `tokenId` must exist
     * `owner` must the msg.owner
     */
    function _setTokenMeta(uint256 _tokenId, TokenMeta memory _meta) private {
        require(_exists(_tokenId));
        _tokenMeta[_tokenId] = _meta;
    }

    function tokenMeta(uint256 _tokenId) public view returns (TokenMeta memory) {
        require(_exists(_tokenId), "Meta data query for Non Existent token");
        return _tokenMeta[_tokenId];
    }

    /**
     * @dev purchase _tokenId
     * @param _tokenId uint256 token ID (token number)
     */
    function purchaseToken(uint256 _tokenId) external payable nonReentrant {
        require(msg.sender != address(0) && msg.sender != ownerOf(_tokenId), "Invalid sender");
        require(msg.value >= _tokenMeta[_tokenId].price, "Price needs to bigger than token's price");
        require(_tokenMeta[_tokenId].sale == true, "The token is not sale now.");
        require(isSaleActive == true, "Minting is coming soon.");
        
        address tokenSeller = ownerOf(_tokenId);

        payable(tokenSeller).transfer(msg.value);

        setApprovalForAll(tokenSeller, true);
        _transfer(tokenSeller, msg.sender, _tokenId);
        _tokenMeta[_tokenId].sale = false;
    }

    function mintToken() external payable nonReentrant returns (uint256) {
        require(seller != address(0));
        require(msg.sender != address(0), "Invalid sender");
        require(msg.value >= pricePBT, "Price for sale needs to bigger than 0.01 ether");
        require(_tokenIds.current() < maxSupply, "All tokens are already minted.");
        require(isSaleActive == true, "Minting is not available now.");

        payable(seller).transfer(msg.value);
        setApprovalForAll(seller, true);
        
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);

        TokenMeta memory meta = TokenMeta(newItemId, pricePBT, false);
        _setTokenMeta(newItemId, meta);
        
        return newItemId;
    }
    
    function mintAdmin(address _to, uint256 _count)
        external 
        onlyOwner
    {
        uint256 supply = _maxSupply();
        uint256 currentid = _tokenIds.current();
        require(_to != address(0), "Invalid receiver");
        require( currentid + _count < supply, "Exceeds maximum supply");
        
        for (uint256 i; i < _count; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(payable(_to), newItemId);
    
            TokenMeta memory meta = TokenMeta(newItemId, pricePBT, true);
            _setTokenMeta(newItemId, meta);
        }
    }    
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Concat.sol";


/********************************************************************************************/
/*                                          Ownable                                         */
/********************************************************************************************/
contract Ownable {
    address private _owner;


    event OwnershipTransferred(address);


    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(_owner);
    }


    modifier onlyOwner() {
        require(_owner == msg.sender, "NOT OWNER");
        _;
    }


    function checkOwner() public view returns(address){
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(address(newOwner) != address(0), "ERROR: ADDRESS ENTERED IS NOT VALID");
        _owner = newOwner;

        emit OwnershipTransferred(_owner);
    }
}


/********************************************************************************************/
/*                                         Pausable                                         */
/********************************************************************************************/
contract Pausable is Ownable {
    bool private _paused;
    

    event Paused(address);
    event Unpaused(address);


    constructor () {
        _paused = false;

        emit Paused(msg.sender);
    }

    modifier whenNotPaused() {
        require(_paused, "CONTRACT IS PAUSED");
        _;
    }

    modifier paused() {
        require(_paused == false, "CONTRACT IS NOT PAUSED");
        _;
    }


    function checkStatus() public view returns(bool){
        return _paused;
    }

    function unpause() public paused() onlyOwner() {
        _paused = true;

        emit Unpaused(msg.sender);
    }

    function pause() public whenNotPaused() onlyOwner() {
        _paused = false;

        emit Paused(msg.sender);
    }
}


/********************************************************************************************/
/*                                          ERC165                                          */
/*                            https://eips.ethereum.org/EIPS/eip-165                        */
/********************************************************************************************/
contract ERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    /*
     * 0x01ffc9a7 ===
     *     bytes4(keccak256('supportsInterface(bytes4)'))
     */

    mapping(bytes4 => bool) private _supportedInterfaces;


    constructor () {
        _registerInterface(_INTERFACE_ID_ERC165);
    }


    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}


/********************************************************************************************/
/*                               ERC721 (NON FUNGIBLE TOKEN)                                */
/********************************************************************************************/
contract ERC721 is Pausable, ERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    
    mapping (uint256 => address) private _tokenOwner;
    
    mapping (uint256 => address) private _tokenApprovals;
    
    mapping (address => Counters.Counter) private _ownedTokensCount;
    
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;


    constructor () {
        _registerInterface(_INTERFACE_ID_ERC721);
    }


    function balanceOf(address owner) public view returns (uint256) {
        return Counters.current(_ownedTokensCount[owner]);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _tokenOwner[tokenId];
    }

    function approve(address to, uint256 tokenId) public {
        require(to != ownerOf(tokenId), "ERROR: ADDRESS ALREADY THE OWNER OF THE TOKEN");
        require(ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "ERROR: CALLER IS NOT TOKEN OWNER");

        _tokenApprovals[tokenId] = to;

        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERROR: TOKEN ENTERED DOESN'T EXIST" );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        
        _operatorApprovals[msg.sender][to] = approved;

        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) virtual internal {
        require(!_exists(tokenId), "ERROR: TOKEN ENTERED ALREADY EXISTS");
        require(to != address(0) && !to.isContract(), "ERROR: ADDRESS ENTERED IS NOT VALID");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(msg.sender, to, tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) virtual internal {
        require(_exists(tokenId), "ERROR: TOKEN ENTERED DOESN'T EXIST" );
        
        require(ownerOf(tokenId) == from, "ERROR: 'FROM' ADDRESS IS NOT OWNER OF THE TOKEN");
        
        require(address(to) != address(0), "ERROR: 'TO' ADDRESS IS NOT VALID");


        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();
        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}


/********************************************************************************************/
/*                               ERC721Enumerable
FKDLAKL;SA
/********************************************************************************************/
contract ERC721Enumerable is ERC165, ERC721 {
    mapping(address => uint256[]) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    /*
     * 0x780e9d63 ===
     *     bytes4(keccak256('totalSupply()')) ^
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
     *     bytes4(keccak256('tokenByIndex(uint256)'))
     */

    constructor () {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return _allTokens[index];
    }

    function _transferFrom(address from, address to, uint256 tokenId) override internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) override internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        //**uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        //**_ownedTokens[from].length--;
        _ownedTokens[from].pop();

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        //**uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        _allTokens.pop();
        _allTokensIndex[tokenId] = 0;
    }
}

contract ERC721Metadata is ERC721Enumerable {//, usingOraclize {

    string private _name;
    string private _symbol;
    string private _baseTokenURI; 

    mapping(uint256 => string) private _tokenURIs;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    /*
     * 0x5b5e139f ===
     *     bytes4(keccak256('name()')) ^
     *     bytes4(keccak256('symbol()')) ^
     *     bytes4(keccak256('tokenURI(uint256)'))
     */


    constructor (string memory name, string memory symbol, string memory baseTokenURI) {
        _name = name;
        _symbol = symbol;
        _baseTokenURI = baseTokenURI;

        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function getName() external view returns(string memory) {
        return _name;
    }

    function getSymbol() external view returns(string memory) {
        return _symbol;
    }

    function getBaseTokenURI() external view returns(string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }

    function setTokenURI(uint256 tokenId) internal {
        require(_exists(tokenId), "ERROR: TOKEN ENTERED DOESN'T EXIST");
        _tokenURIs[tokenId] = Concat.strConcat(_baseTokenURI, Strings.toString(tokenId));
    }

}


contract REERC721Token is ERC721Metadata("REToken", "RST", "https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/") {

    function mint(address to, uint256 tokenId) public onlyOwner whenNotPaused returns (bool){
        super._mint(to, tokenId);
        setTokenURI(tokenId);
        return true;
    }
}
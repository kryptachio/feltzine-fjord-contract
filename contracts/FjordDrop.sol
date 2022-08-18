// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

//OpenZeppelin
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
//AlchemistCoin
import "@alchemist.wtf/token-extensions/contracts/Erc721BurningErc20OnMint.sol";

/*//////////////////////////////////////////////////////////////
                        ERRORS
//////////////////////////////////////////////////////////////*/

error FJORD_TotalMinted();
error FJORD_InsufficientPayment();
error FJORD_MaxMintPerWhitelistWallet();
error FJORD_WhitelistMaxSupplyExceeded();

/**
 @title Fjord x FeltZine
 @notice Fjord x FeltZine drops are a collaboration between FeltZine and Copper
 @author javvvs.eth
 */

contract FjordDrop is Erc721BurningErc20OnMint, ReentrancyGuard, IERC2981 {

/*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
//////////////////////////////////////////////////////////////*/

    uint16 public mintCounter = 1;
    uint16 public constant MAX_SUPPLY = 100;
    string public customBaseURI;
    address private payThroughSplits =
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    bytes32 public whiteListSaleMerkleRoot;
    uint256 private constant PRICE_PER_WHITELIST_NFT = 0.02 ether;
    uint32 private constant MAX_MINT_PER_WHITELIST_WALLET = 2;
    uint32 private constant WHITELIST_SUPPLY = 20;
    uint16 public whitelistCounter;
    mapping(address => uint256) public mintPerWhitelistedWallet;
    mapping(address => bool) whiteListClaims;

/*//////////////////////////////////////////////////////////////
                        INIT/CONSTRUCTOR
//////////////////////////////////////////////////////////////*/

    /// @notice Initialize the contract with the given parameters.
    /// @dev it takes a the URI and stores it as a state variable

    constructor(string memory customBaseURI_, bytes32 whiteListSaleMerkleRoot_)
        ERC721("Fjord Collection #1", "FJORD")
    {
        customBaseURI = customBaseURI_;
        whiteListSaleMerkleRoot = whiteListSaleMerkleRoot_;
    }

/*//////////////////////////////////////////////////////////////
                        EVENTS
//////////////////////////////////////////////////////////////*/

    event MintedAnNFT(address indexed to, uint256 indexed tokenId);

/*//////////////////////////////////////////////////////////////
                        MODIFIERS
//////////////////////////////////////////////////////////////*/

    modifier isValidMerkleProof(bytes32[] calldata _proof, bytes32 root) {
        require(
            MerkleProof.verify(
                _proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

/*//////////////////////////////////////////////////////////////
                            WRITE
//////////////////////////////////////////////////////////////*/

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    /// @notice mint implementation interfacing w Erc721BurningErc20OnMint contract

    function mint(address to) public override nonReentrant returns (uint256) {
        uint256 tokenId = mintCounter;
        if (tokenId == MAX_SUPPLY) {
            revert FJORD_TotalMinted();
        } else {
            _mint(to, tokenId);
            unchecked {
                mintCounter++;
            }
            emit MintedAnNFT(msg.sender, tokenId);
            return tokenId;
        }
    }

    /// @notice mint implementation for the whitelisted wallets

    function mintWhitelisted(uint256 amount, bytes32[] calldata merkleProof)
        public
        onlyOwner
        isValidMerkleProof(merkleProof, whiteListSaleMerkleRoot)
    {
        uint256 tokenId = mintCounter;
        uint256 totalMinted = mintPerWhitelistedWallet[msg.sender];
        if (totalMinted + amount > MAX_MINT_PER_WHITELIST_WALLET) {
            revert FJORD_MaxMintPerWhitelistWallet();
        } else if (whitelistCounter + amount > WHITELIST_SUPPLY) {
            // Just to test - for now -. Probably wont happen in practice as we are
            // specifiying the total wl supply and max mint per wallet to be
            // wl addresses number + max mint per wallet = total wl supply
            revert FJORD_WhitelistMaxSupplyExceeded();
        } else {
            mintPerWhitelistedWallet[msg.sender] += amount;
            uint256 i;
            for (i = 0; i < amount; i++) {
                _mint(msg.sender, tokenId);
                emit MintedAnNFT(msg.sender, tokenId);
                unchecked {
                    mintCounter++;
                    whitelistCounter++;
                }
            }
        }
    }

/*//////////////////////////////////////////////////////////////
                            READ
//////////////////////////////////////////////////////////////*/

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function totalSupply() public view returns (uint256) {
        return mintCounter;
    }

/*//////////////////////////////////////////////////////////////
                WITHDRAW AND ROYALTIES FUNCTIONS
//////////////////////////////////////////////////////////////*/

    ///@notice sets the royalties for secondary sales.
    ///Override function gets royalty information for a token (EIP-2981)
    ///@param salePrice as an input to calculate the royalties
    ///@dev conforms to EIP-2981

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * 15) / 100);
    }

    function withdraw() public nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(payThroughSplits), balance);
    }
}

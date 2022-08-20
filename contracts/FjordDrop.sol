// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

//OpenZeppelin
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
//AlchemistCoin
import "@alchemist.wtf/token-extensions/contracts/Erc721BurningErc20OnMint.sol";
//utils
import "hardhat/console.sol";

/*//////////////////////////////////////////////////////////////
                        ERRORS
//////////////////////////////////////////////////////////////*/

error FJORD_TotalMinted();
error FJORD_InexactPayment();
error FJORD_MaxMintExceeded();
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
        0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    bytes32 public whiteListSaleMerkleRoot;
    uint256 private constant PRICE_PER_WHITELIST_NFT = 0.02 ether;
    uint32 private constant MAX_MINT_PER_WHITELIST_WALLET = 2;
    uint32 private constant WHITELIST_SUPPLY = 20;
    mapping(address => uint32) public mintPerWhitelistedWallet;

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
    event MintedCopper();

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
            "Address is not whitelisted"
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
            //this event fires just to test this specific function
            emit MintedCopper();
            return tokenId;
        }
    }

    /// @notice mint implementation for the whitelisted wallets

    function mintWhitelisted(uint256 amount, bytes32[] calldata merkleProof)
        public
        payable
        isValidMerkleProof(merkleProof, whiteListSaleMerkleRoot)
        //cache the current minted amount by the wallet address
{       uint256 totalMinted = mintPerWhitelistedWallet[msg.sender];
        if (msg.value != PRICE_PER_WHITELIST_NFT * amount) {
            revert FJORD_InexactPayment();
        } else {
            require(totalMinted + amount <= MAX_MINT_PER_WHITELIST_WALLET,
                "Max mint exceeded");
            uint256 i;
            for (i = 0; i < amount; i++) {
                // cache the minteCounter as the tokenId to mint
                uint256 tokenId = mintCounter;
                _mint(msg.sender, tokenId);
                emit MintedAnNFT(msg.sender, tokenId);
                unchecked {
                    mintCounter++;
                    mintPerWhitelistedWallet[msg.sender]++;
                }
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override (Erc721BurningErc20OnMint) {
        ERC721._beforeTokenTransfer(from, to, amount);
        address fakeCopperAddress = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
        // check if it's a mint through the Copper's contract
        if(from  == fakeCopperAddress) {
            if (from == address(0) && to != address(0)) {
                require(
                    erc20TokenAddress != address(0),
                    "erc20TokenAddress undefined"
                );
                console.log("inside Copper's override");
                uint256 balanceOfAddress = IERC20(erc20TokenAddress).balanceOf(to);
                require(balanceOfAddress >= 1, "user does not hold a token");
                ERC20Burnable(erc20TokenAddress).burnFrom(to, 1);
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
        return string(abi.encodePacked(super.tokenURI(tokenId)));
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
//Fallback
    receive() external payable {}
}

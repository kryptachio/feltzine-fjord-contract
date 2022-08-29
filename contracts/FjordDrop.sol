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
error FJORD_WhitelistMintEnded();

//   _____ _               _          _____    _ _       _
//  |  ___(_) ___  _ __ __| | __  __ |  ___|__| | |_ ___(_)_ __   ___
//  | |_  | |/ _ \| '__/ _` | \ \/ / | |_ / _ \ | __|_  / | '_ \ / _ \
//  |  _| | | (_) | | | (_| |  >  <  |  _|  __/ | |_ / /| | | | |  __/
//  |_|  _/ |\___/|_|  \__,_| /_/\_\ |_|  \___|_|\__/___|_|_| |_|\___|
//      |__/

/*
 @title Fjord x FeltZine
 @notice Fjord x FeltZine drops are a collaboration between FeltZine and Copper
 @artist
 @dev javvvs.eth
 */

contract FjordDrop is Erc721BurningErc20OnMint, ReentrancyGuard, IERC2981 {

/*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
//////////////////////////////////////////////////////////////*/

    uint16 public mintCounter;
    uint16 public constant TOTAL_SUPPLY = 100;
    uint16 private constant MAX_MINT_COPPER = 75;
    string public customBaseURI;
    //change to 0xDdC12f7c85a9239519097856B695D1d34FBd61FC before deploy
    //test address 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
    address private payThroughSplits =
        0xDdC12f7c85a9239519097856B695D1d34FBd61FC;
    //change for 0x2EdcA248f8492ec96EFC43aD4D1daf14A2866Deb before deploy
    //test address 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc
    address private goerliCopperAddress =
        0x2EdcA248f8492ec96EFC43aD4D1daf14A2866Deb;
    uint256 public whitelistEndDate;
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

    constructor(
        string memory customBaseURI_,
        bytes32 whiteListSaleMerkleRoot_,
        uint256 mintQtyToOwner
    ) ERC721("Fjord Collection #1", "FJORD") {
        customBaseURI = customBaseURI_;
        whiteListSaleMerkleRoot = whiteListSaleMerkleRoot_;
        for (uint i = 0; i < mintQtyToOwner; i++) {
            unchecked {
                mintCounter++;
            }
            uint256 tokenId = mintCounter;
            _mint(msg.sender, tokenId);
        }
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
            "Address is not whitelisted"
        );
        _;
    }

/*//////////////////////////////////////////////////////////////
                        ONLY OWNER
//////////////////////////////////////////////////////////////*/
    /// @notice set _time in  Unix Time Stamp to end the whitelist

    function setEndDateWhitelist (uint256 time_) public {
        whitelistEndDate = block.timestamp + time_;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function setCopperAddress(address goerliCopperAddress_) external onlyOwner {
        goerliCopperAddress = goerliCopperAddress_;
    }


/*//////////////////////////////////////////////////////////////
                            MINT
//////////////////////////////////////////////////////////////*/

    /// @notice mint implementation interfacing w Erc721BurningErc20OnMint contract

    function mint() public override nonReentrant returns (uint256) {
        if (mintCounter == TOTAL_SUPPLY) {
            revert FJORD_TotalMinted();
        } else {
            unchecked {
                mintCounter++;
            }
            uint256 tokenId = mintCounter;
            _mint(msg.sender, tokenId);
            return tokenId;
        }
    }

    /// @notice mint implementation for the whitelisted wallets

    function whitelistMint(uint256 amount, bytes32[] calldata merkleProof)
        public
        payable
        isValidMerkleProof(merkleProof, whiteListSaleMerkleRoot)
    //cache the current minted amount by the wallet address
    {
        uint256 totalMinted = mintPerWhitelistedWallet[msg.sender];
        if (msg.value != PRICE_PER_WHITELIST_NFT * amount) {
            revert FJORD_InexactPayment();
        } else if( block.timestamp >= whitelistEndDate ){
            revert FJORD_WhitelistMintEnded();
        }
         else {
            require(
                totalMinted + amount <= MAX_MINT_PER_WHITELIST_WALLET,
                "Max mint exceeded"
            );
            uint256 i;
            for (i = 0; i < amount; i++) {
                unchecked {
                    mintCounter++;
                    mintPerWhitelistedWallet[msg.sender]++;
                }
                // cache the minteCounter as the tokenId to mint
                uint256 tokenId = mintCounter;
                _mint(msg.sender, tokenId);
                emit MintedAnNFT(msg.sender, tokenId);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(Erc721BurningErc20OnMint) {
        // check if it's a mint through the Copper's contract
        if (to == goerliCopperAddress) {
            Erc721BurningErc20OnMint._beforeTokenTransfer(from, to, amount);
        } else {
            ERC721._beforeTokenTransfer(from, to, amount);
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

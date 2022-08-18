// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

//OpenZeppelin
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

//AlchemistCoin
import "@alchemist.wtf/token-extensions/contracts/Erc721BurningErc20OnMint.sol";

/*//////////////////////////////////////////////////////////////
                        ERRORS
//////////////////////////////////////////////////////////////*/

error FJORD_TotalMinted();
error FJORD_InsufficientPayment();


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
    address private payThroughSplits;

/*//////////////////////////////////////////////////////////////
                        INIT/CONSTRUCTOR
//////////////////////////////////////////////////////////////*/

    /// @notice Initialize the contract with the given parameters.
    /// @dev it takes a the URI and stores it as a state variable

    constructor(string memory customBaseURI_)
        ERC721("Fjord Collection #1", "FJORD")
    {
        customBaseURI = customBaseURI_;
    }

/*//////////////////////////////////////////////////////////////
                        EVENTS
//////////////////////////////////////////////////////////////*/
    event MintedAnNFT(address indexed to, uint256 indexed tokenId);


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
            emit MintedAnNFT(to, tokenId);
            return tokenId;
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

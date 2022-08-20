import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, waffle } from "hardhat";
import { getMerkleProof } from "../merkle/merkle";
import { getMerkleRoot } from "../merkle/merkle";

describe("FjordDrop", function () {
  async function deployFjordDrop() {
    const root = getMerkleRoot();
    //Price for whitelisted NFTs
    let oneNFTPrice = ethers.utils.parseEther("0.02");
    let twoNFTsPrice = ethers.utils.parseEther("0.04");
    let threeNFTsPrice = ethers.utils.parseEther("0.06");

    const [owner, acc2, acc3, acc4, notWLAcc] = await ethers.getSigners();
    const FjordDrop = await ethers.getContractFactory("FjordDrop");
    const fjordDrop = await FjordDrop.deploy(
      "ipfs://QmfHKiJ7o64ALtYv1uhtNLqcKXUqnug4UmwFKx8t3dAkEy/",
      `0x${root}`
    );
    return {
      fjordDrop,
      owner,
      acc2,
      acc3,
      acc4,
      notWLAcc,
      oneNFTPrice,
      twoNFTsPrice,
      threeNFTsPrice,
    };
  }

  describe("Deployment", function () {
    it("Should deploy and set the right customBaseURI", async function () {
      const { fjordDrop } = await loadFixture(deployFjordDrop);
      expect(await fjordDrop.customBaseURI()).to.equal(
        "ipfs://QmfHKiJ7o64ALtYv1uhtNLqcKXUqnug4UmwFKx8t3dAkEy/"
      );
    });
    it("Should start the mintCounter at 1", async function () {
      const { fjordDrop } = await loadFixture(deployFjordDrop);
      expect(await fjordDrop.mintCounter()).to.equal(1);
    });

    it("Should set the right owner", async function () {
      const { fjordDrop, owner } = await loadFixture(deployFjordDrop);
      expect(await fjordDrop.owner()).to.equal(owner.address);
    });
  });

  describe("Minting", function () {
    describe("Minting via Copper", function () {
      it("Should revert if all tokens were minted", async function () {
        //CODE HERE
      });
      it("Should mint one NFT via Copper's contract and emit MintCopper event", async function () {
        const { fjordDrop, notWLAcc } = await loadFixture(deployFjordDrop);
        // NOTE: notWLAcc is not whitelisted and it calls the mint function
        console.log("notWLAcc", notWLAcc.address);
        await expect(
          fjordDrop.connect(notWLAcc).mint(notWLAcc.address)
        ).to.emit(fjordDrop, "MintedCopper");
      });
    });
    describe("Whitelist minting", function () {
      it("Should revert if all tokens were minted", async function () {
        //CODE HERE
      });
      it("TokenUri ends in '1.json' after first mint", async function () {
        const { fjordDrop, acc3, oneNFTPrice } = await loadFixture(
          deployFjordDrop
        );
        const proof = getMerkleProof(acc3.address);
        await fjordDrop.connect(acc3).mintWhitelisted(1, proof, {
          value: oneNFTPrice,
        });
        const tokenUri = await fjordDrop.tokenURI(1);
        expect(tokenUri.endsWith("1.json")).to.equal(true);
      });

      it("Whitelisted address can mint 1 and update both counters", async function () {
        const { fjordDrop, acc2, oneNFTPrice } = await loadFixture(
          deployFjordDrop
        );
        // const mroot = await fjordDrop.whiteListSaleMerkleRoot();
        // console.log("mroot", mroot);
        const proof = getMerkleProof(acc2.address);
        await fjordDrop.connect(acc2).mintWhitelisted(1, proof, {
          value: oneNFTPrice,
        });
        expect(await fjordDrop.balanceOf(acc2.address)).to.equal(1);
        // Counters update
        const mintCounter = await fjordDrop.mintCounter();
        expect(mintCounter).to.equal(2);
        // buyer's minted nfts amount
        const buyerNFTS = await fjordDrop.mintPerWhitelistedWallet(
          acc2.address
        );
        expect(buyerNFTS).to.equal(1);
      });
      it("Whitelisted mint emits MintedAnNFT event", async function () {
        const { fjordDrop, acc2, oneNFTPrice } = await loadFixture(
          deployFjordDrop
        );
        const proof = getMerkleProof(acc2.address);
        await expect(
          fjordDrop.connect(acc2).mintWhitelisted(1, proof, {
            value: oneNFTPrice,
          })
        )
          .to.emit(fjordDrop, "MintedAnNFT")
          .withArgs(acc2.address, 1);
        expect(await fjordDrop.balanceOf(acc2.address)).to.equal(1);
      });
      it("Whitelisted address can mint 2 and update counter", async function () {
        const { fjordDrop, acc4, twoNFTsPrice } = await loadFixture(
          deployFjordDrop
        );
        // const mroot = await fjordDrop.whiteListSaleMerkleRoot();
        // console.log("mroot", mroot);
        const proof = getMerkleProof(acc4.address);
        await fjordDrop.connect(acc4).mintWhitelisted(2, proof, {
          value: twoNFTsPrice,
        });
        expect(await fjordDrop.balanceOf(acc4.address)).to.equal(2);
        // Counter update
        const mintCounter = await fjordDrop.mintCounter();
        expect(mintCounter).to.equal(3);
        // buyer's minted nfts amount
        const buyerNFTS = await fjordDrop.mintPerWhitelistedWallet(
          acc4.address
        );
        console.log("buyerNFTS", buyerNFTS);
        expect(buyerNFTS).to.equal(2);
      });
      it("Reverts if address is not whitelisted ", async function () {
        const { fjordDrop, twoNFTsPrice, notWLAcc } = await loadFixture(
          deployFjordDrop
        );
        const proof = getMerkleProof(notWLAcc.address);
        await expect(
          fjordDrop.connect(notWLAcc).mintWhitelisted(2, proof, {
            value: twoNFTsPrice,
          })
        ).to.be.revertedWith("Address is not whitelisted");
      });
      it("Reverts if whitelisted user try to mint more than 2", async function () {
        const { fjordDrop, acc2, twoNFTsPrice, acc3, threeNFTsPrice } =
          await loadFixture(deployFjordDrop);
        //balance before minting
        const totalMinted = await fjordDrop.mintPerWhitelistedWallet(
          acc2.address
        );
        console.log("totalMintedBefore mint", totalMinted);
        const proof2 = getMerkleProof(acc2.address);
        //first mint
        await fjordDrop.connect(acc2).mintWhitelisted(2, proof2, {
          value: twoNFTsPrice,
        });
        //balance after minting
        const totalMintedAfterFirstTwoMints =
          await fjordDrop.mintPerWhitelistedWallet(acc2.address);
        console.log(
          "totalMintedAfterFirstTwoMints",
          totalMintedAfterFirstTwoMints
        );
        //check if totalMinted is 2
        const buyerNFTS = await fjordDrop.mintPerWhitelistedWallet(
          acc2.address
        );
        expect(buyerNFTS).to.equal(2);
        //Mint exceeds max limit
        await expect(
          fjordDrop.connect(acc2).mintWhitelisted(2, proof2, {
            value: twoNFTsPrice,
          })
        ).to.revertedWith("Max mint exceeded");
        // try to mint 3 at once
        const proof3 = getMerkleProof(acc3.address);
        await expect(
          fjordDrop.connect(acc3).mintWhitelisted(3, proof3, {
            value: threeNFTsPrice,
          })
        ).to.be.revertedWith("Max mint exceeded");
      });
    });
  });
  describe("Withdrawal", function () {
    //IMPLEMENT
    describe("Validations", function () {
      it("Should revert if its not called by the owner", async function () {
        const { fjordDrop, acc2 } = await loadFixture(deployFjordDrop);
        await expect(fjordDrop.connect(acc2).withdraw()).to.be.revertedWith(
          "Ownable: caller is not the owner"
        );
      });
    });
    it("Should send all the balance to the payThroughSplits address", async function () {
      const { fjordDrop, acc3, acc2, twoNFTsPrice, acc4 } = await loadFixture(
        deployFjordDrop
      );
      //testing with the whitelisted address and function
      const proof = getMerkleProof(acc2.address);
      await fjordDrop.connect(acc2).mintWhitelisted(2, proof, {
        value: twoNFTsPrice,
      });
      //testing with the non whitelisted address and Copper mint function
      await fjordDrop.connect(acc4).mint(acc4.address);
      const provider = waffle.provider;
      //balance before receiving ether
      const contractBalanceBeforeReceivingEther = await provider.getBalance(
        fjordDrop.address
      );
      console.log(
        "contractBalanceBeforeReceivingEther",
        contractBalanceBeforeReceivingEther
      );
      //sends ether to Fjord contract address
      await acc2.sendTransaction({
        to: fjordDrop.address,
        value: ethers.utils.parseEther("100.0"),
      });
      //balance before withdrawal
      const contractBalanceBeforeWithdrawal = await provider.getBalance(
        fjordDrop.address
      );
      const formatted = ethers.utils.formatEther(
        contractBalanceBeforeWithdrawal
      );
      console.log("contractBalanceBeforeWithdrawal", formatted);
      //withdrawal
      await fjordDrop.withdraw();
      const contractBalanceAfterWithdraw = await provider.getBalance(
        fjordDrop.address
      );
      const formattedContractBalanceAfterWithdrawal = ethers.utils.formatEther(
        contractBalanceAfterWithdraw
      );
      console.log(
        "contractBalanceAfterWithdraw",
        formattedContractBalanceAfterWithdrawal
      );
      expect(contractBalanceAfterWithdraw).to.equal(0);
      // checks the balance of the splits address
      const balanceSplitsAddress = await provider.getBalance(acc3.address);
      const formattedReceiverBalance =
        ethers.utils.formatEther(balanceSplitsAddress);
      console.log("balanceSplitsAddress balance", formattedReceiverBalance);
      expect(formattedReceiverBalance).to.equal("10100.04");
    });
  });
});

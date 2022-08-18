import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("FjordDrop", function () {
  async function deployFjordDrop() {
    const [owner, acc2, acc3, acc4] = await ethers.getSigners();

    const FjordDrop = await ethers.getContractFactory("FjordDrop");
    const fjordDrop = await FjordDrop.deploy(
      "ipfs://bafybeiddblti7v4kmhda2neoggpr3jaikdz5rbp4xzzqqyjykotkmf45xy/"
    );

    return { fjordDrop, owner, acc2, acc3, acc4 };
  }

  describe("Deployment", function () {
    it("Should deploy and set the right customBaseURI", async function () {
      const { fjordDrop } = await loadFixture(deployFjordDrop);
      expect(await fjordDrop.customBaseURI()).to.equal(
        "ipfs://bafybeiddblti7v4kmhda2neoggpr3jaikdz5rbp4xzzqqyjykotkmf45xy/"
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
    describe("Validations", function () {
      //IMPLEMENT
      it("Should revert if all tokens were minted", async function () {});
    });

    describe("Events", function () {
      it("Should emit an event on mint", async function () {
        const { fjordDrop, acc2 } = await loadFixture(deployFjordDrop);
        const tokenId = await fjordDrop.mintCounter();

        await expect(fjordDrop.connect(acc2).mint(acc2.address))
          .to.emit(fjordDrop, "MintedAnNFT")
          .withArgs(acc2.address, tokenId);
      });
    });
  });
  describe("Withdrawal", function () {
    //IMPLEMENT
    describe("Validations", function () {
      it("Should revert if its not called by the owner", async function () {});
    });
    it("Should send all the balance to the payThroughSplits address", async function () {});
  });
});

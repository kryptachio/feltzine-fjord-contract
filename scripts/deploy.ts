import { ethers } from "hardhat";

async function main() {
  const FjordDrop = await ethers.getContractFactory("FjordDrop");
  const fjordDrop = await FjordDrop.deploy(
    "ipfs://bafybeiddblti7v4kmhda2neoggpr3jaikdz5rbp4xzzqqyjykotkmf45xy/"
  );

  await fjordDrop.deployed();
  console.log(`FjordDrop deployed to ${fjordDrop.address}`);
  const receipt = await fjordDrop.deployTransaction.wait();
  console.log("gasUsed fjordDrop", receipt.gasUsed._hex);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

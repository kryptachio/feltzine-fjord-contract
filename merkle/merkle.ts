import { MerkleTree } from "merkletreejs";
import { utils } from "ethers";

const addresses: string[] = [
  "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
  "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
  "0xDdC12f7c85a9239519097856B695D1d34FBd61FC",
  "0xa17eC87407Cc5d09e78fCB773Ee22ed6842D686F",
  "0x784bb27d2a0eCB79793DE1f675b69415aE23B314",
  "0x5e080D8b14c1DA5936509c2c9EF0168A19304202",
  "0x9242097B87C052d4F6fC042B283c41499C38e531",
  "0xbC68dee71fd19C6eb4028F98F3C3aB62aAD6FeF3",
  "0x65Ca4F011426fC2AC02041FBAc0D12707070EA35",
  "0x6480Bc106F5a0B13D15F5c3AcB97fa9945B34508",
];

const tree = new MerkleTree(addresses.map(utils.keccak256), utils.keccak256, {
  sortPairs: true,
});

console.log("the Merkle root is:", tree.getRoot().toString("hex"));

export function getMerkleRoot() {
  return tree.getRoot().toString("hex");
}

export function getMerkleProof(address: string) {
  const hashedAddress = utils.keccak256(address);
  return tree.getHexProof(hashedAddress);
}

import { MerkleTree } from "merkletreejs";
import { utils } from "ethers";

const addresses: string[] = [
  "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
  "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
  "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
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

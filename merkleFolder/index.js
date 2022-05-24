const { MerkleTree } = require('merkletreejs')


const { keccak256 } = require("@ethersproject/solidity");

 const whitelist = [
  "0x4c17cF5Ee96Ca430d1Dd14EfCe4385e1e162B556",

  "0x2169B5deeD138e7828cf69D3d8e4fD54c469cdFb",

  "0x81964e06cA51F7426F17c52485f9f5B0bA446F02",

  "0x9816d41ea5132f9cf8cb53aa8cbfea5b8faab85d",

  "0x5f98Bf2254BF20F70f1ca7722abBa28359591deD",
];

  function hashAccount(address) {
  return keccak256(["address"], [address]);
}

 function keccak256Custom(bytes) {
    const buffHash = keccak256(["bytes"], ["0x" + bytes.toString("hex")]);
    return Buffer.from(buffHash.slice(2), "hex");
  }
  
    function getMerkleTree() {
    const leaves = whitelist.map((account) => hashAccount(account));
    return new MerkleTree(leaves, keccak256Custom, { sortPairs: true });
  }


     const tree = getMerkleTree();
    const hexProof = tree.getHexProof(hashAccount("0x81964e06cA51F7426F17c52485f9f5B0bA446F02"));
    const leaf = hashAccount("0x81964e06cA51F7426F17c52485f9f5B0bA446F02");
    const hexRoot = tree.getHexRoot().toString("hex");
    const verify = tree.verify(hexProof, leaf, hexRoot);
    console.log("hex root",hexRoot);
    console.log("hex proof",hexProof);
    console.log(verify);
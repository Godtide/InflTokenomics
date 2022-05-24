const { MerkleTree } = require('merkletreejs')


const { keccak256 } = require("@ethersproject/solidity");

 const whitelist = ["address1", "address2"];

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
    const hexProof = tree.getHexProof(hashAccount("address1"));
    const leaf = hashAccount("address1");
    const hexRoot = tree.getHexRoot().toString("hex");
    const verify = tree.verify(hexProof, leaf, hexRoot);
    console.log("hex root",hexRoot);
    console.log("hex proof",hexProof);
    console.log(verify);
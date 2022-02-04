const hre = require("hardhat");
const { ethers } = require("hardhat");




let currentLimit = 200000000;
let steepness = 9.461e+7;
let maxPrice;
let stakingtime = 3.154e+7;

async function main() {
    / INITIALIZE / /////////////////////////////////////////////////////////
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);


    const ICO = await ethers.getContractFactory(
        "ICO"
    );

    const ico = await ICO.deploy();
    console.log("ICO contract address:", ico.address);

    maxPrice = await ico.computeInitialPriceInAvax(10);

    console.log("maxprice in NanoAvax:", ethers.utils.formatEther( maxPrice ));




    const FixedMath = await ethers.getContractFactory(
        "FixedMath"
    );
    const fixedmath = await FixedMath.deploy();

    console.log("FixedMath Library address:", fixedmath.address);


    const Treasury = await ethers.getContractFactory(
        "Treasury", {
            libraries: {
                FixedMath: `${fixedmath.address}`,
            },
        }
    );

    const treasury = await Treasury.deploy(
        currentLimit,
        steepness,
        maxPrice,
    );

    console.log("Treasury contract address:", treasury.address);


    const INFLStake = await ethers.getContractFactory(
        "INFLStake"
    );

    const inflstake = await INFLStake.deploy(ico.address, stakingtime);
    console.log("INFLStake contract address:", inflstake.address)

}




// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
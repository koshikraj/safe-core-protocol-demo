import hre, { deployments, ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { getWhiteListHook } from "../src/utils/contracts";
import { loadPluginMetadata } from "../src/utils/metadata";
import { buildSingleTx } from "../src/utils/builder";
import { MaxUint256 } from "ethers";
import { getProtocolManagerAddress } from "../src/utils/protocol";

describe("WhitelistHook", async () => {
    let user1: SignerWithAddress, user2: SignerWithAddress;

    before(async () => {
        [user1, user2] = await hre.ethers.getSigners();
    });

    const setup = deployments.createFixture(async ({ deployments }) => {
        await deployments.fixture();
        const manager = await ethers.getContractAt("MockContract", await getProtocolManagerAddress(hre));

        const account = await (await ethers.getContractFactory("ExecutableMockContract")).deploy();
        const plugin = await getWhiteListHook(hre);
        return {
            account,
            plugin,
            manager,
        };
    });

    it("should be initialized correctly", async () => {
        const { plugin } = await setup();
        expect(await plugin.name()).to.be.eq("Whitelist Hook");
        expect(await plugin.version()).to.be.eq("1.0.0");
        expect(await plugin.requiresRootAccess()).to.be.false;
    });

    it("can retrieve meta data for module", async () => {
        const { plugin } = await setup();
        expect(await loadPluginMetadata(hre, plugin)).to.be.deep.eq({
            name: "Whitelist Hook",
            version: "1.0.0",
            requiresRootAccess: false,
            iconUrl: "",
            appUrl: "",
        });
    });

    it("should emit AddressWhitelisted when account is whitelisted", async () => {
        const { plugin, account } = await setup();
        const data = plugin.interface.encodeFunctionData("addToWhitelist", [[user1.address]]);
        expect(await account.executeCallViaMock(await plugin.getAddress(), 0, data, MaxUint256))
            .to.emit(plugin, "AddressWhitelisted")
            .withArgs(user1.address);
    });

    it("Should allow a normal transaction from account", async () => {
        const { plugin, account, manager } = await setup();

        // Required for isOwner(address) to return true
        account.givenMethodReturnBool("0x2f54bf6e", true);;

        await account.executeCallViaMock(await plugin.getAddress(), 0, '0x', MaxUint256)

    });

});

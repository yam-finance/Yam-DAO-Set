// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {DSTest} from "../../lib/test.sol";
import {TreasuryHelpers} from "../HEVMHelpers.sol";

import {SushiBarWrapAdapter} from "../../set-adapters/SushiBarWrapAdapter.sol";

import {IERC20} from "../../interfaces/IERC20.sol";
import {IIntegrationRegistry} from "../../interfaces/IIntegrationRegistry.sol";
import {IStreamingFeeModule} from "../../interfaces/IStreamingFeeModule.sol";
import {IBasicIssuanceModule} from "../../interfaces/IBasicIssuanceModule.sol";
import {ITradeModule} from "../../interfaces/ITradeModule.sol";
import {IWrapModule} from "../../interfaces/IWrapModule.sol";
import {ISetTokenCreator} from "../../interfaces/ISetTokenCreator.sol";
import {ISetToken} from "../../interfaces/ISetToken.sol";

interface Hevm {
    function warp(uint256) external;

    function roll(uint256) external;

    function store(
        address,
        bytes32,
        bytes32
    ) external;

    function load(address, bytes32) external returns (bytes32);

    function origin(address) external;
}

contract BaseTest is DSTest {
    event Logger(bytes);
    event DebugLogger(string);

    // --- constants
    bytes20 constant CHEAT_CODE = bytes20(
        uint160(uint256(keccak256("hevm cheat code")))
    );
    uint256 public constant BASE = 10**18;

    // --- helpers
    Hevm hevm;
    TreasuryHelpers helper;
    address me;

    IIntegrationRegistry integrationRegistry = IIntegrationRegistry(
        0x6655194c95D24B8b10B156DFFCe22A2c126E2E5A
    );

    IBasicIssuanceModule basicIssuanceModule = IBasicIssuanceModule(
        0xd8EF3cACe8b4907117a45B0b125c68560532F94D
    );
    IStreamingFeeModule feeModule = IStreamingFeeModule(
        0x08f866c74205617B6F3903EF481798EcED10cDEC
    );
    ITradeModule tradeModule = ITradeModule(
        0x90F765F63E7DC5aE97d6c576BF693FB6AF41C129
    );
    IWrapModule wrapModule = IWrapModule(
        0xbe4aEdE1694AFF7F1827229870f6cf3d9e7a999c
    );

    IERC20 xsushi = IERC20(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
    IERC20 sushi = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);

    ISetTokenCreator setCreator = ISetTokenCreator(
        0x65d103A810099193c892a23d6b320cF3B9E30D46
    );

    ISetToken setToken;

    function setUpCore() public {
        hevm = Hevm(address(CHEAT_CODE));
        me = address(this);
        helper = new TreasuryHelpers();

        // Become owner of integration registry *evil face*
        hevm.store(
            address(integrationRegistry),
            bytes32(0x0),
            bytes32(
                0x000000000000000000000000683A78bA1f6b25E29fbBC9Cd1BFA29A51520De84
            )
        );
        integrationRegistry.addIntegration(
            address(wrapModule),
            "SushiBarWrapAdapter",
            address(new SushiBarWrapAdapter(address(sushi), address(xsushi)))
        );

        address[] memory tokens = new address[](1);
        tokens[0] = address(sushi);
        int256[] memory amounts = new int256[](1);
        amounts[0] = 1 * (10**18);
        address[] memory modules = new address[](4);
        modules[0] = address(feeModule);
        modules[1] = address(tradeModule);
        modules[2] = address(basicIssuanceModule);
        modules[3] = address(wrapModule);
        setToken = ISetToken(
            setCreator.create(
                tokens,
                amounts,
                modules,
                address(this),
                "Test Set",
                "TEST"
            )
        );

        feeModule.initialize(
            setToken,
            IStreamingFeeModule.FeeState({
                feeRecipient: address(0x1),
                maxStreamingFeePercentage: 1 * (10**17),
                streamingFeePercentage: 2 * (10**16),
                lastStreamingFeeTimestamp: 0
            })
        );
        tradeModule.initialize(setToken);
        basicIssuanceModule.initialize(setToken, address(0x0));
        wrapModule.initialize(setToken);

        helper.write_balanceOf(
            address(sushi),
            address(this),
            100000 * (10**18)
        );
        sushi.approve(address(basicIssuanceModule), 1 * (10**18));
    }

    // --- helpers

    function expect_revert_with(
        address who,
        string memory sig,
        bytes memory args,
        string memory revert_string
    ) public {
        bytes memory calld = abi.encodePacked(helper.sigs(sig), args);
        (bool success, bytes memory ret) = who.call(calld);
        assertTrue(!success);
        string memory ret_revert_string = abi.decode(
            slice(5, ret.length, ret),
            (string)
        );
        assertEq(ret_revert_string, revert_string);
    }

    function expect_revert_with(
        address who,
        bytes4 sig,
        bytes memory args,
        string memory revert_string
    ) public {
        bytes memory calld = abi.encodePacked(sig, args);
        (bool success, bytes memory ret) = who.call(calld);
        assertTrue(!success);
        string memory ret_revert_string = abi.decode(
            slice(5, ret.length, ret),
            (string)
        );
        assertEq(ret_revert_string, revert_string);
    }

    function slice(
        uint256 begin,
        uint256 end,
        bytes memory text
    ) public pure returns (bytes memory) {
        bytes memory a = new bytes(end - begin + 1);
        for (uint256 i = 0; i <= end - begin; i++) {
            a[i] = bytes(text)[i + begin - 1];
        }
        return a;
    }
}

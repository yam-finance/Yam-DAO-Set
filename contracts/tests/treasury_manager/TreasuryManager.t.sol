// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../test_tests/base.t.sol";

import {TreasuryManager} from "../../TreasuryManager.sol";
import {ISetTokenCreator} from "../../interfaces/ISetTokenCreator.sol";
import {ISetToken} from "../../interfaces/ISetToken.sol";

import {ERC20} from "../../lib/ERC20.sol";

contract TreasuryManagerTest is BaseTest {
    ISetTokenCreator setCreator = ISetTokenCreator(
        0x65d103A810099193c892a23d6b320cF3B9E30D46
    );
    ISetToken setToken;
    TreasuryManager manager;

    TreasuryManager portfolioManager;

    function setUp() public {
        setUpCore();

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
                "Yam Test Set",
                "YTS"
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

        address[] memory tokenAllowlist = new address[](1);
        tokenAllowlist[0] = address(sushi);
        manager = new TreasuryManager(
            setToken,
            feeModule,
            tradeModule,
            wrapModule,
            address(this),
            address(0x0),
            tokenAllowlist
        );
        portfolioManager = TreasuryManager(
            address(new ProxyContract(address(manager)))
        );
        manager.setPortfolioManager(address(portfolioManager));
        setToken.setManager(address(manager));

        manager.setAdapterAllowed(
            address(wrapModule),
            "SushiBarWrapAdapter",
            true
        );
        sushi.approve(address(basicIssuanceModule), 1 * (10**18));
        basicIssuanceModule.issue(setToken, 1 * (10**18), address(this));
    }

    //
    // TESTS
    //

    function test_tm_initialization() public {
        // -- force verbose
        assertTrue(false);

        // Assert all values set correctly
        assertEq(address(manager.setToken()), address(setToken));
        assertEq(address(manager.feeModule()), address(feeModule));
        assertEq(address(manager.tradeModule()), address(tradeModule));
        assertEq(address(manager.wrapModule()), address(wrapModule));
        assertEq(address(manager.gov()), address(this));
        assertEq(manager.portfolioManager(), address(portfolioManager));
        assertTrue(manager.tokenAllowlist(address(sushi)));
        assertTrue(!manager.tokenAllowlist(address(xsushi)));
    }

    function test_tm_update_settings() public {
        // -- force verbose
        assertTrue(false);

        manager.setPortfolioManager(address(this));
        assertEq(manager.portfolioManager(), address(this));

        manager.abdicatePortfolioManager();
        assertEq(manager.portfolioManager(), address(0x0));

        manager.setTokenTradable(address(xsushi), true);
        assertTrue(manager.tokenAllowlist(address(xsushi)));
        manager.setTokenTradable(address(sushi), false);
        assertTrue(!manager.tokenAllowlist(address(sushi)));
    }

    function test_tm_sushibar_wrap_adapter() public {
        // -- force verbose
        assertTrue(false);

        manager.setTokenTradable(address(xsushi), true);
        manager.setPortfolioManager(address(this));
        manager.wrap(
            "SushiBarWrapAdapter",
            address(sushi),
            address(xsushi),
            1 * (10**18)
        );
        assertEq(sushi.balanceOf(address(setToken)), 0);
        uint256 xsushiBalance = xsushi.balanceOf(address(setToken));
        assertTrue(xsushiBalance > 0);

        manager.unwrap(
            "SushiBarWrapAdapter",
            address(sushi),
            address(xsushi),
            xsushiBalance
        );
        assertEq(xsushi.balanceOf(address(setToken)), 0);
        uint256 sushiBalance = sushi.balanceOf(address(setToken));
        assertTrue(sushiBalance > 0);
    }
}

// Used as "secondary address" for testing access control
contract ProxyContract {
    address target;

    constructor(address _target) public {
        target = _target;
    }

    receive() external payable {
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let result := call(
                gas(),
                sload(target_slot),
                0,
                0x0,
                calldatasize(),
                0x0,
                0
            )
            returndatacopy(0x0, 0x0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}

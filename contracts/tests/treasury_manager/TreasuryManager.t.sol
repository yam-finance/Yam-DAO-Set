// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../test_tests/base.t.sol";

import {TreasuryManager} from "../../TreasuryManager.sol";
import {ISetTokenCreator} from "../../interfaces/ISetTokenCreator.sol";
import {ISetToken} from "../../interfaces/ISetToken.sol";
import {TradeAdapter} from "../../manager-adapters/TradeAdapter.sol";
import {WrapAdapter} from "../../manager-adapters/WrapAdapter.sol";
import {StreamingFeeAdapter} from "../../manager-adapters/StreamingFeeAdapter.sol";


import {ERC20} from "../../lib/ERC20.sol";

contract TreasuryManagerTest is BaseTest {
    TreasuryManager manager;

    TradeAdapter tradeAdapter;
    WrapAdapter wrapAdapter;
    StreamingFeeAdapter feeAdapter;
    
    function setUp() public {
        setUpCore();

        manager = new TreasuryManager(
            setToken,
            address(this)
        );
        tradeAdapter = new TradeAdapter(setToken, manager, tradeModule, tokenAllowlist, address(this));
        wrapAdapter = new WrapAdapter(setToken, manager, wrapModule, tokenAllowlist,address(this));
        feeAdapter = new StreamingFeeAdapter(setToken, manager, feeModule, address(this));
        manager.setModuleAdapterAllowed(address(tradeModule),address(tradeAdapter), true);
        manager.setModuleAdapterAllowed(address(wrapModule),address(wrapAdapter), true);
        manager.setModuleAdapterAllowed(address(feeModule),address(feeAdapter), true);
        setToken.setManager(address(manager));

        basicIssuanceModule.issue(setToken, 1 * (10**18), address(this));
    }

    //
    // TESTS
    //

    function test_tm_sushibar_wrap_adapter() public {
        // -- force verbose
        assertTrue(false);

        wrapAdapter.wrap(
            "SushiBarWrapAdapter",
            address(sushi),
            address(xsushi),
            1 * (10**18)
        );
        assertEq(sushi.balanceOf(address(setToken)), 0);
        uint256 xsushiBalance = xsushi.balanceOf(address(setToken));
        assertTrue(xsushiBalance > 0);

        wrapAdapter.unwrap(
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

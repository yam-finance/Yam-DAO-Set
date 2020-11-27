// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental "ABIEncoderV2";

import {ISetToken} from "./ISetToken.sol";

interface IBasicIssuanceModule {
    function issue(
        ISetToken _setToken,
        uint256 _quantity,
        address _to
    ) external;

    function redeem(
        ISetToken _setToken,
        uint256 _quantity,
        address _to
    ) external;

    function initialize(ISetToken _setToken, address _preIssueHook) external;

    function getRequiredComponentUnitsForIssue(
        ISetToken _setToken,
        uint256 _quantity
    ) external view returns (address[] memory, uint256[] memory);
}

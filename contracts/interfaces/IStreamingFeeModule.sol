// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental "ABIEncoderV2";

import {ISetToken} from "./ISetToken.sol";

interface IStreamingFeeModule {
    struct FeeState {
        address feeRecipient;
        uint256 maxStreamingFeePercentage;
        uint256 streamingFeePercentage;
        uint256 lastStreamingFeeTimestamp;
    }

    function feeStates(ISetToken _setToken)
        external
        view
        returns (FeeState memory);

    function getFee(ISetToken _setToken) external view returns (uint256);

    function updateStreamingFee(ISetToken _setToken, uint256 _newFee) external;

    function updateFeeRecipient(ISetToken _setToken, address _newFeeRecipient)
        external;

    function initialize(ISetToken _setToken, FeeState memory _settings)
        external;
}

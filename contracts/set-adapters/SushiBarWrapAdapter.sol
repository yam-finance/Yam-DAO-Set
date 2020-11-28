// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

/**
 * @title SushiBarWrapAdapter
 * @author Nate Welch (Yam Finance)
 *
 * Wrap adapter for depositing/withdrawing sushi to/from SushiBar (xSushi)
 */
contract SushiBarWrapAdapter {

    /* ============ State Variables ============ */


    // Address of LEND token
    address public immutable sushiToken;

    // Address of AAVE token
    address public immutable xsushiToken;

    /* ============ Constructor ============ */

    /**
     * State variables
     *
     * @param _sushiToken                      Address of SUSHI token
     * @param _xsushiToken                     Address of XSUSHI token (also the SushiBar)
     */
    constructor(
        address _sushiToken,
        address _xsushiToken
    )
        public
    {
        sushiToken = _sushiToken;
        xsushiToken = _xsushiToken;
    }

    /* ============ External Getter Functions ============ */

    /**
     * Generates the calldata to wrap sushi into xsushi.
     *
     * @param _underlyingToken      Address of the component to be wrapped
     * @param _wrappedToken         Address of the wrapped component
     * @param _underlyingUnits      Total quantity of underlying units to wrap
     *
     * @return address              Target contract address
     * @return uint256              Total quantity of underlying units (if underlying is ETH)
     * @return bytes                Wrap calldata
     */
    function getWrapCallData(
        address _underlyingToken,
        address _wrappedToken,
        uint256 _underlyingUnits
    )
        external
        view
        returns (address, uint256, bytes memory)
    {
        require(_underlyingToken == sushiToken, "Must be SUSHI token");
        require(_wrappedToken == xsushiToken, "Must be XSUSHI token");

        // enter(uint256 _amount)
        bytes memory callData = abi.encodeWithSignature("enter(uint256)", _underlyingUnits);

        return (xsushiToken, 0, callData);
    }

    /**
     * Generates the calldata to unwrap xsushi to sushi
     *
     * @return address              Target contract address
     * @return uint256              Total quantity of wrapped token units to unwrap. This will always be 0 for unwrapping
     * @return bytes                Unwrap calldata
     */
    function getUnwrapCallData(
        address _underlyingToken,
        address _wrappedToken,
        uint256 _wrappedTokenUnits
    )
        external
        view
        returns (address, uint256, bytes memory)
    {
        require(_underlyingToken == sushiToken, "Must be SUSHI token");
        require(_wrappedToken == xsushiToken, "Must be XSUSHI token");

        // leave(uint256 _amount)
        bytes memory callData = abi.encodeWithSignature("leave(uint256)", _wrappedTokenUnits);

        return (xsushiToken, 0, callData);

    }

    /**
     * Returns the address to approve source tokens for wrapping.
     *
     * @return address        Address of the contract to approve tokens to
     */
    function getSpenderAddress(address /*_underlyingToken*/, address /*_wrappedToken*/) external view returns(address) {
        return address(xsushiToken);
    }
}

pragma solidity 0.6.12;
pragma experimental "ABIEncoderV2";


interface UniswapV2Router02 {
    function swapExactTokensForTokens(
  uint amountIn,
  uint amountOutMin,
  address[] calldata path,
  address to,
  uint deadline
) external returns (uint[] memory amounts);

}
/**
 * @title UniswapV2TradeAdapter
 * @author Set Protocol
 *
 * Exchange adapter for Uniswap V2 that returns data for trades
 */

contract UniswapV2Router02TradeAdapter {

    /* ============ State Variables ============ */
    
    // Address of Uniswap V2 Router02 contract
    UniswapV2Router02 public immutable router;
 
    /* ============ Constructor ============ */

    /**
     * Set state variables
     *
     * @param _router       Address of Uniswap V2 Router02 contract
     */
    constructor(
        address _router
    )
        public
    {
        router = UniswapV2Router02(_router);
    }

    /* ============ External Getter Functions ============ */

    /**
     * Return calldata for Uniswap V2 Router02
     *
     * @param  _sourceToken              Address of source token to be sold
     * @param  _destinationToken         Address of destination token to buy
     * @param _destinationAddress        Address that assets should be transferred to
     * @param  _sourceQuantity           Amount of source token to sell
     * @param  _minDestinationQuantity   Min amount of destination token to buy
     *
     * @return address                   Target contract address
     * @return uint256                   Call value
     * @return bytes                     Trade calldata
     */
    function getTradeCalldata(
        address _sourceToken,
        address _destinationToken,
        address _destinationAddress,
        uint256 _sourceQuantity,
        uint256 _minDestinationQuantity,
        bytes memory /*_data*/
    )
        external
        view
        returns (address, uint256, bytes memory)
    {   
        address[] memory path = new address[](2);
        path[0] = _sourceToken;
        path[1] = _destinationToken;
        bytes memory callData = abi.encodeWithSignature("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)", _sourceQuantity,_minDestinationQuantity,path, _destinationAddress, block.timestamp);
        return (address(router), 0, callData);
    }

    /**
     * Returns the address to approve source tokens to for trading. This is the TokenTaker address
     *
     * @return address             Address of the contract to approve tokens to
     */
    function getSpender()
        external
        view
        returns (address)
    {
        return address(router);
    }
}
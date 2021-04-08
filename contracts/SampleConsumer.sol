pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

contract SampleConsumer is ChainlinkClient {

    bytes32 public volume;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    constructor(address _oracle, bytes32 _jobId) public {
        setPublicChainlinkToken();
        oracle = _oracle;
        jobId = _jobId;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    function requestPrData(string memory query) public returns (bytes32) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        request.add("get", "http://localhost:3000");
        request.add("queryParams", query);
        request.add("path", "data.0");

        return sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(bytes32 _requestId, bytes32 _volume) public recordChainlinkFulfillment(_requestId)
    {
        volume = _volume;
    }
}
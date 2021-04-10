pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

contract SampleConsumer is ChainlinkClient {
    bytes32 private userId;
    uint256 private PrCount;

    address private githubOracle;
    bytes32 private userJobId;
    bytes32 private PrJobId;
    string public repoQuery;

    address private alarmOracle;
    bytes32 private alarmJobId;

    uint256 private fee;

    mapping(bytes32 => uint256) public balances;

    constructor(string memory _repoQuery) public {
        setPublicChainlinkToken();
        githubOracle = 0x9e308Dd6Cb8DFF70a3FDAF9604Af93BBA9f4B57e;
        userJobId = "0d840688ccb64ec38790c1a4e65bba46";
        PrJobId = "4b636dd8bf9342b1bcd148e09f066ba2";

        alarmOracle = 0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b;
        alarmJobId = "982105d690504c5d9ce374d040c08654";

        fee = 0.1 * 10**18; // 0.1 LINK
        repoQuery = _repoQuery;

        setPrCheck();
    }

    function setPrCheck() public {
        Chainlink.Request memory req =
            buildChainlinkRequest(
                alarmJobId,
                address(this),
                this.fulfillDelay.selector
            );
        req.addUint("until", now + 24 hours);
        sendChainlinkRequestTo(alarmOracle, req, fee);
    }

    function requestUserId(string memory filter)
        public
        returns (bytes32 requestId)
    {
        Chainlink.Request memory request =
            buildChainlinkRequest(
                userJobId,
                address(this),
                this.fulfillUserId.selector
            );
        request.add("get", "http://localhost:3000");
        request.add("queryParams", repoQuery);
        request.add("path", filter);

        requestId = sendChainlinkRequestTo(githubOracle, request, fee);
    }

    function requestPrData() public returns (bytes32) {
        Chainlink.Request memory request =
            buildChainlinkRequest(
                PrJobId,
                address(this),
                this.fulfillPrData.selector
            );
        request.add("get", "http://localhost:3000");
        request.add("queryParams", repoQuery);
        request.add("path", "count");

        return sendChainlinkRequestTo(githubOracle, request, fee);
    }

    function fulfillUserId(bytes32 _requestId, bytes32 _volume)
        public
        recordChainlinkFulfillment(_requestId)
    {
        userId = _volume;
        balances[userId] = balances[userId] + 1;
    }

    function fulfillPrData(bytes32 _requestId, uint256 _volume)
        public
        recordChainlinkFulfillment(_requestId)
    {
        PrCount = _volume;
        for (uint256 i = 0; i < PrCount; i++) {
            string memory filter =
                string(abi.encodePacked("data.", uintToStr(i)));
            requestUserId(filter);
        }
    }

    function fulfillDelay(bytes32 _requestId)
        public
        recordChainlinkFulfillment(_requestId)
    {
        requestPrData();
        setPrCheck();
    }

    function uintToStr(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}

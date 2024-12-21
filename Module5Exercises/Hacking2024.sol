// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


contract GraderInteractor {
    address public constant GRADER_CONTRACT = 0x6F14A55C82600DCAFeb1841243a15921DCD10aF7;

    string public constant ALIAS = "S3RG1";

    function callRetrieve() external payable {
        require(msg.value >= 4, "Insufficient ETH sent. Minimum 4 wei required.");
        (bool success, ) = GRADER_CONTRACT.call{value: msg.value}(
            abi.encodeWithSignature("retrieve()")
        );
        require(success, "Failed to call retrieve on Grader contract.");
    }

    function callMint() external {
        (bool success, ) = GRADER_CONTRACT.call(
            abi.encodeWithSignature("mint(address)", address(this))
        );
        require(success, "Failed to call mint on Grader contract.");
    }


    function callGradeMe() external {
        (bool success, ) = GRADER_CONTRACT.call(
            abi.encodeWithSignature("gradeMe(string)", ALIAS)
        );
        require(success, "Failed to call gradeMe on Grader contract.");
    }
    receive() external payable {}
}

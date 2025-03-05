// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AISlashingMonitor {
    struct MisconductReport {
        address validator;
        uint256 severity;
        string reason;
        bool confirmed;
    }

    mapping(address => MisconductReport) public reports;

    event MisconductDetected(address indexed validator, uint256 severity, string reason);
    event MisconductConfirmed(address indexed validator, uint256 severity);

    function reportMisconduct(address _validator, uint256 _severity, string memory _reason) external {
        require(_severity > 0 && _severity <= 100, "Invalid severity");
        reports[_validator] = MisconductReport(_validator, _severity, _reason, false);
        emit MisconductDetected(_validator, _severity, _reason);
    }

    function confirmMisconduct(address _validator) external {
        require(reports[_validator].severity > 0, "No misconduct reported");
        reports[_validator].confirmed = true;
        emit MisconductConfirmed(_validator, reports[_validator].severity);
    }
}

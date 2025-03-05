// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AISlashingEnforcer.sol";

contract AISlashingAppeal {
    AISlashingEnforcer public enforcer;
    
    struct Appeal {
        address validator;
        string evidence;
        bool reviewed;
        bool successful;
    }

    mapping(address => Appeal) public appeals;

    event AppealSubmitted(address indexed validator, string evidence);
    event AppealReviewed(address indexed validator, bool successful);

    constructor(address _enforcer) {
        enforcer = AISlashingEnforcer(_enforcer);
    }

    function submitAppeal(string memory _evidence) external {
        require(enforcer.monitor().reports(msg.sender).confirmed, "No slashing to appeal");
        appeals[msg.sender] = Appeal(msg.sender, _evidence, false, false);
        emit AppealSubmitted(msg.sender, _evidence);
    }

    function reviewAppeal(address _validator, bool _success) external {
        require(appeals[_validator].validator == _validator, "No appeal found");
        appeals[_validator].reviewed = true;
        appeals[_validator].successful = _success;
        if (_success) {
            // Reverse slashing
            enforcer.validatorContract().reverseSlash(_validator);
        }
        emit AppealReviewed(_validator, _success);
    }
}

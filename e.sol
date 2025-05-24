// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./storage.sol";

contract e is Crowdfunding{
    function refund(uint256 campaignID) external{
        Campaign storage c = campaigns[campaignID];
        require(block.timestamp > c.deadline, "Campaign not ended yet.");
        require(c.totalFunded < c.goalAmount, "Campaign was successful.");

        uint amount = contributions[campaignID][msg.sender];
        require(amount > 0, "Not fundable amount");

        contributions[campaignID][msg.sender]= 0;
        payable(msg.sender).transfer(amount);
    }

    function getRefundableAmount(uint256 campaignID, address funder) external view returns (uint){
        Campaign memory c = campaigns[campaignID];
        if (block.timestamp <= c.deadline || c.totalFunded >= c.goalAmount){
            return 0;
        }
        return contributions[campaignID][funder];
    }

    function getBalance() external view returns (uint){
        return address(this).balance;
    }

    function getCampaignStatusLabel(uint256 campaignID) external view returns (string memory){
        Campaign memory c = campaigns[campaignID];

        if(c.withdrawn){
            return "success";
        }
        else if (block.timestamp > c.deadline && c.totalFunded < c.goalAmount){
            return "fail";
        }
        else{
            return "on progress";
        }
    }
}

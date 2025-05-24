// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./storage.sol";

contract e {
    Crowdfunding public store;

    // 상속하면 형식만 가져오는 것이고 실제 데이터를 공유하는 역할을 하지 못합니다
    // 컨트랙트가 각자 다른 값들을 보게 됨..
    
    constructor(address _storageAddr) {
        store = Crowdfunding(_storageAddr);
    }

    function refund(uint campaignID) external {

        // 외부 컨트랙트에서 스트럭트를 얻으면 메모리로 밖에 못 받음
        // getCampaign 함수 필요
        Crowdfunding.Campaign memory c = store.getCampaign(campaignID);
        require(block.timestamp > c.deadline, "Campaign not ended yet.");
        require(c.totalFunded < c.goalAmount, "Campaign was successful.");

        uint amount = store.getContribution(campaignID, msg.sender);
        require(amount > 0, "Not fundable amount");

        store.setContribution(campaignID, msg.sender, amount);


        // 근데 이건 캠페인별로 컨트랙트를 따로 배포하겠다는 의미인데?
        payable(msg.sender).transfer(amount);
    }

    function getRefundableAmount(uint campaignID, address funder) external view returns (uint){

        Crowdfunding.Campaign memory c = store.getCampaign(campaignID);
        if (block.timestamp <= c.deadline || c.totalFunded >= c.goalAmount){
            return 0;
        }
        return store.getContribution(campaignID, funder);
    }

    function getBalance() external view returns (uint){
        return address(this).balance;
        // 근데 이건 캠페인별로 컨트랙트를 따로 배포하겠다는 의미인데?
    }

    function getCampaignStatusLabel(uint campaignID) external view returns (string memory){

        // storage struct 안에 있는 라벨이랑 동기화가 안될 위험

        // 이 로직은 set으로 하고
        // storage에다가 get 함수 만드는게

        Crowdfunding.Campaign memory c = store.getCampaign(campaignID);

        if (c.withdrawn){
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

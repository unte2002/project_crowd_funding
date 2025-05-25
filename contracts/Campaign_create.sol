// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    enum Label { InProgress, Success, Failure }

    struct Campaign {
        uint    campaignId;
        uint    goalAmount;
        uint    durationInDays;
        uint    deadline;
        address creator;
        uint    totalFunded;
        bool    withdrawn;
        Label   label;
    }

    uint public campaignCount;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public contributions;

    /// @notice 캠페인 생성
    function createCampaign(uint _goalAmount, uint _durationInDays) external {
        require(_goalAmount > 0, "Goal must be greater than 0");
        require(_durationInDays > 0, "Duration must be at least 1 day");

        Campaign memory newCampaign = Campaign({
            campaignId: campaignCount,
            goalAmount: _goalAmount,
            durationInDays: _durationInDays,
            deadline: block.timestamp + (_durationInDays * 1 days),
            creator: msg.sender,
            totalFunded: 0,
            withdrawn: false,
            label: Label.InProgress
        });

        campaigns[campaignCount] = newCampaign;
        campaignCount++;
    }

    /// @notice 캠페인 상세 조회
    function getCampaign(uint _campaignId) public view returns (Campaign memory) {
        return campaigns[_campaignId];
    }

    /// @notice 전체 캠페인 리스트 조회
    function getAllCampaigns() external view returns (Campaign[] memory) {
        Campaign[] memory result = new Campaign[](campaignCount);
        for (uint i = 0; i < campaignCount; i++) {
            result[i] = campaigns[i];
        }
        return result;
    }

    /// @notice 내가 만든 캠페인만 조회
    function getMyCampaigns() external view returns (Campaign[] memory) {
        // 우선 최대 크기로 배열 생성
        Campaign[] memory temp = new Campaign[](campaignCount);
        uint count = 0;

        for (uint i = 0; i < campaignCount; i++) {
            if (campaigns[i].creator == msg.sender) {
                temp[count] = campaigns[i];
                count++;
            }
        }

        // 정확한 길이의 배열로 복사
        Campaign[] memory myCampaigns = new Campaign[](count);
        for (uint j = 0; j < count; j++) {
            myCampaigns[j] = temp[j];
        }

        return myCampaigns;
    }

    /// 이미 정의되어 있음
    function getContribution(uint _campaignId, address _user) public view returns (uint) {
        return contributions[_campaignId][_user];
    }

    function setContribution(uint _campaignId, address _user, uint amount) public {
        contributions[_campaignId][_user] = amount;
    }
}

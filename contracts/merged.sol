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
    mapping(address => uint[]) public campaignsByCreator;

    // 이벤트 선언
    event CampaignCreated(uint indexed campaignId, address indexed creator, uint goalAmount, uint deadline);
    event Funded(uint indexed campaignId, address indexed funder, uint amount);
    event Withdrawn(uint indexed campaignId, address indexed creator, uint amount);
    event Refunded(uint indexed campaignId, address indexed funder, uint amount);
    event LabelUpdated(uint indexed campaignId, uint8 label);

    constructor() {
        campaignCount = 0;
    }


    modifier onlyCreator(uint campaignId) {
        require(msg.sender == campaigns[campaignId].creator, "Not creator");
        _;
    }

    // 캠페인 생성
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
        campaignsByCreator[msg.sender].push(campaignCount);
        emit CampaignCreated(campaignCount, msg.sender, _goalAmount, newCampaign.deadline);
        campaignCount++;
    }

    // 캠페인 상세 조회
    function getCampaign(uint _campaignId) public view returns (Campaign memory) {
        return campaigns[_campaignId];
    }

    // 주의: 이 함수는 가스비가 아주 많이 들 수 있습니다
    // 백엔드가 이벤트를 수집해서 정보를 보이게 하는 방식이 효율적입니다
    // 전체 캠페인 리스트 조회
    function getAllCampaigns() external view returns (Campaign[] memory) {
        Campaign[] memory result = new Campaign[](campaignCount);
        for (uint i = 0; i < campaignCount; i++) {
            result[i] = campaigns[i];
        }
        return result;
    }

    // 내가 만든 캠페인만 조회
    function getMyCampaigns() external view returns (Campaign[] memory) {
        uint[] memory myCampaignIds = campaignsByCreator[msg.sender];

        uint count = myCampaignIds.length;

        Campaign[] memory myCampaigns = new Campaign[](count);

        for (uint i = 0; i < count; i++) {
            uint campaignId = myCampaignIds[i];
            myCampaigns[i] = campaigns[campaignId];
        }
        return myCampaigns;
    }

    // 후원 내역 조회/설정
    function getContribution(uint _campaignId, address _user) public view returns (uint) {
        return contributions[_campaignId][_user];
    }

    // 캠페인 상태 갱신 함수: 출금 여부, 마감 시간 초과, 목표 금액 도달 여부
    // 함수가 계속 갱신된다는 가정
    function updateLabel(uint campaignId) public {
        Campaign storage c = campaigns[campaignId];
        Label oldLabel = c.label;
        if (c.withdrawn) {
            c.label = Label.Success;
        } else if (block.timestamp > c.deadline && c.totalFunded < c.goalAmount) {
            c.label = Label.Failure;
        } else if (c.totalFunded >= c.goalAmount) {
            c.label = Label.Success;
        } else {
            c.label = Label.InProgress;
        }
        if (uint8(oldLabel) != uint8(c.label)) {
            emit LabelUpdated(campaignId, uint8(c.label));
        }
    }

    // 캠페인 상태 라벨 반환 (업데이트 후 반환)
    function getCampaignStatusLabel(uint campaignId) external returns (string memory) {
        updateLabel(campaignId);
        Campaign memory c = campaigns[campaignId];
        if (c.label == Label.Success) return "success";
        if (c.label == Label.Failure) return "fail";
        return "on progress";
    }

    // 컨트랙트 잔액 조회
    function getBalance() external view returns (uint){
        return address(this).balance;
    }

    // 후원하기 (payable)
    function fundCampaign(uint campaignId) external payable {
        updateLabel(campaignId);
        Campaign storage c = campaigns[campaignId];
        require(c.label == Label.InProgress, "Campaign not in progress");
        require(msg.value > 0, "No ETH sent");
        c.totalFunded += msg.value;
        contributions[campaignId][msg.sender] += msg.value;
        emit Funded(campaignId, msg.sender, msg.value);
    }

    // 총 후원액 확인
    function getTotalFunded(uint campaignId) external view returns (uint) {
        return campaigns[campaignId].totalFunded;
    }

    // 환불
    function refund(uint campaignID) external {
        updateLabel(campaignID);
        Campaign storage c = campaigns[campaignID];
        require(c.label == Label.Failure, "Refund not available");
        uint amount = contributions[campaignID][msg.sender];
        require(amount > 0, "Not fundable amount");
        c.totalFunded -= amount;
        contributions[campaignID][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Refunded(campaignID, msg.sender, amount);
    }

    // 환불 가능 금액 조회
    function getRefundableAmount(uint campaignID, address funder) external view returns (uint){
        Campaign memory c = campaigns[campaignID];
        if (c.label == Label.Failure) {
            return contributions[campaignID][funder];
        }
        return 0;
    }

    // 출금 여부 확인
    function hasWithdrawn(uint campaignId) external view returns (bool) {
        return campaigns[campaignId].withdrawn;
    }

    // 출금 실행
    function withdrawFunds(uint campaignId) external onlyCreator(campaignId) {
        updateLabel(campaignId);
        Campaign storage c = campaigns[campaignId];
        require(c.label == Label.Success, "Not withdrawable");
        require(!c.withdrawn, "Already withdrawn");
        c.withdrawn = true;
        c.label = Label.Success;
        payable(c.creator).transfer(c.totalFunded);
        emit Withdrawn(campaignId, c.creator, c.totalFunded);
    }

    // 주의: 이 함수는 가스비가 아주 많이 들 수 있습니다
    // 백엔드가 이벤트를 수집해서 정보를 보이게 하는 방식이 효율적입니다
    // 마감 안된 캠페인만 조회
    function getActiveCampaigns() external view returns (Campaign[] memory) {
        uint[] memory tempIds = new uint[](campaignCount);
        uint count = 0;
        for (uint i = 0; i < campaignCount; i++) {
            if (campaigns[i].label == Label.InProgress) {
                tempIds[count] = i;
                count++;
            }
        }
        
        Campaign[] memory active = new Campaign[](count);
        for (uint j = 0; j < count; j++) {
            active[j] = campaigns[tempIds[j]];
        }
        return active;
    }

    // 목표 금액 도달 여부
    function checkGoalReached(uint campaignId) external view returns (bool) {
        return campaigns[campaignId].totalFunded >= campaigns[campaignId].goalAmount;
    }

    // 마감 시간 초과 여부
    function hasCampaignEnded(uint campaignId) external view returns (bool) {
        return block.timestamp > campaigns[campaignId].deadline;
    }

    // 펀딩 가능한 상태인지 확인
    function isFundingOpen(uint campaignId) external view returns (bool) {
        Campaign memory c = campaigns[campaignId];
        return (block.timestamp <= c.deadline && c.label == Label.InProgress);
    }

    // 마감까지 남은 시간(초)
    function getTimeRemaining(uint campaignId) external view returns (uint) {
        Campaign memory c = campaigns[campaignId];
        if (block.timestamp >= c.deadline) {
            return 0;
        }
        return c.deadline - block.timestamp;
    }
} 
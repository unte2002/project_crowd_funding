// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {

    enum Label {
        InProgress, // 진행 중
        Success,    // 성공
        Failure     // 실패
    }


    // 캠페인 구조체
    struct Campaign {
        uint    campaignId;         // 캠페인 식별 번호 (0부터 증가)
        uint    goalAmount;         // 목표 금액 (단위: wei)
        uint    durationInDays;     // 마감까지 남은 일 수
        uint    deadline;           // 캠페인 마감 Unix 타임스탬프
        address creator;            // 캠페인 생성자
        uint    totalFunded;        // 현재까지 모금된 총 ETH (wei)
        bool    withdrawn;          // 창작자가 출금했는지 여부
        Label   label;              // 상태 텍스트 ("진행중", "성공", "실패" 등)
    }

    // setter 함수에 제한할 용도
    modifier onlyCreator(uint campaignId) {
        require(msg.sender == campaigns[campaignId].creator, "Not creator");
        _;
    }


    // 캠페인 ID 증가용 카운터
    uint public campaignCount;

    // 캠페인 정보 저장
    mapping(uint => Campaign) public campaigns;

    // 캠페인별 후원 내역 (후원자 → 금액)
    mapping(uint => mapping(address => uint)) public contributions;

    // 이재민님

    // createCampaign(goal, duration) | 캠페인 생성

    // getCampaign(campaignId) | 캠페인 상세 조회

    function getCampaign(uint _campaignId) public view returns(Campaign memory){
        return campaigns[_campaignId];
    }

    // getAllCampaigns() | 전체 캠페인 리스트 조회

    // getMyCampaigns() | 자신이 만든 캠페인만 조회

    function getContribution(uint _campaignId, address _user) public view returns(uint) {
        return contributions[_campaignId][_user];
    }

    // whitelist modifier 있으면 좋긴한데 프로토타입이니까
    function setContribution(uint _campaignId, address _user, uint amount) public {
        contributions[_campaignId][_user] = amount;
    }



    // 후원자 주소 (함수 매개변수로 사용)
    // address funder;

    // 전송된 금액 (함수 매개변수로 사용)
    // uint amount;

    // 현재 시각 (함수 내 block.timestamp 사용)
    // uint currentTime;

    // 참고:
    // - `funder`, `amount`, `currentTime`은 상태 변수로 선언하지 않고 함수 호출 시 매개변수나 내부에서 사용합니다.
    // - 구조체 내에 이미 모든 상태를 담고 있으므로 외부 상태 변수로 반복 선언하지 않습니다.
}

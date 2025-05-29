// 출금 여부 확인
function hasWithdrawn(uint campaignId) external view returns (bool) {
    return campaigns[campaignId].withdrawn;
}

// 출금 실행
function withdrawFunds(uint campaignId) external onlyCreator(campaignId) {
    //onlyCreator는 이미 있는 모디파이어 사용
    Campaign storage c = campaigns[campaignId];

    require(block.timestamp > c.deadline, "Campaign not ended yet");
    require(c.totalFunded >= c.goalAmount, "Goal not reached");
    require(!c.withdrawn, "Already withdrawn");

    c.withdrawn = true;
    c.label = Label.Success;

    payable(c.creator).transfer(c.totalFunded);
}

// 상태 반환
function campaignStatus(uint campaignId) public view returns (string memory) {
    Campaign memory c = campaigns[campaignId];

    if (c.withdrawn) return "Success";
    if (block.timestamp > c.deadline && c.totalFunded < c.goalAmount) return "Failure";
    return "In Progress";
}

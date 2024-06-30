// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeFiStaking {
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public rewardRate;
    uint256 public totalStaked;

    struct Staker {
        uint256 balance;
        uint256 rewards;
        uint256 lastUpdateTime;
    }

    mapping(address => Staker) public stakers;

    constructor(address _stakingToken, address _rewardToken, uint256 _rewardRate) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRate = _rewardRate;
    }

    function stake(uint256 amount) external {
        updateRewards(msg.sender);
        stakingToken.transferFrom(msg.sender, address(this), amount);
        stakers[msg.sender].balance += amount;
        totalStaked += amount;
    }

    function withdraw(uint256 amount) external {
        require(stakers[msg.sender].balance >= amount, "Not enough balance to withdraw");
        updateRewards(msg.sender);
        stakingToken.transfer(msg.sender, amount);
        stakers[msg.sender].balance -= amount;
        totalStaked -= amount;
    }

    function claimReward() external {
        updateRewards(msg.sender);
        uint256 reward = stakers[msg.sender].rewards;
        stakers[msg.sender].rewards = 0;
        rewardToken.transfer(msg.sender, reward);
    }

    function updateRewards(address staker) internal {
        stakers[staker].rewards += calculateRewards(staker);
        stakers[staker].lastUpdateTime = block.timestamp;
    }

    function calculateRewards(address staker) internal view returns (uint256) {
        return (block.timestamp - stakers[staker].lastUpdateTime) * rewardRate * stakers[staker].balance / 1e18;
    }
}

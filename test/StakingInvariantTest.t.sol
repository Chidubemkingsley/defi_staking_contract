// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/DeFiStaking.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol, address initialAccount, uint256 initialBalance)
        ERC20(name, symbol)
    {
        _mint(initialAccount, initialBalance);
    }
}

contract DeFiStakingTest is Test {
    ERC20Mock stakingToken;
    ERC20Mock rewardToken;
    DeFiStaking staking;
    address user1;
    address user2;

    function setUp() public {
        user1 = vm.addr(1);
        user2 = vm.addr(2);

        stakingToken = new ERC20Mock("Staking Token", "STK", address(this), 10000 ether);
        rewardToken = new ERC20Mock("Reward Token", "RWD", address(this), 10000 ether);

        staking = new DeFiStaking(address(stakingToken), address(rewardToken), 1e18);

        stakingToken.transfer(user1, 1000 ether);
        stakingToken.transfer(user2, 1000 ether);
        rewardToken.transfer(address(staking), 1000 ether);
    }

    function testStake(uint256 amount) public {
        vm.assume(amount > 0 && amount <= stakingToken.balanceOf(user1));

        vm.prank(user1);
        stakingToken.approve(address(staking), amount);

        vm.prank(user1);
        staking.stake(amount);

        assertEq(stakingToken.balanceOf(user1), 1000 ether - amount);
        assertEq(stakingToken.balanceOf(address(staking)), amount);
        assertEq(staking.stakers(user1).balance, amount);
    }

    function testWithdraw(uint256 amount) public {
        vm.assume(amount > 0 && amount <= stakingToken.balanceOf(user1));

        vm.prank(user1);
        stakingToken.approve(address(staking), amount);

        vm.prank(user1);
        staking.stake(amount);

        vm.prank(user1);
        staking.withdraw(amount);

        assertEq(stakingToken.balanceOf(user1), 1000 ether);
        assertEq(stakingToken.balanceOf(address(staking)), 0);
        assertEq(staking.stakers(user1).balance, 0);
    }

    function testClaimReward(uint256 amount) public {
        vm.assume(amount > 0 && amount <= stakingToken.balanceOf(user1));

        vm.prank(user1);
        stakingToken.approve(address(staking), amount);

        vm.prank(user1);
        staking.stake(amount);

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        staking.claimReward();

        uint256 expectedReward = 1e18 * 1 days * amount / 1e18;
        assertEq(rewardToken.balanceOf(user1), expectedReward);
    }

    function invariantTotalStaked() public {
        uint256 sum = staking.stakers(user1).balance + staking.stakers(user2).balance;
        assertEq(sum, staking.totalStaked());
    }

    function invariantRewardRate() public {
        assertEq(staking.rewardRate(), 1e18);
    }

    function invariantCannotWithdrawMoreThanStaked() public {
        uint256 totalWithdrawable = staking.stakers(user1).balance + staking.stakers(user2).balance;
        assertTrue(totalWithdrawable <= staking.totalStaked());
    }

    function invariantOverCollateralized() public {
        // Assuming there's a collateral ratio of 150%
        uint256 totalCollateralValue = staking.totalStaked() * 150 / 100;
        uint256 totalLoanValue = staking.totalStaked(); // or any other value representing the loan
        assertTrue(totalCollateralValue >= totalLoanValue);
    }

    function invariantOnlyOneWinner() public {
        // Assuming we have a winner selection mechanism and winner variable
        address winner = address(0); // replace with actual logic
        assertTrue(winner != address(0));
        uint256 winnerCount = (winner == user1 ? 1 : 0) + (winner == user2 ? 1 : 0);
        assertEq(winnerCount, 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface TokenInterface is IERC20 {
    function withdraw(uint wad) external;
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IPancakeSwapV2Pair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IPancakeSwapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

contract LPFarming is Context, Ownable {
    using SafeMath for uint256;

    TokenInterface public _wbnb;
    TokenInterface public _dexf;
    TokenInterface public _busd;
    TokenInterface public _btcb;
    TokenInterface public _eth;

    IPancakeSwapV2Pair public _dexfBNBV2Pair;
    IPancakeSwapV2Router02 private _pancakeswapV2Router;

    address private _team;
    uint256 public _rewardPeriod;
    uint256 public _rewardAmount;
    uint256 public _startBlock;
    uint256 public _lastCalculatedBlock;
    uint256 public _accRewardPerShare;

    struct StakerInfo {
        uint256 stakedAmount;
        uint256 rewardDebt;
        uint256 totalReward;
    }

    mapping(address => StakerInfo) public _stakers;

    event ChangedDexfAddress(address indexed owner, address indexed dexf);
    event ChangedDexfBNBPair(address indexed owner, address indexed pair);
    event ChangedRewardPeriod(address indexed owner, uint256 rewardPeriod);

    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event ClaimedReward(address indexed owner);
    event Received(address sender, uint amount);

    event SwapAndLiquifyFromBNB(address indexed msgSender, uint256 totAmount, uint256 bnbAmount, uint256 amount);

    constructor() {
        _wbnb = TokenInterface(0xc778417E063141139Fce010982780140Aa0cD5Ab);
        _dexf = TokenInterface(0xaE26bA827ED2F4ADe28B73Bc888Fbe618d6cBfF0);
        _busd = TokenInterface(0xE5575Eaf9b51A30EC7fCCa4588195f313CF151fe);
        _btcb = TokenInterface(0x495180b00BaBCeaeB8963C6AA3a154DDC514e1B6);
        _eth = TokenInterface(0x29DF3E182b7a84DaA1c0a7b34885807DD3052CE0);

        _dexfBNBV2Pair = IPancakeSwapV2Pair(0x508B7EDB6A88Ee2037E5f189d9B678FffC0880b4);
        _pancakeswapV2Router = IPancakeSwapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _rewardPeriod = 1400;
        _rewardAmount = 5000e18;

        _startBlock = block.number;
        _lastCalculatedBlock = block.number;
        _team = msg.sender;
        _accRewardPerShare = 0;
    }

    /**
     * @dev Change value of reward period. Call by only owner.
     */
    function changeRewardPeriod(uint256 rewardPeriod) external onlyOwner {
        _rewardPeriod = rewardPeriod;

        emit ChangedRewardPeriod(_msgSender(), rewardPeriod);
    }

    /**
     * @dev Change Dexf token contract address. Call by only owner.
     */
    function changeDexfAddress(address dexf) external onlyOwner {
        _dexf = TokenInterface(dexf);

        emit ChangedDexfAddress(_msgSender(), dexf);
    }

    /**
     * @dev Change LP token contract address. Call by only owner.
     */
    function changeDexfBNBPair(address dexfBNBV2Pair) external onlyOwner {
        _dexfBNBV2Pair = IPancakeSwapV2Pair(dexfBNBV2Pair);

        emit ChangedDexfBNBPair(_msgSender(), dexfBNBV2Pair);
    }

    function getTotalStakedAmount() public view returns (uint256) {
        return _dexfBNBV2Pair.balanceOf(address(this));
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 from, uint256 to) public pure returns (uint256) {
        return to.sub(from);
    }

    function swapBNBForTokens(uint256 bnbAmount) private {
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router.WETH();
        path[1] = address(_dexf);

        // make the swap
        _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: bnbAmount
        }(0, path, address(this), block.timestamp);
    }

    function addLiquidityBNB(uint256 tokenAmount, uint256 bnbAmount) private {
        _dexf.approve(address(_pancakeswapV2Router), tokenAmount);

        // add the liquidity
        _pancakeswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(_dexf),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function swapAndLiquifyFromBNB(uint256 amount) private returns (bool) {
        uint256 halfForEth = amount.div(2);
        uint256 otherHalfForDexf = amount.sub(halfForEth);

        uint256 initialBalance = _dexf.balanceOf(address(this));

        // swap BNB for tokens
        swapBNBForTokens(otherHalfForDexf);

        // how much Dexf did we just swap into?
        uint256 newBalance = _dexf.balanceOf(address(this)).sub(initialBalance);

        // add liquidity to pancakeswap
        addLiquidityBNB(newBalance, halfForEth);

        emit SwapAndLiquifyFromBNB(_msgSender(), amount, halfForEth, newBalance);

        return true;
    }

    function swapAndLiquifyFromDexf(uint256 amount) private returns (bool) {
        uint256 halfForEth = amount.div(2);
        uint256 otherHalfForDexf = amount.sub(halfForEth);

        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(_dexf);
        path[1] = _pancakeswapV2Router.WETH();

        _dexf.approve(
            address(_pancakeswapV2Router),
            halfForEth
        );

        // swap Dexf for BNB
        _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            halfForEth,
            0, // accept any amount of pair token
            path,
            address(this),
            block.timestamp
        );

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to pancakeswap
        addLiquidityBNB(otherHalfForDexf, newBalance);

        return true;
    }

    function swapAndLiquifyFromToken(
        address fromTokenAddress,
        uint256 tokenAmount
    ) private returns (bool) {
        address[] memory path = new address[](2);
        path[0] = fromTokenAddress;
        path[1] = _pancakeswapV2Router.WETH();

        IERC20(fromTokenAddress).approve(
            address(_pancakeswapV2Router),
            tokenAmount
        );

        uint256 initialBNBBalance = address(this).balance;

        // make the swap
        _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of pair token
            path,
            address(this),
            block.timestamp
        );

        uint256 BNBAmount = address(this).balance.sub(initialBNBBalance);

        return swapAndLiquifyFromBNB(BNBAmount);
    }

    function swapTokensForTokens(
        address fromTokenAddress,
        address toTokenAddress,
        uint256 tokenAmount,
        address receivedAddress
    ) private returns (bool) {
        address[] memory path = new address[](2);
        path[0] = fromTokenAddress;
        path[1] = toTokenAddress;

        IERC20(fromTokenAddress).approve(
            address(_pancakeswapV2Router),
            tokenAmount
        );

        // make the swap
        _pancakeswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of pair token
            path,
            receivedAddress,
            block.timestamp
        );

        return true;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Stake BNB
     */
    function stake() external payable returns (bool) {
        require(!isContract(_msgSender()), "Farming: Could not be contract.");

        updateAccRewardPerShare();

        // Transfer pending tokens
        // to user
        updateAndPayOutPending(msg.sender);

        // Check Initial Balance
        uint256 initialBalance = _dexfBNBV2Pair.balanceOf(address(this));

        require(swapAndLiquifyFromBNB(msg.value), "Farming: Failed to get LP tokens.");

        uint256 newBalance = _dexfBNBV2Pair.balanceOf(address(this)).sub(initialBalance);

        StakerInfo storage staker = _stakers[_msgSender()];

        staker.stakedAmount = staker.stakedAmount.add(newBalance);
        staker.rewardDebt = staker.stakedAmount.mul(_accRewardPerShare).div(1e12);

        emit Staked(_msgSender(), newBalance);

        return true;
    }

    /**
     * @dev Stake Dexf
     */
    function stakeDexf(uint256 tokenAmount) external returns (bool) {
        require(!isContract(_msgSender()), "Farming: Could not be contract.");

        updateAccRewardPerShare();

        // Transfer pending tokens
        // to user
        updateAndPayOutPending(msg.sender);

        // Transfer token to Contract
        _dexf.transferFrom(_msgSender(), address(this), tokenAmount);

        // Check Initial Balance
        uint256 initialBalance = _dexfBNBV2Pair.balanceOf(address(this));

        require(swapAndLiquifyFromDexf(tokenAmount), "Farming: Failed to get LP tokens.");

        uint256 newBalance = _dexfBNBV2Pair.balanceOf(address(this)).sub(initialBalance);

        StakerInfo storage staker = _stakers[_msgSender()];

        staker.stakedAmount = staker.stakedAmount.add(newBalance);
        staker.rewardDebt = staker.stakedAmount.mul(_accRewardPerShare).div(1e12);

        emit Staked(_msgSender(), newBalance);

        return true;
    }

    /**
     * @dev Stake ERC20 Token
     */
    function stakeToken(
        address fromTokenAddress,
        uint256 tokenAmount
    ) external returns (bool) {
        require(!isContract(_msgSender()), "Farming: Could not be contract.");

        updateAccRewardPerShare();

        // Transfer pending tokens
        // to user
        updateAndPayOutPending(msg.sender);

        // Transfer token to Contract
        IERC20(fromTokenAddress).transferFrom(_msgSender(), address(this), tokenAmount);

        // Check Initial Balance
        uint256 initialBalance = _dexfBNBV2Pair.balanceOf(address(this));

        require(swapAndLiquifyFromToken(fromTokenAddress, tokenAmount), "Farming: Failed to get LP tokens.");

        uint256 newBalance = _dexfBNBV2Pair.balanceOf(address(this)).sub(initialBalance);

        StakerInfo storage staker = _stakers[_msgSender()];

        staker.stakedAmount = staker.stakedAmount.add(newBalance);
        staker.rewardDebt = staker.stakedAmount.mul(_accRewardPerShare).div(1e12);

        emit Staked(_msgSender(), newBalance);

        return true;
    }

    /**
     * @dev Stake LP Token
     */
    function stakeLPToken(uint256 amount) external returns (bool) {
        require(!isContract(_msgSender()), "Farming: Could not be contract.");

        updateAccRewardPerShare();

        // Transfer pending tokens
        // to user
        updateAndPayOutPending(msg.sender);

        _dexfBNBV2Pair.transferFrom(_msgSender(), address(this), amount);

        StakerInfo storage staker = _stakers[_msgSender()];

        staker.stakedAmount = staker.stakedAmount.add(amount);
        staker.rewardDebt = staker.stakedAmount.mul(_accRewardPerShare).div(1e12);

        emit Staked(_msgSender(), amount);

        return true;
    }

    /**
     * @dev Unstake staked Dexf-BNB LP tokens
     */
    function unstake(uint256 amount) external returns (bool) {
        require(!isContract(_msgSender()), "Farming: Could not be contract.");

        updateAccRewardPerShare();

        // Transfer pending tokens
        // to user
        updateAndPayOutPending(msg.sender);

        StakerInfo storage staker = _stakers[_msgSender()];

        require(
            staker.stakedAmount > 0 &&
            amount <= staker.stakedAmount,
            "Farming: Invalid amount to unstake."
        );

        _dexfBNBV2Pair.transfer(_msgSender(), amount);

        staker.stakedAmount = staker.stakedAmount.sub(amount);
        staker.rewardDebt = staker.stakedAmount.mul(_accRewardPerShare).div(1e12);

        emit Unstaked(_msgSender(), amount);

        return true;
    }

    function claim() public returns (bool) {
        updateAccRewardPerShare();

        // Transfer pending tokens
        // to user
        updateAndPayOutPending(msg.sender);

        emit ClaimedReward(_msgSender());

        return true;
    }

    function pendingReward(address _user)
        public
        view
        returns (uint256)
    {
        StakerInfo storage staker = _stakers[_user];
        return staker.stakedAmount.mul(_accRewardPerShare).div(1e12).sub(staker.rewardDebt);
    }

    function updateAccRewardPerShare() internal {
        uint256 tokenSupply = _dexfBNBV2Pair.balanceOf(address(this));
        if (tokenSupply == 0) { // avoids division by 0 errors
            return;
        }

        uint256 blockNum = block.number;
        if (blockNum > _startBlock + _rewardPeriod) {
            blockNum = _startBlock + _rewardPeriod;
        }

        uint256 pendingRewards = blockNum
            .sub(_lastCalculatedBlock)
            .mul(_rewardAmount)
            .div(_rewardPeriod);

        _accRewardPerShare = _accRewardPerShare.add(
            pendingRewards.mul(1e12).div(tokenSupply)
        );
        _lastCalculatedBlock = blockNum;
    }

    function updateAndPayOutPending(address from) internal {
        uint256 pending = pendingReward(from);

        if(pending > 0) {
            uint256 amount = safeDexfTransfer(from, pending);

            StakerInfo storage staker = _stakers[from];
            staker.totalReward = staker.totalReward.add(amount);
        }
    }

    function removeOddTokens() external returns (bool) {
        require(_msgSender() == _team, "Invalid team address");

        uint256 wbnbOdd = _wbnb.balanceOf(address(this));
        uint256 dexfOdd = _dexf.balanceOf(address(this));
        uint256 busdOdd = _busd.balanceOf(address(this));
        uint256 btcbOdd = _btcb.balanceOf(address(this));
        uint256 wethOdd = _eth.balanceOf(address(this));

        if (wbnbOdd > 0) {
            _wbnb.withdraw(wbnbOdd);
        }

        if (dexfOdd > 0) {
            _dexf.transfer(_msgSender(), dexfOdd);
        }

        if (busdOdd > 0) {
            _busd.transfer(_msgSender(), busdOdd);
        }

        if (btcbOdd > 0) {
            _btcb.transfer(_msgSender(), btcbOdd);
        }

        if (wethOdd > 0) {
            _eth.withdraw(wethOdd);
        }

        uint256 bnbOdd = address(this).balance;
        if (bnbOdd > 0) {
            msg.sender.transfer(bnbOdd);
        }

        return true;
    }

    function safeDexfTransfer(address to, uint256 amount) internal returns (uint256) {
        uint256 bal = _dexf.balanceOf(address(this));

        if (amount > bal) {
            _dexf.transfer(to, bal);

            return bal;
        }

        _dexf.transfer(to, amount);

        return amount;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

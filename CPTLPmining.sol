pragma solidity ^0.5.1;

contract ERC20token{
   function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
   function transfer(address _to,uint256 _value) public returns (bool success);
   function balanceOf(address _address) public view returns (uint);

}

library SafeMath {
   function add(uint a, uint b) public pure returns (uint c) {
       c = a + b;
       require(c >= a);
   }
   function sub(uint a, uint b) public pure returns (uint c) {
       require(b <= a);
       c = a - b;
   }
   function mul(uint a, uint b) public pure returns (uint c) {
       c = a * b;
       require(a == 0 || c / a == b);
   }
   function div(uint a, uint b) public pure returns (uint c) {
       require(b > 0);
       c = a / b;
   }
}

contract  CPTLPmining   {

    using SafeMath for uint256;

    address public owner;
    uint256 public lastRewardBlock ;
    uint256 public accCPTPerShare = 0;
    uint256 public CPTPerBlock ;
    uint256 public endBlock ;

    struct UserInfo {
            uint256 amount;
            uint256 rewardDebt;
    }

mapping (address => UserInfo) public userMap;

ERC20token LPtoken;
ERC20token CPT;

constructor(
    address _address1, address _address2, uint256 _lastRewardBlock, uint256 _CPTPerBlock,uint256 _endBlock
  ) public {
        owner = msg.sender;
        lastRewardBlock = _lastRewardBlock;
        CPTPerBlock = _CPTPerBlock;
        endBlock = _endBlock;
        LPtoken = ERC20token(_address1);
        CPT = ERC20token(_address2);
        }

modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

event Deposit(address indexed user,  uint256 amount);
event Withdraw(address indexed user,  uint256 amount);

function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
    if (_to>endBlock ) {
        return endBlock.sub(_from);
    }else{
        return _to.sub(_from);
    }
        }



function pendingCPT( address _user) external view returns (uint256) {

    UserInfo storage user = userMap[_user];
    uint256 accCPTPerShare = accCPTPerShare;
    uint256 lpSupply =  LPtoken.balanceOf(address(this));
    if (block.number > lastRewardBlock && lpSupply != 0) {
        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 CPTReward = multiplier.mul(CPTPerBlock);
        accCPTPerShare = accCPTPerShare.add(CPTReward.div(lpSupply));
    }
    return user.amount.mul(accCPTPerShare).sub(user.rewardDebt);
}



function updatePool( ) internal {
    if (block.number <= lastRewardBlock) {
        return;
    }
    uint256 lpSupply = LPtoken.balanceOf(address(this));
    if (lpSupply == 0) {
        lastRewardBlock = block.number<endBlock? block.number : endBlock;
        return;
    }
    uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
    uint256 CPTReward = multiplier.mul(CPTPerBlock);

    accCPTPerShare =accCPTPerShare.add(CPTReward.div(lpSupply));
    lastRewardBlock = block.number<endBlock? block.number : endBlock;

}



function deposit( uint256 _amount) public {
    require(block.number< endBlock );
    UserInfo storage user = userMap[msg.sender];
    updatePool( );
    if (user.amount > 0) {
        uint256 pending = user.amount.mul(accCPTPerShare).sub(user.rewardDebt);
        CPT.transfer(msg.sender, pending);
    }
    LPtoken.transferFrom ( msg.sender, address(this), _amount);
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.amount.mul(accCPTPerShare);
    emit Deposit(msg.sender, _amount);
}


function withdraw( uint256 _amount) public {
    UserInfo storage user = userMap[msg.sender];
    require(user.amount >= _amount, "withdraw: not good");
    updatePool( );
    uint256 pending = user.amount.mul(accCPTPerShare).sub(user.rewardDebt);
    CPT.transfer(msg.sender, pending);
    user.amount = user.amount.sub(_amount);
    user.rewardDebt = user.amount.mul(accCPTPerShare);
    LPtoken.transfer ( msg.sender , _amount);
    emit Withdraw(msg.sender,  _amount);
}

/// During testing, we assume miners will collect crypto within 30 Block Time,
/// otherwise it will be automatically recalled
function withdramLeftCPTs() external onlyowner{
     require (block.number >= endBlock.add(30));
     uint256 leftTokens = CPT.balanceOf(address(this));
     CPT.transfer(owner, leftTokens);

}
}

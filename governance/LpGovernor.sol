// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "../../openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "../../openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../../openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "./GovernorAlpha.sol";
import "./RewardDistribution.sol";

contract LpGovernor is
    Initializable,
    ContextUpgradeable,
    ERC20Upgradeable,
    GovernorAlpha,
    RewardDistribution
{
    // admin:  to mint/burn token
    address internal _minter;

    /**
     * @notice  Initialize LpGovernor instance.
     *
     * @param   name        ERC20 name of token.
     * @param   symbol      ERC20 symbol of token.
     * @param   minter      The role that has privilege to mint / burn token.
     * @param   target      The target of execution, all action of proposal will be send to target.
     * @param   rewardToken The ERC20 token used as reward of mining / reward distribution.
     * @param   poolCreator The address of pool creator, whose owner will be the owner of governor.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address minter,
        address target,
        address rewardToken,
        address poolCreator
    ) public virtual initializer {
        __ERC20_init_unchained(name, symbol);
        __GovernorAlpha_init_unchained(target);
        __RewardDistribution_init_unchained(rewardToken, poolCreator);

        _minter = minter;
        _target = target;
    }

    function getMinter() public view returns (address) {
        return _minter;
    }

    /**
     * @notice  Mint token to account.
     */
    function mint(address account, uint256 amount) public virtual {
        require(_msgSender() == _minter, "must be minter to mint");
        _mint(account, amount);
    }

    /**
     * @notice  Burn token from account. Voting will block also block burning.
     */
    function burn(address account, uint256 amount) public virtual {
        require(_msgSender() == _minter, "must be minter to burn");
        _burn(account, amount);
    }

    function isLocked(address account) public virtual returns (bool) {
        return GovernorAlpha.isLockedByVoting(account);
    }

    /**
     * @notice  Override ERC20 balanceOf.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override(ERC20Upgradeable, GovernorAlpha, RewardDistribution)
        returns (uint256)
    {
        return ERC20Upgradeable.balanceOf(account);
    }

    /**
     * @notice  Override ERC20 balanceOf.
     */
    function totalSupply()
        public
        view
        virtual
        override(ERC20Upgradeable, GovernorAlpha, RewardDistribution)
        returns (uint256)
    {
        return ERC20Upgradeable.totalSupply();
    }

    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(!isLocked(sender), "sender is locked");
        _updateReward(sender);
        _updateReward(recipient);
        super._beforeTokenTransfer(sender, recipient, amount);
    }

    bytes32[50] private __gap;
}

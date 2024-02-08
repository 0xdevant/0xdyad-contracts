// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {VaultManager} from "./VaultManager.sol";
import {Dyad}         from "./Dyad.sol";
import {Vault}        from "./Vault.sol";
import {IVault}       from "../interfaces/IVault.sol";

import {ERC20}         from "@solmate/src/tokens/ERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract BoundedKerosineVault is IVault {
  using EnumerableSet   for EnumerableSet.AddressSet;

    // TODO: add a limit to the number of vaults
  EnumerableSet.AddressSet private vaults;

  VaultManager  public immutable vaultManager;
  ERC20         public immutable asset;
  Dyad          public immutable dyad;

  mapping(uint => uint) public id2asset;

  modifier onlyVaultManager() {
    if (msg.sender != address(vaultManager)) revert NotVaultManager();
    _;
  }

  constructor(
    VaultManager  _vaultManager,
    ERC20         _asset, 
    Dyad          _dyad
  ) {
    vaultManager   = _vaultManager;
    asset          = _asset;
    dyad           = _dyad;
  }

  function deposit(
    uint id,
    uint amount
  )
    external 
      onlyVaultManager
  {
    id2asset[id] += amount;
    emit Deposit(id, amount);
  }

  function move(
    uint from,
    uint to,
    uint amount
  )
    external
      onlyVaultManager
  {
    id2asset[from] -= amount;
    id2asset[to]   += amount;
    emit Move(from, to, amount);
  }

  function getUsdValue(
    uint id
  )
    external
    view 
    returns (uint) {
      return id2asset[id] * assetPrice() * 2;
  }

  function assetPrice() 
    public 
    view 
    returns (uint) {
      uint tvl;
      uint numberOfVaults = vaults.length();
      for (uint i = 0; i < numberOfVaults; i++) {
        Vault vault = Vault(vaults.at(i));
        tvl += vault.asset().balanceOf(address(vault)) * vault.assetPrice();
      }
      return (tvl - dyad.totalSupply()) / asset.totalSupply();
  }
}

## Fork changes
This Fork contains:
* **Fixes** for several issues with [original Codex Arcanum mod](https://github.com/itayfeder/Codex-Arcanum) without introducing any major (except for bugfixes) gameplay changes
* **API refactoring** (migrated to SMODS API)
* **Compressed art**
* **Compatibility** with other mods like [**Bunco**](https://github.com/Firch/Bunco), [**Ortalab**](https://github.com/Eremel/Ortalab), [**Pokermon**](https://github.com/InertSteak/Pokermon), [**Talisman**](https://github.com/MathIsFun0/Talisman), etc. 

<ins>Any bug/incompatibility reports are welcome</ins>, but before reporting any issue please reset your game progress and confirm if issue is still here.

Also check out [**Redux Arcanum**](https://github.com/jumbocarrot0/Redux-Arcanum)!

## Branch changes

Except for Fork changes, this branch also introduces:
* New Sticker - Synthesized: Card will return to its original state after 1 round. Basically that IS original mod's mechanic, but now you got marker that will help you distinguish enhanced cards and alchemically enhanced cards.
Also, it says `to its original`, meaning that if it was, for example, Wild card and you used Silver to make it Lucky card, it will become back Wild card when Blind is completed, unlike original mod where it will become Base card. Note, that if you use Silver and then Chariot, it will ignore Chariot effect and card still will be returned to what it was before Silver.
And also - it says `after 1 round`, right? Well, we all knows what can happen with numbers in effects description...
* Changed Mutated Joker Chips per unique Alchemical from +10 to +15 (just remember about the fact that Runner is a Common Joker too)
* Blueprint that copies Studious Joker now can be sold for Alchemical! (I'm sure everyone wanted this)
* Chain Reaction will not give Negative edition to copies, but will copy card edition properly
* Antimony makes copied Jokers cost $0 instead of being Eternal (now you can freely sell it to win Boss Blind), but if you build contains Swashbuckler and you copy... like... Egg... Well, nuh uh!
* Cauldron voucher require 40 Alchemical cards to be selected from any Alchemy Pack to be unlocked
* Alchemical Tycoon voucher require 10 Alchemical cards to be bought from shop to be unlocked
* New Alchemical - Lithium: Removes Eternal, Perishable, Rental and Debuff from selected Joker. 
Unlocks by beating Crimson Heart or Verdant Leaf
* New Alchemical - Honey: Disables Boss Blind effect (similar to Chicot / selling Luchador), but sets Blind reward to $0.
Unlocks by beating The Wall or Violet Vessel
* New Alchemical - Chlorine: Enhances up to 3 cards to Wild card.
Unlocks by having at least 6 Wild cards in full deck
* New Alchemical - Stone: Enhances up to 3 cards to Stone card.
Unlocks by having at least 8 Stone cards in full deck

Add new unlock conditions:
* Uranium require 10 (was 5) Alchemical cards to be used in the same run to be unlocked
* Sliver, Gold, Manganese and Glass require having at least 8 Lucky, Gold, Steel and Glass cards respectively
* Oil requires to play debuffed card
* Acid requires to have more than 68 cards in your full deck
* Brimstone requires to discard a **Pair** **2**'s
* Philosopher's Deck requires to discover a Philosopher's Stone card
* Herbalist's Deck requires to discover The Seeker card
* Chain Reaction requires to discover 24 or more Alchemical cards (That's kinda harder than before cuz only 12 of them is unlocked by default)
* Breaking Bozo requires to use 5 or more Alchemical cards and then DIE before 6 ante
* Catalyst Joker requires to use 4 or more consumables within one Blind
---

<p align="center">
  <a href="" rel="noopener">
 <img width=600px src="promos/logo.png?raw=true" alt="Project logo"></a>
</p>


<div align="center">

[![Status](https://img.shields.io/badge/status-active-success.svg)]()
[![GitHub Issues Original](https://img.shields.io/github/issues/itayfeder/Codex-Arcanum.svg)](https://github.com/itayfeder/Codex-Arcanum/issues)
[![GitHub Issues Fork](https://img.shields.io/github/issues/AirBurn0/Codex-Arcanum.svg)](https://github.com/AirBurn0/Codex-Arcanum/issues)
[![License](https://img.shields.io/badge/license-GNU-blue.svg)](/LICENSE)

</div>

---

<p align="center"> A new alchemical expansion for Balatro!
    <br> 
</p>

## 📝 Table of Contents

- [About](#about)
- [How to Download](#how_to_download)
- [Credits](#credits)

## 🧐 About <a name = "about"></a>

**Codex Arcanum** is a mod that aims to expand Balatro by adding a new type of consumable card: **Alchemical Cards**!

It adds:
 
<img width=800px src="promos/content.png?raw=true" alt="Content"></a>

**Alchemical cards** possess powerful abilities that you can use during single Blind, like adding hands and discards, drawing cards, reducing the blind, and much more!

<img width=800px src="promos/alchemicals_1.png?raw=true" alt="Alchemicals 1"></a>

<img width=800px src="promos/alchemicals_2.png?raw=true" alt="Alchemicals 2"></a> 

<img width=800px src="promos/alchemicals_3.png?raw=true" alt="Alchemicals 3"></a>

**New Jokers** will help with alchemical cards game experience.

<img width=800px src="promos/jokers.png?raw=true" alt="Jokers"></a>

## ⬇ How to Download <a name = "how_to_download"></a>

- Install [Steamodded](https://github.com/Steamodded/smods/wiki)

### With git

- Open Command line in `%appdata%/Balatro/Mods` folder and execute `git clone https://github.com/AirBurn0/Codex-Arcanum`

To receive any updates just execute `git pull` in mod folder.

For alternative versions (like rebalance):

- Navigate to Codex Arcanum mod folder (probably will be `%appdata%/Balatro/Mods/Codex-Arcanum`), open Command line and execute `git branch` to see list of available branches, then execute `git checkout [branch-name]`.
### Without git
- Download repo as Zip

![image](https://github.com/user-attachments/assets/ed6b6c40-818f-4468-9f8b-ed52d0fed185)

- Extract `Codex-Arcanum` __folder__ into `%appdata%/Balatro/Mods`. Mod folder will be: `%appdata%/Balatro/Mods/Codex-Arcanum`.

For alternative versions (like rebalance):

![image](https://github.com/user-attachments/assets/2efd96a0-f79b-4154-be19-c616a8e37997)

- Choose any of existed branches, then click on it and download branch repo as Zip as described earlier.

## 🎉 Credits <a name = "credits"></a>

- The original mod was written by [**Itayfeder**](https://github.com/stars/itayfeder/lists/balatro-modding);
- Art created by [**Lyman**](https://github.com/spikeof2010);
- Fixes and reworks introduced by [**Jumbo**](https://github.com/jumbocarrot0), [**lshtech**](https://github.com/lshtech) and [**AirBurn**](https://github.com/AirBurn0).
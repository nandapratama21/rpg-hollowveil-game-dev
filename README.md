# Name: Muhammad Nanda Pratama

## 📝 Introduction

**Hollowveil** is a charming top-down adventure RPG where you play as Aren, a shipwreck survivor who washes up on a mysterious island. After regaining consciousness on an unfamiliar beach, Aren must explore the island, uncovering its secrets and the strange events that have twisted its once-peaceful forests.

Guided by a local herbalist named Lily and a reclusive former warrior named Garron, Aren learns about the rise of the Raccoon King—an enormous creature who was once a harmless forest dweller. Now empowered by a strange, magical calamari, the Raccoon King rules the forest with brute strength, supported by an army of raccoon and reptile minions.

## 🎮 Diversifiers

- **Boost**: The Calamari power-up increases the player's maximum health when consumed.
- **Inventory**: Aren can collect and manage various weapons and items through a comprehensive inventory system. Players can:
    - Cycle between weapons using **Q/E** keys.
    - Directly select items with number keys (**1-9**).
    - Toggle the inventory UI with the **I** key to display collected items in a grid format, with visual indicators for equipped weapons.
- **Boss Fight**: The King Racoon serves as the game's boss. It features increased health, stronger attacks, and a larger size compared to regular raccoons. Defeating the King Racoon triggers a victory dialogue sequence and transitions to the game's credits.

---

## 🎮 Controls

### Movement
- **WASD** or **Arrow Keys**: Move Aren in four directions.
- **Shift** - Sprint (consumes stamina)

### Combat
- **Space** / **E**: Attack with the equipped weapon.
- **1-9**: Quick-select weapons from the inventory.
- **Q**: Switch to the previous weapon.
- **E**: Switch to the next weapon.

### Interaction
- **Space** / **Enter**: Interact with NPCs and objects.
- **Space** / **Enter**: Skip or advance dialogue.

### Game Management
- **ESC**: Pause the game.
- **I**: Open the inventory.

---

## 🏃‍♂️ Latest Update: Sprint & Stamina System

**Balancing the Journey to Raccoon King**

### ⚔️ The Challenge
Based on feedback, players needed to reach the Raccoon King in under 6 minutes when running non-stop. The original movement speed made this goal difficult to achieve.

### 🛠️ The Solution
To address this, I redesigned the map to be more compact and introduced a sprint system with stamina management:

### 🚀 New Features:
- **Sprint Mechanic** ➤ Hold Shift to run faster
- **Stamina System** ➤ A blue stamina bar appears in the UI
- **Smart Balancing** ➤ Sprint drains stamina to prevent infinite speed runs

### 🔧 Technical Implementation
- **Sprint Speed**: 400 units/sec (vs 300 normal speed)
- **Stamina Drain**: 30 units/sec while sprinting
- **Stamina Regen**: 15 units/sec when idle or walking
- **Visual Feedback**: New StaminaUI component added to HUD

### 🎮 Player Experience
This system encourages players to strategically manage stamina, creating a balance between speed and endurance. It adds tension and depth, making every journey toward the Raccoon King feel like a calculated push.

*Hollowveil - A top-down RPG adventure where Aren must escape a mysterious island and defeat the Raccoon King.*

---

## 📦 Sources & Credits

### 🎮 Dialogue Systems
- [Eric De Sedas – Dialogue System Test (GitHub)](https://github.com/ericdsw/dialogue_system_test)  
- [World Eater Games – HowTo: A Simple Dialogue System in Godot](https://worldeater-dev.itch.io/bittersweet-birthday/devlog/224241/howto-a-simple-dialogue-system-in-godot)  

### 🖼️ Art & Assets
- [AntarcticBees – The Painted Lands: Forest Tileset (Itch.io)](https://antarcticbees.itch.io/antarcticbees-the-painted-lands-forest)  
- [BlodyAvenger – RPG Items Retro Pack (Itch.io)](https://blodyavenger.itch.io/rpg-items-retro-pack)  
- [GiannyDev – Udemy Profile](https://www.udemy.com/user/gianny-dev/)




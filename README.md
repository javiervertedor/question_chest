# 📦 Question Chest Mod for Luanti (Educational Edition)

This Luanti mod adds **interactive question chests** for classroom use. Teachers can create open-ended and multiple-choice questions tied to in-game rewards. Students must answer correctly to access the rewards — ideal for gamified learning!

---

## ✨ Features

### ✅ Two Chest Types
- **Open Question Chest** (`question_chest:chest`)
  - Students must type a correct free-text answer
- **Multiple Choice Chest** (`question_chest:mc_chest`)
  - Students must select all correct options from checkboxes

### 🎓 Teacher Tools
- Place and configure chests if you have the `question_chest_admin` privilege
- GUI includes:
  - Question input
  - Answers (comma-separated)
  - (For MCQ) Options (comma-separated)
  - Reward item slots
  - Save/Close buttons
  - Auto-cleared answer tracking per new question
- Preview list of students who answered correctly

### 🧠 Student Interaction
- Answer a question via GUI form
- Immediate feedback: **Correct / Incorrect**
- If correct, chest opens with reward
- Rewards are one-time and player-specific
- Partial collection supported — students may return to finish collecting

### 🔐 Protection & Fairness
- Students cannot destroy question chests
- Rewards are stored in detached inventories (per-student)
- Students cannot insert items into the chest

---

## 🛠 Setup

1. Place this mod in your `mods/` folder
2. Add it to your `world.mt`:
   ```
   load_mod_question_chest = true
   ```
3. Ensure you're using a Luanti version that supports detached inventories and `minetest.show_formspec`

---

## 🔑 Privileges

- Grant yourself the `question_chest_admin` privilege to configure chests:
  ```
  /grant teacher question_chest_admin
  ```

---

## 📁 File Structure

| File | Description |
|------|-------------|
| `init.lua` | Mod entry point, loads chest types |
| `chest_base.lua` | Registers the base node for question chests |
| `chest_open.lua` | Manages student-specific reward inventory |
| `open_question.lua` | Logic for open-ended question chests |
| `mc_question.lua` | Logic for multiple-choice question chests |
| `student_form.lua` | Open-ended student form layout |
| `teacher_form.lua` | Open-ended teacher form layout |
| `mc_student_form.lua` | MCQ student form with checkboxes |
| `mc_teacher_form.lua` | MCQ teacher form with option/answer input |
| `reward_form.lua` | Reward collection inventory form |

---

# 🧩 Future Enhancements (Implemented in Experimental Versions)

## 1. 🧱 Node Metadata Inventories (Per-Student Reward Persistence)

**Goal:**  
Replace `detached` inventories with `nodemeta`-based inventories for each student (`reward_<player_name>`), enabling reliable reward tracking and persistence.

**Advantages:**
- ✅ Rewards persist across sessions and server restarts
- ✅ Each student's progress is stored independently
- ✅ Students can collect rewards partially and return later

**How it works:**
- On correct answer:
  ```lua
  inv:set_size("reward_" .. player_name, 8)
  inv:set_list("reward_" .. player_name, reward_items)
  ```
- Inventory displayed using:
  ```lua
  list[nodemeta:<pos>;reward_<player_name>;0.3,1;8,1;]
  ```

---

## 📚 License

This mod is licensed under the **GNU General Public License v3.0**

See [LICENSE](https://www.gnu.org/licenses/gpl-3.0.html)
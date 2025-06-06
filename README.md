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
  - (For MCQ) Options with special formatting:
    - Simple options: `Selection, Loop, Array`
    - Single-quoted options: `"First Option", "Second Option"`
    - Options with commas: `""Option 1, Option 2, Option 3""`
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
- Multiple choice answers must exist in the options list

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
| `utils.lua` | Helper functions for string parsing and validation |

### 📝 Multiple Choice Format Examples

```
Question: What are the key components of a loop?
Options: "Counter", "Condition", ""Body, Update, Expression"", Loop
Correct answers: "Counter", "Condition"

Question: Which statement best describes iteration?
Options: ""A process of repeating steps"", "A one-time operation", Selection
Correct answers: ""A process of repeating steps""
```

---

## 📚 License

This project is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/) license.

### You are free to:
- Share — copy and redistribute the material in any medium or format
- Adapt — remix, transform, and build upon the material

### Under the following terms:
- **Attribution** — You must give appropriate credit (to Francisco Javier Vertedor Postigo), provide a link to the license, and indicate if changes were made.
- **NonCommercial** — You may not use the material for commercial purposes.

---

Developed by Francisco Javier Vertedor Postigo for Luanti educational environments.

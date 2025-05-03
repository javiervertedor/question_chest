# 🎓 Luanti Education Mod: `question_chest`

An interactive and configurable question chest for Luanti (formerly Minetest) designed specifically for classroom use. Teachers can place reward chests that students must **unlock by answering questions** correctly. A powerful tool for combining gamification with learning.

---

## 🚀 Features

- 📦 Place indestructible, protected chests that reward players upon correct answers
- ✅ Supports **open-ended** and **multiple-choice** questions
- 🎁 Each question has a **custom reward** (item + count)
- 🔁 **MCQ answers are shuffled** randomly per student
- 🧠 Students unlock one question at a time and earn rewards as they progress
- 📚 **Answer log**: track which students answered which questions
- 🧑‍🏫 Teacher-only configuration interface (requires `question_chest_admin` privilege)
- 🧾 Optional integration with Luanti’s `whitelist.txt` for tracking participation
- ✏️ Add/Edit/Delete multiple questions per chest
- 🔒 Built on top of `protector:chest` for safe use in classroom areas

---

## 🧑‍🏫 Teacher Setup

1. **Right-click** the question chest (must have `question_chest_admin` privilege)
2. Configure:
   - Question text
   - Question type (`open-ended` or `multiple-choice`)
   - Answer list and correct options
   - Reward (itemstring + count)
3. Add multiple questions, preview existing ones, and view who has completed each
4. Use the "📦 Edit Rewards" button to select the reward for each question

---

## 👩‍🎓 Student Interaction

- Right-click the chest
- Answer the current question shown
- If correct:
  - Receive the reward for that question
  - Progress to the next question
- If incorrect:
  - Chest closes (natural cooldown)
  - Retry by clicking again
- When all questions are completed:
  - Chest appears empty for that student

---

## 🔧 Optional Features (Planned)

- Retry cooldown or attempt limits
- `question_chest:tool` for copying/pasting configs between chests
- CSV export of student answers
- Unlock questions in timed or sequential formats

---

## 📁 Installation

1. Clone or download this repository into your `mods/` folder:
    ```bash
    git clone https://github.com/javiervertedor/question_chest.git
    ```
2. Enable the mod in your world’s `world.mt`:
    ```
    load_mod_question_chest = true
    ```
3. (Optional) Install `protector` mod if not already installed

---

## 🔐 Privileges

| Privilege               | Description                           |
|------------------------|---------------------------------------|
| `question_chest_admin` | Allows configuring and editing chests |

---

## 📜 License

GNU General Public License v3.0.

---

## 👨‍💻 Development

This project was designed for classroom gamification in Luanti. Contributions and suggestions are welcome.


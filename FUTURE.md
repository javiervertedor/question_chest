
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

## 2. 🚫 Prevent Students from Inserting Items into the Chest

**Goal:**  
Ensure students can only **collect** rewards — not insert or store their own items.

**Implementation:**
Add this to your chest node registration (e.g., in `chest_base.lua`):

```lua
allow_metadata_inventory_put = function(pos, listname, index, stack, player)
    if listname:sub(1, 7) == "reward_" then
        return 0  -- Disallow insertion
    end
    return stack:get_count()
end
```

**Benefit:**
- ✅ Secures the chest content
- ✅ Prevents cheating or unintended item storage

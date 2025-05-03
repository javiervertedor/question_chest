# 📘 filter++ Chat Filter Configuration for Luanti

This document explains how to enable and configure multilingual (English + Chinese) chat filtering in your **Luanti** (Minetest) server using the `filter++` mod.

---

## ✅ What We Did

These two files contain a list of swear words:

- `swear_words.en.lua`: Contains English swear words and inappropriate terms.
- `swear_words.cn.lua`: Contains Chinese inappropriate words and phrases, including their pinyin versions.

These are now automatically loaded when the server starts.

---

## 📂 Where to Put the Files

Place both files in your `filterpp_lib/` mod directory:

```
mods/
└── filterpp_lib/
    ├── init.lua
    ├── swear_words.en.lua
    └── swear_words.cn.lua
```

---

## 🧠 How It Works

Inside your `init.lua` file in `filterpp_lib`, add the following block of code **at the end**:

```lua
if #filterpp_lib.blacklist == 0 then
    dofile(minetest.get_modpath("filterpp_lib") .. "/swear_words.en.lua")
    dofile(minetest.get_modpath("filterpp_lib") .. "/swear_words.cn.lua")
end
```

This ensures the blacklist loads only once and includes both English and Chinese filters.

---

## ✅ Result

Players who attempt to type offensive words in English **or** Chinese will have their messages censored according to the configured behavior in `filter++`.

You can customize how violations are handled (e.g., warnings, mutes, kicks) in `filterpp_lib`'s main Lua logic.

---

## 💬 Need Help?

Feel free to ask for:
- Custom violation messages
- Word log tracking
- Automatic muting or banning

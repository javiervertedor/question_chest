local function parse_quoted_string(str)
    local items = {}
    local current_pos = 1
    local len = string.len(str)
    
    while current_pos <= len do
        -- Skip whitespace
        current_pos = string.find(str, "[^%s]", current_pos) or (len + 1)
        if current_pos > len then break end

        if string.sub(str, current_pos, current_pos + 1) == '""' then
            -- Find the end of the double-quoted block
            local _, end_pos = string.find(str, '""[^"]*""', current_pos)
            if end_pos then
                -- Extract without the outer quotes
                local item = string.sub(str, current_pos + 2, end_pos - 2)
                table.insert(items, item)
                current_pos = end_pos + 1
            else
                break
            end
        elseif string.sub(str, current_pos, current_pos) == '"' then
            -- Find the end of the single-quoted token
            local _, end_pos = string.find(str, '"[^"]*"', current_pos)
            if end_pos then
                -- Extract without the quotes
                local item = string.sub(str, current_pos + 1, end_pos - 1)
                table.insert(items, item)
                current_pos = end_pos + 1
            else
                break
            end
        else
            -- Unquoted item until next comma or end
            local end_pos = string.find(str, ",", current_pos) or (len + 1)
            local item = string.sub(str, current_pos, end_pos - 1):match("^%s*(.-)%s*$")
            if item and item ~= "" then
                table.insert(items, item)
            end
            current_pos = end_pos + 1
        end
    end
    return items
end

return {
    parse_quoted_string = parse_quoted_string
}